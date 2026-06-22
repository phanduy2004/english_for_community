# Backend: cấu trúc thư mục & quy ước đặt tên

> **Phạm vi:** `english_for_community_backend/` (Express + Mongoose, ESM). 187 file .js.
> **Mục đích:** đánh giá tổ chức folder/file đã chuẩn chưa, chỉ chỗ lộn xộn, và đưa **cấu trúc + quy ước đặt tên chuẩn** + **plan dọn an toàn** (move file = vỡ `import`, phải làm cẩn thận).
> **Nguồn:** quét trực tiếp 06/2026.

---

## 1. Đánh giá tổng quan — **7/10**

> **Lõi xếp lớp rất tốt; lộn xộn chỉ ở các thư mục "rìa" (ops/tooling/helpers).**

| Khía cạnh | Điểm | Nhận định |
|-----------|:----:|-----------|
| Xếp lớp (layered MVC-service) | 9/10 | Đủ `config/constants/models/routes/controllers/services/middleware/jobs/socket` — chuẩn Express. |
| Đặt tên controllers/models | 9/10 | **22/22** controller đúng `xxxController.js`; **34/34** model PascalCase. Nhất quán. |
| Thư mục ops (scripts/migrations/tests/seeds) | 4/10 | **Rải 3–4 nơi**, trùng vai, có folder rỗng. |
| Helpers (lib vs utils) | 5/10 | Ranh giới mờ, lẫn helper hạ tầng với logic nghiệp vụ. |
| Đặt tên file lẻ | 6/10 | Vài chỗ lệch case (`jwt_token`, `AppError`); folder `tools` đặt sai nghĩa. |

**Một dòng:** không cần "đập đi xây lại" — chỉ **dọn rìa** (xoá folder rỗng/typo, gom scripts/tests về một mối, đổi tên vài chỗ).

---

## 2. Điểm tốt (GIỮ NGUYÊN)

- **Xếp lớp chuẩn:** `routes → controllers → services → models`, tách `middleware`, `jobs` (cron), `socket`, `config`, `constants`. Đây là mô hình đúng cho Express, không cần đổi.
- **Đặt tên đồng nhất ở tầng chính:** mọi controller `*Controller.js` (camelCase), mọi model PascalCase, phần lớn service `*Service.js`.
- **`migrations/` (root)** có runner + nhật ký — đúng chuẩn, giữ.

---

## 3. Chỗ lộn xộn (kèm đường dẫn)

### 3.1 🔴 Thư mục rỗng / gõ sai (xoá ngay, không rủi ro)
- **`src/untils/`** — gõ sai "utils", **rỗng**, lại tồn tại song song `src/utils/` → **xoá**.
- **`tool/`** (root) — rỗng (đã có `src/tools/`) → **xoá**.
- **`test/`** (root) — rỗng (đã có `src/tests/`) → **xoá**.

### 3.2 🟡 Scripts/migrations/tests rải nhiều nơi (gom một mối)
Hiện "việc ngoài request" (seed/migrate/inspect/cleanup/audit/test) nằm ở **4–5 nơi**:
| Nơi | Nội dung | Vấn đề |
|-----|----------|--------|
| `migrations/` (root) | runner + `001/002/003-*.js` | ✅ đúng — giữ |
| `scripts/` (root) | `auditD4, goldenCapture, goldenDiff, discoverExamSnapshotParity, backupPreMigration…` | tooling migration D4 |
| `src/scripts/` (11) | **lẫn lộn:** migration (`migrateCmsContent/Dictation/Progress`), phá huỷ (`clearAllExamData/clearExamAssignments`), seed-check (`checkSeedLogin`), soi data (`inspectAtlasData/inspectExamSkillLinks`) | 4 loại việc khác nhau cùng 1 folder |
| `src/seeds/` (16) | seed dữ liệu | tách riêng với src/scripts |
| `src/tests/` (1) + `test/` rỗng + **`*.test.js` nằm TRONG `src/services/`** (`examIntegratedScoring.test.js`, `releaseStateMachine.test.js`) | test 3 kiểu đặt | không nhất quán |
→ **Migration thật** (`migrateCmsContent/Dictation/Progress`) nên ở `migrations/`, KHÔNG ở `src/scripts`.

