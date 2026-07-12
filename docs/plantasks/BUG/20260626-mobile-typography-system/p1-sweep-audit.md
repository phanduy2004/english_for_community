# P1 Sweep Audit — `fontSize` hardcode trên màn student (mobile)

- **Task:** 20260626-mobile-typography-system · **Phase:** P1 (sweep)
- **Audit date:** 2026-07-10 · **Auditor:** Opus (5 explorer fan-out) · **Implementer dự kiến:** Cursor
- **Liên quan:** vừa thêm `AppTypography._mobileScale = kIsWeb ? 1.0 : 0.9` (app native nhỏ 10%, web giữ nguyên). Scale này **chỉ áp cho chỗ dùng AppTypography** → các `fontSize` hardcode dưới đây KHÔNG co lại → sweep này vừa đồng bộ cỡ, vừa làm scale 0.9 áp đều.

---

## 1. Verdict

**Chưa đồng bộ.** P0 (theme/dialog/slot) đã DONE, nhưng **P1 sweep chưa làm**. Cụ thể:

- Chỉ **18** call-site dùng `fontSize: AppTypography.*` (đúng hệ thống).
- Còn **~255 literal `fontSize: <số>` / ~57 file student-facing** hardcode cỡ, nhiều giá trị **lệch scale** (10, 12, 17, 20, 22, 24) → mỗi màn một cỡ.
- Scale hợp lệ chỉ có: **11 · 13 · 14 · 15 · 16 · 18** (web px; native = ×0.9).

| Vùng | Literal | File |
|---|---|---|
| Shared factories (`core/ui/**`) | ~13 | 6 |
| Listening / Reading | 33 | 5 |
| Speaking / Writing / Vocabulary | 92 | 12 |
| `student/**` (exams, classes, messages, join) | 50 | 17 |
| `classroom_chat/**` | 54 | 13 |
| Home / Progress / Profile | 26 | 10 |
| **Tổng** | **~255** | **~57** |

---

## 2. Nguyên nhân gốc (systemic — sửa đúng chỗ là lan)

**RC-A — Shared style factory tự hardcode cỡ.** 2 file định nghĩa style dùng chung nhưng ghi `fontSize` literal → mọi màn consume đều lệch, và scale 0.9 không tới:
- `core/ui/exam_system_ui.dart` (anchor: `captionSecondary`=12, `captionMuted`=12, `embeddedCardTitleStyle`=14, `embeddedSectionLabelStyle`=13, `embeddedBodyStyle`=13, `embeddedCaptionStyle`=12, `embeddedButtonLabelStyle`=13, `embeddedTabLabelStyle`=13). Consumer = toàn bộ `student/exams/**`.
- `classroom_chat/widgets/classroom_chat_ui.dart` (anchor: `headerTitle`=13/14, `headerSubtitle`=11, `messageBody`=13, `senderName`=11, `timestamp`=10, `composerDecoration.hintStyle`=13, `searchFieldDecoration.hintStyle`=13). Consumer = toàn bộ chat.

**RC-B — `.copyWith(fontSize:)` đè lên token tốt.** Rất nhiều site ở `student/exams/**` gọi `ExamSystemUi.captionMuted.copyWith(fontSize: 11)` / `StudentMobileUi.cardTitle(...).copyWith(fontSize: 14)` → hardcode lại cỡ, vô hiệu token. Fix RC-A xong thì phần lớn override này **bỏ được** (kế thừa base).

**RC-C — Giá trị lệch scale.** 10 / 12 / 17 / 20 / 22 / 24 xuất hiện khắp nơi — không nằm trong 11/13/14/15/16/18.

**RC-D — Hero number chưa có token.** Score reveal dùng 32 / 44 / 48 (số điểm lớn) — hợp lý về mặt thị giác nhưng đang literal, mỗi nơi một số.

---

## 3. Chính sách map (áp dụng cho mọi bảng bên dưới)

