# Documentation — English for Community

> **Mục đích:** Một chỗ vào duy nhất cho mọi tài liệu dự án.  
> **Quy tắc:** Không thêm file `.md` trực tiếp vào `docs/` root — luôn đặt vào thư mục con phù hợp.

---

## Nguyên tắc tổ chức

| Quy tắc | Chi tiết |
|---------|----------|
| **Một domain = một thư mục** | UI, teacher exam, dev, product, architecture, trackers tách riêng. |
| **Số thứ tự chỉ trong bộ spec** | `01-`, `02-`… chỉ dùng *bên trong* một bộ (vd. `ui-ux-system/`). Không prefix số ở root. |
| **Tracker ≠ Spec** | Tiến độ công việc → `trackers/`. Chuẩn thiết kế / nghiệp vụ → thư mục domain. |
| **README mỗi thư mục** | Mỗi folder con có `README.md` giải thích phạm vi + index file. |
| **Artifact tạm** | Log analyze, output agent → `dev/artifacts/` (không commit nếu có thể). |

---

## Bản đồ thư mục

```
docs/
├── README.md                 ← Bạn đang ở đây
├── trackers/                 ← Tiến độ task / remediation (living docs)
├── ui-ux-system/             ← Design system: token, component, screen, a11y
├── teacher-exam-system/      ← Nghiệp vụ & kỹ thuật: GV, lớp, thi, chấm
├── exam-scoring/             ← Quy tắc chấm điểm (integrated skills)
├── auto-update/              ← Phát hành app, CI/CD, admin duyệt release
├── product/                  ← Tổng hợp nghiệp vụ, báo cáo, notification, animation
├── dev/                      ← Dev guide, deploy, seed, agent workflow
├── architecture/             ← Use case, PlantUML, sơ đồ
└── reference/                ← Tài liệu tham khảo lẻ (phỏng vấn, v.v.)
```

---

## Bắt đầu nhanh theo vai trò

| Bạn cần… | Đọc |
|----------|-----|
| Lệnh Flutter terminal (run, build, hot reload) | [`dev/flutter-terminal-commands.md`](dev/flutter-terminal-commands.md) |
| Sửa UI teacher web | [`trackers/teacher-web-ui-remediation.md`](trackers/teacher-web-ui-remediation.md) + [`ui-ux-system/18-teacher-web-audit-and-standards.md`](ui-ux-system/18-teacher-web-audit-and-standards.md) |
| Sửa UI admin web | [`trackers/admin-web-ui-remediation.md`](trackers/admin-web-ui-remediation.md) + [`ui-ux-system/19-admin-web-audit-and-standards.md`](ui-ux-system/19-admin-web-audit-and-standards.md) |
| Token / component Flutter | [`ui-ux-system/README.md`](ui-ux-system/README.md) → `02`, `07`, `11` |
| Cấu trúc code Flutter | [`dev/flutter-coding-structure.md`](dev/flutter-coding-structure.md) |
| Hệ thống thi GV | [`teacher-exam-system/README.md`](teacher-exam-system/README.md) |
| Gap nghiệp vụ tổng | [`product/nghiep-vu-tong-hop-va-khoang-trong.md`](product/nghiep-vu-tong-hop-va-khoang-trong.md) |
| Seed tài khoản test | [`dev/seeds/README.md`](dev/seeds/README.md) |
| Deploy domain | [`dev/deploy-tenten-domain.md`](dev/deploy-tenten-domain.md) |
| Agent tự chạy task | [`dev/agent-autonomous-workflow.md`](dev/agent-autonomous-workflow.md) |

---

## Các bộ tài liệu chính

### [`ui-ux-system/`](ui-ux-system/README.md)
Single source of truth cho thiết kế Flutter (mobile + web teacher/admin).

### [`teacher-exam-system/`](teacher-exam-system/README.md)
Teacher role, classroom, skills exam, grading, analytics — backend + Flutter.

### [`trackers/`](trackers/README.md)
Theo dõi remediation / sprint — **cập nhật khi đóng task**, không thay spec.

### [`product/`](product/README.md)
Nghiệp vụ tổng hợp, báo cáo tiến độ dự án, notification, animation.

### [`dev/`](dev/README.md)
Công cụ dev, deploy, seed data, workflow agent.

### [`architecture/`](architecture/README.md)
Use case UML, PlantUML diagrams.

---

## Thêm tài liệu mới

1. Chọn thư mục con (không đặt ở root).
2. Thêm dòng vào `README.md` của thư mục đó.
3. Nếu là tiến độ task → `trackers/`; nếu là chuẩn lâu dài → domain folder.
4. PR UI/visual: cập nhật `ui-ux-system/11-implementation-mapping.md` migration log.

---

## Di chuyển file (2026-06) — **Hoàn tất**

Các file từng nằm lẫn ở `docs/` root đã chuyển vào thư mục con. Stub redirect (1 dòng) giữ ở path cũ cho link ngoài — xóa stub khi không còn tham chiếu.

| Path cũ (root) | Path mới |
|----------------|----------|
| `flutter-coding-structure.md` | `dev/flutter-coding-structure.md` |
| `deploy-tenten-domain.md` | `dev/deploy-tenten-domain.md` |
| `agent-autonomous-workflow.md` | `dev/agent-autonomous-workflow.md` |
| `seed-*.md` | `dev/seeds/` |
| `00-nghiep-vu-…` | `product/nghiep-vu-tong-hop-va-khoang-trong.md` |
| `bao-cao-tien-do-project.md` | `product/` |
| `notifications-…`, `animations-…` | `product/` |
| `use-cases-*.md` | `architecture/use-cases/` |
| `plantuml/` | `architecture/plantuml/` |
| `phong-van-…` | `reference/` |