### 3.3 🟡 `src/tools/` đặt tên sai nghĩa
- `src/tools/{definitions.js, implementations.js}` thực ra là **AI Gemini function-calling** (`export const geminiTools = …`) — KHÔNG phải "tooling/scripts". Tên `tools` gây hiểu nhầm + đụng khái niệm dev-tools. → nên là **`src/services/ai/`** (hoặc `src/ai/`).

### 3.4 🟡 `src/lib` vs `src/utils` — ranh giới mờ
- `lib/`: `mongoUri, loadEnv, mongoosePlugins, leanApiSerialize, jwt_token` (hạ tầng) **+** `examAttemptScoreUtils` (logic nghiệp vụ — lệch chỗ).
- `utils/`: `asyncHandler, AppError, tokenHash, ttlCache, localDayBounds, sendMailUtil` (helper thuần) **+** `scoring, progressTracker` (nghiệp vụ — lệch chỗ).
→ `examAttemptScoreUtils` (lib) và `scoring` (utils) **chồng vai**. Cần định nghĩa rõ ranh giới (xem §5) và dời 2–3 file nghiệp vụ về `services/`.

### 3.5 🟢 Đặt tên file lẻ
- `src/lib/jwt_token.js` — **snake_case** duy nhất → `jwtToken.js`.
- `src/utils/AppError.js` — PascalCase giữa nhóm camelCase: **chấp nhận được** (file định nghĩa class → PascalCase là hợp lệ), nhưng ghi rõ quy ước.
- 10 file trong `services/` không có hậu tố `Service` (`assignmentPolicy, releaseStateMachine, examSnapshotStore, teacherNotificationHelper…`) — phần lớn là **policy/state-machine/store/helper** hợp lệ; chấp nhận services/ chứa "module nghiệp vụ" nói chung, nhưng nên thống nhất (xem §5).

---

## 4. Cấu trúc đề xuất (target)

```
english_for_community_backend/
├── app.js · server.js
├── migrations/            # runner + NNN-*.js (gồm cả migrate CMS/Dictation/Progress dời từ src/scripts)
├── scripts/               # việc ngoài runtime, chia rõ:
│   ├── seeds/             # (← src/seeds)
│   ├── dev/               # soi/inspect (inspectAtlasData, checkSeedLogin…)
│   ├── ops/               # phá huỷ/cẩn trọng (clearAllExamData, backupPreMigration…)
│   └── audit/             # goldenCapture/goldenDiff/auditD4… (tooling migration)
├── test/                  # gom mọi test (hoặc co-locate *.test.js — chọn 1, xem §5)
└── src/
    ├── config/            # env, db, cloudinary, firebase
    ├── constants/
    ├── models/  (+ sub/)
    ├── routes/
    ├── controllers/
    ├── services/
    │   └── ai/            # (← src/tools: geminiTools definitions/implementations)
    ├── middleware/
    ├── jobs/
    ├── socket/
    ├── lib/               # HẠ TẦNG: db (mongoUri, mongoosePlugins), env (loadEnv),
    │                      #   serializer (leanApiSerialize), auth (jwtToken), mail
    └── utils/             # HELPER THUẦN, không phụ thuộc domain: asyncHandler, AppError,
                           #   tokenHash, ttlCache, localDayBounds
    # (dời examAttemptScoreUtils, scoring, progressTracker → services/ domain tương ứng)
    # XOÁ: src/untils, tool/, test/ rỗng
```

---

## 5. Quy ước đặt tên chuẩn (chốt một lần)

| Loại | Thư mục | Case file | Hậu tố | Ví dụ |
|------|---------|-----------|--------|-------|
| Model (Mongoose) | `models/` | **PascalCase** | (không) | `ExamAttempt.js` |
| Controller | `controllers/` | camelCase | `Controller` | `teacherExamController.js` |
| Service (nghiệp vụ) | `services/` | camelCase | `Service` (ưu tiên) | `examGradingService.js` |
| Policy / state-machine / store / helper nghiệp vụ | `services/` | camelCase | mô tả vai (`Policy`/`StateMachine`/`Store`) | `assignmentPolicy.js` |
| Route | `routes/` | camelCase | `Routes` | `teacherRoutes.js` |
| Middleware | `middleware/` | camelCase | (mô tả) | `examRateLimit.js` |
| Lib hạ tầng | `lib/` | camelCase | (không) | `mongoUri.js`, `jwtToken.js` |
| Util thuần | `utils/` | camelCase; **class → PascalCase** | (không) | `asyncHandler.js`, `AppError.js` |
| Job/cron | `jobs/` | camelCase | `Job` | `examAttemptExpireJob.js` |
| Migration | `migrations/` | `NNN-kebab-case` | (không) | `002-backfill-...js` |
| Script ops/seed | `scripts/**` | camelCase | (mô tả) | `seedTeacher.js` |
| Test | cạnh nguồn hoặc `test/` | camelCase | `.test.js` | `releaseStateMachine.test.js` |

