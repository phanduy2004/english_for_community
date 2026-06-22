# Work-Order — BUG: Mobile auto-update không hiện khi đã release version mới

- **Task ID:** 20260622-mobile-auto-update
- **Loại:** BUG
- **Mục tiêu:** Khi user đăng nhập/mở app và đã có version mới được *published*, app phải hiện dialog "Cập nhật ngay".
- **Cỡ task:** T1 (chủ yếu operational + 1–2 fix code nhỏ) → 1 work-order (file này).
- **Người phân tích:** Opus (brain). **Implementer:** Cursor. **Status:** PHÂN TÍCH XONG — chờ diagnose để chốt nhánh fix.

> Quy ước: artifact theo `docs/AI-Working-Process-vi.md`. Opus không tự sửa code; phần Diff bên dưới để Cursor implement sau khi DEV chạy Diagnose.

---

## 1. Vấn đề + nguyên nhân gốc (có dẫn chứng code)

**Triệu chứng:** đã release app mới nhưng client không được mời cập nhật.

**Luồng đã verify (ground-truth):**

```
CI (push main → lib/**) →  bump versionCode = BASE + GITHUB_RUN_NUMBER  (workflow .yml:62)
   → build APK SAU khi bump (.yml:132-134)  → APK buildNumber == versionCode đăng ký  ✅ khớp
   → POST /api/app/releases/ci-candidates  → AppRelease {status:'pending_approval', isActive:false}  ❌ CHƯA hiện
   → admin approve → publish  → {status:'published', isActive:true}  ✅ MỚI hiện
client AppUpdateGuard: check lúc mở app + resume + đổi auth (đăng nhập)  (app_update_guard.dart:32-72, forceRefresh:true)
   → GET /api/app/version-check?platform=&versionCode=&environment=production  (dioPublic, không cần login)
   → server findOne{platform, environment, status:'published', isActive:true} sort versionCode desc  (appVersionService.js:369-376)
   → resolveStatus: chỉ update khi currentVersionCode < latestVersionCode  (appVersionService.js:359-364, so sánh INT — không có bug chuỗi)
   → KHÔNG match → ÂM THẦM trả 'up_to_date'  (appVersionService.js:378-390)
```

**Kết luận ground-truth (loại trừ):**
- ❌ KHÔNG phải bug so sánh version chuỗi — cả 2 phía dùng `versionCode` (int): client `app_update_bloc.dart:44`, server `appVersionService.js:359-363`.
- ❌ KHÔNG phải "không gọi check khi login" — `AppUpdateGuard` gọi đủ lúc mở app / resume / đăng nhập, đều `forceRefresh:true` (`app_update_guard.dart:32-72`).
- ❌ KHÔNG phải lệch buildNumber — CI bump pubspec rồi mới build (`.yml:40-85` → `132-134`).

**Nguyên nhân gốc thật sự (theo thứ tự khả năng):**

| # | Nguyên nhân | Dẫn chứng | Loại |
|---|-------------|-----------|------|
| **RC1** | **version-check ĐANG lỗi do `trust proxy`** (đã xảy ra trên prod). `globalLimiter` áp cho *mọi* `/api` (`app.js:86`) trước routes → trước fix `912b26a`, Render ném `ERR_ERL_UNEXPECTED_X_FORWARDED_FOR` → version-check fail → client **nuốt lỗi** (`app_update_bloc.dart:52-59`, guard chỉ phản ứng `info` không phản ứng `errorMessage`) → không hiện dialog. | log prod (login 400 cùng lỗi); `app.js:86`; commit `912b26a` | Đã fix hôm nay — **cần re-test** |
| **RC2** | **AppRelease mồ côi ở DB `test`.** Release tạo/publish trước khi pin `english_community` (fix `6bb7aae`) nằm ở `test.appreleases`; version-check giờ đọc `english_community` → không thấy → trả `up_to_date`. | `mongoUri.js:getMongoDbName`; `server.js` connect; backend audit | Đã fix DB hôm nay — **cần migrate / re-publish** |
| **RC3** | **Candidate chưa được publish.** Không có endpoint admin tự tạo; CI chỉ tạo `pending_approval`. Phải admin **approve → publish** thủ công thì client mới thấy (`releaseStateMachine.js:11`, `appVersionService.js:254-292`). | backend audit | Operational |
| **RC4** | **Environment lệch.** Release lưu `staging` còn client luôn query `production` (`app_update_remote_datasource.dart:11`). 4-field filter trượt → `up_to_date`. | `appVersionService.js:369-374` | Data |
| — | (Phụ, KHÔNG gây "no update") `minSupportedVersionCode == versionCode` ở CI (`.yml:210`) khiến MỌI client cũ bị **force_update** thay vì soft. Cần sửa nhưng không phải nguyên nhân triệu chứng. | `.yml:210`; `appVersionService.js:360` | Bug UX |

**Điểm khuếch đại (vì sao khó phát hiện):** server trả `up_to_date` khi không match (im lặng), và client nuốt mọi lỗi API → bất kỳ trong RC1–RC4 đều cho ra cùng triệu chứng "không có gì xảy ra".

---

