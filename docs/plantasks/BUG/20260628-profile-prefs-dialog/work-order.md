# Work-order — Profile (student mobile): pickers bottom-sheet → dialog + audit layout

- **Task ID:** 20260628-profile-prefs-dialog
- **Loại:** BUG (sửa hành vi/layout màn Profile)
- **Platform:** student mobile
- **Màn + file:** Profile · `english_for_community/lib/feature/profile/profile_page.dart`
- **Mục tiêu:** Các picker trong Profile đang mở **bottom sheet kéo lên** → đổi sang **dialog** (giữ chrome `StudentDialogShell`), + fix các lỗi layout nhỏ tìm thấy trên màn.
- **Cỡ task:** MICRO → 1 file work-order (1 file code bị chạm).
- **Trạng thái:** PLANNED — chờ Cursor IMPLEMENT.

---

## 1) Vấn đề + nguyên nhân gốc (dẫn chứng code)

Trong `profile_page.dart` có **3 picker** đang dùng `StudentBottomSheet.show(...)` (modal bottom sheet kéo từ đáy):

| Method | Dòng | Mục trên màn | Nội dung |
|---|---|---|---|
| `_showDailyTimePicker` | `139–166` | Learning Preferences | chọn 15/30/45/60 phút/ngày |
| `_showLessonGoalPicker` | `168–195` | Learning Preferences | chọn 3/5/7/10 bài/ngày |
| `_showAppLanguagePicker` | `197–243` | General Settings | chọn EN/VI + footnote |

Nguyên nhân: cả 3 gọi `StudentBottomSheet.show(context, StudentBottomSheet(...))` (`profile_page.dart:141, 170, 200`), trong khi yêu cầu là hiển thị dialog.

**Đã có sẵn hạ tầng dialog — không cần dựng mới:**
- `StudentDialogShell` (`core/ui/student_mobile_ui.dart:1391`): `Dialog` chuẩn, có `title / subtitle / child / actions / maxWidth(=320)`, padding `AppSpacing.s7`, `crossAxisAlignment: stretch`.
- Mẫu chuyển đổi chuẩn của repo: `feature/home/listening_mode_dialog.dart:16` → `showDialog(... builder: (ctx) => StudentDialogShell(...))`, đóng bằng `Navigator.pop(ctx)` trong `onTap`. Pattern này KHỚP nguyên với 3 method hiện tại → đổi 1-1, không đổi logic.
- `StudentMobileUi.listTile` (`student_mobile_ui.dart:354`) là `Row(Expanded + trailing)` → render tốt trong dialog.

## 2) Audit downstream

- `StudentBottomSheet` vẫn được dùng ở chỗ khác (writing_topics, chat_input_bar, free_speaking, chat_settings_menu, teacher_*). **KHÔNG xoá/sửa class `StudentBottomSheet`** — chỉ đổi *cách gọi* trong `profile_page.dart`. Không ảnh hưởng consumer khác.
- 3 method này được gọi nội bộ trong `profile_page.dart` (onTap của `_SettingsTile`) → đổi thân hàm là đủ, không đổi signature, không đụng caller.
- `_quickUpdateProfile(...)` (logic cập nhật BLoC) **giữ nguyên** — chỉ đổi vỏ UI.

## 3) Quyết định thiết kế + cảnh báo

- **Dùng `StudentDialogShell` + `showDialog`** (đúng pattern `listening_mode_dialog`). Không tạo widget mới.
- **Đóng dialog:** giữ `Navigator.pop(ctx)` trong `onTap` (ctx = builder context). Barrier tap & nút back vẫn đóng (mặc định `barrierDismissible: true`). Dialog **không cần nút X** (khác bottom sheet) — đồng bộ với `listening_mode_dialog`.
- **App Language footnote:** chuyển `t.appLanguageFootnote` từ một `Padding(Text(...))` trong `child` → dùng slot **`subtitle`** của `StudentDialogShell` (bỏ `Padding` thừa). Sạch hơn, đúng vai trò subtitle.
- **Lề:** `StudentDialogShell` đã có padding `s7`; `listTile` có padding ngang `s5` → tổng inset trái ~`s7+s5`. Đây là chuẩn dialog của repo (listening_mode_dialog cũng nest card có padding trong shell `s7`). Implementer **verify mắt** 1 lần; nếu thấy quá sâu thì set `maxWidth: 360` cho thoáng (KHÔNG dùng padding âm).
- **Phạm vi đổi:** đổi cả 3 (gồm App Language ở General Settings) để màn Profile **không còn bottom sheet nào** → nhất quán. (User nhắc "learning preference"; App Language cùng pattern nên gộp luôn — nếu chỉ muốn 2 cái Learning Preferences thì báo, sẽ bỏ phần `_showAppLanguagePicker`.)
- Cảnh báo: `reminderTime` đang dùng **`showTimePicker` native** (đã là dialog) → **không đụng**.

