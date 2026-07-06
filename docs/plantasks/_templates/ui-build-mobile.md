# Template — XÂY UI STUDENT MOBILE (E4C)

> Template để **dựng/redesign 1 màn student mobile** đúng chuẩn Editorial Black + density v3, đủ perf + a11y + 4 states.
> Nguồn sự thật: `docs/ui-ux-system/` (doc thắng khi mâu thuẫn) + code `lib/core/theme/*` + `lib/core/ui/*`.
> Cách dùng: đọc **A. Standards** (bất di) → điền **B. Build-spec** cho màn → soi **C. Perf** → tick **D. Pre-ship** → nối **E. Handoff** vào work-order CONTEXT BUNDLE.
> Task web (teacher/admin) → dùng `ui-build-web.md`. Kick-off nhanh bằng prompt → `uiux-layout-prompt.md`.
>
> ⚠️ **DRIFT doc↔code (đọc trước):** `04-mobile-components.md` là bản CŨ chưa đồng bộ density v3. Khi số liệu lệch: **token (`02`) + code `StudentMobileUi`/`AppCard` là cái BẠN BUILD**; doc thắng về *nguyên tắc*, nhưng số phải khớp code hiện tại (nêu lệch thì raise, đừng tự đổi). Bảng lệch ở cuối §A.

---

## A. STANDARDS — BẤT DI (đọc trước khi gõ dòng đầu)

### A0. 4 nguyên tắc lõi
1. **Editorial Black.** Brand = đen `#0A0A0A`. Chữ mặc định đen `#1C1917`. **Amber `#F59E0B` CHỈ để "ăn mừng"** (streak/KPI nổi/level-up/chart highlight) — KHÔNG bao giờ làm nút chính, KHÔNG tô heading.
2. **Token-only.** Mọi màu/spacing/radius/duration qua token. `Color(0x…)` / radius-literal / `Duration(milliseconds:N)` trong `lib/feature/**` = **reject** (CI `tool/ui_audit.sh`).
3. **Server là sự thật → 4 states.** Mọi màn fetch data phải có **loading (skeleton) · empty · error+retry · success**.
4. **Tái dùng, không dựng lại.** Ưu tiên `StudentMobileUi.*` / `AppCard` / widget sẵn có. Cấm `AppCard2`/`MyCustomCard` — sửa gốc hoặc dùng `variant`.

### A1. COLOR TOKENS — `AppColors` (`lib/core/theme/app_color.dart`) — verbatim
| Token | Hex | Dùng |
|---|---|---|
| `primary` | `#0A0A0A` | Filled button, AppBar logo, chevron, link (Editorial black) |
| `primaryDark` | `#000000` | Pressed / focus ring |
| `onPrimary` | `#FFFFFF` | Chữ trên nền primary |
| `accent` | `#F59E0B` | **CHỈ celebrate** (streak/KPI/chart highlight) |
| `surface` | `#FAFAF9` | BG màn (KHÔNG trắng tinh) |
| `surfaceCard` | `#FFFFFF` | Card, sheet |
| `surfaceSubtle` | `#F5F5F4` | Search field bg, callout, hover |
| `surfaceInverse` | `#1C1917` | Snackbar/offline banner bg |
| `outline` | `#E7E5E4` | Viền card/divider mặc định |
| `outlineMuted` | `#F1F0EE` | Divider inset, skeleton |
| `outlineStrong` | `#D6D3D1` | Viền input |
| `textPrimary` | `#1C1917` | **Mặc định MỌI chữ** |
| `textSecondary` | `#57534E` | CHỈ meta lẻ: timestamp, tag count |
| `textMuted` | `#A8A29E` | CHỈ placeholder & disabled |
| `success`/`warning`/`danger`/`info` | `#16A34A`/`#D97706`/`#DC2626`/`#6366F1` | Semantic — ⚠️ tên lỗi là **`danger`** (KHÔNG `error`) |
| `successBg`/`warningBg`/`dangerBg`/`infoBg` | `#ECFDF5`/`#FFFBEB`/`#FEF2F2`/`#EEF2FF` | Nền semantic-50 (banner/tag/MCQ review) |
| `primaryTint` | đen @6% | Chip selected, nav indicator, list-selected |
| `accentTint` | amber @14% | Streak chip, KPI nổi |
| `scrim` | `0x66000000` | Backdrop dialog/sheet |
| `shadowCard`/`shadowAmbient` | `0x0A000000`/`0x04000000` | Bóng card mảnh (tối đa 2 lớp) |

