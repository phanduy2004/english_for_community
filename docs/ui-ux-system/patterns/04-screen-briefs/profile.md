# Screen Brief — Profile / Settings (student)

> Áp blueprint **A9 · Profile / Settings** ([`../01-screen-archetypes.md`](../01-screen-archetypes.md)) vào màn thật.
> **Màn:** tab Hồ sơ & Cài đặt học sinh · **File:** `lib/feature/profile/profile_page.dart` (edit flow: `feature/profile/edit_profile_page.dart` + `change_password_dialog.dart`).
> **Trạng thái:** cấu trúc grouped-list đã đúng A9, NHƯNG còn **2 vi phạm màu** (amber `accent` + `skill color` rải khắp các group — profile là **phi-kỹ-năng** → chỉ primary/neutral) và **logout không có confirm**. Brief này lo phần **màu, confirm destructive & dùng đúng token chung**.

---

## 1. Hiện trạng (đo theo token)

```
┌──────────────────────────────────────────┐  pagePadding = LTRB(12,10,12,20)  ← StudentMobileUi.pagePadding:31
│ Profile & Settings                  (appBar) │  appBar showBack:false (profile_page.dart:304)
│ ┌────────────────────────────────────────┐│
│ │▌(av 64) Phan Tất Duy            [✎]     ││  _buildProfileHeader (:519)
│ │▌        duy@…                            ││   ▌ = border-left accent 3px (:529)  ⚠ amber
│ │▌        (Member)(Lv.1✦)(0 XP★)(🔥)       ││   badge Lv = AppSkillColors.writing (:567)  ⚠ skill
│ └────────────────────────────────────────┘│   card: outline + surfaceCard (:521-525)
│   ↕ sectionGap(14)                          │  StudentMobileUi.sectionGap:316
│ Learning preferences                  (h2)  │  sectionHeader (:318)
│   ↕ s3                                       │
│ ┌────────────────────────────────────────┐│  _SettingsGroup = AppCard(outline,r12) (:612)
│ │ [⏱] Daily time goal        15 min       ││  _SettingsTile (:322) iconColors=accent ⚠
│ │ ───────────────────────────────────────││  _GroupDivider outlineMuted indent16 (:701)
│ │ [⚑] Daily lesson goal      5 lessons    ││  ⚠ accent
│ │ ───────────────────────────────────────││
│ │ [🔔] Daily reminder        [Switch]     ││  trailing Switch (activeTrack=primary) ⚠ accent icon
│ │ [⏰] Reminder time         19:00        ││  (chỉ khi isReminderOn :360)
│ └────────────────────────────────────────┘│
│   ↕ sectionGap                              │
│ Progress / Teacher / General / Account…    │  4 group nữa, mỗi group cách sectionGap
│ │ [🕘] Exercise history (skill:reading) › ││  ⚠ skill color (:387)
│ │ [🏫] My classes (skill:speaking)      › ││  ⚠ skill color (:403)
│ │ [🌐] App language          Tiếng Việt   ││  skill:vocabulary (:439) ⚠
│ │ [🔒] Change password (accent)         › ││  ⚠ accent (:467)
│   ↕ s8                                       │  AppSpacing.s8 (:484)
│ [        Sign out (outline)              ]  │  OutlinedButton textPrimary (:488)  ✗ KHÔNG confirm
│   ↕ s4                                       │
│ [        Delete account (đỏ)             ]  │  TextButton danger (:504) → có confirm dialog (:73)
│   ↕ s9                                       │
└──────────────────────────────────────────┘
```

**Đo:** header (avatar 64 + identity + badges) → 5 group `_SettingsGroup` cách `sectionGap(14)` → 2 nút cuối. Cấu trúc grouped-list **đúng A9**. Vấn đề nằm ở **màu** (amber + skill rải khắp, sai quy ước "profile = primary/neutral") và **logout không confirm** (chỉ delete có).

### Đánh giá
| ✅ Giữ | ⚠️ Sửa |
|--------|--------|
| Grouped list iOS-style: group header `sectionHeader` + rows trong `AppCard(outline)` + divider inset — đúng A9 anatomy (`profile_page.dart:318,612,701`) | **Skill color trên profile:** rows dùng `skill: SkillType.reading/speaking/writing/vocabulary` (`:387,403,412,421,439`) — A9 cấm skill color, phải neutral |
| Chevron HỢP LỆ trong settings rows (`_SettingsTile.showChevron` `:650,691`) — khác A5 chat-list | **Amber `accent` làm màu icon row:** Learning prefs + Change password set `iconColors=SkillColorSet(accent…)` (`:326-330,338-342,348-353,366-370,467-471`) — amber chỉ cho celebrate |
| Delete account = `danger` + AlertDialog confirm (`:504,73-95`) | **Logout KHÔNG confirm:** `_handleLogout` (`:68-71`) gọi thẳng `SignOutEvent` từ OutlinedButton (`:489`) — A9: destructive phải confirm |
| Edit qua `StudentBottomSheet` (time/lesson/language picker `:141,170,200`) + dialog (change password `:63`) — đúng A9 "sửa giá trị → sheet/dialog" | **Header border-left amber** (`:529`) + badge Lv `AppSkillColors.writing` (`:567`) — profile header nên primary/neutral |
| RefreshIndicator + Bloc loading/error/unauth states (`:269-282,305`) | **Tile tự-cuộn:** `_SettingsTile`/`_SettingsGroup`/`_GroupDivider` (`:612,627,701`) re-implement `StudentMobileUi.listTile` + `AppCard(outline)` thay vì dùng token chung |