## 2. Audit downstream (consumer của version-check)

| Consumer | File:line | Phụ thuộc gì |
|----------|-----------|--------------|
| `AppUpdateGuard` | `app_update_guard.dart:32-88` | chỉ phản ứng `info.hasUpdate`; bỏ qua `errorMessage` |
| `AppUpdateBloc` | `app_update_bloc.dart:27-59` | web bị skip (`kIsWeb`); throttle 30' (các trigger đều forceRefresh nên ok); nuốt lỗi vào `errorMessage` |
| `app_update_remote_datasource` | `:11,15-22` | hardcode `environment:'production'`; dùng `dioPublic` |
| server `version-check` | `appVersionService.js:369-409` | filter 4 trường; no-match → up_to_date im lặng |
| CI candidate | workflow `.yml:181-228` | gửi `minSupportedVersionCode == versionCode` |

---

## 3. BƯỚC 0 — DIAGNOSE (DEV chạy TRƯỚC, để chốt nhánh fix; không đoán)

Chạy 3 lệnh, dán kết quả vào tracker:

**D1 — Hỏi trực tiếp prod (giả lập client cũ versionCode=1):**
```bash
curl -s "https://english-for-community.onrender.com/api/app/version-check?platform=android&versionCode=1&environment=production"
```
- Trả `status:'soft_update'|'force_update'` + `latestVersionCode` lớn + `downloadUrl` → **server OK**, lỗi nằm ở client/app cũ → nghi RC1 đã được fix, re-test app thật.
- Trả `status:'up_to_date'` (latestVersionCode=1) → **không có release published** trong `english_community` → RC2/RC3/RC4.

**D2 — Kiểm tra DB `english_community` có release published không:**
```js
// mongosh, dùng đúng DB english_community
use english_community
db.appreleases.find({ platform:'android', environment:'production' },
  { versionName:1, versionCode:1, status:1, isActive:1, publishedAt:1 }).sort({versionCode:-1})
```
- So sánh với DB `test`: `use test; db.appreleases.find(...)`. Nếu release nằm ở `test` mà `english_community` rỗng → **RC2 xác nhận**.

**D3 — Xác nhận trên Render Logs:** dòng `✅ Connected to MongoDB (...) [db: english_community]` (đã thêm ở `6bb7aae`) + CI step "Create release candidate success".

→ Kết quả D1–D3 quyết định đi nhánh nào ở mục 5.

---

## 4. Scope IN / OUT

**IN (được chạm):**
- `.github/workflows/main-auto-build-candidate.yml` — sửa `minSupportedVersionCode` (Fix C1).
- `english_for_community_backend/src/services/appVersionService.js` — thêm log quan sát khi no-match (Fix C2).
- (Tùy chọn) `english_for_community/lib/feature/app_update/...` — surface lỗi version-check khi debug (Fix C3).
- Operational runbook (mục 5) — DEV/admin thao tác, không phải code.

**OUT (chạm là DỪNG & hỏi):**
- ❌ Tạo endpoint `POST /api/admin/app-releases` (feature mới — docs hứa nhưng chưa làm).
- ❌ Sửa `releaseStateMachine` / quy trình approval.
- ❌ Đổi schema `AppRelease`, đổi unique index.
- ❌ Luồng update cho iOS/web; in-app APK install.
- ❌ Đổi cơ chế so sánh version (đang đúng).

---

## 5. Nhánh xử lý theo kết quả Diagnose

**Nhánh A — D1 trả up_to_date & release nằm ở `test` (RC2):**
- Cách nhanh & sạch: **re-run CI** (push main chạm `lib/**`) để tạo candidate mới trong `english_community`, rồi admin **approve → publish**. (Không nên copy thủ công row từ test sang để tránh lệch index.)
- Nếu cần giữ row cũ: viết script migrate có kiểm soát (OUT scope mặc định — hỏi trước).

**Nhánh B — candidate có trong `english_community` nhưng chưa published (RC3):**
- Admin chạy: `POST /api/admin/app-releases/:id/approve` → `POST /api/admin/app-releases/:id/publish` (hoặc qua Release Management UI).
- Verify lại bằng D1.

**Nhánh C — D1 đã trả soft_update (server OK) nhưng app vẫn không hiện (RC1 tàn dư):**
- Đảm bảo app đang trỏ đúng base URL prod (`config/prod.json`) và backend đã redeploy bản có `912b26a`.
- Cài lại APK cũ (versionCode thấp) → mở app → phải thấy dialog.

---

## 6. Diff cụ thể (code fixes — Cursor implement)

### Fix C1 — CI không để `minSupportedVersionCode == versionCode` (tránh force-update mọi bản cũ)
File: `.github/workflows/main-auto-build-candidate.yml`, step "Create release candidate", ~dòng 210.
```diff
   env:
     ...
     VERSION_CODE: ${{ steps.version.outputs.version_code }}
+    MIN_SUPPORTED_VERSION_CODE: ${{ vars.MIN_SUPPORTED_VERSION_CODE }}
     DOWNLOAD_URL: ${{ steps.apk_host.outputs.download_url }}
   ...
-              \"minSupportedVersionCode\": ${VERSION_CODE},
+              \"minSupportedVersionCode\": ${MIN_SUPPORTED_VERSION_CODE:-1},
```
→ Mặc định floor = 1 (soft update). Khi muốn ép buộc, set repo variable `MIN_SUPPORTED_VERSION_CODE`. Cập nhật là chủ ý, không phải mỗi build.

