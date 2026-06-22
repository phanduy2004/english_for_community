# 26 — Chiến lược feedback & thông báo (mobile student)

> **Vấn đề:** trên màn mobile học sinh vẫn xuất hiện **toast góc phải-dưới** (`AppCornerToast`) — đó là idiom **web** (teacher/admin). Cần: bỏ toast góc trên mobile; **lỗi/exception → dialog**; **sự kiện socket → push**. Đánh giá cách làm này có hợp lý không + đưa phương án tối ưu.
> **Nguồn:** đọc code 06/2026. Liên quan [`04`](04-mobile-components.md), [`09`](09-content-and-microcopy.md), [`15`](15-mobile-smart-patterns.md), [`20`](20-student-mobile-audit-and-standards.md).

---

## 1. Hiện trạng

- **`AppCornerToast`** dùng **66 chỗ** trong màn student-facing (cao nhất: `student_join_coordinator` 12, `integrated_exam_runner` 8, `chat_settings_menu` 7, `writing_task` 4, `exam_runner` 4, `notification_inbox` 4…). So với chỉ **3 SnackBar**, 24 `showDialog`, 4 bottom-sheet → toast là kênh feedback chính.
- `app_corner_toast.dart` **đã có nhánh phân biệt** (`:62 isStudentMobileFeedback()`):
  - student mobile (`role=='user'`, **không phải web**) → **SnackBar đáy full-width** (đúng mobile).
  - web/teacher/admin → **toast nổi góc phải-dưới** (đúng desktop).
- **Lỗ hổng:** điều kiện dựa vào **`kIsWeb`** (`:25`). Khi **chạy app student TRÊN TRÌNH DUYỆT** (dev) → `kIsWeb=true` → rơi vào nhánh **corner-toast** dù là học sinh. ⇒ đó là lý do bạn thấy toast góc phải trên "màn mobile". Trên điện thoại thật thì student đã ra SnackBar đáy.
- **Realtime:** `socket_notification_handler.dart` chỉ đẩy data về UI tự xử lý (`:16`) — chưa có chuẩn rõ "foreground hiện gì / background đẩy push gì".

---

## 2. Đánh giá cách làm của bạn (có hợp lý không?)

| Ý tưởng | Đánh giá | Tinh chỉnh |
|---------|----------|-----------|
| **Bỏ toast góc trên mobile** | ✅ Đúng. Toast góc phải là idiom desktop. | Phát hiện theo **role/layout**, KHÔNG theo `kIsWeb` (student chạy web vẫn phải feedback kiểu mobile). |
| **Lỗi/exception → dialog** | ⚠️ Đúng **một phần**. | KHÔNG phải MỌI lỗi đều dialog — sẽ thành "bão modal" (vd lúc 500 dội liên tục như bug reading submit). Chỉ **lỗi blocking/cần quyết định** mới dialog; lỗi nhẹ/tạm → SnackBar/inline. |
| **Socket → push** | ✅ Đúng hướng. | Tinh chỉnh theo **trạng thái app**: foreground-đúng-màn → cập nhật tại chỗ; foreground-màn-khác → **banner trong app**; background → **system push**. KHÔNG toast. |

> **Tóm:** hướng đúng, nhưng cốt lõi là **phân loại theo MỨC ĐỘ + NGỮ CẢNH**, không "một-kênh-cho-tất-cả".

---

## 3. Phân loại feedback chuẩn (taxonomy)

| Loại sự kiện | Ví dụ | Mobile student | Web teacher/admin |
|--------------|-------|----------------|-------------------|
| **Xác nhận nhẹ** (thành công, không cần chú ý) | "Đã lưu", "Đã sao chép", "Đã tham gia lớp" | **SnackBar đáy** ngắn (1.5–2s) hoặc dấu ✓ inline | corner toast |
| **Lỗi field / validation** | "Chưa chọn đáp án", "Email sai" | **inline dưới field** (KHÔNG toast/dialog) | inline |
| **Lỗi nhẹ / tạm (tự hồi)** | mạng chập chờn có auto-retry | **banner mảnh** / SnackBar có "Thử lại" | toast |
| **Lỗi BLOCKING / cần quyết định** | submit thất bại, hết phiên thi, không có quyền, dữ liệu hỏng | **DIALOG** + hành động rõ (Thử lại / OK) | dialog |
| **Realtime — đang ở đúng màn** | tin nhắn mới khi đang mở phòng chat | **cập nhật UI tại chỗ** (tin hiện ra) | tại chỗ |
| **Realtime — màn khác (foreground)** | tin mới / bài giao mới khi đang ở Home | **in-app banner đỉnh màn** + badge tab | banner/badge |
| **Realtime — background** | tin/đề mới khi app nền | **system push** (FCM/Local notif) → mở đúng màn | desktop notif/push |

**Nguyên tắc chống "bão thông báo":** gộp/giảm tần suất (debounce), không hiện trùng; lỗi lặp lại liên tục (vd 500 dội) → **một dialog/banner duy nhất**, không spam.

