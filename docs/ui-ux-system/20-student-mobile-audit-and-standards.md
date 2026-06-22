# 20 — Student mobile: đánh giá thiết kế & tiêu chuẩn bổ sung

> **Phạm vi:** trải nghiệm **mobile học sinh** — `lib/feature/{home,student,listening,listening_comp,reading,speaking,writing,vocabulary,profile,progress}/**`.
> **Mục đích:** lặp lại quy trình của [`18`](18-teacher-web-audit-and-standards.md)/[`19`](19-admin-web-audit-and-standards.md) cho mobile — (1) chấm điểm UX 4 trục; (2) khoảng trống **tuân thủ** & **trải nghiệm** (kèm `file:dòng`); (3) **tiêu chuẩn mới** (đặc thù mobile: touch target, haptic, gesture, celebrate, reduce-motion); (4) remediation plan có **audit gate**.
> **Nguồn:** đọc trực tiếp code 06/2026. Chuẩn nền: [`03`](03-mobile-foundations.md), [`04`](04-mobile-components.md), [`10`](10-accessibility.md), [`15`](15-mobile-smart-patterns.md).
> **Khác web:** điểm chốt là **trải nghiệm chạm** (44–48dp, haptic, swipe, ăn mừng), không phải tuân thủ token (mobile đã sạch).

---

## 1. Điểm số tổng quan (hiện trạng)

| Trục đánh giá | Điểm | Tóm tắt |
|---------------|:----:|---------|
| **Thân thiện người dùng** | 7.0 / 10 | Home phân cấp rõ, cá nhân hoá lời chào, skill-accent dễ nhận diện. Trừ: **nhiều touch target < 44dp** (header 34, quick-action 42, profile-edit 40, join-submit 38, bottom nav 54<60). |
| **Trải nghiệm mượt** | 6.5 / 10 | Home dùng skeleton shimmer; Speaking swipe + haptic + mic-pulse rất tốt. Trừ: **progress bar nhảy tức thời**, Duration literal rải rác, **haptic chỉ có ở Speaking**, **không có animation "ăn mừng"** cho streak/level/XP. |
| **Kết hợp màu sắc** | 8.0 / 10 | **Token-first ~85–90%**, `AppSkillColors` (5 kỹ năng) mạch lạc. Trừ: `listening_comp` còn **21 hex literal** (gray/green/amber copy từ Tailwind). |
| **Chuẩn component** | 7.0 / 10 | `StudentMobileUi` tái dùng tốt; MCQ/nút runner đạt 44–72dp. Trừ: **Semantics gần như trống** (screen-reader không đọc được đáp án/điều khiển), reduce-motion có sẵn nhưng **không áp dụng**, spinner thay skeleton ngoài home. |
| **Tổng** | **7.1 / 10** | Nền màu/token tốt nhất trong 3 role; nợ nằm ở **trải nghiệm chạm mobile**: touch target, haptic system-wide, celebrate, accessibility. |

> **Kết luận một dòng:** Student sạch về token — việc chính là **nâng "chất mobile"**: bảo đảm 44dp, haptic toàn cục, ăn mừng gamification, Semantics + reduce-motion, và dọn nốt `listening_comp`.

---

## 2. Điểm mạnh cần giữ

1. **Token-first.** ~85–90% file dùng `AppColors`/`AppSpacing`/`AppRadius`. Runner kỹ năng gần như **0 hex literal** (trừ `listening_comp`).
2. **`AppSkillColors`** (`app_skill_colors.dart`) — 5 kỹ năng × (color/tint/dark), quy tắc dùng rõ (chỉ icon/progress, không tô chữ). **Token gốc hợp lệ → whitelist.**
3. **Skeleton ở Home.** `HomeContentSkeleton` + `AppSkeleton.box()` shimmer 1400ms (`app_skeleton.dart`) — không spinner trơ ở màn chính.
4. **Speaking = runner mẫu mực:** PageView swipe (`speaking_skills_page.dart:572`, BouncingScrollPhysics) + `HapticFeedback.mediumImpact()` khi record (`:244,319`) + mic-pulse animation.
5. **Vocabulary flashcard:** `AnimatedSwitcher` lật thẻ 220ms = `AppMotion.page` (`review_session_page.dart:296`); SRS 3 nút (Hard/Good/Easy) 44dp, radius pill.
6. **Reduce-motion framework tồn tại:** `AppMotion.effective(context, duration)` — chỉ cần áp dụng.

