#!/bin/bash
# Rewrite HEAD commit message without changing code (bypasses Cursor co-author injection).
set -euo pipefail
if [ $# -lt 1 ]; then
  echo "Usage: $0 \"commit message\"" >&2
  exit 1
fi
cd "$(git rev-parse --show-toplevel)"
tree=$(git rev-parse 'HEAD^{tree}')
parent=$(git rev-parse 'HEAD^')
msg_file=$(mktemp)
printf '%s\n' "$1" > "$msg_file"
new=$(git commit-tree "$tree" -p "$parent" -F "$msg_file")
rm -f "$msg_file"
git reset --hard "$new"
echo "Rewrote HEAD: $(git rev-parse --short HEAD)"
git log -1 --format=fuller
