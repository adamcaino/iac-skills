#!/usr/bin/env bash
# Validates every Bicep root, unreferenced shared module, and .bicepparam file under a tree.
# Builds each main.bicep (which also compiles referenced modules), any module not referenced
# by another .bicep file, and each params/*.bicepparam into builds/env.<env>.json. Compiled
# ARM templates are discarded, so no stray .json files are written next to sources.
# Diagnostics are de-duplicated, paths are made relative, and doc links are stripped so the
# output stays compact. Exits 1 on any error. Windows: use validate-bicep.ps1 instead.
#
# Usage: ./validate-bicep.sh [root-path]   (defaults to ./bicep if present, else .)

set -uo pipefail
export AZURE_BICEP_CHECK_VERSION=false
# Forward the setting when WSL calls a Windows az/bicep binary.
export WSLENV="${WSLENV:+$WSLENV:}AZURE_BICEP_CHECK_VERSION"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
	if [ -d "bicep" ]; then TARGET="bicep"; else TARGET="."; fi
fi

if command -v bicep >/dev/null 2>&1; then
	build()        { bicep build "$1" --stdout </dev/null >/dev/null; }
	build_params() { bicep build-params "$1" --outfile "$2" </dev/null; }
else
	build()        { az bicep build --file "$1" --stdout </dev/null >/dev/null; }
	build_params() { az bicep build-params --file "$1" --outfile "$2" </dev/null; }
fi

DIAG="$(mktemp)"
trap 'rm -f "$DIAG" "$DIAG.u"' EXIT
FAIL=0
roots=0; orphans=0; params=0

while IFS= read -r f; do
	roots=$((roots + 1))
	build "$f" 2>>"$DIAG" || FAIL=1
done < <(find "$TARGET" -name "main.bicep" -not -path "*/modules/*" -not -path "*/.*/*" | sort)

while IFS= read -r mod; do
	name="$(basename "$mod")"
	if ! grep -rlF --include="*.bicep" "$name" "$TARGET" | grep -vxF "$mod" | grep -q .; then
		orphans=$((orphans + 1))
		build "$mod" 2>>"$DIAG" || FAIL=1
	fi
done < <(find "$TARGET" -path "*/modules/*.bicep" -not -path "*/.*/*" | sort)

while IFS= read -r pf; do
	params=$((params + 1))
	builds_dir="$(dirname "$(dirname "$pf")")/builds"
	mkdir -p "$builds_dir"
	env_name="$(basename "$pf" .bicepparam)"
	env_name="${env_name#env.}"
	build_params "$pf" "$builds_dir/env.${env_name}.json" 2>>"$DIAG" || FAIL=1
done < <(find "$TARGET" -path "*/params/*.bicepparam" -not -path "*/.*/*" | sort)

sed_escape() { printf '%s' "$1" | sed 's/[][\\.*^$#()+?{}|]/\\&/g'; }
strip_cwd=(-e "s#$(sed_escape "$(pwd -P)/")##")
if command -v wslpath >/dev/null 2>&1; then
	strip_cwd+=(-e "s#$(sed_escape "$(wslpath -w "$(pwd -P)")\\")##I")
fi
tr -d '\r' < "$DIAG" | sed -E -e 's/^(WARNING|ERROR): //' -e 's/[[:space:]]*\[https:\/\/aka\.ms\/[^]]+\]$//' \
	-e '/new Bicep release is available/d' -e '/^[[:space:]]*$/d' "${strip_cwd[@]}" | sort -u > "$DIAG.u"
errors=$(grep -vc ': Warning ' "$DIAG.u" || true)
warnings=$(grep -c ': Warning ' "$DIAG.u" || true)
{ grep -v ': Warning ' "$DIAG.u"; grep ': Warning ' "$DIAG.u"; } || true

summary="roots=$roots orphan-modules=$orphans params=$params errors=$errors warnings=$warnings"
if [ "$FAIL" -ne 0 ]; then echo "FAIL $summary"; exit 1; fi
echo "PASS $summary"