| Literal | → Token | Helper |
|---|---|---|
| 10 | caption 11 | `context.captionStyle` |
| 11 | caption/label 11 | `context.captionStyle` / `AppTypography.label()` |
| 12 | 11 (meta) hoặc 13 (body) — theo vai trò | `context.captionStyle` / `context.bodyStyle` |
| 13 | body/h3 13 | `context.bodyStyle` / `context.h3Style` |
| 14 | h2 14 | `context.h2Style` |
| 15 | bodyLg 15 / kpi 15 | `context.bodyLgStyle` / `AppTypography.kpiValue(web:false)` |
| 16 | h1 16 | `context.h1Style` |
| 17 | 15 hoặc 16 — theo vai trò | `context.bodyLgStyle` / `context.h1Style` |
| 18 | display 18 | `AppTypography.displaySm()` |
| 20 / 22 / 24 | display 18 | `AppTypography.displaySm()` |

**Giữ nguyên (allowlist — KHÔNG snap):**
- **Hero score number** 32/44/48 → thêm **1 token mới** `AppTypography.heroNumber({double size})` (đề xuất base 40, `kpiValue`-like: w700, tabularFigures) và trỏ 4 nơi về đó. KHÔNG để literal.
- **Emoji glyph** (28), **avatar initials / ChatAvatar size** (11/12/13 dạng *tham số widget*, không phải `TextStyle`) → là kích thước component/trang trí, **OUT scope** (không tính là typography).

> Nguyên tắc: giữ **weight/color/height** cũ, chỉ đổi nguồn cỡ. Không đổi layout/logic. Với style có biến thể `compact` → dùng token nhỏ hơn 1 bậc thay vì literal.

---

## 4. Kế hoạch phase (theo LEVERAGE — làm P1.0 trước)

### P1.0 — Shared factory (làm ĐẦU TIÊN, fan-out lớn nhất)
Sửa literal → hằng `AppTypography.mobile*` (giữ được `const`; tự hưởng scale 0.9 native).

| File | Site → token |
|---|---|
| `core/ui/exam_system_ui.dart` | `captionSecondary`(12)→`mobileCaption` · `captionMuted`(12)→`mobileCaption` · `embeddedCardTitleStyle`(14)→`mobileH2` · `embeddedSectionLabelStyle`(13)→`mobileH3` · `embeddedBodyStyle`(13)→`mobileBody` · `embeddedCaptionStyle`(12)→`mobileCaption` · `embeddedButtonLabelStyle`(13)→`mobileBody`/`mobileH3` · `embeddedTabLabelStyle`(13)→`mobileH3` |
| `classroom_chat/widgets/classroom_chat_ui.dart` | `headerTitle`(13/14)→`mobileH3`/`mobileH2` · `headerSubtitle`(11)→`mobileCaption` · `messageBody`(13)→`mobileBody` · `senderName`(11)→`mobileLabel` · `timestamp`(10)→`mobileCaption` · composer/search `hintStyle`(13)→`mobileBody` |
| `core/ui/widget/common_cards.dart` | :126 body(14)→`bodyStyle`/`bodyLgStyle` |
| `core/ui/widget/app_corner_toast.dart` | :51 toast(13)→`bodyStyle` |
| `core/ui/feedback/app_in_app_banner.dart` | :77 title(13)→`h3Style` · :89 body(12)→`captionStyle`/`bodyStyle` |
| `core/ui/feedback/app_feedback.dart` | :79 field error(12)→`captionStyle` |
| `core/ui/motion/app_score_reveal.dart` | :65 hero(44)→**`AppTypography.heroNumber`** (token mới) |

> Sau P1.0: toàn bộ `student/exams/**` (RC-B) và `classroom_chat/**` phần lớn tự đúng cỡ. **Nên làm & nghiệm thu P1.0 trước khi sang các phase màn.**

### P1.1 — Skills: Listening / Reading (33)

