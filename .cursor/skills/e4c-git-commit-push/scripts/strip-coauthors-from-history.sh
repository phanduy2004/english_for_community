#!/bin/bash
# Remove AI co-author trailers from all commit messages on main. Code (trees) unchanged.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
export FILTER_BRANCH_SQUELCH_WARNING=1

before_tree=$(git rev-parse 'HEAD^{tree}')
filter='sed -e "/[Cc]o-[Aa]uthored-[Bb]y:.*cursoragent@cursor\\.com/d" -e "/[Cc]o-[Aa]uthored-[Bb]y:.*anthropic\\.com/d" -e "/^[Mm]ade-with:.*[Cc]ursor/d"'

git filter-branch -f --msg-filter "$filter" main

after_tree=$(git rev-parse 'HEAD^{tree}')
if [ "$before_tree" != "$after_tree" ]; then
  echo "ERROR: HEAD tree changed — aborting" >&2
  exit 1
fi

remaining=$(git log main --grep='Co-authored' --grep='Co-Authored' -i --oneline | wc -l | tr -d ' ')
if [ "$remaining" != "0" ]; then
  echo "ERROR: $remaining commits still have co-author trailers" >&2
  exit 1
fi

git for-each-ref --format='%(refname)' refs/original/ | while read -r ref; do
  git update-ref -d "$ref"
done 2>/dev/null || true

echo "OK: messages cleaned, tree unchanged at $after_tree"
echo "Next: git push --force-with-lease origin main"
