# Xử lý co-author (Cursor / Claude)

GitHub đếm contributor từ dòng `Co-authored-by:` trong commit message. Agent **không** được để các dòng này trong message.

## Phòng ngừa

1. **Cursor IDE:** Settings → Agents → Attribution → OFF (Commit + PR)
2. **Git hook** (một lần mỗi clone) — tạo `.git/hooks/prepare-commit-msg`:

```sh
#!/bin/sh
if [ -f "$1" ]; then
  sed -i '/[Cc]o-[Aa]uthored-[Bb]y:.*cursoragent@cursor\.com/d' "$1" 2>/dev/null || \
    sed -i '' '/[Cc]o-[Aa]uthored-[Bb]y:.*cursoragent@cursor\.com/d' "$1" 2>/dev/null || true
  sed -i '/[Cc]o-[Aa]uthored-[Bb]y:.*anthropic\.com/d' "$1" 2>/dev/null || \
    sed -i '' '/[Cc]o-[Aa]uthored-[Bb]y:.*anthropic\.com/d' "$1" 2>/dev/null || true
  sed -i '/^[Mm]ade-with:.*[Cc]ursor/d' "$1" 2>/dev/null || \
    sed -i '' '/^[Mm]ade-with:.*[Cc]ursor/d' "$1" 2>/dev/null || true
fi
```

```bash
chmod +x .git/hooks/prepare-commit-msg
```

Hook nằm trong `.git/` — không commit lên repo; mỗi clone cần cài lại.

## Sửa commit vừa tạo (message sai, code không đổi)

`git commit --amend` có thể bị Cursor chèn lại trailer. Dùng `commit-tree` qua Git Bash:

```bash
cd "$(git rev-parse --show-toplevel)"
tree=$(git rev-parse 'HEAD^{tree}')
parent=$(git rev-parse 'HEAD^')
msg_file=$(mktemp)
cat > "$msg_file" <<'EOF'
feat(scope): your message here

Body nếu cần. Không có Co-authored-by.
EOF
new=$(git commit-tree "$tree" -p "$parent" -F "$msg_file")
rm -f "$msg_file"
git reset --hard "$new"
git log -1 --format=fuller
```

PowerShell: dùng `HEAD^{tree}` trong **single-quoted** string hoặc chạy cả block bằng `bash.exe`.

## Xóa co-author toàn bộ lịch sử `main` (user yêu cầu)

Chỉ sửa **message**, không đổi code. **Bắt buộc** verify tree trước/sau giống nhau.

```bash
cd "$(git rev-parse --show-toplevel)"
export FILTER_BRANCH_SQUELCH_WARNING=1
before_tree=$(git rev-parse 'HEAD^{tree}')

git filter-branch -f --msg-filter \
  "sed -e '/[Cc]o-[Aa]uthored-[Bb]y:.*cursoragent@cursor\\.com/d' -e '/[Cc]o-[Aa]uthored-[Bb]y:.*anthropic\\.com/d' -e '/^[Mm]ade-with:.*[Cc]ursor/d'" \
  main

after_tree=$(git rev-parse 'HEAD^{tree}')
test "$before_tree" = "$after_tree" || { echo "ERROR: tree changed"; exit 1; }

git log main --grep='Co-authored' -i --oneline | wc -l
# phải = 0

git for-each-ref --format='%(refname)' refs/original/ | while read -r ref; do
  git update-ref -d "$ref"
done 2>/dev/null || true
```

Push (chỉ khi user đồng ý):

```bash
git push --force-with-lease origin main
```

Subject commit cleanup nên có `[skip ci]`. Báo user: GitHub Contributors có thể cập nhật chậm 1–2 giờ.