**Cấm:** heading tô accent; filled button nền amber; AppBar nền đen toàn phần; teal `#0D9488` hay brand thứ 2; `textSecondary`/`textMuted` cho body.

### A2. SKILL COLORS — `AppSkillColors.of(SkillType)` — CHỈ màn kỹ năng học sinh
| Skill | color | tint | dark | Icon |
|---|---|---|---|---|
| listening | `#3B82F6` | `#EFF6FF` | `#1D4ED8` | `headphones_outlined` |
| speaking | `#10B981` | `#ECFDF5` | `#047857` | `record_voice_over_outlined` |
| reading | `#EA580C` | `#FFF7ED` | `#C2410C` | `menu_book_outlined` |
| writing | `#7C3AED` | `#F5F3FF` | `#5B21B6` | `edit_note_outlined` |
| vocabulary | `#E11D48` | `#FFF1F2` | `#BE123C` | `style_outlined` |

**Rule:** chỉ **icon box bg (tint) / progress fill (color) / left-accent border (color)** dùng skill color. Card bg vẫn `surfaceCard`; heading/body vẫn `textPrimary`. KHÔNG trộn 2 skill color trong 1 row. Màn **phi-kỹ-năng** (home chrome, messages, profile, settings, auth) → primary + neutral, KHÔNG skill color.

### A3. SPACING + RADIUS — verbatim
`AppSpacing`: `s1`=2 · `s2`=4 · `s3`=8 · `s4`=12 · `s5`=16 · `s6`=20 · `s7`=24 · `s8`=32 · `s9`=40 · `s10`=56 · `s11`=80. **Unit gốc 4 — cấm số lẻ 7/11/13/18.**
`AppRadius`: `xs`=4 · `chip`=6 · `input`=8 · `card`=10 · `sheet`=14 · `lg`=20 · `pill`=999. **Card mobile = `card`(10) + viền `outline`, KHÔNG shadow cho list rộng.**

### A4. TYPOGRAPHY — density v3, font **Inter** (`AppFonts.fontFamily`)
| Vai trò | size/weight/LH | Helper code |
|---|---|---|
| display (hero) | 18/700/1.2 | `AppTypography.displaySm()` |
| h1 (greeting) | 16/600/1.25 | `StudentMobileUi.greeting(context)` |
| h2 (AppBar, section) | **14/600**/1.3 | `StudentMobileUi.sectionTitle(context)` |
| h3 (card/list title) | 13/600/1.35 | `StudentMobileUi.cardTitle(context)` |
| body (**default**) | **13/400**/1.5 | `StudentMobileUi.body(context)` |
| bodyLg (reading) | 15/400/1.5 | `StudentMobileUi.bodyLg(context)` |
| kpi (số điểm/streak) | 15/600/1.2 tabular | `StudentMobileUi.kpi(context)` |
| caption (meta) | 11/400/1.4 | `StudentMobileUi.caption(context)` |
| label (button/chip) | 11/600 | `AppTypography.label()` |

**Cấm:** Medium(500) cho body; bold cả câu để nhấn; `textSecondary` cho body/đoạn.

### A5. MOTION — `AppMotion` (`lib/core/theme/app_motion.dart`)
`micro`=90 · `fast`=120 · `base`=180 · `page`=220 · `celebrate`=380 · `debounce`=350 (ms). **Bọc reduce-motion:** `AppMotion.effective(context, dur)` → trả `reducedFade`(80ms) khi `MediaQuery.disableAnimationsOf(context)`. Cấm `Duration(milliseconds:N)` thô trong widget.

### A6. FEEDBACK TAXONOMY — `AppFeedback` (`26`) — định tuyến theo MỨC ĐỘ, không "một-kênh-cho-tất"
| Sự kiện | Kênh |
|---|---|
| Xác nhận nhẹ ("Đã lưu/gửi") | `AppFeedback.success/info` → SnackBar ngắn (1.5–2s) |
| Lỗi field/validation | `AppFeedback.fieldError(msg)` → **inline dưới field** (KHÔNG toast/dialog) |
| Lỗi nhẹ tự hồi (mạng) | `AppFeedback.error(msg, onRetry:…)` → SnackBar/banner "Thử lại" |
| Lỗi BLOCKING (submit fail, hết phiên, no-permission, dữ liệu hỏng) | `AppFeedback.error(msg, blocking:true)` → **DIALOG** |
| Realtime đúng màn | cập nhật UI tại chỗ (không toast) |
| Realtime màn khác (foreground) | in-app banner đỉnh + badge tab |
| Realtime background | system push (FCM) mở đúng màn |
Dedup: nuốt message trùng trong ~3s; lỗi 500 dội → 1 dialog/banner, không spam/chồng. Student (kể cả chạy web) luôn nhận feedback kiểu mobile — detection `WorkspaceLayoutScope.isWebWorkspace`, KHÔNG `kIsWeb`.

