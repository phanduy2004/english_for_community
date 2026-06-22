# Kế hoạch đổi cấu trúc Database an toàn (DB ↔ Backend ↔ Flutter)

> **Mục tiêu:** thực thi các thay đổi schema ở [`../database-design-audit.md`](../database-design-audit.md) mà **KHÔNG làm vỡ** backend đang chạy, client Flutter đã phát hành, và dữ liệu cũ.
> **Bối cảnh:** đổi schema MongoDB lan toả 3 tầng — **DB → logic backend (services/controllers) → contract API (JSON) → parse Flutter**. Đây là phần rủi ro cao, cần migration + audit kỹ.
> Bổ sung cho [`backend-optimization-plan.md`](backend-optimization-plan.md) (perf). Stack: Express + Mongoose + MongoDB + Socket.IO; client Flutter parse JSON theo key.

---

## 0. Nguyên tắc an toàn (đọc trước khi làm bất cứ gì)

1. **Expand–Contract (đổi song song, 4 bước) — bắt buộc cho mọi đổi shape:**
   1) **Expand:** THÊM field/collection mới, **giữ nguyên cái cũ** (deploy không phá gì).
   2) **Backfill:** script điền dữ liệu mới từ cũ (idempotent, batched, có `--dry`).
   3) **Switch:** đổi code **đọc** sang field mới (vẫn ghi cả 2 — dual-write).
   4) **Contract:** sau khi xác nhận ổn N ngày → ngừng ghi cũ, xoá field cũ (deploy riêng).
   > KHÔNG bao giờ "thêm mới + xoá cũ" trong cùng một deploy.

2. **API contract là TƯỜNG LỬA.** Nếu **giữ nguyên shape JSON** trả ra client thì **Flutter không phải đổi**. Phần lớn refactor DB (snapshot, sub-schema, index, cascade) là **backend-only** nếu resolve về đúng field cũ. Chỉ đổi-tên-field / đổi-kiểu-lộ-ra mới đụng Flutter.

3. **Mọi đổi schema phải có migration script**: idempotent (chạy lại không hại), batched (không khoá DB), log rõ, **dry-run trước**, **backup DB trước khi chạy prod**, chạy **staging trước**.

4. **Schema không strict cho dữ liệu chưa backfill.** Khi thêm sub-schema (vd `scores`), dùng `strict:false`/field optional trước, siết dần sau khi dữ liệu sạch — tránh Mongoose reject document cũ.

5. **TTL = xoá vĩnh viễn.** Bật TTL phải bắt đầu với **thời hạn dài + theo dõi**, không bao giờ đặt ngắn ngay. Sai TTL = mất dữ liệu không hồi.

6. Mỗi giai đoạn = **1 commit + audit gate + đường rollback**.

---

## 1. Phân loại thay đổi theo rủi ro & tầng ảnh hưởng

| Thay đổi (từ audit) | DB | Logic backend | Contract API | Flutter | Migration | Rủi ro |
|---------------------|:--:|:-------------:|:------------:|:-------:|:---------:|:------:|
| Thêm index còn thiếu | ✔ | – | – | – | không (build nền) | 🟢 thấp |
| Plugin serializer `id` (sửa `.lean()` trả `_id`) | – | ✔ | **nhất quán hơn** (thêm `id`) | xác minh đọc `id` | không | 🟢 thấp |
| `User` → `timestamps:true` | ✔ | – | giữ `createdAt/updatedAt` | – | backfill `updatedAt` null | 🟢 thấp |
| Sub-schema `scores`/`integrity` | ✔ | ghi/đọc | **giữ shape** | – (nếu shape giữ) | không (strict:false) | 🟡 vừa |
| Cascade / soft-delete chuẩn hoá | ✔ | ✔ | list lọc bớt item xoá | – | gắn `deletedAt` cũ | 🟡 vừa |
| TTL log/notification | ✔ | – | – | – | không | 🟡 vừa (mất data nếu sai) |
| **`examSnapshot` dedup** (ref thay copy) | ✔ | ✔ nhiều | **giữ `examSnapshot`** resolve | – (nếu API resolve) | **backfill lớn** | 🔴 cao |
| `SpeakingAttempt.speakingSetId` String→ObjectId | ✔ | populate | thường giữ (string id) | xác minh | convert chuỗi→OID | 🟡 vừa |
| `Word.user` → `userId` (đổi TÊN) | ✔ | ✔ | **ĐỔI shape** | **CẦN đổi** | dual-field | 🟡 vừa |
| Daily-progress 1 nguồn | ✔ | ✔ | có thể bỏ field ở `User` | xác minh đọc | – | 🟡 vừa |

