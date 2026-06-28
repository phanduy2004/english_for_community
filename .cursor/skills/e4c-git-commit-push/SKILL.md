---
name: e4c-git-commit-push
description: >-
  Commit and push English for Community (E4C) monorepo safely: stage the right
  files, avoid unnecessary CI (web deploy / APK version bump), strip AI co-author
  trailers, verify tree unchanged on history rewrite, and push. Use when the user
  asks to commit, push, đẩy code, lưu git, sync GitHub, or skip CI.
---

# E4C — Commit & Push

## Trigger

User says: commit, push, đẩy code, lưu lên git, sync GitHub, skip CI, etc.

**Only commit when explicitly asked.** If unclear, ask first.

## Workflow checklist

```
- [ ] 1. git status + git diff + git log -5 (parallel)
- [ ] 2. bash scripts/preview-ci-impact.sh — báo user web/APK có chạy không
- [ ] 3. Stage relevant files only (exclusions below)
- [ ] 4. Draft commit message (+ [skip ci] nếu docs/skill/backend-only)
- [ ] 5. Commit via commit-from-file.sh (not inline git commit)
- [ ] 6. Verify: no co-author trailer in message
- [ ] 7. git push origin main (or -u origin HEAD)
- [ ] 8. Report: hash, CI impact, push result
```

Scripts live under `.cursor/skills/e4c-git-commit-push/scripts/`.

## CI/CD — tránh build/deploy oan

Chi tiết path: [ci-paths.md](ci-paths.md)

| Thay đổi | Web deploy | APK + versionCode mới |
|----------|------------|------------------------|
| `lib/`, `web/`, `assets/`, `pubspec.*`, `config/prod.json` | Có | Có (nếu đụng lib/android/…) |
| `docs/`, `.cursor/`, skill, plantasks | Không | Không |
| `english_for_community_backend/` only | Không | Không |
| Rewrite history (chỉ message) | Không* | Không* |

\*Nếu paths không đổi. Vẫn nên thêm `[skip ci]` vào subject khi rewrite/force push.

### `[skip ci]` — khi nào thêm vào subject

```
chore(docs): update seed accounts [skip ci]
chore(cursor): improve commit skill [skip ci]
```

Dùng cho: docs-only, skill/hook, co-author history cleanup, backend-only (chưa có workflow backend).

**Không** thêm `[skip ci]` khi đổi `lib/` hoặc file web/android cần deploy.

### Preview trước khi push

```bash
bash .cursor/skills/e4c-git-commit-push/scripts/preview-ci-impact.sh
```

### Manual deploy

GitHub Actions → workflow → **Run workflow** (`workflow_dispatch`).

## Author identity (sole contributor)

| Field | Value |
|-------|-------|
| `user.name` | `phanduy2004` |
| `user.email` | `conlocmuahe2004@gmail.com` |

**Never** in commit message: `Co-authored-by: Cursor …`, `Co-Authored-By: Claude …`, `Made-with: Cursor`.

Verify after commit:

```bash
git log -1 --format="%B" | grep -iE 'co-authored|cursoragent|anthropic|made-with' || true
# must print nothing
```

## Stage / exclude

### Never commit

| Path | Reason |
|------|--------|
| `.env`, `english_for_community_backend/.env` | secrets |
| `firebase-service-account.json` | secrets |
| `english_for_community/android/gradle.properties` | machine JVM tuning |
| `docs/dev/artifacts/` | agent temp |
| `english_for_community_backend/migrations/artifacts/` | migration dumps |
| `.dart_tool/`, `build/`, `node_modules/` | cache |
| `config/local.json`, `*.jks`, `key.properties` | local/signing |

### Typical stage scope

- `english_for_community/lib/`, `lib/l10n/`, `lib/main.dart`
- `english_for_community_backend/src/`, `server.js`
- `docs/` (not `docs/dev/artifacts/`)
- `.github/workflows/` when changing CI
- `.cursor/skills/` when updating this skill

## Commit message

```
feat(mobile): short summary

Why in 1-2 sentences. [skip ci]   ← only when appropriate
```

Prefixes: `feat`, `fix`, `chore`, `docs`, `refactor`, `perf`.

## Commit (bypass Cursor --trailer injection)

```bash
# 1. Write message to a file (e.g. .git/COMMIT_MSG.txt)
# 2. Stage files
git add ...
# 3. Commit
bash .cursor/skills/e4c-git-commit-push/scripts/commit-from-file.sh .git/COMMIT_MSG.txt
```

**Do not** run bare `git commit -m "..."` from Agent — Cursor may inject `--trailer "Co-authored-by: …"`.

## Co-author fixes

| Situation | Action |
|-----------|--------|
| First clone | `bash scripts/install-coauthor-hook.sh` |
| Message has co-author after commit | `bash scripts/rewrite-last-commit-msg.sh "full message"` |
| Remove AI from all history (user asks) | `bash scripts/strip-coauthors-from-history.sh` then `git push --force-with-lease origin main` |
| IDE setting | Cursor Settings → Agents → Attribution → OFF |

History rewrite: verify `git rev-parse 'HEAD^{tree}'` unchanged before push.

## Push rules

- Normal: `git push origin main`
- New branch: `git push -u origin HEAD`
- Force push `main`: **only** when user explicitly requests history rewrite
- Never update `git config`, never `--no-verify`, never commit secrets

## Shell (Windows)

PowerShell: use `;` not `&&`. Prefer Git Bash for commit scripts:

```powershell
& "C:\Program Files\Git\bin\bash.exe" ".cursor/skills/e4c-git-commit-push/scripts/preview-ci-impact.sh"
```

## PR (if asked)

Use `gh pr create`; no Cursor attribution in PR body.