## 4) Scope IN / OUT

**IN (được chạm — chỉ `profile_page.dart`):**
- `_showDailyTimePicker` (139–166), `_showLessonGoalPicker` (168–195), `_showAppLanguagePicker` (197–243): đổi `StudentBottomSheet.show` → `showDialog` + `StudentDialogShell`.
- (Tùy chọn, mục 5.D) fix nhỏ `_SettingsTile.value` overflow + dead-tap `timezone`.

**OUT — chạm là DỪNG & hỏi:**
- KHÔNG sửa class `StudentBottomSheet` / `StudentDialogShell` trong `student_mobile_ui.dart`.
- KHÔNG đụng `_quickUpdateProfile`, `UserBloc`, event/state, schema, l10n keys (dùng key có sẵn).
- KHÔNG đổi `_showTimePicker` (native), `_handleDeleteAccount`, `ChangePasswordDialog`.
- KHÔNG đổi màn/file khác ngoài `profile_page.dart`.

## 5) Diff cụ thể (dán được)

> Mỗi block dưới đây thay **nguyên thân** method tương ứng trong `profile_page.dart`. Không thêm import (file đã import `student_mobile_ui.dart`).

### A. `_showDailyTimePicker` (139–166)
```dart
void _showDailyTimePicker(BuildContext context, int currentMinutes) {
  final t = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => StudentDialogShell(
      title: t.setDailyTimeGoal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [15, 30, 45, 60]
            .map(
              (mins) => StudentMobileUi.listTile(
                context: ctx,
                title: t.minutesPerDayOption(mins),
                leading: StudentMobileUi.skillIconBox(Icons.timer_outlined, size: 40),
                trailing: currentMinutes == mins
                    ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (currentMinutes != mins) _quickUpdateProfile(dailyMinutes: mins);
                },
              ),
            )
            .toList(),
      ),
    ),
  );
}
```

### B. `_showLessonGoalPicker` (168–195)
```dart
void _showLessonGoalPicker(BuildContext context, int currentGoal) {
  final t = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => StudentDialogShell(
      title: t.setDailyLessonGoal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [3, 5, 7, 10]
            .map(
              (count) => StudentMobileUi.listTile(
                context: ctx,
                title: t.lessonsPerDayOption(count),
                leading: StudentMobileUi.skillIconBox(Icons.flag_outlined, size: 40),
                trailing: currentGoal == count
                    ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (currentGoal != count) _quickUpdateProfile(dailyLessonGoal: count);
                },
              ),
            )
            .toList(),
      ),
    ),
  );
}
```

### C. `_showAppLanguagePicker` (197–243) — footnote → `subtitle`
```dart
void _showAppLanguagePicker(BuildContext context) {
  final t = AppLocalizations.of(context)!;
  final ctrl = GetIt.I<AppLocaleController>();
  showDialog(
    context: context,
    builder: (ctx) => StudentDialogShell(
      title: t.selectAppLanguage,
      subtitle: t.appLanguageFootnote,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StudentMobileUi.listTile(
            context: ctx,
            title: t.languageEnglish,
            leading: StudentMobileUi.skillIconBox(Icons.language, size: 40),
            trailing: ctrl.locale.languageCode == 'en'
                ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                : null,
            onTap: () {
              ctrl.setLocale(const Locale('en'));
              Navigator.pop(ctx);
            },
          ),
          StudentMobileUi.listTile(
            context: ctx,
            title: t.languageVietnamese,
            leading: StudentMobileUi.skillIconBox(Icons.language, size: 40),
            trailing: ctrl.locale.languageCode == 'vi'
                ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                : null,
            onTap: () {
              ctrl.setLocale(const Locale('vi'));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}
```

> Sau khi đổi, import `AppSpacing` có thể còn dùng ở chỗ khác trong file (header, tiles) → **không xoá import**. Chạy `dart analyze` để chắc không có import thừa mới phát sinh.

### D. (TÙY CHỌN — fix layout nhỏ phát hiện khi audit; làm nếu user OK)

**D1 — `_SettingsTile.value` có thể tràn (overflow) với value dài.** `profile_page.dart:685-686`: `value` là `Text` đặt thẳng trong `Row` (title đã `Expanded`), value **không** bọc `Flexible` → value dài (timezone/label tương lai) gây RenderFlex overflow. Sửa an toàn:
```dart
// thay:  if (value != null) Text(value!, style: AppTypography.body(color: AppColors.textPrimary)),
if (value != null)
  Flexible(
    child: Text(
      value!,
      style: AppTypography.body(color: AppColors.textPrimary),
      textAlign: TextAlign.end,
      overflow: TextOverflow.ellipsis,
    ),
  ),
```

