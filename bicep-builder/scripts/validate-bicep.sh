#!/usr/bin/env bash
# Validates all Bicep modules, platform/workload roots, and parameter files under
# a bicep tree. Builds shared modules, then each root's main.bicep, then every
# .bicepparam file into its matching builds/env.<env>.json.
#
# Usage: ./validate-bicep.sh [root-path]
#   root-path defaults to bicep (or current directory if bicep/ does not exist)

set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
	if [ -d "bicep" ]; then
		TARGET="bicep"
	elif [ -d "workloads" ]; then
		TARGET="."
	else
		TARGET="."
	fi
fi

FAIL=0

echo "== Building shared modules =="
module_found=0
while IFS= read -r mod_file; do
	[ -n "$mod_file" ] || continue
	module_found=1
	echo "-- $mod_file"
	az bicep build --file "$mod_file" || FAIL=1
done < <(find "$TARGET" -path "*/modules/*.bicep" -not -path "*/.*/*" | sort)

if [ "$module_found" -eq 0 ]; then
	echo "(no shared modules found under $TARGET)"
fi

echo "== Building platform and workload roots =="
while IFS= read -r main_file; do
	[ -n "$main_file" ] || continue
	echo "-- $main_file"
	az bicep build --file "$main_file" || FAIL=1
done < <(find "$TARGET" -name "main.bicep" -not -path "*/modules/*" -not -path "*/.*/*" | sort)

echo "== Building parameter files =="
while IFS= read -r params_dir; do
	[ -n "$params_dir" ] || continue
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
done < <(find "$TARGET" -type d -name "params" -not -path "*/.*/*" | sort)

if [ "$FAIL" -ne 0 ]; then
	echo "" >&2
	echo "One or more Bicep builds failed. See output above." >&2
	exit 1
fi

echo ""
echo "All Bicep modules, roots, and parameter files built successfully."