> **Đọc bảng:** ô "Flutter" trống = không cần đụng Flutter **miễn là giữ contract**. Chỉ 2 dòng thật sự đụng Flutter: `Word.user` rename (làm sau cùng, dual-field) và (có thể) daily-progress.

---

## 2. Lộ trình theo giai đoạn (rủi ro tăng dần)

> Làm **dễ/an toàn trước**, để lại `examSnapshot` (nặng nhất) cho cuối, cô lập.

### D0 — Chuẩn bị (bắt buộc)
- Backup DB prod; dựng **staging** có dữ liệu giống prod (hoặc subset).
- Viết **migration runner** chuẩn (§4) + thư mục `backend/migrations/`.
- **Chụp "golden" contract**: lưu JSON response của ~10 endpoint nóng (login, dashboard, gradebook, grading hub attempts, attempt-for-grading, live-screen, chat list, notifications, exam list, classroom detail) → dùng để **diff sau mỗi giai đoạn**.
- Cổng: staging chạy, golden đã lưu.

### D1 — Additive rủi ro-thấp (backend-only)
- Thêm index còn thiếu (audit §4.4) — `Model.index(...)` + để Mongo build nền.
- **Plugin serializer chung**: mọi schema có `toJSON{ id }`; **đặc biệt** thêm `id: String(_id)` ở các endpoint dùng `.lean()` (đây là gốc bug doc 25). Quét backend mọi `.lean()` trả thẳng doc → map id.
- `User` → `{timestamps:true}` (bỏ createdAt/updatedAt thủ công + pre-save), backfill `updatedAt` cho doc null.
- **Cổng:** golden diff = chỉ THÊM `id` (không mất field); `explain()` query nóng ra `IXSCAN`; smoke backend; `dart analyze lib` 0 lỗi; mở các màn list kiểm `id` (grading hub bấm vào được — doc 25).

### D2 — Sub-schema cho dữ liệu lõi (backend-only, giữ contract)
- Định nghĩa sub-schema `scores` (`{totalAwarded,totalMax,skillScores:[{skill,score}]}`) + `integrity`, đặt **`strict:false`/optional** để không reject doc cũ.
- KHÔNG đổi cách serialize → JSON `scores`/`integrity` giữ nguyên key.
- **Cổng:** golden diff scores/integrity = identical; chấm thử 1 bài (grading) không vỡ; Flutter gradebook/hub/attempt hiển thị điểm đúng.

### D3 — Toàn vẹn & vòng đời (data-affecting, thận trọng)
- **Soft-delete chuẩn hoá:** thêm `deletedAt` + query helper/plugin lọc mặc định; chọn soft-delete cho content/classroom thay hard-delete.
- **Cascade:** middleware `pre/post` xoá con khi xoá `Classroom`/`User`/`Exam` (hoặc soft-cascade).
- **TTL:** chỉ cho `Notification`/`AdminAuditLog`/`ClassroomActivityLog`, **thời hạn dài** (vd 180–365 ngày) + theo dõi 1 chu kỳ trước khi rút ngắn.
- **Cổng:** test xoá 1 lớp/đề trên staging → đếm bản ghi con = 0 mồ côi; list không lộ item đã xoá; TTL index tồn tại nhưng **chưa** xoá gì ngoài ý muốn (kiểm thời hạn).