**D2 — Tile "Timezone" là dead-tap.** `profile_page.dart:449-454`: `onTap: () {}` rỗng → có ripple nhưng không làm gì, value dài lại không có chevron. Nếu chưa có picker timezone → **bỏ `onTap`** để thành dòng chỉ-hiển-thị (như App Version), tránh gây hiểu nhầm bấm được:
```dart
_SettingsTile(
  icon: Icons.public,
  title: t.timezone,
  value: user.timezone ?? 'GMT+7',
), // bỏ onTap: () {}
```
(Tile "Export Data" cũng gọi `_goExportData()` rỗng — **để nguyên** lần này, ngoài scope; ghi nhận ở mục 8.)

## 6) Lệnh verify (chạy ngay)

```bash
cd english_for_community
flutter analyze lib/feature/profile/profile_page.dart
# build nhanh (debug) để chắc không gãy:
flutter build apk --debug -t lib/main.dart   # hoặc chạy app và mở Profile
```
Kỳ vọng: `analyze` 0 lỗi/0 warning mới. Mở Profile → bấm "Daily time goal", "Daily lesson goal", "App language" → hiện **dialog** (mờ nền, bo góc) thay vì sheet kéo lên; chọn option → đóng + cập nhật đúng.

## 7) HANDOFF PROMPT cho Cursor (IMPLEMENT)

```text
Bạn là implementer (Codex/Sonnet). Theo docs/AI-Working-Process-vi.md, chỉ làm ĐÚNG file & diff dưới.

FILE DUY NHẤT được sửa: english_for_community/lib/feature/profile/profile_page.dart

VIỆC:
1. Thay nguyên thân 3 method bằng code ở mục 5.A / 5.B / 5.C của work-order
   (docs/plantasks/BUG/20260628-profile-prefs-dialog/work-order.md):
   - _showDailyTimePicker  → showDialog + StudentDialogShell
   - _showLessonGoalPicker → showDialog + StudentDialogShell
   - _showAppLanguagePicker→ showDialog + StudentDialogShell (footnote → subtitle)
2. Áp mục 5.D1 (Flexible cho _SettingsTile.value) và 5.D2 (bỏ onTap rỗng tile Timezone).

TUYỆT ĐỐI KHÔNG:
- Sửa class StudentBottomSheet / StudentDialogShell trong core/ui/student_mobile_ui.dart.
- Đụng _quickUpdateProfile, UserBloc/event/state, l10n keys, schema.
- Đổi _showTimePicker (native), Export Data, hay bất kỳ file nào khác.
- Thêm/đổi import trừ khi analyze báo thiếu.

VERIFY (dán kết quả vào tracker/work-order):
- cd english_for_community && flutter analyze lib/feature/profile/profile_page.dart  → 0 lỗi mới.
- Chạy app → Profile → 3 mục mở DIALOG (không phải bottom sheet), chọn option đóng + cập nhật đúng.
Khi pass: đặt trạng thái DONE và báo "implementer đã xong, audit đi".
```

## 8) Checklist OPUS AUDIT (chạy khi implementer xong)

- [ ] Cả 3 method dùng `showDialog` + `StudentDialogShell`; không còn `StudentBottomSheet.show` trong `profile_page.dart`.
- [ ] `Navigator.pop(ctx)` dùng đúng builder context; chọn option đóng dialog + gọi `_quickUpdateProfile` đúng tham số như cũ.
- [ ] `_showAppLanguagePicker`: footnote nằm ở `subtitle`, bỏ `Padding` thừa; set locale vẫn hoạt động.
- [ ] Không đổi signature 3 method; caller `_SettingsTile.onTap` không đổi.
- [ ] `StudentBottomSheet` class còn nguyên (consumer khác không gãy) — grep xác nhận.
- [ ] 5.D1/5.D2 áp đúng; không scope-creep sang Export Data / file khác.
- [ ] `flutter analyze` 0 lỗi/warning mới; verify mắt dialog hiển thị đúng.
- [ ] Việc còn lại của DEV: cân nhắc làm picker Timezone thật + nối Export Data (đang rỗng) — **defer**, ngoài task này.

---

### Phụ lục — Audit layout màn Profile (ground-truth, ngoài 3 picker)

| # | Vị trí | Mức | Mô tả | Xử lý |
|---|---|---|---|---|
| L1 | `_SettingsTile` `685-686` | Med | `value` Text không `Flexible` → overflow nếu value dài | Fix 5.D1 |
| L2 | Timezone tile `449-454` | Low | `onTap: () {}` rỗng → ripple nhưng dead-tap | Fix 5.D2 |
| L3 | Export Data `476-480` | Low | `_goExportData` rỗng `{}` → tile bấm không làm gì | Defer (ngoài scope) |
| L4 | Avatar `542-547` | Low | `NetworkImage` không `onError` → avatar lỗi URL hiện vòng trống | Defer (robustness, không phải layout) |

> Các điểm Med/Low còn lại không phải lỗi tràn thật sự ở data hiện tại; L1 là latent-overflow đáng fix luôn.
