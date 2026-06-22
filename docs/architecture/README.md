# Architecture — Use case & sơ đồ

| Thư mục / file | Nội dung |
|----------------|----------|
| [`use-cases/use-cases-uml.md`](use-cases/use-cases-uml.md) | Use case UML (Mermaid) — User / Teacher / Admin |
| [`use-cases/use-cases-diagrams.md`](use-cases/use-cases-diagrams.md) | Diagrams bổ sung |
| [`use-cases/use-cases-detailed-for-word.md`](use-cases/use-cases-detailed-for-word.md) | Bản chi tiết export Word |
| [`plantuml/`](plantuml/README.md) | File `.puml` cho PlantText / luận văn |

**Kỹ thuật triển khai:** [`../teacher-exam-system/07-technical-architecture.md`](../teacher-exam-system/07-technical-architecture.md)

**Backend & Database:**
| File | Nội dung |
|------|----------|
| [`backend-optimization-plan.md`](backend-optimization-plan.md) | Tối ưu hiệu năng backend (G0–G4): bảo mật, N+1, aggregation, kiến trúc |
| [`../database-design-audit.md`](../database-design-audit.md) | **Đánh giá thiết kế DB** (35 schema): điểm số, vấn đề kèm `file:dòng`, chuẩn đề xuất |
| [`database-migration-plan.md`](database-migration-plan.md) | **Plan đổi schema an toàn** (expand-contract) DB↔Backend↔Flutter + audit 4 tầng + migration |
| [`backend-structure-and-naming.md`](backend-structure-and-naming.md) | **Cấu trúc thư mục & đặt tên backend:** đánh giá, chỗ lộn xộn (untils typo, scripts rải, tools=AI), cấu trúc chuẩn + quy ước tên + plan dọn an toàn |
