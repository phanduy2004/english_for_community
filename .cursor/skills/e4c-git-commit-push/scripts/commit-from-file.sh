#!/bin/bash
# Commit staged changes with a message file — avoids Cursor injecting --trailer Co-authored-by.
set -euo pipefail
if [ $# -lt 1 ]; then
  echo "Usage: $0 path/to/message.txt" >&2
  exit 1
fi
cd "$(git rev-parse --show-toplevel)"
msg_file=$1
if [ ! -f "$msg_file" ]; then
  echo "Message file not found: $msg_file" >&2
  exit 1
fi
git commit -F "$msg_file"
if git log -1 --format='%B' | grep -qiE 'co-authored|cursoragent|anthropic|made-with'; then
  echo "ERROR: co-author trailer detected — rewrite with rewrite-last-commit-msg.sh" >&2
  exit 1
fi
echo "OK: $(git rev-parse --short HEAD)"
