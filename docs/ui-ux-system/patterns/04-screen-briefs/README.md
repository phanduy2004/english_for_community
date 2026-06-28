# Screen briefs — index

> Brief = áp 1 **archetype** ([`../01-screen-archetypes.md`](../01-screen-archetypes.md)) vào **màn thật**: hiện trạng đo theo token → đánh giá → target layout (before/after) → **build diff** cho Cursor → states → checklist.
> Mọi claim có `file:line`; chỉ map về token/widget **đang tồn tại**. Quy tắc màu: skill-screen → skill color; phi-skill → primary; amber chỉ celebrate.

## Danh sách brief

| Màn | Archetype | File brief | Màn thật |
|-----|-----------|-----------|----------|
| **Home** | A1 | [`home.md`](home.md) | `feature/home/home_page.dart` |
| **Skill Hub** (Reading) | A2 | [`skill-hub.md`](skill-hub.md) | `feature/reading/reading_list_page.dart` |
| **Runner** (exam) | A3 | [`runner.md`](runner.md) | `feature/student/exams/exam_runner_page.dart` |
| **Messages hub** | A5 | [`messages-hub.md`](messages-hub.md) | `feature/student/messages/student_classroom_chat_hub_page.dart` |
| **Student classroom detail** | A3 | [`student-classroom-detail.md`](student-classroom-detail.md) | `feature/student/classes/student_classroom_detail_page.dart` |
| **Profile / Settings** | A9 | [`profile.md`](profile.md) | `feature/profile/profile_page.dart` |
| **Progress / Stats** | A12 | [`progress.md`](progress.md) | `feature/progress/progress_report_page.dart` |

## Khuyến nghị nổi bật (đọc nhanh)

| Màn | 2 việc đáng làm nhất |
|-----|----------------------|
| **Home** | (1) Daily-goal đang vẽ **3 lần** + stats nằm dưới chart → gộp 1 progress card, đưa stats lên trên (tiết kiệm ~140dp). (2) Thiếu card **"Tiếp tục"** (A1) + grid 6 nút (2 amber) → thêm Continue card, rút grid ≤5 nút/1 hàng. |
| **Skill Hub** | (1) Hiện **filter trước search** → đổi sang search → filter → list; gộp 2 `sectionGap` thừa. (2) Tách **search-empty** khỏi data-empty (dùng `Icons.search_off`). |
| **Runner** | (1) Thay Container+Row bottom tự chế + `PopScope` tay bằng `bottomActionBar` + `runnerPopScope` (có sẵn, kèm spinner submit). (2) Thay block progress padding **24px off-token** bằng `mcqPagerHeader` (+ `%`), thêm `✕` thoát, bỏ nút "Trước" cạnh tranh → 1 CTA chính. |
| **Messages** | (1) Bỏ banner to / header 1 hàng `Messages ── N lớp`. (2) Bỏ `_SectionHeader` đếm trùng → hội thoại lên sớm ~120dp. |
| **Profile** | (1) Bỏ **skill color + amber** ở các row settings (phi-skill → primary/neutral); chỉ giữ badge XP/streak amber. (2) Thêm **confirm dialog** cho Đăng xuất (đang fire thẳng, khác delete-account đã confirm). |
| **Progress** | (1) Mở đầu bằng **KPI row** + kéo weekly chart lên (đang bị chôn gần đáy). (2) Ép quy tắc **"1 amber"**: goal-bar đổi `accent`→`primary`, amber chỉ cho streak + cột hôm nay + #1; ngừng "rainbow" 6 skill cùng lúc. |

> Khi áp 1 brief vào màn → ghi commit vào [`../../11-implementation-mapping.md`](../../11-implementation-mapping.md) "Migration log".
