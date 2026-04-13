#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_ROOT="${COPILOT_HOME:-$HOME/.copilot}"
DEST_SKILLS_DIR="$DEST_ROOT/skills"

mkdir -p "$DEST_SKILLS_DIR"

copied=0

while IFS= read -r -d '' skill_file; do
  skill_dir="$(dirname "$skill_file")"
  skill_name="$(basename "$skill_dir")"
  dest_dir="$DEST_SKILLS_DIR/$skill_name"

  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"
  cp -R "$skill_dir"/. "$dest_dir"/

  copied=$((copied + 1))
  printf 'Installed %s -> %s\n' "$skill_name" "$dest_dir"
done < <(find "$SCRIPT_DIR" -mindepth 2 -maxdepth 2 -type f -name 'SKILL.md' -print0 | sort -z)

if [[ "$copied" -eq 0 ]]; then
  echo "No skills found to install."
  exit 1
fi

printf 'Installed %d skills into %s\n' "$copied" "$DEST_SKILLS_DIR"