---

## 4. Giải pháp kỹ thuật (tối ưu)

### 4.1 Một API feedback định tuyến theo ngữ cảnh — `AppFeedback`
Thay vì call site tự chọn `AppCornerToast.show(...)`, dùng API ngữ nghĩa, để **lớp này** quyết kênh theo (role/layout + mức độ):
```dart
AppFeedback.success(context, 'Đã lưu');          // → SnackBar (mobile) / toast (web)
AppFeedback.info(context, '...');
AppFeedback.error(context, msg, blocking: false); // nhẹ → SnackBar/banner
AppFeedback.error(context, msg, blocking: true);  // → DIALOG (Thử lại/OK)
AppFeedback.fieldError(...)                        // inline (không nổi)
```
- **Bỏ corner-toast cho student:** điều kiện chuyển sang **`WorkspaceLayoutScope.isWebWorkspace` (teacher/admin)**, KHÔNG `kIsWeb`. Student (kể cả chạy web) luôn nhận feedback kiểu mobile (SnackBar/dialog/banner).
- Dedup: nuốt message trùng trong N giây; lỗi blocking đang mở dialog thì không chồng dialog mới.

### 4.2 Dialog lỗi chuẩn (cho lỗi blocking)
- `AppFeedback.error(..., blocking:true)` → dialog tiêu đề ngắn + nội dung hệ quả + 1–2 nút (Thử lại / Đóng). Tái dùng cho: submit fail, hết phiên, no-permission, parse/dữ liệu hỏng.

### 4.3 Realtime: banner + push (bỏ toast)
- **In-app banner** (widget đỉnh màn, tự ẩn, bấm để mở) cho sự kiện foreground màn-khác — thay vì toast. Kèm **badge** ở tab tương ứng.
- **Background → `LocalNotificationService`/FCM**: chuẩn hoá payload (deeplink: classroom/assignment/listening…) để bấm mở đúng màn. Socket handler **không** tự toast; chỉ: foreground→banner, background→push.
- Đang ở đúng màn (phòng chat đang mở) → chỉ cập nhật list, **không** banner/push.

### 4.4 Giảm phụ thuộc toast
- Map lại 66 chỗ `AppCornerToast.show`: xác nhận nhẹ→`success/info`; lỗi→`error(blocking?)`; validation→`fieldError` inline; sự kiện realtime→banner/push.

---

## 5. Kế hoạch sửa

1. **Tạo `AppFeedback`** (bọc logic hiện có của `AppCornerToast` + thêm `blocking`/`fieldError`/`banner`); đổi detection corner-toast sang `isWebWorkspace` (bỏ `kIsWeb`).
2. **Sweep 66 call site** `AppCornerToast.show` → `AppFeedback.*` đúng mức độ (success/info/error-blocking/error-light/fieldError).
3. **Dialog lỗi blocking** cho: exam submit fail, hết phiên (`exam_live_session_guard`), no-permission, lỗi parse.
4. **Realtime**: thêm in-app banner + badge; socket handler chỉ foreground-banner / background-push; chuẩn hoá deeplink push.
5. **Dedup** message trùng + chặn chồng dialog.

---

## 6. Audit checklist

- [ ] Trên student (kể cả chạy web): **không còn toast góc phải-dưới**; xác nhận nhẹ = SnackBar đáy/inline.
- [ ] Lỗi blocking (submit fail / hết phiên / no-permission) = **dialog** có hành động; KHÔNG modal cho lỗi nhẹ/validation.
- [ ] Validation = inline dưới field.
- [ ] Realtime foreground màn-khác = banner + badge; background = system push mở đúng màn; đang ở đúng màn = cập nhật tại chỗ.
- [ ] Lỗi lặp (500 dội) = 1 thông báo duy nhất, không spam; không chồng dialog.
- [ ] `dart analyze lib` 0 lỗi; smoke: làm bài lỗi mạng, nhận tin khi ở Home vs ở phòng chat vs nền.

---

## 7. Bản đồ file ↔ việc

| File | Việc |
|------|------|
| `core/ui/widget/app_corner_toast.dart` | đổi detection sang `isWebWorkspace`; (giữ làm backend của `AppFeedback`) |
| `core/ui/feedback/app_feedback.dart` (mới) | API `success/info/error(blocking)/fieldError`; dedup; dialog lỗi |
| 66 call site `AppCornerToast.show` (student-facing) | map sang `AppFeedback.*` đúng mức độ |
| `core/socket/handlers/socket_notification_handler.dart` + nơi tiêu thụ | foreground→banner/badge, background→push; bỏ toast |
| `core/notification/local_notification_service.dart` | chuẩn hoá payload deeplink mở đúng màn |
| `exam_live_session_guard.dart`, `exam_runner_page.dart`, runner | lỗi blocking → dialog |

> Ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md). Tham chiếu microcopy [`09`](09-content-and-microcopy.md) cho nội dung thông báo.
</content>