---

## 2. Target layout (refined) — primary/neutral, destructive confirm

Theo A9 + iOS Settings/Notion/Things. **Giữ nguyên cấu trúc grouped-list** (đã đúng), chỉ **gỡ skill/amber → primary/neutral** và **thêm confirm cho logout**.

```
TRƯỚC (skill + amber rải khắp, logout raw)   SAU (primary/neutral, destructive confirm)
┌───────────────────────────┐                ┌───────────────────────────┐
│▌(av) Duy            [✎]     │  amber ▌      │ (av) Duy             [✎]    │  border neutral/primary
│▌     duy@… (Lv✦ writing)    │  skill badge  │      duy@… (Member·Lv.1)    │  badge primaryTint/accentTint*
│ Learning preferences        │                │ Learning preferences        │
│ ┌────────────────────────┐ │                │ ┌────────────────────────┐ │
│ │[⏱ amber] Daily time 15m│ │  accent icon  │ │[⏱ neutral] Daily time 15m│ │  roundIconBox primary
│ │[⚑ amber] Lesson goal  5│ │                │ │[⚑ neutral] Lesson goal  5│ │
│ │[🔔 amber] Reminder [⏻] │ │                │ │[🔔 neutral] Reminder [⏻] │ │  Switch track = primary ✓
│ └────────────────────────┘ │                │ └────────────────────────┘ │
│ [🕘 reading] History     › │  skill         │ [🕘 neutral] History      › │  neutral icon
│ [🔒 amber] Change pass   › │                │ [🔒 neutral] Change pass  › │
│ [ Sign out (outline) ]     │  ✗ no confirm  │ [ Sign out (outline) ]      │  → confirm dialog ✓
│ [ Delete account (đỏ) ]    │  ✓ confirm     │ [ Delete account (đỏ) ]     │  ✓ confirm (giữ)
└───────────────────────────┘                └───────────────────────────┘
                                              ↳ * accentTint chỉ cho XP/streak badge (celebrate) — OK
```

### Zones (target)
| Zone | Nội dung | Token | Ghi chú |
|------|----------|-------|---------|
| Identity header | avatar 64 + `fullName` (h2) + `email` (caption) + badges | `surfaceCard` + `outline`; border-left → `primary` (hoặc bỏ) | Role/Lv badge = `primaryTint`; XP/🔥 = `accentTint` (celebrate ✓ — ngoại lệ duy nhất) |
| Edit affordance | nút `[✎]` góc phải → `EditProfilePage` | `surfaceSubtle` + `textPrimary` | giữ nguyên (`:592-604`) |
| Group header | `sectionHeader(title)` (h2) | `textPrimary` | giữ `StudentMobileUi.sectionHeader` |
| Settings rows | icon box + title (+subtitle/value) + chevron/Switch | leading `roundIconBox` **primary**; chevron `textSecondary` | gỡ `skill:` và `iconColors=accent` → để mặc định primary |
| Group container | rows + divider inset | `AppCard(outline)` + `outlineMuted` divider | = `_SettingsGroup`/`_GroupDivider` (đúng) hoặc `StudentMobileUi.listTile` |
| Destructive | Sign out (outline) · Delete account (đỏ) | `danger` text; cả 2 **confirm dialog** | logout thêm `StudentDialogShell`/AlertDialog confirm |

> **Quy ước A9:** profile = **primary/neutral**, **KHÔNG skill color**. Ngoại lệ duy nhất: badge **XP/streak** ở header được dùng `accentTint` (đây là "celebrate" KPI — đúng quy ước amber). Mọi icon row settings → neutral primary.

---

## 3. Build diff (đường dẫn cụ thể cho Cursor)

File: `lib/feature/profile/profile_page.dart`.

1. **Gỡ amber `accent` khỏi icon các row** — xoá mọi `iconColors: SkillColorSet(color: AppColors.accent, tint: AppColors.accentTint, dark: AppColors.accentDark)` ở Learning preferences (`:326-330,338-342,348-353,366-370`) và Change password (`:467-471`). Bỏ luôn param → `_SettingsTile` render `skillIconBox` với màu **primary** mặc định (`student_mobile_ui.dart:746-748`).

2. **Gỡ `skill:` khỏi các row settings** — bỏ `skill: SkillType.reading` (`:387`), `speaking` (`:403`), `writing` (`:412`), `writing` (`:421`), `vocabulary` (`:439`). Profile là phi-kỹ-năng → icon về primary/neutral. (Chevron giữ — A9 cho phép trong settings.)

