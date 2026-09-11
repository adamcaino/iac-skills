#!/usr/bin/env bash
# Validates all Terraform platform and workload roots under a target directory tree.
# Initializes each root without a backend and runs terraform validate.
#
# Usage: ./validate-terraform.sh [root-path]
#   root-path defaults to terraform (or current directory if not found)

set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
	if [ -d "terraform" ]; then
		TARGET="terraform"
	elif [ -d "workloads" ] || [ -d "platform" ]; then
		TARGET="."
	else
		TARGET="."
	fi
fi

FAIL=0

validate_dir() {
	local d="$1"
	echo "== Validating Terraform in $d =="
	terraform -chdir="$d" init -backend=false || FAIL=1
	terraform -chdir="$d" validate || FAIL=1
}

if [ -f "$TARGET/main.tf" ]; then
	validate_dir "$TARGET"
else
	found=0
	while IFS= read -r main_file; do
		[ -n "$main_file" ] || continue
		found=1
		workload_dir="$(dirname "$main_file")"
		validate_dir "$workload_dir"
	done < <(find "$TARGET" -maxdepth 4 -name "main.tf" -not -path "*/.*/*" | sort)

	if [ "$found" -eq 0 ]; then
		echo "No main.tf found under $TARGET" >&2
		exit 1
	fi
fi

if [ "$FAIL" -ne 0 ]; then
	echo "" >&2
	echo "One or more Terraform validations failed. See output above." >&2
	exit 1
fi

echo ""
echo "All Terraform configurations validated successfully."