| relpath:line | raw | role | token |
|---|---|---|---|
| listening/widget/listening_common_widgets.dart:95 | 18 | progress-header title (onPrimary) | `displaySm()` |
| listening/widget/listening_common_widgets.dart:114 | 10 | level chip label | `label()` |
| listening/widget/listening_common_widgets.dart:123 | 13 | "x/y done" caption | `bodyStyle` |
| listening/widget/listening_common_widgets.dart:148 | 11 | "NN%" trong progress circle | `captionStyle` |
| listening/widget/practice_tab.dart:130 | 12 | "Meaning" label (non-compact) | `label()` |
| listening/widget/practice_tab.dart:187 | 13 | "Auto-play next" switch label | `bodyStyle` |
| listening/widget/discussion_tab.dart:181 | 12 | "Replying to {user}" banner | `captionStyle` |
| listening/widget/discussion_tab.dart:252 | 13 | comment author name | `h3Style` |
| listening/widget/discussion_tab.dart:252 | 10 | comment timestamp | `captionStyle` |
| listening/widget/discussion_tab.dart:254 | 14 | comment body (RichText) | `bodyStyle` |
| listening/widget/discussion_tab.dart:257 | 10 | reaction count badge | `captionStyle` |
| listening/widget/discussion_tab.dart:259 | 12 (×2) | "Reply"/like action label | `label()` |
| listening_comp/listening_comp_page.dart:326 | 16 | quiz-result summary body | `bodyLgStyle` |
| listening_comp/listening_comp_page.dart:558 | 15 | timer number | `kpiValue(web:false)` |
| listening_comp/listening_comp_page.dart:592 | 14 | review-header label | `h2Style` |
| listening_comp/listening_comp_page.dart:610 | 13 | translate-toggle label | `h3Style` |
| listening_comp/listening_comp_page.dart:729 | 13 | feedback-explain label | `h3Style` |
| listening_comp/listening_comp_page.dart:743 | 14 | feedback reasoning body | `bodyStyle` |
| listening_comp/listening_comp_page.dart:750 | 14 | translated feedback body | `bodyStyle` |
| listening_comp/listening_comp_page.dart:842 | 16 | "Transcript locked" title | `h1Style` |
| listening_comp/listening_comp_page.dart:850 | 14 | locked hint subtitle | `bodyStyle` |
| listening_comp/listening_comp_page.dart:867 | 14 | "Original transcript" heading | `h2Style` |
| listening_comp/listening_comp_page.dart:876 | 16 | transcript body (Serif) | `bodyLgStyle` |
| listening_comp/listening_comp_page.dart:892 | 14 | "Translation transcript" heading | `h2Style` |
| listening_comp/listening_comp_page.dart:904 | 16 | translated transcript body | `bodyLgStyle` |
| reading/reading_detail_page.dart:280 | 16 | quiz-result summary body | `bodyLgStyle` |
| reading/reading_detail_page.dart:446 | 15 | timer number | `kpiValue(web:false)` |
| reading/reading_detail_page.dart:485 | 14 | review-header status | `h2Style` |
| reading/reading_detail_page.dart:535 | 14 | passage body (compact) | `bodyStyle` |
| reading/reading_detail_page.dart:540 | 17 | passage body (non-compact) | `bodyLgStyle` |
| reading/reading_detail_page.dart:554 | 18 | translation section title | `displaySm()` |
| reading/reading_detail_page.dart:560 | 16 | translation body (italic) | `bodyLgStyle` |

### P1.2 — Skills: Speaking / Writing / Vocabulary (92)

