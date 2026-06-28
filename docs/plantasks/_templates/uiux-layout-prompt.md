# Template prompt — Xây/Sửa layout UI/UX

> Dùng để khởi động task layout theo `../../AI-Working-Process-vi.md` (Opus = brain + audit Phase 4, Cursor = implement) + bám `../../ui-ux-system`.
> Cách dùng: copy **(1)** cho nhanh, hoặc điền **(2)** khi cần chặt scope. Phần **(3)** Opus tự áp, không cần ghi.

---

## (1) Câu ngắn — dán nhanh (1 dòng)

```text
Opus, theo docs/AI-Working-Process-vi.md (bạn là brain, KHÔNG tự code): phân tích + plan layout để [XÂY MỚI / SỬA] màn "[TÊN MÀN]" ([student mobile | teacher web | admin web]). Bám docs/ui-ux-system: tokens (02), foundation+components ([03+04 | 06+07]), archetype phù hợp trong patterns/, screen-brief liên quan, guardrails (12) + audit-standards ([20 | 18 | 19]). Đối chiếu 1 màn anh-em đã chuẩn để chrome đồng bộ (AppBar/spacing/card/màu). Ra work-order ở docs/plantasks/ + handoff cho Cursor IMPLEMENT; xong báo Opus audit (Phase 4). Tài liệu thắng khi mâu thuẫn; chỉ dùng token, không hardcode.
```

---

## (2) Khối điền đầy đủ — Phần A (biến thể UI/UX layout)

```text
• Task ID:          [trống → tự sinh YYYYMMDD-slug]
• Loại:             FEATURE (xây layout mới) | BUG (sửa layout lệch)
• Màn + file:       [tên màn] · [đường dẫn .dart]
• Platform:         student mobile | teacher web | admin web
• Mục tiêu:         [1 câu — màn này phải làm được / trông như thế nào]
• Archetype:        [A1–A12 trong patterns/01-screen-archetypes, hoặc "tự chọn + giải thích"]
• Tham chiếu app:   [Duolingo/Headway/Linear/Notion/... — học CỤ THỂ cái gì]
• Màn anh-em chuẩn: [màn đã làm tốt để đồng bộ chrome — vd Progress/Profile]
• Trạng thái cần:   loading(skeleton) | empty | error+retry | success   [đánh dấu cái bắt buộc]
• Scope IN:         [file/widget được chạm]
• Scope OUT:        [tuyệt đối không chạm — shared UI, màn khác, logic/bloc, schema...]
• Kỳ vọng đầu ra:   dart analyze 0 lỗi mới; chrome khớp màn anh-em; token-only; a11y (44dp/Semantics); đủ trạng thái đã chọn
• Bối cảnh/ảnh:     [ảnh hiện trạng / mockup / log nếu có]
```

---

## (3) "Hằng số" Opus luôn tự áp (không cần ghi vào prompt)

- **Ground-truth trước:** đọc code thật + doc liên quan; *tài liệu thắng* khi lệch (sửa code theo doc).
- **Tái dùng helper dùng chung** thay vì dựng lại — gốc của "đồng bộ":
  - Mobile student → `lib/core/ui/student_mobile_ui.dart` (`StudentMobileUi`: appBar, sectionHeader, searchField, filterRow, statCard, emptyState, errorBanner, skeleton…).
  - Teacher/Admin web → `feature/teacher/layout/teacher_web_ui.dart` (`TeacherWebUi`) / `AdminWebUi`.
- **Token-only:** `AppColors / AppSpacing / AppRadius / AppTypography` — không hardcode hex/px. Editorial Black là brand; **amber chỉ cho celebrate** (KPI nổi/streak/chart highlight), không làm nút chính.
- **Đối chiếu 1 màn anh-em** để AppBar (căn giữa, h2/14px)/spacing/card(`AppCard outline`, phẳng)/màu khớp toàn tab.
- **A11y:** touch ≥44dp, `Semantics`, reduce-motion, skeleton thay spinner (doc 20).
- **Đủ 4 trạng thái** server-driven: loading / empty / error+retry / success.
- **Đầu ra quy trình:** work-order tại `docs/plantasks/{Loại}/{TaskID}/` → handoff Cursor **IMPLEMENT** → báo Opus **AUDIT** (Phase 4) → cập nhật doc + migration log (`11`).

---

## (4) Doc kéo theo platform (Opus tự chọn đúng bộ)

| Platform | Bộ doc bắt buộc đọc |
|----------|---------------------|
| **student mobile** | `02` tokens · `03` foundations · `04` components · `05` screens · `patterns/01-screen-archetypes` + `patterns/04-screen-briefs/` · `15` smart-patterns · `20` mobile audit/standards · `26` feedback&noti · `12` guardrails · `11` mapping |
| **teacher web** | `02` · `06` foundations · `07` components · `08` screens · `13` live console · `14` dialogs · `17` dashboard · `18` web audit/standards · `12` · `11` · `patterns/` |
| **admin web** | `02` · `06` · `07` · `08` · `19` admin audit/standards · `12` · `11` · `patterns/` |

> Archetype A1–A12: `patterns/01-screen-archetypes.md`. Screen brief mẫu: `patterns/04-screen-briefs/` (home, skill-hub, runner, progress, profile, messages-hub).