---

## 3. Khoảng trống TUÂN THỦ (token còn sót)

> Baseline (06/2026, scope student-facing): hex **30** · radius literal **142** · Duration literal **35** · spinner `AppLoadingIndicator.center` **30**.

### 3.1 Hex literal — tập trung ở `listening_comp` (vi phạm [`10`](10-accessibility.md) §14)

- `listening_comp_page.dart` chứa **21 hex** copy từ Tailwind, hầu hết map thẳng token:
  - `0xFF71717A/0xFFA1A1AA/0xFF52525B` → `textSecondary/textMuted` (dòng 441,709,718,790…)
  - `0xFF09090B` → `textPrimary` (529,783,818)
  - `0xFFF0FDF4/0xFF15803D` → `successBg/success` (549,555,561,575)
  - `0xFFE4E4E7` → `outline` (733,771,827)
  - `0xFFF59E0B` → `accent` (698); `0xFFFAFAFA` → `surfaceSubtle` (690)
  - `0xFF166534` (green-800, translated text) → **thêm token `AppColors.successDark`** (726,846).
- 8 hex còn lại nằm ở `student/` (rải rác) + 1 ở `vocabulary/`.

### 3.2 Radius / Duration / alpha literal

- **Radius 142 literal** → `AppRadius`. Lưu ý mobile dùng nhiều **12 & 16** (ngoài scale) — map `12→card(10)` hoặc `sheet(14)`, `16→sheet(14)`/`lg(20)` theo bảng teacher. Ví dụ: `listening_comp_page.dart:297,770` `circular(12)`; `listening_skills_page.dart:384` `circular(16)`; `exam_session_lobby_page.dart:257,266` `circular(10)`.
- **Duration 35 literal** → `AppMotion`. Nhiều cái **đã trùng token nhưng viết literal**: `speaking_skills_page.dart:136` `900`(=pulse), `:703` `220`(=page); `writing_task_page.dart:937` `200`(=base). Vài cái lệch scale: `:311` `500`, `:434` `300`. ⚠️ Không đụng `Duration(hours:…)`.
- **Alpha rời** `.withValues(alpha: 0.03/0.04/0.12/0.35/0.85)` → overlay token (`hoverOverlay/pressOverlay`) khi hợp.

### 3.3 Spinner thay skeleton — vi phạm [`10`](10-accessibility.md) §12

- **30 spinner** `AppLoadingIndicator.center()` ở mọi runner kỹ năng + vocabulary + listening_comp + lobby. Skeleton **chỉ dùng ở home**. List/màn nội dung lớn phải skeleton.

---

## 4. Khoảng trống TRẢI NGHIỆM (chuẩn mobile còn thiếu)

### 4.1 Touch target < 44dp — vi phạm [`10`](10-accessibility.md) §2

| Vị trí | Kích thước | Cần |
|--------|-----------|-----|
| `home_page.dart:322,326` header notification/AI button | 34×34 | ≥44 |
| Quick-action icon circle (`student_mobile_ui.dart:554`) | 42×42 | ≥44 |
| `home_page.dart` avatar | 34×34 | ≥44 |
| `profile` edit button | 40×40 | ≥44 |
| `student_unified_join_card.dart:112` nút gửi | **38** | ≥44 |
| Bottom nav (`app_navigation_bar.dart:147`) | 54 cao | 60 (chuẩn mobile) |
| Stat icon box (home) | 30×30 | ≥40 |

