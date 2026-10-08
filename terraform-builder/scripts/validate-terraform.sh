#!/usr/bin/env bash
# Validates every Terraform root (directory containing main.tf) under a tree.
# Runs `terraform init -backend=false` and `terraform validate` per root. Init output is shown
# only on failure; diagnostics are printed one per line as <path>:<line>: <severity>: <message>
# (falls back to compact plain text if python3 is unavailable). Provider plugins are cached
# across roots (TF_PLUGIN_CACHE_DIR) to avoid repeat downloads. Exits 1 on any error.
# Windows: use validate-terraform.ps1 instead.
#
# Usage: ./validate-terraform.sh [root-path]   (defaults to ./terraform if present, else .)

set -uo pipefail
export TF_IN_AUTOMATION=1
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
	if [ -d "terraform" ]; then TARGET="terraform"; else TARGET="."; fi
fi

if [ -f "$TARGET/main.tf" ]; then
	ROOTS=("$TARGET")
else
	mapfile -t ROOTS < <(find "$TARGET" -maxdepth 4 -name "main.tf" -not -path "*/.*/*" -exec dirname {} \; | sort)
fi
if [ "${#ROOTS[@]}" -eq 0 ]; then echo "FAIL no main.tf found under $TARGET"; exit 1; fi

FORMAT_PY='
import json, sys
root = sys.argv[1]
r = json.load(sys.stdin)
for d in r.get("diagnostics", []):
    rng = d.get("range")
    where = "%s/%s:%s" % (root, rng["filename"], rng["start"]["line"]) if rng else root
    detail = " - " + " ".join(d["detail"].split()) if d.get("detail") else ""
    print("%s: %s: %s%s" % (where, d["severity"], d["summary"], detail))
'

FAIL=0; roots=0; errors=0; warnings=0
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

for root in "${ROOTS[@]}"; do
	roots=$((roots + 1))
	rel="${root#./}"
	if ! terraform -chdir="$root" init -backend=false -input=false -no-color </dev/null >"$LOG" 2>&1; then
		FAIL=1; errors=$((errors + 1))
		echo "$rel: init failed"
		sed '/^[[:space:]]*$/d' "$LOG" | tail -n 15 | sed 's/^/  /'
		continue
	fi

	if command -v python3 >/dev/null 2>&1; then
		terraform -chdir="$root" validate -json -no-color </dev/null >"$LOG" 2>/dev/null || FAIL=1
		out="$(python3 -c "$FORMAT_PY" "$rel" <"$LOG")"
	else
		terraform -chdir="$root" validate -no-color </dev/null >"$LOG" 2>&1 || FAIL=1
		out="$(grep -v '^Success!' "$LOG" | sed '/^[[:space:]]*$/d')"
	fi
	if [ -n "$out" ]; then
		echo "$out"
		errors=$((errors + $(grep -cE '(: error: |^Error: )' <<<"$out" || true)))
		warnings=$((warnings + $(grep -cE '(: warning: |^Warning: )' <<<"$out" || true)))
	fi
done

summary="roots=$roots errors=$errors warnings=$warnings"
if [ "$FAIL" -ne 0 ]; then echo "FAIL $summary"; exit 1; fi
echo "PASS $summary"