# UI/UX System — English for Community

> **Single source of truth** cho mọi quyết định thiết kế trong app E4C.
>
> Ai cần đọc: agent AI viết code, designer, dev frontend (Flutter), reviewer.
> Khi mã nguồn và tài liệu mâu thuẫn — **tài liệu thắng**, hãy sửa code theo doc.

## Triết lý cốt lõi

1. **Hai trải nghiệm, một ngôn ngữ thiết kế.**
   - **Học sinh → mobile-first.** App học, làm bài, tra cứu — tối ưu cho điện thoại.
   - **Giáo viên & Admin → web-first.** Dashboard quản lý lớp, soạn đề, chấm bài, vận hành — tối ưu cho desktop.
2. **Chữ đen, mảnh, gọn — và brand cũng đen.** `textPrimary` (#1C1917) là mặc định cho **mọi** chữ trừ tag/timestamp/placeholder. Brand mark dùng **`#0A0A0A` Editorial black** cho filled button, AppBar logo, link nhấn. Accent duy nhất là **amber `#F59E0B`** dành cho "ăn mừng" (KPI nổi, streak chip, chart highlight) — không phải nút chính.
3. **Cân đối – tinh tế – không phô trương.** Lấy cảm hứng từ Linear, Notion, Vercel, Stripe Dashboard, Cron, Cal.com (web) và Duolingo, Headway, Robinhood, iOS HIG, Material 3 (mobile).
4. **Server là sự thật.** UI phản ánh state server, không phán đoán; loading / error / empty đều có spec.

## Cấu trúc tài liệu

| File | Nội dung |
|------|----------|
| [`00-compact-density-v3.md`](00-compact-density-v3.md) | **Bắt đầu tại đây** — scale v3 nhỏ gọn (typography + spacing + dashboard) |
| [`01-design-philosophy.md`](01-design-philosophy.md) | Khán giả, principles, references, định hướng từng nền tảng |
| [`02-design-tokens.md`](02-design-tokens.md) | Color, typography (mobile + web), spacing, radii, shadow, motion |
| [`03-mobile-foundations.md`](03-mobile-foundations.md) | Layout grid mobile, navigation, page anatomy, gestures |
| [`04-mobile-components.md`](04-mobile-components.md) | Button, card, list, input, chip, dialog, sheet, skeleton (mobile) |
| [`05-mobile-screens.md`](05-mobile-screens.md) | Đặc tả màn học sinh: home, skill hubs, runner, exam, profile |
| [`06-web-foundations.md`](06-web-foundations.md) | Layout web cho teacher/admin: sidebar, max width, density |
| [`07-web-components.md`](07-web-components.md) | Table, drawer, command bar, filter, toolbar, page header |
| [`08-web-screens.md`](08-web-screens.md) | Đặc tả màn teacher & admin (dashboard, classroom, exam editor, grading, releases) |
| [`09-content-and-microcopy.md`](09-content-and-microcopy.md) | Tone, l10n, microcopy mẫu, error/empty copy |
| [`10-accessibility.md`](10-accessibility.md) | Contrast, focus, hit target, motion-reduce, screen reader |
| [`11-implementation-mapping.md`](11-implementation-mapping.md) | Map token → Flutter (`AppColors`, `AppTheme`, `ExamSystemUi`); refactor list |
| [`12-ai-guardrails.md`](12-ai-guardrails.md) | Rules cho AI agent: được/không được làm gì, checklist trước khi commit |
| [`13-teacher-live-session-console-layout.md`](13-teacher-live-session-console-layout.md) | Live session console: tabs-first, metadata thu gọn, list HS dày |
| [`14-teacher-dialogs.md`](14-teacher-dialogs.md) | **Dialog giáo viên:** shell, account hub, edit profile, password, picker |
| [`15-mobile-smart-patterns.md`](15-mobile-smart-patterns.md) | **Mobile patterns thông minh:** micro-interactions, haptic, bottom sheet, carousel, gamification, badge, transitions, coachmark, offline, dark mode prep |
| [`16-teacher-live-participant-status.md`](16-teacher-live-participant-status.md) | **Live session:** chip trạng thái HS (lobby + đang làm / đã nộp) — Session control & Live monitor |
| [`17-teacher-dashboard-layout.md`](17-teacher-dashboard-layout.md) | **Dashboard giáo viên v5:** KPI + stats panels, inbox tách route |
| [`18-teacher-web-audit-and-standards.md`](18-teacher-web-audit-and-standards.md) | **Audit web teacher (06/2026):** chấm điểm UX, khoảng trống tuân thủ + trải nghiệm, **tiêu chuẩn mới đề xuất** (token enforcement, skeleton, inline-validate, save-state, destructive, focus-visible) |
| [`19-admin-web-audit-and-standards.md`](19-admin-web-audit-and-standards.md) | **Audit web admin (06/2026):** chấm điểm UX, khoảng trống tuân thủ + trải nghiệm, tiêu chuẩn mới (`AdminStatusPalette`, gỡ fork `content_widgets`, rollback-confirm, tái dùng skeleton/focus/save-state). Audit: `tool/ui_audit.sh admin` |
| [`20-student-mobile-audit-and-standards.md`](20-student-mobile-audit-and-standards.md) | **Audit mobile student (06/2026):** chấm điểm UX, tiêu chuẩn **đặc thù mobile** (touch-target 44dp, `AppHaptics`, celebrate, skeleton, reduce-motion, Semantics, exit-confirm). Audit: `tool/ui_audit.sh student` |
| [`21-teacher-web-scroll-smoothness-and-polish.md`](21-teacher-web-scroll-smoothness-and-polish.md) | **Hiệu năng & mượt teacher (06/2026):** chẩn đoán 3 tầng — **render/scroll** (hover-khi-cuộn, shadow blur, RepaintBoundary), **data/rebuild** (waterfall API, buildWhen/Selector, parse trong build), **backend** (N+1 ~40 query/attempt, thiếu index/`.lean()`, analytics 10 query) + giải pháp P0/P1 + cách đo |
| [`22-student-chat-scroll-and-conversation-list.md`](22-student-chat-scroll-and-conversation-list.md) | **Chat student (06/2026):** chẩn đoán scroll giật/flash khi vào màn (forward list + jumpTo) → giải pháp **reverse list** bỏ anchor; redesign **danh sách cuộc trò chuyện** (rebuild chọn lọc, Messenger-clean tile, skeleton) + audit checklist |
| [`23-conversation-list-redesign.md`](23-conversation-list-redesign.md) | **Redesign danh sách cuộc trò chuyện web + mobile (06/2026):** học Messenger/Telegram/Slack — một `ConversationTile` dùng chung, time căn phải, bỏ chevron, avatar màu-theo-tên, bỏ thẻ accent mobile, badge pill + before/after mockup |
| [`24-teacher-live-mirror-work-cutoff.md`](24-teacher-live-mirror-work-cutoff.md) | **Live mirror teacher (06/2026):** bài làm học sinh bị bản đồ câu hỏi che/cắt — bỏ khoá 72% chiều cao + giới hạn/đồng bộ-tab/thu gọn bản đồ, bài làm vào `Expanded` |
| [`25-grading-hub-open-attempt-bug.md`](25-grading-hub-open-attempt-bug.md) | **Bug grading hub (06/2026):** bấm thẻ/Grade không mở bài làm — lệch key `_id` (backend `.lean()`) ↔ `id` (frontend). Fix: backend map `id`, frontend đọc `id ?? attemptId ?? _id` |
| [`26-mobile-feedback-and-notifications.md`](26-mobile-feedback-and-notifications.md) | **Feedback & thông báo mobile student (06/2026):** bỏ corner-toast trên student, `AppFeedback` định tuyến theo mức độ (SnackBar/dialog blocking/inline), realtime → banner/push; taxonomy + kế hoạch sweep 66 toast |
| [`../dev/flutter-coding-structure.md`](../dev/flutter-coding-structure.md) | **Cấu trúc code Flutter** — import widget, file map, checklist tránh lỗi compile |

## Cách dùng tài liệu

- **Đang sửa một màn hình** → đọc `02` (token), `03/04` (mobile) hoặc `06/07` (web), rồi `05/08` cho spec màn cụ thể.
- **Tạo component mới** → bắt buộc đọc `02` + `04` (mobile) hoặc `07` (web), thêm tham chiếu vào `11` khi commit.
- **AI agent (Cursor/Codex)** → đọc trước `12` mỗi lần làm task UI; đọc [`flutter-coding-structure.md`](../dev/flutter-coding-structure.md) khi thêm file/import widget teacher.

## Quy ước cập nhật

- Mọi PR thay đổi visual phải kèm cập nhật doc tương ứng (không có doc → không merge).
- Nếu deprecate token / component → ghi vào `11` mục “Migration log” với commit hash.
- Tài liệu này được giữ **đồng bộ** với `lib/core/theme/*` và `lib/core/ui/*`. Nếu thấy lệch — fix code, không fix doc theo code.
- **06/2026:** `06` và `07` đã được đồng bộ về **compact v3** (sidebar 212/48, top bar 44, button 32, row 40, card radius 10) cho khớp `00`, `08`, `17` và code `TeacherWebUi`. Các số v2 cũ trong hai file đó đã bị thay. Xem audit hiện trạng + tiêu chuẩn bổ sung ở [`18`](18-teacher-web-audit-and-standards.md).
