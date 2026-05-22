# 14 — Teacher workspace dialogs

> **Phạm vi:** Giáo viên (web + teacher mobile shell). Không áp dụng cho học sinh (mobile profile dùng page / bottom sheet — xem `04`, `05`).

## 1. Nguyên tắc

| Quy tắc | Chi tiết |
|---------|----------|
| **Luôn dialog căn giữa** | Không `showModalBottomSheet` cho cài đặt tài khoản, đổi mật khẩu, sửa hồ sơ, chọn ngôn ngữ/múi giờ. |
| **Một shell chung** | Mọi modal dùng `TeacherDialogShell` (`07` §4). |
| **Nút chuẩn workspace** | Footer: `TeacherDialogFooterActions` + `TeacherWebUi.compactOutlinedStyle` / `compactFilledStyle`. |
| **Form chuẩn** | Label trên field (`TeacherWebUi.formFieldLabel`), ô `formInputDecoration` — không copy layout mobile `_ColorfulInput`. |
| **Hub → dialog con** | Menu tài khoản đóng trước, mở dialog con bằng `rootNavigatorKey` (tránh context dispose). |

## 2. Anatomy — `TeacherDialogShell`

```
┌─────────────────────────────────────────────┐
│ [icon 40]  Title (web.h2)            [×]   │
│            Subtitle (metaMuted)             │
├─────────────────────────────────────────────┤
│  scroll body (maxHeight configurable)       │
├─────────────────────────────────────────────┤
│  [ Cancel outlined ]  [ Primary filled ]    │  ← optional footer
└─────────────────────────────────────────────┘
```

| Thuộc tính | Giá trị mặc định | Ghi chú |
|------------|------------------|---------|
| Width | 480 | Hub account: 440; form edit profile: 520 |
| Padding | 24 | Header / body / footer |
| Radius | 16 | |
| Backdrop | `rgba(0,0,0,.40)` | |
| Close | Icon 18, `compactHeaderIconStyle` | Góc phải header |
| Body scroll | `maxBodyHeight` 200–520 | Form dài: 480 |

**Mở dialog:**

```dart
TeacherDialogShell.show<void>(context, child: const MyDialog());
// hoặc
TeacherDialogs.showEditProfile(context);
```

## 3. Catalog dialog

| Dialog | File | Width | Footer | Mô tả |
|--------|------|-------|--------|--------|
| **Account hub** | `teacher_account_menu.dart` | 440 | Đăng xuất + xóa TK | Danh sách `TeacherDialogOptionTile` |
| **Edit profile** | `teacher_edit_profile_dialog.dart` | 520 | Cancel + Save | Avatar, public/private fields, email read-only |
| **Change password** | `teacher_change_password_dialog.dart` | 480 | Cancel + Save | 3 ô password |
| **Language** | `teacher_account_menu.dart` | 400 | Close only | `_PickerChoiceTile` EN / VI |
| **Timezone** | `teacher_account_menu.dart` | 420 | Close only | Danh sách IANA zones |
| **Delete account** | `teacher_account_menu.dart` | 480 | Cancel + Delete (destructive) | Xác nhận ngắn |
| **Assign exam** | `teacher_assign_exam_dialog.dart` | 560 | Cancel + Giao bài | Đối tượng, mode grid 2×2, lịch theo mode, rules trong `ExpansionTile` |
| **Edit assignment** | `teacher_edit_assignment_dialog.dart` | 560 | Cancel + Save | Chỉnh lịch, time limit, attempts, kết quả — mode read-only chips |

## 4. Patterns

### 4.1 Hub menu (`TeacherDialogOptionTile`)

- Mỗi mục: khung `outlineMuted`, icon trong ô 32×32 `surfaceSubtle`.
- Trailing: giá trị hiện tại (ngôn ngữ, TZ) + chevron nếu có `onTap`.
- Nhóm: `TeacherDialogSectionLabel` (dùng l10n `accountAndSecurity`, `generalSettings`, …).

### 4.2 Picker dialog (language / timezone)

- Body: cột `_PickerChoiceTile` — selected = `primaryTint` + viền `primary` 1.5px + `check_circle`.
- Footer: một nút **Close** full-width outlined (không Cancel/Save đôi).

### 4.3 Assign exam dialog

- **Mở:** `TeacherDialogs.showAssignExam(context, examId: …)` từ Ngân hàng đề / Lớp / Dashboard — **không** full-page `/assign` (route legacy chỉ mở dialog rồi pop).
- **Header:** subtitle = tên đề khi load xong.
- **Body:** `TeacherDialogSectionLabel` → Đối tượng (segmented Lớp / Link) → Hình thức (**grid 2×2** mode card + hint) → khối lịch động (due / opens+closes / realtime note) → preset (tuỳ chọn) → `TeacherDialogExpandableSection` (Lượt làm & kết quả: viền + icon + nút **Tùy chỉnh / Thu gọn**).
- **Footer:** Cancel + **Giao bài**; success → `TeacherCornerToast` + `Navigator.pop(assignment)`.
- **Realtime:** không nhập opens/closes; ghi chú info box → mở phòng sau trên dashboard.

### 4.4 Form dialog (profile / password)

- Section label trong body (`sectionPublicInfo`, …).
- `_Field` wrapper: label + gap 6 + `TextFormField` / `DropdownButtonFormField`.
- Primary **disabled** khi chưa dirty (`primaryEnabled: _isDirty`).
- Success: `TeacherCornerToast.show` (góc dưới phải, rộng vừa chữ) rồi `Navigator.pop`.

### 4.5 Destructive confirm

- `TeacherDialogFooterActions(destructive: true)` → primary filled `AppColors.danger`.
- Body có thể rỗng nếu subtitle đủ context.

## 5. Code map

| Thành phần | Path |
|------------|------|
| Corner toast (success/error) | `lib/feature/teacher/layout/teacher_corner_toast.dart` |
| Shell + footer + option tile + expandable section | `lib/feature/teacher/layout/teacher_dialog_shell.dart` |
| API mở nhanh | `lib/feature/teacher/layout/teacher_dialogs.dart` |
| Account hub | `lib/feature/teacher/layout/teacher_account_menu.dart` |
| Assign exam | `lib/feature/teacher/layout/teacher_assign_exam_dialog.dart` |
| Edit profile | `lib/feature/teacher/layout/teacher_edit_profile_dialog.dart` |
| Change password | `lib/feature/teacher/layout/teacher_change_password_dialog.dart` |
| Trigger (sidebar ⋮) | `lib/feature/teacher/layout/teacher_shell.dart` → `showTeacherAccountMenu` |

**Student route** `/profile/edit` (`EditProfilePage`) vẫn tồn tại cho shell học sinh; teacher **không** navigate route này từ account hub.

## 6. Checklist (AI / dev)

- [ ] Không bottom sheet cho teacher account/settings.
- [ ] Dialog dùng `AppColors` / `TeacherWebUi`, không hardcode Zinc/Shadcn từ student profile.
- [ ] Footer nút cao 32 (`buttonHeightPrimary`), không padding 16 kiểu mobile.
- [ ] Chuỗi UI qua `AppLocalizations` (EN + VI).
- [ ] Cập nhật doc này khi thêm dialog teacher mới.

## 7. Liên kết

- Token & modal spec chung: [`07-web-components.md`](07-web-components.md) §4
- Sidebar footer: [`06-web-foundations.md`](06-web-foundations.md) §2.1
- Implementation map: [`11-implementation-mapping.md`](11-implementation-mapping.md)