### 4.2 Haptic chỉ có ở Speaking — vi phạm tinh thần [`15`](15-mobile-smart-patterns.md)

- Có: Speaking record `mediumImpact` (`:244,319`). **Thiếu:** chọn đáp án MCQ (reading/listening), submit dictation, lưu writing, **lật flashcard & SRS feedback** (vocabulary), tap card/quick-action ở home. Mobile kỳ vọng phản hồi rung khi tương tác chính.

### 4.3 Không có animation "ăn mừng" gamification

- Streak/level/XP chỉ là **số tĩnh** (`home_page.dart` stats, profile badge `Lv.X · XP · 🔥`). Không confetti/scale khi đạt mốc. `AppMotion.celebrate` (380ms) + accent amber đang **dưới-dụng** đúng mục đích thiết kế. (Progress page chỉ có icon `celebration_rounded` tĩnh.)

### 4.4 Gesture nghèo (ngoài Speaking)

- ExamRunner / Reading-MCQ / Listening-MCQ **không swipe** chuyển câu — chỉ nút/cuộn (`exam_runner_page.dart`, `reading_detail_page.dart`). Speaking là ngoại lệ làm đúng (PageView).

### 4.5 Accessibility desert — vi phạm [`10`](10-accessibility.md) §3,§5

- **Gần như 0 `Semantics`** trong runner/home. Đáp án MCQ (`StudentMobileUi.mcqOption` = InkWell+Container) không có `Semantics(label/inMutuallyExclusiveGroup)`; nút audio play/mic không label; icon-only (notification/AI/quick-action) không tooltip. Screen-reader không dùng được luồng thi.
- **Reduce-motion không áp dụng:** `AppMotion.effective()` có sẵn nhưng AnimatedSwitcher/AnimatedContainer dùng Duration thô.
- **Focus ring không dùng:** `AppColors.focusRing` định nghĩa nhưng không vẽ.

### 4.6 Tiểu tiết "mượt" còn thiếu

- **Progress bar nhảy tức thời** (setState) ở mọi runner — nên `Tween`/`AnimatedBuilder` (`exam_runner_page.dart:706`, `integrated_exam_runner_page.dart:913`).
- **Error state lệch nhau:** ExamRunner có retry; Listening text-only không retry; Writing chỉ toast; IntegratedRunner set lỗi nhưng **không render UI**.
- **Thoát bài thi không xác nhận:** `exam_runner_page.dart:641` PopScope chỉ clear socket, **không confirm** (dễ thoát nhầm giữa bài). IntegratedRunner có confirm cho realtime — chuẩn hoá.
- **Audio player thiếu:** không thanh tiến độ/độ dài, disabled state không mờ, nút play không label (`listening_skills_page.dart:337`).

---

## 5. TIÊU CHUẨN MỚI ĐỀ XUẤT (đặc thù mobile)

> Tái dùng tokens/skeleton đã có; bổ sung các chuẩn **chạm/cảm giác** mà web không cần.

### 5.1 Touch-target floor 44dp (P0)
- Mọi phần tử tap được ≥ **44dp** (ưu tiên 48); bottom nav 60. Thêm helper `StudentMobileUi.tappable(minSize: 48)` bọc icon-only; audit cảnh báo `Size(…, <44)`/`height: <44` cho nút.

### 5.2 `AppHaptics` — chuẩn rung toàn cục (P0)
```dart
abstract final class AppHaptics {
  static void select()  => HapticFeedback.selectionClick(); // chọn đáp án / tab / chip / lật thẻ
  static void confirm() => HapticFeedback.mediumImpact();   // submit / record / SRS feedback
  static void celebrate()=> HapticFeedback.heavyImpact();   // đạt mốc streak/level
}
```
→ Gắn `select()` vào MCQ/flashcard/tab; `confirm()` vào submit/save; tôn trọng `reduce-motion`/tắt-rung hệ thống.