### D4 — `examSnapshot` dedup (cô lập, expand-contract đầy đủ)
> Nặng & rủi ro nhất → làm riêng, không chung commit với D1–D3.
1. **Expand:** tạo collection `ExamSnapshot {assignmentId, contentVersion, sections, settings}` (hoặc nhúng 1 lần vào `ExamAssignment`); thêm `ExamAttempt.examSnapshotId` (nullable). **Giữ `examSnapshot` cũ.**
2. **Backfill:** với mỗi assignment, tạo 1 snapshot; mỗi attempt set `examSnapshotId` trỏ tới; (tuỳ chọn) so khớp `examSnapshot` cũ == snapshot mới để chắc.
3. **Switch:** code đọc đề-khi-chấm/live-screen lấy từ `examSnapshotId` (populate 1 lần); **API vẫn trả field `examSnapshot`** đã resolve → **Flutter không đổi**. Khi tạo attempt mới: chỉ set `examSnapshotId` (vẫn ghi `examSnapshot` cũ trong giai đoạn dual-write).
4. **Contract:** sau khi xác nhận, ngừng ghi + xoá `examSnapshot` cũ (deploy riêng + migration $unset).
- **Cổng mỗi bước:** golden diff các endpoint chấm/live = identical; mở chấm 1 bài + live mirror thật; đo dung lượng collection giảm; rollback = quay lại đọc `examSnapshot` cũ (vẫn còn).

### D5 — Dọn nhất quán (đụng Flutter tối thiểu)
- `SpeakingAttempt.speakingSetId` String→ObjectId: backfill convert; verify populate; Flutter thường không đổi (id vẫn chuỗi trong JSON) — kiểm màn speaking.
- `Word.user` → `userId`: **dual-field** (ghi cả 2, API trả cả 2) → đổi Flutter đọc `userId` → bỏ `user`. (Đụng Flutter → làm cuối.)
- Daily-progress 1 nguồn: giữ `UserDailyProgress`, coi field trong `User` là cache có hook (hoặc bỏ sau khi Flutter chuyển sang đọc từ endpoint progress).

---

## 3. Khung AUDIT sau mỗi giai đoạn (4 tầng — để tránh lỗi)

> Chạy **đủ 4 tầng** ở mỗi cổng. Không qua giai đoạn sau nếu một tầng đỏ.

**T1 · Toàn vẹn DB (mongosh script):**
- Đếm orphan (ref trỏ tới doc không tồn tại) ở collection vừa đụng = 0.
- Đếm `required` bị null sau migration = 0.
- **Parity backfill:** số doc có field mới == số doc có field cũ (vd attempt có `examSnapshotId` == attempt có `examSnapshot`); sample 20 doc so khớp nội dung.
- Index tồn tại + `explain()` query nóng = `IXSCAN` (không `COLLSCAN`).

**T2 · Contract API (golden diff):**
- Gọi lại ~10 endpoint nóng, **diff JSON với golden D0**. Kỳ vọng: chỉ khác đúng phần CHỦ ĐÍCH (vd thêm `id`); **không mất/đổi field** nào khác. Bất kỳ khác ngoài dự kiến = chặn.
- `npm start` sạch; socket.io kết nối; smoke login + 3 luồng chính.

**T3 · Flutter:**
- `dart analyze lib` → 0 lỗi mới.
- Smoke **đúng màn đọc field bị đụng** (xem §5): mở, thấy dữ liệu, không trắng/parse-fail. Đặc biệt: grading hub **bấm vào bài** (id), gradebook hiện điểm (scores), live mirror hiện đề (snapshot).

**T4 · Hồi quy luồng E2E:**
- Học sinh làm 1 đề → nộp → giáo viên chấm → release → học sinh xem điểm.
- Chat: gửi/nhận, danh sách, unread.
- Enroll/progress 1 kỹ năng.

---

## 4. Chuẩn migration script

