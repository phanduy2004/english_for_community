#!/bin/bash
# Preview which CI workflows would run for staged + unstaged changes vs last commit.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

web_patterns=(
  'english_for_community/lib/'
  'english_for_community/web/'
  'english_for_community/assets/'
  'english_for_community/pubspec.yaml'
  'english_for_community/pubspec.lock'
  'english_for_community/config/prod.json'
  'english_for_community/firebase.json'
  'english_for_community/.firebaserc'
  '.github/workflows/firebase-hosting-merge.yml'
)

apk_patterns=(
  'english_for_community/lib/'
  'english_for_community/android/'
  'english_for_community/assets/'
  'english_for_community/pubspec.yaml'
  'english_for_community/pubspec.lock'
  'english_for_community/config/prod.json'
  '.github/workflows/main-auto-build-candidate.yml'
)

matches_any() {
  local file=$1
  shift
  local pat
  for pat in "$@"; do
    case "$file" in
      $pat*) return 0 ;;
    esac
  done
  return 1
}

changed=$(git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached 2>/dev/null)
changed=$(echo "$changed" | sed '/^$/d' | sort -u)

web=0
apk=0
if [ -z "$changed" ]; then
  echo "No file changes vs HEAD (working tree clean)."
  exit 0
fi

echo "Changed files:"
echo "$changed" | sed 's/^/  /'

while IFS= read -r f; do
  [ -z "$f" ] && continue
  if matches_any "$f" "${web_patterns[@]}"; then web=1; fi
  if matches_any "$f" "${apk_patterns[@]}"; then apk=1; fi
done <<< "$changed"

echo ""
echo "CI impact (push to main, no [skip ci]):"
if [ "$web" -eq 1 ]; then echo "  WEB deploy (firebase-hosting): YES"; else echo "  WEB deploy (firebase-hosting): no"; fi
if [ "$apk" -eq 1 ]; then echo "  APK candidate build (+ versionCode): YES"; else echo "  APK candidate build (+ versionCode): no"; fi

if [ "$web" -eq 0 ] && [ "$apk" -eq 0 ]; then
  echo ""
  echo "Tip: docs/skill/backend-only — CI should not run. Optional: add [skip ci] to subject anyway."
fi