**Quy tắc chung:** một loại = một quy ước; **không** snake_case (`jwt_token` → `jwtToken`); folder số nhiều theo vai (`services`, `models`), không từ mơ hồ (`tools` → `ai` hoặc `scripts`).

---

## 6. Plan dọn an toàn (move = vỡ import → làm theo bước)

> **Nguyên tắc:** dễ-không-rủi-ro trước; mỗi nhóm = 1 commit + `npm start`/test sau đó; mỗi lần rename/move **phải cập nhật mọi `import`** trỏ tới (grep đường dẫn cũ → sửa hết → server khởi động sạch).

**Bước 1 — Xoá rỗng/typo (rủi ro 0):** xoá `src/untils/`, `tool/`, `test/` (rỗng). Verify: `npm start` OK.

**Bước 2 — Đổi tên file lẻ (rủi ro thấp):**
- `lib/jwt_token.js` → `lib/jwtToken.js` + sửa mọi import.
- Verify: grep `jwt_token` = 0; server OK.

**Bước 3 — `src/tools` → `src/services/ai/` (rủi ro thấp–vừa):**
- Di chuyển `definitions.js`/`implementations.js` vào `src/services/ai/`; sửa import (`tools/` → `services/ai/`).
- Verify: tính năng AI (Gemini) gọi được; grep `tools/` = 0.

**Bước 4 — Gom scripts/migrations/tests (rủi ro vừa, nhiều file):**
- Tạo `scripts/{seeds,dev,ops,audit}`; chuyển `src/seeds → scripts/seeds`, `src/scripts` chia về `dev`/`ops`, `scripts/` (root) → `scripts/audit`.
- Migration thật (`migrateCmsContent/Dictation/Progress`) → `migrations/` (đổi tên `NNN-*`).
- Test: chọn **co-locate `*.test.js`** (đang có sẵn 2 file trong services) hoặc gom hết về `test/` — **chốt 1**; cập nhật script `package.json test`.
- Verify: chạy seed/migrate/test bằng đường dẫn mới; những script này thường gọi tay nên ít ảnh hưởng runtime.

**Bước 5 — Ranh giới lib/utils (rủi ro vừa):**
- Dời `lib/examAttemptScoreUtils.js`, `utils/scoring.js`, `utils/progressTracker.js` → `services/` (gần domain dùng nó); sửa import.
- Verify: server OK; test chấm/điểm không vỡ.

**AUDIT mỗi bước:** (1) grep đường dẫn cũ = 0; (2) `npm start` sạch + socket OK; (3) smoke 3 luồng chính (login, dashboard GV, chấm bài); (4) `git status` chỉ là move/rename như dự kiến.

---

## 7. Checklist

- [ ] `src/untils`, `tool/`, `test/` rỗng đã xoá.
- [ ] Không còn snake_case (`jwt_token`); folder `tools` đổi thành `services/ai`.
- [ ] scripts/migrations/seeds/tests về đúng mối; migration thật nằm trong `migrations/`.
- [ ] lib = hạ tầng, utils = helper thuần; file nghiệp vụ đã rời khỏi lib/utils.
- [ ] Quy ước §5 áp cho file mới về sau (ghi vào README backend).
- [ ] Sau mỗi bước: grep path cũ = 0, `npm start` sạch, smoke OK, 1 commit riêng.

> Ưu tiên: Bước 1–3 làm ngay (rẻ, sạch ngay). Bước 4–5 gom dần. Ghi vào nhật ký + cập nhật README backend mô tả cấu trúc chuẩn.
</content>