### Fix C2 — Backend: log khi version-check không tìm thấy release (hết im lặng)
File: `english_for_community_backend/src/services/appVersionService.js`, nhánh no-match (~378-390, trước khi return up_to_date).
```js
// THÊM trước khi trả 'up_to_date' do !latestRelease:
console.warn('[version-check] no published+active release', {
  platform: parsed.platform, environment: parsed.environment,
});
```
→ Giúp ops thấy ngay RC2/RC3/RC4 trong log thay vì âm thầm.

### Fix C3 (tùy chọn) — Client: không nuốt lỗi version-check khi debug
File: `english_for_community/lib/feature/app_update/.../app_update_bloc.dart` (~52-59).
- Khi `kDebugMode`, `debugPrint` lỗi version-check thay vì chỉ set `errorMessage`. (Không đổi hành vi release.)

> Lưu ý: C1 & C2 là an toàn, nên làm bất kể nhánh A/B/C. C3 tùy chọn.

---

## 7. Lệnh verify

```bash
# 1) Server trả đúng sau khi publish:
curl -s "https://english-for-community.onrender.com/api/app/version-check?platform=android&versionCode=1&environment=production"
#   → mong đợi: status=soft_update, latestVersionCode>1, downloadUrl trỏ GitHub Release .apk

# 2) Backend khởi động đúng DB (Render logs):
#   ✅ Connected to MongoDB (...) [db: english_community]

# 3) CI candidate gửi đúng min (sau Fix C1): xem body POST ci-candidates trong Actions log
#   → "minSupportedVersionCode": 1 (hoặc giá trị vars)

# 4) Backend lint/syntax sau Fix C2:
cd english_for_community_backend && node --check src/services/appVersionService.js
```

**Nghiệm thu (acceptance):**
- Có ≥1 AppRelease `status:published, isActive:true, platform:android, environment:production` trong `english_community` với `versionCode` > buildNumber của app đang cài.
- D1 trả `soft_update` + `downloadUrl` hợp lệ.
- Cài APK versionCode thấp → mở app/đăng nhập → hiện dialog "Cập nhật ngay" → bấm mở được link tải.
- (C1) candidate mới có `minSupportedVersionCode < versionCode` (trừ khi cố ý nâng).

---

## 8. HANDOFF PROMPT cho Cursor (copy nguyên khối)

```text
Bạn là implementer. CHỈ sửa đúng các file dưới; file ngoài danh sách → DỪNG & hỏi.
Repo: english_for_community (Flutter) + english_for_community_backend (Node).

FILE ĐƯỢC SỬA:
  1. .github/workflows/main-auto-build-candidate.yml  — Fix C1 (minSupportedVersionCode)
  2. english_for_community_backend/src/services/appVersionService.js — Fix C2 (log no-match)
  3. (tùy chọn) english_for_community/lib/feature/app_update/**/app_update_bloc.dart — Fix C3 (debugPrint lỗi)

THEO ĐÚNG diff ở mục 6 của work-order. TUYỆT ĐỐI KHÔNG:
  - Tạo endpoint admin-create, đổi releaseStateMachine, đổi schema/index AppRelease.
  - Đổi cơ chế so sánh versionCode, đổi luồng iOS/web.
  - Mở rộng scope.

VERIFY: chạy `node --check src/services/appVersionService.js`; với workflow chỉ cần đảm bảo YAML hợp lệ.
Xong → dán kết quả vào tracker, đặt trạng thái DONE.

LƯU Ý: nguyên nhân chính (release chưa publish / mồ côi DB test) là OPERATIONAL — DEV/admin xử lý theo mục 5, không phải việc của implementer.
```

---

## 9. Checklist OPUS AUDIT (chạy khi implementer xong)

- [ ] C1: `minSupportedVersionCode` không còn `== versionCode`; default floor đúng; có env/var.
- [ ] C2: log no-match được thêm đúng nhánh `!latestRelease`, không đổi response shape.
- [ ] C3 (nếu làm): chỉ `debugPrint`, không đổi hành vi release.
- [ ] Không scope-creep (không đụng file OUT).
- [ ] `node --check` pass; YAML workflow hợp lệ.
- [ ] DEV đã chạy Diagnose (D1–D3) + thực hiện nhánh A/B/C; D1 trả soft_update.

---

## 10. Việc thực tế còn lại của DEV (ngoài code)

1. Chạy Diagnose D1–D3.
2. Theo nhánh A/B/C: re-run CI tạo candidate trong `english_community` **hoặc** admin approve→publish candidate hiện có.
3. Set Render env (nếu chưa): `MONGO_DB_NAME=english_community`, kiểm tra `CI_RELEASE_TOKEN`, `BACKEND_BASE_URL`.
4. Re-test trên thiết bị thật với APK versionCode thấp.
