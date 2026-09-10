#!/usr/bin/env bash
# Validates a Terraform workload directory: initializes without a backend and
# runs terraform validate. Run this once instead of reasoning through
# init/validate output manually.
#
# Usage: ./validate-terraform.sh [directory]
#   directory defaults to the current directory

set -euo pipefail

DIR="${1:-.}"

echo "== terraform init (no backend) in $DIR =="
terraform -chdir="$DIR" init -backend=false

echo "== terraform validate in $DIR =="
terraform -chdir="$DIR" validate

echo ""
echo "Terraform configuration is valid."
