# Work-order: Skill list layout audit + fix

**Task ID:** 20260626-skill-list-layout  
**Loại:** PERF  
**Trạng thái:** IMPLEMENTED (chờ smoke test)

## 1) Vấn đề + nguyên nhân

- **Style:** `skillAccentCard` default `emphasized: true` → mọi card list kỹ năng có viền trái accent (không đồng nhất Home).
- **Overflow web hẹp:** Footer card hoàn thành dùng `Row(Expanded + nút cố định)` → tràn ngang ~320–400px (listening, listening comp, reading, speaking hub).
- **Không có CRITICAL** `RenderBox was not laid out` trên luồng student list → runner (đã verify grep/read).

## 2) Quyết định

- Đổi default `emphasized` → `false`; chỉ truyền `true` khi cần highlight.
- Thêm `StudentMobileUi.skillListCardFooter(info, actions)` — meta trên, nút căn phải dưới.
- **OUT (defer):** refactor nested `ListView` → `CustomScrollView`; `listening_skills_page` TabBarView height 450.

## 3) Diff đã áp dụng

| File | Thay đổi |
|------|----------|
| `lib/core/ui/student_mobile_ui.dart` | `emphasized` default `false`; `skillListCardFooter` |
| `lib/feature/listening/list_listening/listening_list_page.dart` | Footer column |
| `lib/feature/listening_comp/listening_comp_list_page.dart` | Footer column |
| `lib/feature/reading/reading_list_page.dart` | Footer column |
| `lib/feature/speaking/speaking_hub_page.dart` | Footer column |

## 4) Verify

```bash
cd english_for_community
dart analyze lib/core/ui/student_mobile_ui.dart \
  lib/feature/listening/list_listening/listening_list_page.dart \
  lib/feature/listening_comp/listening_comp_list_page.dart \
  lib/feature/reading/reading_list_page.dart \
  lib/feature/speaking/speaking_hub_page.dart
```

Smoke (Edge): Home → từng kỹ năng → list card không viền accent; card completed không overflow; thu hẹp cửa sổ ~360px.

## 5) Opus audit checklist

- [ ] Default `emphasized` không làm hỏng màn cần highlight (mode dialog, featured card)
- [ ] 4 list footer không overflow trên web hẹp
- [ ] Không scope-creep (nested ListView chưa đụng)