### A7. Bảng DRIFT doc↔code (số v3 chuẩn — build theo cột phải)
| Thuộc tính | `04` (cũ) | **v3 chuẩn** | Ghi chú |
|---|---|---|---|
| Filled button height | 48 | **44** (`02 §8`, `03 §6`) | hit target ≥44 |
| Input height | 48 | **44** | |
| Card radius | 12 | **10** = `AppRadius.card` (khớp `AppCard`) | |
| Card/page padding (doc) | 16 | doc v3 nói **14**, **code `StudentMobileUi.pagePadding`=`fromLTRB(12,10,12,20)` + `AppCard` default `all(12)` đang dùng 12** | build theo code (12); lệch doc → raise |
| cardGap trong list | 12 | **8** (`StudentMobileUi.cardGap`) | |
| Chip filter height | 32 | **28** (`02 §8`); hit-area vẫn ≥44 | |

---

## B. BUILD-SPEC — điền cho MÀN cụ thể

> Điền khối này thành phần thân của work-order (hoặc screen-brief). Mọi số/màu trỏ token; mọi widget trỏ API thật.

**Màn:** `<tên>` · **File:** `lib/feature/<...>.dart` · **Archetype:** `<A?>` · **Skill (nếu có):** `<SkillType.?>` · **Màn anh-em tham chiếu (chrome sync):** `<màn đã chuẩn>`

### B1. Chọn ARCHETYPE (A1–A12) + zones + build-with
| # | Archetype | Zones chính | Build-with (widget THẬT) | Màu |
|---|---|---|---|---|
| A1 | Home/Dashboard | Greeting · Stats(3×) · Continue · Skill grid | `greeting()`, `headerIconButton`, `statCard(compact)`, `skillProgressBar`, `quickActionButton` | chrome=primary; grid=skill |
| A2 | Hub/Browse list | Header · Banner · Search+filter · List | `skillHubBanner`, `searchField`, `filterRow`, `skillAccentCard`, `listLoading()` | skill |
| A3 | Runner/Focused | Top(`✕`+pager) · Body(prompt+options) · Bottom CTA | `runnerPopScope`, `mcqPagerHeader`, `mcqOption`, `bottomActionBar`, `runnerLoading()` | option=semantic (info/success/danger), KHÔNG skill |
| A4 | Detail/Reader | `skillAppBar` · Body typographic · CTA tùy | `skillAppBar`, `bodyLg`, callout `surfaceSubtle` | skill accent line |
| A5 | Conversation list | Inset-grouped card list, avatar màu-theo-tên, time phải, KHÔNG chevron | `ConversationTile`, `emptyState(forum)` | **primary** (KHÔNG skill/emerald) |
| A6 | Chat thread | `reverse:true` list · bubble nhóm · composer | `classroom_chat`, `RepaintBoundary`/bubble, send=primary | primary; GV bubble=accentTint |
| A7 | Search & Filter (nhúng) | `searchField` + `filterRow` 1-chọn, debounce ~250ms | `searchField`, `filterRow`, memo `(data,query,filter)` | theo A2/A5 |
| A8 | Empty/Loading/Error | 3 state bắt buộc mọi màn | `StudentMobileSkeleton.*`, `emptyState`, `errorRetry` | — |
| A9 | Profile/Settings | Grouped list iOS · destructive+confirm · edit qua sheet | `listTile`(chevron OK ở settings), `StudentBottomSheet`, `danger` | primary/neutral (KHÔNG skill) |
| A10 | Auth/Onboarding | 1 quyết định/màn · inline-validate · bottom CTA | `FilledButton`, input `04 §4`, `mcqOption`, `bottomActionBar` | primary |
| A11 | Result/Celebrate | **chỗ DUY NHẤT amber khoe** · 2 CTA | `CelebrateBurst`/`AppLottieView`, `statCard`, `streakChip` | amber celebrate |
| A12 | Stats/Progress | KPI row · weekly chart (highlight hôm nay=accent) · per-skill bar | `statCard`, `weekly_activity_bars_chart`, `skillProgressBar(skill:)` | 1 amber highlight; skill bar hợp lệ |

