# Commit workflow (mô tả cho Agent)

Agent **đọc file này** khi cần commit/push — không cần chạy script trong folder skill.

## 1. Thu thập trạng thái

Chạy song song:

```bash
git status
git diff
git diff --cached
git log -5 --oneline
```

## 2. Đánh giá CI trước khi push

Lấy danh sách file đổi (staged + unstaged):

```bash
git diff --name-only HEAD
git diff --name-only --cached
```

Đối chiếu với bảng path trong [ci-paths.md](ci-paths.md):

| Nếu file đổi khớp prefix… | Web deploy | APK + versionCode |
|---------------------------|------------|-------------------|
| `english_for_community/lib/`, `web/`, `assets/`, `pubspec.*`, `config/prod.json`, firebase config, workflow web | Có | Có (nếu khớp path APK) |
| Chỉ `docs/`, `.cursor/`, `english_for_community_backend/`, plantasks | Không | Không |

**Báo user** rõ WEB/APK có chạy hay không. Nếu chỉ docs/skill → thêm `[skip ci]` vào subject.

## 3. Stage file

Chỉ `git add` file liên quan. **Không** add:

- `.env`, secrets, `gradle.properties`, artifacts, `.dart_tool/`, `build/`, `node_modules/`

## 4. Commit an toàn (tránh Cursor chèn co-author)

Cursor Agent có thể bọc `git commit -m` bằng `--trailer "Co-authored-by: Cursor …"`. **Không** dùng `git commit -m` trực tiếp từ Agent.

**Cách làm:**

1. Ghi message vào file tạm (ví dụ `.git/COMMIT_MSG.txt`)
2. Stage xong
3. Commit qua Git Bash:

```bash
cd "$(git rev-parse --show-toplevel)"
git commit -F .git/COMMIT_MSG.txt
```

4. Kiểm tra message:

```bash
git log -1 --format='%B' | grep -iE 'co-authored|cursoragent|anthropic|made-with' || echo "OK: clean"
```

Nếu còn co-author → xem [co-author-fixes.md](co-author-fixes.md).

**Windows (PowerShell):**

```powershell
& "C:\Program Files\Git\bin\bash.exe" -lc "cd /d/Workspace/english_for_community && git commit -F .git/COMMIT_MSG.txt"
```

## 5. Push

```bash
git push origin main
```

Branch mới: `git push -u origin HEAD`

## 6. Báo cáo cho user

- Commit hash + subject
- CI impact (web / APK / không chạy)
- `[skip ci]` có trong message không
