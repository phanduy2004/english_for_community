# Work-order — Writing topic cards không nhấn được (web)

- **Task ID:** 20260628-writing-topic-card-tap
- **Loại:** BUG
- **Platform:** student mobile (triệu chứng trên **Flutter Web / Edge**)
- **Mục tiêu:** Card topic Writing (Technology, Education, …) phải mở bottom sheet chọn task type khi tap.
- **Cỡ task:** MICRO (1 file, ~1 dòng logic)
- **Trạng thái:** IMPLEMENTED

---

## 1) Vấn đề + nguyên nhân gốc

**Triệu chứng:** Trên màn Writing Practice, tap card topic không phản hồi — không mở modal chọn loại bài (Opinion, Discussion, …).

**Luồng đúng:** `WritingTopicsPage._onCardTap` → `_showTaskSelectionModal` (`writing_topics_page.dart:194–196, 89–175`).

**Nguyên nhân:** `WritingCard` truyền `tapViaChildActionsOnWeb: true` vào `StudentMobileUi.skillAccentCard`:

```dart
// student_mobile_ui.dart:648-649
final effectiveOnTap =
    onTap == null || (kIsWeb && tapViaChildActionsOnWeb) ? null : onTap;
```

Trên web, cờ này **tắt hoàn toàn** `onTap` của card ngoài — được thiết kế cho list có **nút con** (Start/Review) như Reading/Listening/Speaking (`reading_list_page.dart:376–394`).

`WritingCard` **không** có footer button — chỉ whole-card tap + icon history. Kết quả: web = không có target tap nào cho card body → dead tap.

**Bằng chứng:** User chạy `flutter run -d edge`; screenshot list topic hiển thị bình thường nhưng tap không mở sheet.

## 2) Audit downstream

| Consumer | Ảnh hưởng |
|---|---|
| `writing_topics_page.dart` | Gọi `WritingCard(onTap: _onCardTap)` — không đổi |
| `skillAccentCard` | Không sửa API |
| Reading/Listening/Speaking cards | Giữ `tapViaChildActionsOnWeb: true` (có nút con) — không đụng |

## 3) Quyết định thiết kế

- **Xóa** `tapViaChildActionsOnWeb: true` khỏi `WritingCard` — bật lại outer `inkTap` (web dùng `GestureDetector`, `student_mobile_ui.dart:78–83`).
- Icon history vẫn dùng `GestureDetector`/`IconButton` riêng — tap history không trigger card (hit test con ưu tiên).
- Không thêm footer button — UX whole-card tap đúng spec Writing.

## 4) Scope IN / OUT

**IN:** `lib/feature/writing/widgets/writing_card.dart` — bỏ 1 dòng `tapViaChildActionsOnWeb: true`.

**OUT:** Không sửa `student_mobile_ui.dart`, bloc, API, l10n.

## 5) Diff

```dart
// writing_card.dart — skillAccentCard call
return StudentMobileUi.skillAccentCard(
  skill: SkillType.writing,
  onTap: onTap,  // bỏ tapViaChildActionsOnWeb: true
  child: Row(...),
);
```

## 6) Ràng buộc hiệu năng

Không áp dụng — thay đổi 1 prop widget, không rebuild thêm.

## 7) Hồi quy tối thiểu

1. Web (Edge): Writing → tap card "Technology" → bottom sheet task type mở.
2. Web: tap icon history → modal lịch sử (không mở task sheet).
3. Android/iOS (nếu có): tap card vẫn mở sheet (regression không đổi — trước đó mobile đã hoạt động).

Account test: `docs/dev/seeds/seed-hoangdong-accounts.md` (student).

## 8) Verify

```bash
cd english_for_community
dart analyze lib/feature/writing/widgets/writing_card.dart lib/feature/writing/writing_topics_page.dart
```

## 9) HANDOFF (Phase 3)

- Sửa **duy nhất** `writing_card.dart`: xóa `tapViaChildActionsOnWeb: true`.
- Hot restart web → smoke mục 7.

## 10) Checklist OPUS AUDIT (Phase 4)

- [x] Root cause khớp code (`effectiveOnTap` null trên web)
- [x] Fix tối thiểu, không scope creep
- [x] Không phá pattern list có footer button (file khác giữ nguyên)
- [ ] Smoke web Edge xác nhận tap card + history

**Verdict:** APPROVED (pending smoke web)