### 5.3 Celebrate standard (P1)
- Đạt mốc streak/level/XP → overlay confetti/scale `AppMotion.celebrate` + accent amber + `AppHaptics.celebrate()`. Một widget `CelebrateBurst` dùng chung (home, progress, kết thúc bài).

### 5.4 Skeleton everywhere (P1)
- Tạo skeleton mobile cho: list bài, runner (khung câu hỏi), flashcard, lobby — thay 30 spinner. Ghép `AppSkeleton.box` như `HomeContentSkeleton`.

### 5.5 Reduce-motion bắt buộc (P1)
- Mọi `AnimatedX`/transition bọc `AppMotion.effective(context, …)`; cấm `Duration(milliseconds:<số>)` thô trong widget. Slide→fade 80ms khi bật reduce-motion ([`10`](10-accessibility.md) §6).

### 5.6 Semantics mobile (P0)
- Đáp án MCQ: `Semantics(label, button, selected, inMutuallyExclusiveGroup)`. Audio/mic: `Semantics(label: 'Phát/Tạm dừng/Ghi âm', button)`. Icon-only: `tooltip` + label. Status = text (không icon-only).

### 5.7 Animated progress (P2)
- Progress bar dùng `TweenAnimationBuilder<double>` (motion `base`) thay vì nhảy setState.

### 5.8 Exit-confirm khi đang làm bài (P0)
- `PopScope(canPop: false)` + dialog "Thoát bài? Tiến độ có thể mất" cho mọi runner khi `in_progress` (chuẩn hoá từ IntegratedRunner).

### 5.9 Error-with-retry chuẩn (P1)
- Mọi fetch lỗi → khối lỗi + nút **Thử lại** (không text-only, không chỉ toast). Dùng chung `StudentMobileUi.errorRetry(onRetry)`.

### 5.10 Audio player chuẩn (P2)
- Thanh tiến độ + thời lượng + nút play/pause có label + disabled mờ rõ.

---

## 6. Remediation plan (thực thi theo phase, có audit gate)

> **Baseline:** hex **30** · radius **142** · Duration **35** · spinner **30**.
> **Whitelist:** `app_skill_colors.dart` (màu kỹ năng gốc) + dòng `// audit-ignore`.

### 6.0 Ưu tiên gốc

| Ưu tiên | Hạng mục |
|:-------:|----------|
| **P0** | §5.1 touch-target · §5.2 AppHaptics · §5.6 Semantics · §5.8 exit-confirm |
| **P1** | §5.3 celebrate · §5.4 skeleton · §5.5 reduce-motion · §5.9 error-retry · dọn `listening_comp` |
| **P2** | §5.7 animated progress · §5.10 audio player · gesture swipe runner |

### 6.1 Phase 0 — Audit
- Thêm scope `student` cho `tool/ui_audit.sh`; whitelist `app_skill_colors.dart`. **Cổng:** in đúng baseline 30/142/35/30.

### 6.2 Phase 1 — Foundation
- `AppHaptics` (§5.2); `AppColors.successDark` (§3.1); helper `StudentMobileUi.tappable()` + `errorRetry()`; skeleton mobile (§5.4); `CelebrateBurst` (§5.3).
- **Cổng:** `dart analyze` sạch.

### 6.3 Phase 2 — Sweep cơ học (subagent song song)
- Hex → token (dọn `listening_comp` 21 + 9 chỗ khác). **hex 30→0** (trừ whitelist).
- Radius → `AppRadius`; Duration → `AppMotion` (bọc `effective`). **142→0, 35→0** (trừ `hours:`).
- **Cổng:** `ui_audit student` hex/radius/duration = 0; analyze sạch.

### 6.4 Phase 3 — Trải nghiệm theo màn