**speaking/speaking_feedback_page.dart** — :727 `44` CEFR band hero → **`heroNumber`**.
**speaking/widget/word_details_dialog.dart** — :260 `24` headword→`displaySm()` · :266 `16` phonetic→`h1Style` · :300 `16` meaning→`h1Style` · :309 `14` "Definitions"→`h2Style` · :329 `14` POS→`h2Style` · :340 `14` list number→`h2Style` · :345 `14` definition body→`bodyStyle` · :351 `13` example→`bodyStyle`.
**speaking/free_speaking_page.dart** — :488 `18`→`displaySm()` · :519 `12`→`captionStyle` · :660 `13`→`bodyStyle` · :729 `12`→`label()` · :793 `13`→`bodyStyle` · :815 `15`→`bodyLgStyle` · :825 `14` hint→`bodyLgStyle` · :1095 `15` bubble→`bodyLgStyle` · :1113 `18` typing dots→(decor) · :1147 `14` translation→`h2Style`.
**speaking/speaking_skills_page.dart** — 23 site (nhiều ternary `examCompact?…`): counters/labels `10–12`→`captionStyle`/`label()`; transcript/script `13–17`→`bodyStyle`/`bodyLgStyle`; :688 `16` button→`h1Style`; :1148 script `15/17/22`→`bodyLgStyle`/`displaySm()`; :1117 "Accuracy"`14`→`h2Style`; :1241 score pill `13`→`h3Style`. *(Xem chi tiết từng dòng ở output audit; giữ nhánh compact = token nhỏ hơn 1 bậc.)*
**writing/writing_feedback_page.dart** — :102 `11` badge→`label()` · :123 `14` prompt→`bodyStyle` · :135 `13`→`bodyStyle` · :141 `48` band hero→**`heroNumber`** · :208 `16` heading→`h1Style` · :213 `13`→`bodyStyle` · :285 `14`→`h2Style` · :294 `13`→`h3Style` · :319 `15`→`bodyLgStyle` · :320 `14`→`h2Style` · :334 `13`→`bodyStyle` · :358 `14`→`bodyStyle` · :387 `16`→`h1Style` · :404 `15`→`bodyLgStyle` · :494 `13`→`h3Style` · :509 `10` badge→`label()` · :521 `13`→`bodyStyle`.
**writing/writing_task_page.dart** — :666 `15`→`bodyLgStyle` · :673 `12`→`captionStyle` · :692 `14`→`bodyStyle`.
**writing/widgets/history_modal.dart** — :49 `14`→`h2Style` · :50 `18` topic→`displaySm()` · :173 `16` score badge→`h1Style`/`kpiValue` · :189 `15`→`bodyLgStyle` · :205 `10` status→`label()` · :218/:222 `12` meta→`captionStyle`.
**writing/widgets/writing_common_widgets.dart** — :38 `18`→`displaySm()` · :47 `13`→`bodyStyle` · :61 `11` badge→`label()` · :106/:109 `14` search text/hint→`h2Style`/`bodyStyle` · :170 `13` chip→`label()` · :205 `14` empty→`h2Style`.
**writing/widgets/interactive_diff_text.dart** — :33/:47/:72/:87/:106 `15` diff body→`bodyLgStyle` · :172/:188 `14` error token→`h2Style` · :233 `16`→`h1Style` · :285 `18` popup title→`displaySm()` · :307 `13`→`bodyStyle` · :317 `15`→`bodyLgStyle`.
**vocabulary/vocabulary_tutorial_dialog.dart** — :40 `15`→`bodyLgStyle` · :212 `22` title→`displaySm()` · :223 `15`→`bodyLgStyle`.
**vocabulary/dict_detail_page.dart** — :101 `24` headword→`displaySm()`.
**vocabulary/review_session_page.dart** — :375 `32` flashcard word (override trên `kpiValue`) → **`heroNumber`** hoặc `displaySm()` tuỳ ý.

### P1.3 — `student/**` (50) — phần lớn là `.copyWith(fontSize:)` đè lên `ExamSystemUi.*`; sau P1.0 nhiều cái BỎ được (kế thừa base)

