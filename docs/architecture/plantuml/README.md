# PlantUML — Use Case Diagrams (E4C)

**PlantText** ([planttext.com](https://www.planttext.com/)) dùng **PlantUML**, không phải Mermaid.

## Cách dùng

1. Mở file `.puml` trong thư mục này (ví dụ `teacher-use-case.puml`).
2. Copy **toàn bộ** nội dung (từ `@startuml` đến `@enduml`).
3. Dán vào PlantText → bấm **Refresh**.
4. Export PNG/SVG để chèn luận văn.

## Lỗi thường gặp

| Triệu chứng | Nguyên nhân |
|-------------|-------------|
| Chỉ thấy "Welcome to PlantUML!" | Thiếu `@startuml` / `@enduml`, hoặc dán code **Mermaid** (`usecaseDiagram`) |
| Parse error | Dòng `actor Teacher as "Teacher"` kiểu Mermaid — PlantUML dùng `actor "Teacher" as Teacher` |
| Sơ đồ quá rối | User diagram lớn — zoom out hoặc tách theo nhóm |

## File

| File | Mục |
|------|-----|
| `user-use-case.puml` | 2.4.1.2 User |
| `teacher-use-case.puml` | 2.4.1.3 Teacher |
| `admin-use-case.puml` | 2.4.1.4 Admin |

Markdown + Mermaid: [../use-cases/use-cases-uml.md](../use-cases/use-cases-uml.md)