| Batch | Màn | Việc |
|------|-----|------|
| 3a | mọi runner + vocab + listening_comp + lobby | spinner→skeleton; error→retry chuẩn |
| 3b | home, runner, reading/listening MCQ | `AppHaptics.select/confirm`; touch-target ≥44; exit-confirm |
| 3c | runner, MCQ, audio | Semantics đáp án/điều khiển; reduce-motion bọc animation; animated progress |
| 3d | home, progress, kết thúc bài | celebrate streak/level/XP (§5.3) |

- **Cổng (mỗi batch):** spinner màn=0; nút ≥44dp; Semantics có; haptic gắn; ký nhận màn × tiêu chí.

### 6.5 Phase 4 — Polish
- Swipe chuyển câu cho ExamRunner/MCQ (§4.4); audio player chuẩn (§5.10); focus ring nếu hỗ trợ keyboard.
- **Cổng:** checklist §7 full ✓.

### 6.6 Cơ chế audit check (mọi cổng)
1. **Tự động:** `tool/ui_audit.sh student` — trước/sau (về 0 trừ whitelist).
2. **Tĩnh:** `dart analyze lib` 0 lỗi mới.
3. **Thủ công:** ký nhận màn × tiêu chí (touch-target/haptic/skeleton/Semantics/exit-confirm/celebrate).
4. **Hồi quy:** test trên 360×640; bật TalkBack/VoiceOver + reduce-motion.

---

## 7. Checklist tuân thủ (mở rộng [`10`](10-accessibility.md) §14 cho mobile student)

- [ ] Mọi phần tử tap được ≥ 44dp (ưu tiên 48); bottom nav 60.
- [ ] Tương tác chính có haptic (`AppHaptics`); tôn trọng tắt-rung/reduce-motion.
- [ ] Không `Color(0x…)` (trừ `app_skill_colors.dart`); không radius/Duration literal rời.
- [ ] Loading = skeleton; lỗi fetch = khối lỗi + **Thử lại**.
- [ ] Đáp án/điều khiển audio có `Semantics`; icon-only có tooltip.
- [ ] Animation bọc `AppMotion.effective`; progress bar animated.
- [ ] Đang làm bài: `PopScope` + confirm thoát.
- [ ] Đạt mốc gamification có animation ăn mừng + amber.

---

## 8. Bản đồ file ↔ vấn đề (tra nhanh)

| File | Vấn đề chính | Mục |
|------|--------------|-----|
| `listening_comp_page.dart` | 21 hex; radius 12/16; spinner; thiếu Semantics | 3.1, 3.2, 3.3, 4.5 |
| `home_page.dart` / `student_mobile_ui.dart` | touch-target 34/42/30; thiếu haptic card; Duration literal | 4.1, 4.2, 3.2 |
| `app_navigation_bar.dart` | bottom nav 54<60; icon 20 nhỏ | 4.1 |
| `student_unified_join_card.dart` | nút gửi 38<44 | 4.1 |
| `exam_runner_page.dart` | progress nhảy; **thoát không confirm**; không swipe; timer ValueKey | 4.6, 4.4, 5.7, 5.8 |
| `integrated_exam_runner_page.dart` | error không render; banner status có thể collapse | 4.6 |
| `reading_detail_page.dart` / `listening_skills_page.dart` | MCQ không haptic/swipe; error không retry; audio không label | 4.2, 4.4, 4.6 |
| `speaking_skills_page.dart` | **mẫu tốt** (swipe+haptic); Duration literal 900/220/350 | 2, 3.2 |
| `review_session_page.dart` (vocabulary) | flip tốt; thiếu haptic/streak; spinner | 2, 4.2, 4.3 |
| `profile` / `progress` | edit-button 40; emoji lẫn text; celebrate tĩnh | 4.1, 4.3 |

> **Khi sửa xong:** cập nhật `03`/`04`/`15` nếu đổi pattern; ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md) "Migration log".
</content>