### B2. Cấu trúc màn chuẩn (page anatomy)
AppBar(52dp, no elevation/tint) → pagePadding → Section header (h2 + optional "Xem tất cả") → gap `s3` → Card(`card` radius, viền outline) → gap `s3`(cardGap) → … → gap `sectionGap`(giữa 2 section) → NavigationBar(60dp, `surfaceCard`, indicator `primaryTint`). Back = `Icons.arrow_back_rounded` size 20 góc trái (ẩn ở route gốc tab; trong sheet dùng `close_rounded`). AppBar action icon-only size 20, **max 2** (3+ → `more_vert`).

### B3. ZONES (điền — bảng như screen-brief)
| Zone | Nội dung | Token/widget | Ghi chú |
|---|---|---|---|
| `<...>` | `<...>` | `<...>` | `<...>` |

### B4. STATES (bắt buộc điền đủ)
- **Loading:** skeleton khung giống thật — `<StudentMobileSkeleton.skillList/runnerQuestion/flashcard/examLobby>` (KHÔNG spinner full-màn).
- **Empty (chưa có data):** `emptyState(icon, title, body, ctaLabel?, skill?)`.
- **Empty (search):** `emptyState(icon: Icons.search_off, …)` — copy khác empty-data.
- **Error:** `errorRetry(context, message, onRetry)` (có `AppHaptics.confirm`).
- **State đặc thù:** `<sending/optimistic/upload/in-progress…>`.

### B5. WIDGET QUICK-REF — `StudentMobileUi` (signature thật, `lib/core/ui/student_mobile_ui.dart`)
- AppBar: `appBar(context, {title, actions?, showBack})` · `skillAppBar(context, {title, skill, actions?, showBack, showLoading})`
- Section: `sectionHeader(context, {title, actionLabel?, onAction?})`
- States: `emptyState(context, {icon, title, body, ctaLabel?, onCta?, skill?, lottie?})` · `errorRetry(context, {message, onRetry, title?, retryLabel?})` · `errorBanner({message, onRetry, retryLabel})` · `listLoading({itemCount})` · `runnerLoading()`
- Search/filter: `searchField({controller, hintText, showClear?, onClear?})` · `filterChip({label, selected, onTap, skill?})` · `filterRow({labels, selectedIndex, onSelected, skill?})`
- List/tap: `listTile({context, title, subtitle?, leading?, trailing?, onTap?})` · `tappable({context, child, onTap, minSize:48, tooltip?, semanticsLabel?})`
- Skill cards: `skillHubBanner({context, title, subtitle, icon, badge?, skill?})` · `skillAccentCard({skill, child, onTap?, padding, emphasized})` · `skillIconBox(icon, {size, skill})` · `skillProgressBar({value, context?, skill?, height, color?})` · `quickActionButton({context, icon, label, onTap, skill?})` · `statCard({context, icon, value, label, skill?, compact})`
- Runner: `confirmRunnerExit(context)` · `runnerPopScope({context, blockExit, child, onConfirmedExit?})` · `bottomActionBar({context, progressLabel, ctaLabel, onCta, ctaEnabled, loading})` · `mcqPagerHeader(context, {current, total})` · `mcqOption({context, index, text, selected, showReviewCorrect, showReviewWrong, …})`
- Misc: `headerIconButton({context, icon, onPressed, tooltip?, badge?})` · `notificationBadge(count)` · `streakChip(context, days)` · `pagePadding` (=`fromLTRB(12,10,12,20)`)
- Containers: `AppCard(child, {variant: elevated|filled|outline(default)|danger, padding: all(12), radius: 10, onTap?})` · `StudentDialogShell(title, subtitle?, child, actions?, maxWidth:320)` · `StudentBottomSheet.show(context, StudentBottomSheet(title, child, showClose))`
- Nav: `AppNavigationBar.studentMain({currentIndex, onIndexSelected, homeLabel, messagesLabel, progressLabel, profileLabel, messagesBadge?})`
- Haptic (`AppHaptics`): `select()` (chọn/tab/chip) · `confirm()` (submit/save) · `celebrate()` (mốc ≥7 ngày)

---

