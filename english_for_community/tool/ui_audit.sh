#!/usr/bin/env bash
# ui_audit.sh — Đếm vi phạm tiêu chuẩn UI/UX theo role.
# Spec: docs/ui-ux-system/18 §6.6 (teacher) · 19 §6 (admin) · 20 §6 (student).
# Dùng:
#   bash tool/ui_audit.sh [teacher|admin|student|all] [--list]
#   (mặc định teacher; --list để in từng dòng vi phạm)
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

WHO="teacher"; LIST=""
for a in "$@"; do
  case "$a" in
    teacher|admin|student|all) WHO="$a" ;;
    --list) LIST="--list" ;;
  esac
done

# Bỏ qua dòng có `// audit-ignore` và các file palette gốc (màu hợp lệ).
EXCLUDE_LINES='// *audit-ignore'
EXCLUDE_FILES='admin_skill_palette\.dart|app_skill_colors\.dart'

STUDENT_DIRS="lib/feature/home lib/feature/student lib/feature/listening lib/feature/listening_comp lib/feature/reading lib/feature/speaking lib/feature/writing lib/feature/vocabulary lib/feature/profile lib/feature/progress"

count() { # $1 = space-separated relative dirs  $2 = pattern
  local paths=""
  for d in $1; do paths="$paths $ROOT/$d"; done
  grep -rEn --include='*.dart' "$2" $paths 2>/dev/null \
    | grep -vE "$EXCLUDE_LINES" \
    | grep -vE "$EXCLUDE_FILES"
}

report() { # $1 = dirs  $2 = nhãn  $3 = pattern
  local hits; hits="$(count "$1" "$3")"
  local n; n="$(printf '%s' "$hits" | grep -c . )"
  printf '%-46s %4s   (mục tiêu: 0)\n' "$2" "$n"
  if [ "$LIST" = "--list" ] && [ "$n" -gt 0 ]; then
    printf '%s\n' "$hits" | sed 's/^/    /'
    echo
  fi
}

audit_scope() { # $1 = nhãn hiển thị  $2 = dirs
  echo "──────────────────────────────────────────────────────────────"
  echo " UI AUDIT · $1"
  echo "──────────────────────────────────────────────────────────────"
  report "$2" "Hex literal  Color(0x…)"             'Color\(0x'
  report "$2" "Radius literal  circular(<số>)"      'BorderRadius\.circular\([0-9]'
  report "$2" "Duration literal  milliseconds:<số>" 'Duration\(milliseconds: *[0-9]'
  report "$2" "Spinner  AppLoadingIndicator.center" 'AppLoadingIndicator\.center'
}

case "$WHO" in
  teacher) audit_scope teacher "lib/feature/teacher" ;;
  admin)   audit_scope admin   "lib/feature/admin"   ;;
  student) audit_scope "student (mobile)" "$STUDENT_DIRS" ;;
  all)     audit_scope teacher "lib/feature/teacher"; echo
           audit_scope admin   "lib/feature/admin";   echo
           audit_scope "student (mobile)" "$STUDENT_DIRS" ;;
esac

echo "──────────────────────────────────────────────────────────────"
echo "0 = đạt (trừ admin_skill_palette.dart / app_skill_colors.dart). Chi tiết: thêm --list"