- Đặt ở `backend/migrations/NNN-tên.js`; chạy qua runner ghi `migrations` collection (đã chạy cái nào).
- **Bắt buộc:** `--dry` (in thống kê, không ghi); **batched** (`cursor` + `bulkWrite` ~1000/lần); **idempotent** (chạy lại cho kết quả như nhau, dùng `$set`/guard `if exists`); **log** số đọc/ghi/bỏ qua; **không** `deleteMany` ở bước expand/backfill.
- Quy trình chạy: dry trên staging → thật trên staging → audit T1 → **backup prod** → dry prod → thật prod (giờ thấp tải) → audit.
- Reversible: mỗi migration kèm ghi chú cách hồi (vd `$unset` field mới); với D4 giữ field cũ là đường lùi.

---

## 5. Bản đồ thay đổi ↔ file backend + endpoint + màn Flutter (tra để biết phải kiểm gì)

| Thay đổi | Backend đụng | Endpoint (golden) | Flutter đọc (smoke) |
|----------|--------------|-------------------|---------------------|
| `id` serializer / `.lean()` | mọi service trả list `.lean()` (gradebook, hub, dashboard) | `assignments/:id/attempts`, gradebook, dashboard | grading hub (`m['id']`), gradebook, mọi list — bấm mở được |
| `scores`/`integrity` sub-schema | `examGradingService`, `examAttemptService` | `grading-attempts/:id`, attempts list | `teacher_gradebook_view`, `teacher_assignment_grading_hub_view`, `teacher_exam_attempt_grade_page` (đọc `scores.totalAwarded/skillScores`) |
| `examSnapshot` dedup | `examAttemptService` (tạo attempt, getForGrading, getLiveScreen), `examSessionService` | `grading-attempts/:id`, `attempts/:id/live-screen`, student `attempts/:id` | `teacher_exam_attempt_grade_page`, `student_exam_live_mirror_view`, exam runner (đọc `examSnapshot.sections`) |
| cascade/soft-delete | classroom/exam/user delete services | list lớp/đề/thành viên | các list (không lộ item đã xoá) |
| TTL | – (chỉ index) | notifications, audit | inbox thông báo |
| `SpeakingAttempt` ObjectId | speaking grading/populate | speaking attempt endpoints | màn speaking review |
| `Word.user`→`userId` | vocabulary service | vocabulary endpoints | `vocabulary` (đọc `user`/`userId`) |

---

## 6. Rollback theo giai đoạn

- D1/D2/D3: revert commit; index/sub-schema/TTL additive nên gỡ an toàn (TTL: drop index trước khi nó xoá thêm).
- D4: vì còn `examSnapshot` cũ (dual-write) → chỉ cần đổi code đọc về field cũ; chưa chạy bước "Contract" thì dữ liệu nguyên vẹn.
- D5 (`Word` rename): dual-field nên revert đọc về `user`.
- **Vàng:** không xoá field/collection cũ cho tới khi giai đoạn đó "xanh" ổn định nhiều ngày.

---

## 7. Checklist tổng (mỗi giai đoạn tick đủ mới qua)

- [ ] Migration: dry-run staging OK → chạy staging → **T1 (orphan/required/parity/index) xanh**.
- [ ] **T2 golden diff**: chỉ khác phần chủ đích; backend `npm start` + smoke OK.
- [ ] **T3 Flutter**: `dart analyze` 0 lỗi + smoke đúng màn ở §5.
- [ ] **T4 E2E**: làm-nộp-chấm-release / chat / enroll OK.
- [ ] Backup prod trước khi chạy prod; commit riêng; ghi nhật ký migration.
- [ ] Đường rollback đã xác nhận (field cũ còn nguyên).

> **Khuyến nghị thứ tự thực thi:** D0 → D1 → D2 → D3 → **(dừng, ổn định)** → D4 (cô lập) → D5. Mỗi giai đoạn là một PR riêng. Ghi commit vào nhật ký migration + tham chiếu [`../database-design-audit.md`](../database-design-audit.md).
</content>
