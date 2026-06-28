---
name: e4c-git-commit-push
description: >-
  Commit and push English for Community (E4C) monorepo safely: stage the right
  files, avoid unnecessary CI (web deploy / APK version bump), strip AI co-author
  trailers, verify tree unchanged on history rewrite, and push. Use when the user
  asks to commit, push, đẩy code, lưu git, sync GitHub, or skip CI.
---

# E4C — Commit & Push

Skill chỉ gồm **markdown** — Agent đọc và thực hiện lệnh git/bash khi cần, không gọi script trong folder này.

## Tài liệu

| File | Nội dung |
|------|----------|
| [commit-workflow.md](commit-workflow.md) | Checklist commit/push, commit qua file message |
| [ci-paths.md](ci-paths.md) | Path trigger web / APK, `[skip ci]` |
| [co-author-fixes.md](co-author-fixes.md) | Hook, sửa message, rewrite history |

## Trigger

User: commit, push, đẩy code, lưu git, sync GitHub, skip CI.

**Chỉ commit khi user yêu cầu rõ.**

## Checklist nhanh

```
- [ ] git status + diff + log -5
- [ ] Đánh giá CI theo ci-paths.md — báo user web/APK
- [ ] Stage đúng file (không secrets, gradle.properties, artifacts)
- [ ] Message conventional (+ [skip ci] nếu docs/skill/backend-only)
- [ ] git commit -F file (KHÔNG git commit -m từ Agent)
- [ ] Verify không có co-authored trong message
- [ ] git push origin main
```

## Author (chỉ phanduy2004)

`phanduy2004 <conlocmuahe2004@gmail.com>` — không `Co-authored-by` Cursor/Claude.

## Stage / exclude

**Không commit:** `.env`, secrets, `gradle.properties`, `docs/dev/artifacts/`, `migrations/artifacts/`, `.dart_tool/`, `build/`, `node_modules/`, signing keys.

**Thường commit:** `lib/`, `l10n/`, backend `src/`, `docs/` (trừ artifacts), `.github/workflows/`, `.cursor/skills/`.

## Message mẫu

```
feat(mobile): short summary

Why in 1-2 sentences. [skip ci]
```

## Push

- `git push origin main`
- Force push `main`: chỉ khi user yêu cầu rewrite history → xem [co-author-fixes.md](co-author-fixes.md)

## Windows

PowerShell: `;` thay `&&`. Git plumbing / commit: dùng Git Bash (`C:\Program Files\Git\bin\bash.exe`).

## PR

`gh pr create` — không attribution Cursor trong body.
