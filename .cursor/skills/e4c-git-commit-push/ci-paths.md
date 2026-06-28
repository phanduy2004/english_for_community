# E4C — CI/CD path triggers

GitHub Actions chỉ chạy khi push `main` **đổi file trong paths** (hoặc `workflow_dispatch` thủ công).

## Web — `firebase-hosting-merge.yml`

| Path | Lý do |
|------|--------|
| `english_for_community/lib/**` | Dart UI/logic |
| `english_for_community/web/**` | index.html, manifest |
| `english_for_community/assets/**` | static assets |
| `english_for_community/pubspec.yaml` | deps / version |
| `english_for_community/pubspec.lock` | lockfile |
| `english_for_community/config/prod.json` | `--dart-define-from-file` |
| `english_for_community/firebase.json` | hosting config |
| `english_for_community/.firebaserc` | Firebase project |
| `.github/workflows/firebase-hosting-merge.yml` | workflow itself |

**Không trigger** khi chỉ đổi: `docs/**`, `.cursor/**`, `english_for_community_backend/**`, skill, plantasks.

## Android APK — `main-auto-build-candidate.yml`

| Path | Lý do |
|------|--------|
| `english_for_community/lib/**` | app code |
| `english_for_community/android/**` | native / Gradle (not `gradle.properties` local) |
| `english_for_community/assets/**` | bundled assets |
| `english_for_community/pubspec.yaml` | deps / version |
| `english_for_community/pubspec.lock` | lockfile |
| `english_for_community/config/prod.json` | prod API defines |
| `.github/workflows/main-auto-build-candidate.yml` | workflow itself |

APK build **tăng versionCode** mỗi lần chạy — tránh chạy oan cho commit docs/skill.

## Skip CI trong commit message

Thêm vào **dòng subject** (hoặc body):

```
[skip ci]
```

hoặc `[ci skip]` — cả hai workflow đều tôn trọng (trừ `workflow_dispatch`).

Ví dụ:

```
chore(docs): update seed accounts [skip ci]
```

Dùng khi: docs-only, skill-only, history rewrite (message-only), backend-only (nếu chưa có workflow backend riêng).

## Backend-only changes

Push chỉ `english_for_community_backend/**` → **không** trigger web hay APK hiện tại. Deploy backend qua Render (hoặc pipeline riêng).

## Manual deploy

GitHub → Actions → chọn workflow → **Run workflow** (`workflow_dispatch`).