| relpath:line | raw | role | token |
|---|---|---|---|
| student/messages/student_classroom_chat_hub_page.dart:165 | 13 | swipe "Đã đọc" | `bodyStyle` |
| student/messages/student_classroom_chat_hub_page.dart:589 | 11 | section header label | `label()` |
| student/messages/student_classroom_chat_hub_page.dart:600 | 11 | unread count | `captionStyle` |
| student/join/student_unified_join_card.dart:117 | 13 | join-code input (bỏ override) | `bodyStyle` |
| student/classes/student_classroom_member_tile.dart:60 | 14 | member name (bỏ override cardTitle) | `h2Style` |
| student/classes/student_classroom_member_tile.dart:83 | 10 | "You" badge | `label()` |
| student/classes/student_classroom_member_tile.dart:114 | 11 | role chip | `label()` |
| student/classes/student_classroom_info_sheet.dart:332 | 12 | status pill | `label()`/`captionStyle` |
| student/classes/student_classroom_detail_page.dart:382 | 13 | TabBar labelStyle | `h3Style` |
| student/classes/student_classroom_hub_tile.dart:70 | 14 | class name | `h2Style` |
| student/classes/student_classroom_hub_tile.dart:102 | 10 | join-policy chip | `label()` |
| student/exams/exam_embedded_fixed_writing_panel.dart:78 | 15 | essay input body | `bodyLgStyle` |
| student/exams/exam_embedded_listening_dictation_review_panel.dart:170 | 12 | q-number badge | `label()` |
| student/exams/exam_embedded_speaking_review_panel.dart:164 | 12 | q-number badge | `label()` |
| student/exams/exam_embedded_speaking_review_panel.dart:211 | 15 | transcript body | `bodyLgStyle` |
| student/exams/exam_embedded_writing_review_panel.dart:95 | 15 | draft body | `bodyLgStyle` |
| student/exams/exam_section_tag.dart:383 | 11 | tag title | `captionStyle` |
| student/exams/exam_section_tag.dart:392 | 10 | tag subtitle | `captionStyle` |
| student/exams/exam_section_tag.dart:299 | 11/13 | q-number badge (ternary) | `label()`/`h3Style` |
| student/exams/exam_session_status_banner.dart:42 | 13 | status banner label | `h3Style` |
| student/exams/exam_session_lobby_page.dart:392 | 13 | avatar initials | `bodyStyle` |
| student/exams/student_exam_live_mirror_view.dart:451 | 11 | "Qn: X" chip | `label()`/`captionStyle` |
| student/exams/integrated_exam_score_widgets.dart:291 | 12 | avg formula hint | `captionStyle` |
| student/exams/integrated_exam_score_widgets.dart:303/:314 | 11 | table col header | `label()` |
| student/exams/integrated_exam_score_widgets.dart:340 | 14 | skill row label | `h2Style` |
| student/exams/integrated_exam_score_widgets.dart:346/:410/:417/:431/:523/:579 | 11–12 | pending/detail notes | `captionStyle` |
| student/exams/integrated_exam_score_widgets.dart:356 | 20 | final score KPI | `kpiValue`/`heroNumber` |
| student/exams/integrated_exam_score_widgets.dart:441 | 14 | skill score value | `kpiValue(web:false)` |
| student/exams/integrated_exam_score_widgets.dart:559 | 13/14 | compact label (ternary) | `h3Style`/`h2Style` |
| student/exams/integrated_exam_score_widgets.dart:568 | 16/18 | compact score (ternary) | `displaySm()`/`kpiValue` |
| student/exams/integrated_exam_runner_page.dart:884 | 11 | "done/total" counter | `captionStyle` |
| student/exams/integrated_exam_runner_page.dart:1976 | 11 | listening-type chip | `label()` |
| student/exams/integrated_exam_runner_page.dart:2195 | 11/12 | timer countdown (ternary) | `captionStyle` |
| student/exams/integrated_exam_grammar_widgets.dart:91 | 13 | MCQ letter badge | `h3Style` |
| student/exams/integrated_exam_grammar_widgets.dart:179/:236/:1845 | 12/11 | id/index badge | `label()` |
| student/exams/integrated_exam_grammar_widgets.dart:687/:728 | 11 | blank/answer label | `captionStyle` |
| student/exams/integrated_exam_grammar_widgets.dart:756/:951 | 13 | numbered prefix | `h3Style` |
| student/exams/integrated_exam_grammar_widgets.dart:962/:1459 | 12 | kind/hint text | `captionStyle` |

*(Bỏ qua `exam_section_tag.dart:140 fontSize: fontSize` — biến forward, không phải literal; ChatAvatar/avatar-initial size = tham số widget, OUT scope.)*

### P1.4 — `classroom_chat/**` màn (54) — sau P1.0 (factory) phần lớn còn lại là dialog/menu

Nặng nhất: **`chat_settings_menu.dart` (21 literal)** — dialog/menu body & member rows: `10–18` → map `captionStyle`/`label()`/`bodyStyle`/`h2Style`/`h1Style`/`displaySm()` theo vai trò (xem output audit từng dòng). Các file còn lại (`chat_message_bubble.dart` 6, `chat_input_bar.dart` 4, `classroom_chat_body.dart` 4, `conversation_tile.dart` 2, `chat_reply_preview.dart` 2, `classroom_chat_room_tile.dart` 2, `chat_media_actions.dart`/`chat_reaction_bar.dart`/`classroom_chat_app_bar.dart`/`classroom_chat_mini_window.dart`/`classroom_chat_list_panel.dart` 1–2): map theo §3. Emoji glyph `28` + avatar-initial size = OUT scope.

### P1.5 — Home / Progress / Profile (26)

