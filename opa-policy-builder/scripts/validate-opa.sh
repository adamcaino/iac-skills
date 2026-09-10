#!/usr/bin/env bash
# Runs opa test across policy/ and tests/, then evaluates every example input
# under examples/. Run this once instead of invoking opa test/eval
# individually per package.
#
# Usage: ./validate-opa.sh [policy-root]
#   policy-root defaults to the current directory (expects policy/, tests/,
#   examples/ beneath it)

set -euo pipefail

ROOT="${1:-.}"
FAIL=0

echo "== opa test =="
opa test "$ROOT/policy" "$ROOT/tests" -v || FAIL=1

echo "== opa eval examples =="
for example in "$ROOT"/examples/*/*.json; do
	[ -e "$example" ] || continue
	echo "-- $example"
	opa eval --format pretty --data "$ROOT/policy" --input "$example" "data" >/dev/null || FAIL=1
done

if [ "$FAIL" -ne 0 ]; then
	echo "" >&2
	echo "OPA validation failed. See output above." >&2
	exit 1
fi

echo ""
echo "All OPA policies and examples validated successfully."
