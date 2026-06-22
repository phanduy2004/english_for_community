# 25 — Bug: không mở được bài làm từ Grading hub (Student work)

> **Phạm vi:** màn "Student work" (grading hub assignment-level) — bấm thẻ học sinh / nút **Grade** không mở trang chấm bài.
> **Loại:** bug logic (lệch key id giữa backend ↔ frontend), KHÔNG phải UI.
> **Nguồn:** đọc code 06/2026.

---

## 1. Triệu chứng
Bấm vào thẻ học sinh hoặc nút **Grade** ở danh sách "Student submissions" → **không có gì xảy ra** (không mở trang chấm). Tên/điểm/trạng thái vẫn hiển thị bình thường.

---

## 2. Root-cause (lệch key `id`)

| Tầng | Sự thật | `file:dòng` |
|------|---------|-------------|
| **Backend** | `getAssignmentGradingHub` dùng `.lean()` và **trả nguyên document** (`rows = attempts.map(plain => … return plain)`) → mỗi item chỉ có **`_id`** (string), **KHÔNG có `id`/`attemptId`** | `english_for_community_backend/src/services/examAttemptService.js:1775-1799` |
| **Frontend** | Thẻ + nút Grade gọi `onOpen`, mà `onOpen` đọc **`m['id']`** → rỗng → **`return` sớm**, không push route | `lib/feature/teacher/teacher_assignment_grading_hub_view.dart:266-268` (và `:259` key, `:271`, `:278`) |

```dart
// teacher_assignment_grading_hub_view.dart:265-268 — id rỗng → return, không mở
onOpen: () {
  final id = m['id'] as String? ?? '';   // ← '_id' chứ không phải 'id' ⇒ rỗng
  if (id.isEmpty) return;                 // ← thoát ở đây
  context.push(TeacherExamAttemptGradePage.location(assignmentId, id));
},
```

> Datasource trả nguyên mảng, không remap: `teacher_exam_remote_datasource.dart:153-156` (`{'attempts': data}`). Nên item giữ key `_id` của Mongo.

---

## 3. Giải pháp (sửa cả 2 tầng — backend là gốc, frontend là phòng vệ)

### S1 · Backend (gốc) — thêm `id` (string) vào mỗi attempt item
Tại `getAssignmentGradingHub`, map mỗi `plain` kèm id chuỗi (giữ `attemptId` cho nhất quán các endpoint khác):
```js
const rows = attempts.map((plain) => {
  // …stats giữ nguyên…
  return { ...plain, id: String(plain._id), attemptId: String(plain._id) };
});
```
→ Client nhận `id` → `onOpen` push được. (Các endpoint attempt khác trong service đã dùng `attemptId: attempt._id.toString()` — đây cho nhất quán.)

### S2 · Frontend (phòng vệ) — đọc id nhiều key
Mọi nơi đọc id của attempt trong grading hub đọc fallback:
```dart
String _attemptId(Map m) => (m['id'] ?? m['attemptId'] ?? m['_id'])?.toString() ?? '';
```
Áp cho `onOpen` (`:266`), `onAi` (`:271`), `onRelease` (`:278`), và `key: ValueKey(...)` (`:259`).
→ Bền vững nếu một endpoint trả `_id`/`attemptId` thay vì `id`.

> Làm **S1 hoặc S2 đều fix được**; làm cả hai là chắc chắn nhất.

---

## 4. Audit / verify
- [ ] Mở Student work của 1 assignment có bài nộp → **bấm thẻ học sinh** mở trang chấm (`TeacherExamAttemptGradePage`).
- [ ] **Bấm nút Grade** cũng mở; nút AI / Release vẫn chạy (cùng id).
- [ ] Kiểm payload `GET teacher/exams/assignments/:id/attempts`: mỗi item có `id` (chuỗi) khớp `_id`.
- [ ] `dart analyze lib` 0 lỗi mới; backend không đổi shape field khác (chỉ thêm `id`/`attemptId`).

---

## 5. Bản đồ file ↔ việc
| File | Việc |
|------|------|
| `examAttemptService.js` (`getAssignmentGradingHub` ~1789-1799) | map mỗi row `{ ...plain, id: String(plain._id), attemptId: String(plain._id) }` |
| `teacher_assignment_grading_hub_view.dart` (`:259,266,271,278`) | helper `_attemptId(m)` đọc `id ?? attemptId ?? _id` |

> Ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md) "Migration log".
</content>