## C. PERF GATE (Flutter mobile) — soi trước khi ship
- **List:** `ListView.builder`/`.separated` + pagination/lazy (fetch khi còn 3 item trước cuối). Cấm `ListView(children: map)` khi N>~20.
- **Rebuild:** `BlocSelector`/`buildWhen`; KHÔNG rebuild cả Scaffold; memo cho search/filter `(data,query,filter)`; KHÔNG parse/format nặng trong `build()`.
- **Network:** parallel, cache, pull-to-refresh có chủ đích; KHÔNG gọi API trong `build()`.
- **Search:** debounce ~250–350ms (`AppMotion.debounce`), không filter mỗi keystroke.
- **Chat/scroll:** list `reverse:true` (không jumpTo/anchor → tránh flash/giật), `RepaintBoundary` mỗi bubble, ảnh cố định kích thước.
- **Media:** `cached_network_image` + placeholder skeleton + error icon; không full-res mọi tile.
- **Motion:** mọi `AnimatedX` bọc `AppMotion.effective(context,…)`; progress bar `TweenAnimationBuilder` (không nhảy setState); reduce-motion tắt stagger/confetti/shake/pulse.
- **Lifecycle:** dispose controller/subscription/timer; socket listener không trùng.
- **Đo:** DevTools performance overlay (`p`); scroll list, mở tab, search, socket. Budget (`10 §11`): route push ≤250ms; list 100 rows ≤200ms; frame drop >16ms <1%.

---

## D. PRE-SHIP CHECKLIST (gộp guardrails `12 §5` + audit mobile `20 §7` + a11y `10 §14`)

**Token & cấu trúc (guardrail chung):**
- [ ] Không `Color(0x…)` trong widget feature; mọi màu qua `AppColors`/`AppScoreScale`.
- [ ] Không spacing magic (7/11/13/18); qua `AppSpacing`. Radius qua `AppRadius`. Duration qua `AppMotion`.
- [ ] `textPrimary` cho mọi body; amber chỉ celebrate; 1 Filled primary/màn.
- [ ] Có **loading(skeleton) + empty(CTA) + error(retry)**.
- [ ] L10n đủ **EN + VI** (`app_en.arb` + `app_vi.arb`) + đã chạy `flutter gen-l10n`.
- [ ] Không tạo component trùng (AppCard2…); tái dùng `variant`.

**Chất mobile (audit `20 §7` — bổ sung riêng student):**
- [ ] Mọi phần tử tap ≥ **44dp** (ưu tiên 48; bottom nav 60) — bọc `StudentMobileUi.tappable(minSize:48)`.
- [ ] Tương tác chính có haptic (`AppHaptics`); tôn trọng tắt-rung/reduce-motion.
- [ ] Loading = skeleton (không spinner); lỗi fetch = khối lỗi + Thử lại.
- [ ] Đáp án MCQ/điều khiển audio có `Semantics`; icon-only có tooltip.
- [ ] Animation bọc `AppMotion.effective`; progress bar animated.
- [ ] Đang làm bài: `runnerPopScope(blockExit)` + confirm thoát.
- [ ] Đạt mốc gamification: animation ăn mừng + amber (không auto-audio, chỉ haptic celebrate).

**Cổng verify (chạy, dán kết quả):**
```bash
cd english_for_community/english_for_community
bash tool/ui_audit.sh student --list      # 4 pattern (hex/radius/duration/spinner) → 0 (trừ whitelist)
dart analyze lib                            # 0 lỗi mới
flutter gen-l10n                            # nếu thêm string
```
- [ ] Hồi quy trên **360×640**; bật TalkBack/VoiceOver + reduce-motion.
- [ ] Áp archetype/pattern mới → ghi `docs/ui-ux-system/11-implementation-mapping.md` Migration log.

---

## E. HANDOFF → nối vào work-order

Khi giao Cursor: viết work-order theo `work-order.md`, phần **§5 CONTEXT BUNDLE** cho từng touch-site (anchor + BEFORE/AFTER + symbol), và **SYMBOL TABLE** liệt kê token/widget dùng (verbatim từ §A/§B5 trên, đánh dấu [CÓ]). Handoff theo `handoff-cursor.md` (BƯỚC 0 đọc work-order). Đính kèm:
- Archetype + màn anh-em tham chiếu (chrome sync).
- Bảng ZONES (B3) + STATES (B4) đã điền.
- Pre-ship checklist §D là tiêu chí nghiệm thu; lệnh verify §D là verify của work-order §7.
- GATE: đây là task UI → luôn có UI/UX gate (§A/§B/§D) + Perf gate (§C).