3. **Logout phải confirm** — đổi `onPressed: _handleLogout` (`:489`) sang mở confirm trước. Tách `_confirmLogout()` theo đúng mẫu `_handleDeleteAccount` (`:73-95`):
   ```dart
   void _confirmLogout() {
     final t = AppLocalizations.of(context)!;
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: AppColors.surfaceCard,
         title: Text(t.signOut, style: AppTypography.titleMd()),
         content: Text(t.signOutConfirmBody, style: AppTypography.body()),  // thêm key l10n
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
           TextButton(
             style: TextButton.styleFrom(foregroundColor: AppColors.danger),
             onPressed: () { Navigator.pop(ctx); _handleLogout(); },
             child: Text(t.signOut),
           ),
         ],
       ),
     );
   }
   ```
   (Hoặc gói gọn bằng `StudentDialogShell` cho đồng bộ `04` §6.1.)

4. **Header: gỡ amber/skill** — trong `_buildProfileHeader` (`:519`): đổi `foregroundDecoration` border-left từ `AppColors.accent` (`:529`) → `AppColors.primary` (hoặc bỏ hẳn cho phẳng). Badge Lv (`:565-570`) đang dùng `AppSkillColors.writing` → đổi sang `_ProfileBadge(label: 'Lv.${…}')` mặc định (primaryTint). **GIỮ** badge XP/🔥 dùng `accentTint` (`:572-585`) — đây là celebrate hợp lệ.

5. **(Tùy chọn dọn dẹp) Hợp nhất tile về token chung** — `_SettingsTile` (`:627`) lặp lại `StudentMobileUi.listTile` (`student_mobile_ui.dart:292`) và `_SettingsGroup` (`:612`) chỉ bọc `AppCard(outline)`. Nếu muốn 1-source, thay `_SettingsTile`→`StudentMobileUi.listTile(leading: roundIconBox(icon))` và bỏ `_SettingsTile/_GroupDivider`. Không bắt buộc cho lần này (chỉ-màu là đủ); ưu tiên không-vỡ.

6. **Giữ nguyên:** grouped-list structure, `sectionHeader`, `sectionGap`/`s3` spacing, chevron, các `StudentBottomSheet` picker (time/lesson/language `:141,170,200`), `ChangePasswordDialog` (`:63`), RefreshIndicator + Bloc states.

> Không đụng `student_mobile_ui.dart` (dùng chung). Không đụng `edit_profile_page.dart`/`change_password_dialog.dart` (chỉ tham chiếu edit-flow).

---

## 4. States

- **Loading** (chưa có user) → `Scaffold(body: StudentMobileUi.runnerLoading())` ✔ (`:277-282`).
- **Loaded** → grouped-list (đảm bảo 0 skill/0 amber sau diff).
- **Error** → Bloc `listener` bắn `AppFeedback.error` (`:272-274`) ✔; pull-to-refresh `GetProfileEvent` (`:307`).
- **Unauthenticated** → `context.goNamed(LoginPage.routeName)` (`:271`) ✔.
- **Edit giá trị (sheet):** daily time / lesson goal / language → `StudentBottomSheet.show` + `listTile` rows + check `primary` (`:141-166,168-195,197-243`) ✔.
- **Edit hồ sơ / mật khẩu (dialog/page):** `[✎]` → `EditProfilePage` (`:56-60`); change password → `ChangePasswordDialog` (`:62-64`) ✔.
- **Logout confirm (MỚI):** dialog danger + Cancel/Sign out → mới `_handleLogout` (disconnect socket + `SignOutEvent`).
- **Delete confirm (giữ):** AlertDialog danger `deletePermanently` → `DeleteAccountEvent` (`:73-95`) ✔.

## 5. Checklist
- [ ] Gỡ toàn bộ `iconColors: SkillColorSet(accent…)` ở Learning prefs + Change password (5 chỗ).
- [ ] Gỡ `skill:` khỏi 5 row settings (reading/speaking/writing×2/vocabulary).
- [ ] Header: border-left amber → primary (hoặc bỏ); badge Lv → primaryTint; **giữ** XP/🔥 accentTint (celebrate).
- [ ] **Logout có confirm dialog** (danger), giống delete-account; cả 2 destructive đều confirm.
- [ ] Grunt-check màu: profile **0 skill color, 0 amber** trừ badge XP/streak ở header.
- [ ] Chevron giữ ở settings rows (hợp lệ A9); grouped-list không đổi cấu trúc.
- [ ] `dart analyze lib/feature/profile` 0 lỗi mới.
- [ ] Xem trên 360×640: 5 group đọc dễ; nút Sign out/Delete tách rõ; tap Sign out → confirm hiện.

> Áp xong ghi vào [`../../11-implementation-mapping.md`](../../11-implementation-mapping.md) "Migration log".
