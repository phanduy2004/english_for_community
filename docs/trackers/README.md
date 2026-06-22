# Trackers — Theo dõi tiến độ công việc

> **Khác spec:** File ở đây ghi **đã làm / chưa làm / cổng audit** — cập nhật thường xuyên khi implement.  
> Chuẩn thiết kế lâu dài vẫn nằm trong `ui-ux-system/`, `teacher-exam-system/`, v.v.

| Tracker | Phạm vi | Spec tham chiếu |
|---------|---------|-----------------|
| [`teacher-web-ui-remediation.md`](teacher-web-ui-remediation.md) | UI/UX web role **teacher** — remediation 06/2026 | [`../ui-ux-system/18-teacher-web-audit-and-standards.md`](../ui-ux-system/18-teacher-web-audit-and-standards.md) |
| [`admin-web-ui-remediation.md`](admin-web-ui-remediation.md) | UI/UX web role **admin** — remediation 06/2026 | [`../ui-ux-system/19-admin-web-audit-and-standards.md`](../ui-ux-system/19-admin-web-audit-and-standards.md) |
| [`ui-visual-polish-remediation.md`](ui-visual-polish-remediation.md) | **Thẩm mỹ thị giác** teacher web + student mobile (bố cục/màu/phân cấp) — 06/2026 | [`../ui-ux-system/18-teacher-web-audit-and-standards.md`](../ui-ux-system/18-teacher-web-audit-and-standards.md) · [`20`](../ui-ux-system/20-student-mobile-audit-and-standards.md) |
| [`review-fixups-perf-batch.md`](review-fixups-perf-batch.md) | **Fixups sau review** batch perf+polish: bug writing `examOnly`, dead code gradebook — 06/2026 | — |

**Index docs:** [`../README.md`](../README.md)

## Quy ước cập nhật

- Trạng thái: `✅ Done` · `🟡 Partial` · `⬜ Todo` · `⏸ Deferred`
- Mỗi lần đóng batch: cập nhật tracker + dòng migration log trong `ui-ux-system/11-implementation-mapping.md`
- Chạy `bash tool/ui_audit.sh` trước khi đánh dấu phase **Done**