| relpath:line | raw | role | token |
|---|---|---|---|
| home/home_page.dart:946 | 13 | hero stat pill label (`_pillStyle`) | `h3Style` |
| progress/progress_report_page.dart:573 | 20 | "..." separator glyph | `displaySm()` (hoặc icon) |
| progress/progress_report_page.dart:720 | 10 | KPI subtitle (bỏ override) | `captionStyle` |
| progress/widgets/weekly_activity_bars_chart.dart:190 | 11 | x-axis day label | `captionStyle`/`label()` |
| progress/widgets/weekly_activity_bars_chart.dart:233/234/235 | 10 | y-axis tick | `captionStyle` |
| profile/change_password_dialog.dart:111 | 18 | dialog title | `displaySm()` |
| profile/change_password_dialog.dart:122 | 13 | subtitle | `bodyStyle` |
| profile/change_password_dialog.dart:216 | 13 | field label | `h3Style` |
| profile/change_password_dialog.dart:248 | 14 | input text | `h2Style` |
| profile/change_password_dialog.dart:251 | 13 | hint | `bodyStyle` |

*(core/ui shared trong bảng P1.0.)*

---

## 5. Token mới cần thêm (P1.0, trong `app_typography.dart`)

```dart
// Hero score number — score reveal / band lớn. Không dùng cho body text.
static const double mobileHero = 40;   // ×_mobileScale tự áp
static const double webHero = 40;
static TextStyle heroNumber({Color? color, bool web = false, double? size}) => TextStyle(
      fontFamily: _f,
      fontSize: size ?? (web ? webHero : mobileHero),
      height: 1.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: color ?? AppColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
```
Consumer: `app_score_reveal.dart:65`, `speaking_feedback_page.dart:727`, `writing_feedback_page.dart:141`, `integrated_exam_score_widgets.dart:356/568`, (tuỳ) `review_session_page.dart:375`.

---

## 6. Verify / Acceptance mỗi phase

```bash
cd english_for_community
dart analyze lib/<folder-vừa-sửa>
# đo tiến độ (chỉ literal số, không tính AppTypography.*):
grep -rnE "fontSize:\s*[0-9]" lib/feature/<folder> | wc -l   # kỳ vọng → 0 (trừ allowlist decor)
```
- **P1.0 xong:** mở 1 màn exam embedded + 1 phòng chat → cỡ chữ đồng nhất, native nhỏ hơn web ~10%.
- Mỗi phase: `dart analyze` sạch; xem 360×640 không vỡ; giữ đúng weight/color; hero number vẫn to.
- **Định nghĩa DONE P1:** `grep -rnE "fontSize:\s*[0-9]" lib/feature/{home,progress,profile,listening,listening_comp,reading,speaking,writing,vocabulary,student,classroom_chat} lib/core/ui` → chỉ còn allowlist (emoji glyph, avatar-initial size, hero token đã centralize).

---

## 7. HANDOFF — Cursor (copy khối, làm P1.0 trước)

```text
Bạn là implementer. Work-order: docs/plantasks/BUG/20260626-mobile-typography-system/ (work-order.md §6 + p1-sweep-audit.md).
Làm THEO PHASE, P1.0 trước, mỗi phase 1 PR nhỏ. CHỈ đổi NGUỒN cỡ chữ — giữ nguyên weight/color/height/layout/logic.

P1.0 (đầu tiên, fan-out lớn):
  - lib/core/theme/app_typography.dart: thêm token heroNumber (§5).
  - lib/core/ui/exam_system_ui.dart + lib/feature/classroom_chat/widgets/classroom_chat_ui.dart: thay mọi fontSize literal → hằng AppTypography.mobile* (giữ const) theo bảng §4/P1.0.
  - core/ui/widget/common_cards.dart, app_corner_toast.dart, feedback/app_in_app_banner.dart, feedback/app_feedback.dart, motion/app_score_reveal.dart.
Sau đó P1.1→P1.5 theo bảng.

Map cỡ theo §3. Với `.copyWith(fontSize:)` đè lên ExamSystemUi/StudentMobileUi: ưu tiên BỎ override để kế thừa base (sau khi base đã đúng ở P1.0); nếu là biến thể compact → dùng token nhỏ hơn 1 bậc.
KHÔNG: đổi con số token gốc; snap hero number (32/44/48 → dùng heroNumber); đụng teacher/admin/web (feature/teacher, feature/admin, *_web_ui.dart); đổi kích thước avatar/emoji glyph.
VERIFY mỗi phase: dart analyze lib/<folder> sạch + grep -rnE "fontSize:\s*[0-9]" lib/<folder> → 0 (trừ allowlist). Dán kết quả.
```
