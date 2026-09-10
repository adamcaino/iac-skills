#!/usr/bin/env bash
# Validates all Bicep modules, workload roots, and parameter files under a
# bicep/workloads tree. Builds shared modules, then each root's main.bicep,
# then every .bicepparam file into its matching builds/env.<env>.json.
#
# Usage: ./validate-bicep.sh [root-path]
#   root-path defaults to bicep/workloads

set -euo pipefail

ROOT="${1:-bicep/workloads}"
FAIL=0

echo "== Building shared modules =="
if [ -d "$ROOT/modules" ]; then
	for f in "$ROOT"/modules/*.bicep; do
		[ -e "$f" ] || continue
		echo "-- $f"
		az bicep build --file "$f" || FAIL=1
	done
else
	echo "(no modules/ folder found under $ROOT)"
fi

echo "== Building workload roots =="
for main in "$ROOT"/*/main.bicep; do
	[ -e "$main" ] || continue
	echo "-- $main"
	az bicep build --file "$main" || FAIL=1
done

echo "== Building parameter files =="
for params_dir in "$ROOT"/*/params; do
	[ -d "$params_dir" ] || continue
	root_dir="$(dirname "$params_dir")"
	builds_dir="$root_dir/builds"
	mkdir -p "$builds_dir"
	for pf in "$params_dir"/*.bicepparam; do
		[ -e "$pf" ] || continue
		env_name="$(basename "$pf" .bicepparam)"
		outfile="$builds_dir/env.${env_name}.json"
		echo "-- $pf -> $outfile"
		az bicep build-params --file "$pf" --outfile "$outfile" || FAIL=1
	done
done

if [ "$FAIL" -ne 0 ]; then
	echo "" >&2
	echo "One or more Bicep builds failed. See output above." >&2
	exit 1
fi

echo ""
echo "All Bicep modules, roots, and parameter files built successfully."
