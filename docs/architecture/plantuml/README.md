# PlantUML — Use Case & Database Diagrams (E4C)

**PlantText** ([planttext.com](https://www.planttext.com/)) dùng **PlantUML**, không phải Mermaid.

## Cách dùng

1. Mở file `.puml` trong thư mục này.
2. Copy **toàn bộ** nội dung (từ `@startuml` đến `@enduml`).
3. Dán vào PlantText → bấm **Refresh**.
4. Export PNG/SVG để chèn luận văn / báo cáo Word.

## Lỗi thường gặp

| Triệu chứng | Nguyên nhân |
|-------------|-------------|
| Chỉ thấy "Welcome to PlantUML!" | Thiếu `@startuml` / `@enduml`, hoặc dán code **Mermaid** |
| Parse error | Cú pháp Mermaid ≠ PlantUML |
| Sơ đồ quá rối / chữ nhỏ | Zoom out; export **SVG**; scale trong Word (~14–16 cm ngang) |

## Use case (theo vai trò)

| File | Mục |
|------|-----|
| `user-use-case.puml` | 2.4.1.2 User |
| `teacher-use-case.puml` | 2.4.1.3 Teacher |
| `admin-use-case.puml` | 2.4.1.4 Admin |

Markdown + Mermaid: [../use-cases/use-cases-uml.md](../use-cases/use-cases-uml.md)

## Database — Mermaid (khuyến nghị, giống use case)

Markdown + Mermaid: [../database/database-diagrams-uml.md](../database/database-diagrams-uml.md)

Hướng dẫn export Word: [../database-diagrams-for-word.md](../database-diagrams-for-word.md)

## Database — PlantUML (tuỳ chọn / PlantText)

| File | Hình | Nội dung |
|------|:----:|----------|
| **`database-overview.puml`** | 1 | Tổng quan 32 collection |
| **`database-domain-classroom-exam.puml`** | 2 | Lớp học + Đề thi |
| **`database-domain-learning.puml`** | 3 | 4 kỹ năng |
| **`database-domain-core.puml`** | 4 *(tuỳ chọn)* | Core & hệ thống |
| **`database-full.puml`** | Phụ lục | Schema đầy đủ 7 trang |
