---
name: e4c-git-commit-push
description: >-
  Commit and push English for Community (E4C) monorepo changes safely: stage the
  right files, write conventional commit messages, strip AI co-author trailers
  (Cursor/Claude), verify code tree unchanged, and push. Use when the user asks
  to commit, push, đẩy code, lưu git, or sync changes to GitHub.
---

# E4C — Commit & Push

## Trigger

User says: commit, push, đẩy code, lưu lên git, sync GitHub, etc.

**Only commit when explicitly asked.** If unclear, ask first.

## Author identity (must stay sole contributor)

| Field | Value |
|-------|-------|
| `user.name` | `phanduy2004` |
| `user.email` | `conlocmuahe2004@gmail.com` |

**Never** add to commit message:

- `Co-authored-by: Cursor <cursoragent@cursor.com>`
- `Co-Authored-By: Claude … <noreply@anthropic.com>`
- `Made-with: Cursor`

Cursor Agent may inject these automatically. Always verify after commit:

```bash
git log -1 --format="%B" | grep -iE 'co-authored|cursoragent|anthropic|made-with'
# must return nothing
```

If present → fix before push (see [Fix co-author injection](#fix-co-author-injection)).

## Workflow checklist

```
- [ ] 1. git status + git diff (staged & unstaged) + git log -5 (message style)
- [ ] 2. Stage relevant files only (see exclusions)
- [ ] 3. Draft 1–2 sentence conventional commit (focus on why)
- [ ] 4. Commit (hook strips co-authors; verify message)
- [ ] 5. git status — confirm clean or only intentional leftovers
- [ ] 6. git push (or push -u origin HEAD for new branch)
- [ ] 7. Report commit hash + push result
```

Run `git status`, `git diff`, and `git log` in **parallel** before staging.

## What to stage / exclude

### Always exclude (never commit)

| Path / pattern | Reason |
|----------------|--------|
| `.env`, `english_for_community_backend/.env` | secrets |
| `firebase-service-account.json` | secrets |
| `english_for_community/android/gradle.properties` | machine-specific JVM/Gradle tuning |
| `docs/dev/artifacts/` | agent analysis temp files |
| `english_for_community_backend/migrations/artifacts/` | runtime migration dumps |
| `english_for_community/.dart_tool/` | Flutter cache |
| `english_for_community/build/` | build output |
| `node_modules/` | dependencies |
| `config/local.json` | local API IP (if present) |
| `*.jks`, `*.keystore`, `key.properties` | signing keys |

### Typical stage scope

- `english_for_community/lib/` + `lib/l10n/` (include generated l10n if ARB changed)
- `english_for_community_backend/src/`, `server.js`, `app.js`
- `docs/` (except `docs/dev/artifacts/`)

## Commit message format

Follow recent repo style — conventional prefix + short body:

```
feat(mobile): student classroom detail redesign

Redesign hub tiles and detail page; extend classroom API for member list.
```

Prefixes: `feat`, `fix`, `chore`, `docs`, `refactor`, `perf`, `test`.

Pass message via HEREDOC (bash) or here-string (PowerShell). **Do not** append co-author lines.

## Shell notes (Windows)

PowerShell old versions: use `;` not `&&`. For git plumbing use **Git Bash**:

```bash
& "C:\Program Files\Git\bin\bash.exe" -lc "cd /d/Workspace/english_for_community && git status"
```

## Fix co-author injection

### A. Prevention — install hook (once per clone)

```bash
bash .cursor/skills/e4c-git-commit-push/scripts/install-coauthor-hook.sh
```

Hook: `.git/hooks/prepare-commit-msg` — strips Cursor/Claude trailers before each commit.

### B. After commit — message has co-author

Cursor may re-inject on `git commit --amend`. Use `commit-tree` via Git Bash:

```bash
bash .cursor/skills/e4c-git-commit-push/scripts/rewrite-last-commit-msg.sh "your full message"
```

Then verify tree unchanged:

```bash
# BEFORE_TREE and AFTER_TREE must match
git rev-parse 'HEAD^{tree}'
```

### C. User also disables in Cursor IDE

`Cursor Settings → Agents → Attribution` → OFF **Commit Attribution** and **PR Attribution**.

## Push rules

- **Never** `git push --force` to `main` unless user explicitly asks to rewrite history.
- Normal push: `git push origin main`
- New branch: `git push -u origin HEAD`
- After history rewrite (co-author cleanup): `git push --force-with-lease origin main` — **only when user requests**.

## Git safety (non-negotiable)

- Never update `git config` (except user asks)
- Never `--no-verify`, `--no-gpg-sign`, `push --force` to main (unless explicit)
- Never commit secrets
- Never `git commit --amend` unless: user asked, HEAD is your commit unpushed, hook auto-fixed files
- If commit hook fails → **new commit**, do not amend

## Remove AI from GitHub Contributors (history rewrite)

Only when user asks to remove Cursor/Claude from contributors **without changing code**:

1. Rewrite **commit messages only** on `main` (tree must stay identical):

```bash
bash .cursor/skills/e4c-git-commit-push/scripts/strip-coauthors-from-history.sh
```

2. Verify: `git log main --grep=co-authored -i --oneline` → empty
3. Verify: `before_tree == after_tree` at HEAD
4. `git push --force-with-lease origin main`
5. Tell user GitHub Contributors may take 1–2 hours to refresh

## PR creation (if asked)

Use `gh pr create` per user rules; do not add Cursor attribution to PR body.

## Quick reference — one-shot commit & push

```bash
cd /d/Workspace/english_for_community
git status
git add docs/ english_for_community/lib/ english_for_community/lib/l10n/ english_for_community/lib/main.dart english_for_community_backend/server.js english_for_community_backend/src/
# adjust paths to actual changes; never add excluded paths
git commit -m "$(cat <<'EOF'
feat(scope): short summary

Why this change matters in 1-2 sentences.
EOF
)"
git log -1 --format="%B" | grep -iE 'co-authored|cursoragent|anthropic' && echo "STOP: fix co-author first" || git push origin main
```

Adjust `git add` paths to match the actual diff every time.
