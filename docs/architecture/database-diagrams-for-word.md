# Sơ đồ Cơ sở dữ liệu — Hướng dẫn chèn vào Word



> **Phạm vi:** 32 collection MongoDB (`english_for_community_backend/src/models/`).



---



## 1. Bộ sơ đồ Mermaid — kiểu luận văn (ERD)



**File:** [`database/database-diagrams-uml.md`](./database/database-diagrams-uml.md) — **3 hình** (tách Hình 1 cũ thành 2 để chữ/line rõ hơn).

| Mục Word | File PNG export |
|----------|-----------------|
| **2.x.2.1** | `export/erd-hinh-1a-user-lop.png` — User + hệ thống + lớp |
| **2.x.2.2** | `export/erd-hinh-1b-de-thi.png` — Đề thi |
| **2.x.2.3** | `export/erd-hinh-2-hoc-tap.png` — 4 kỹ năng |



### Xem & export (md = ảnh)

1. Mở [`database-diagrams-uml.md`](./database/database-diagrams-uml.md) → **Ctrl+Shift+V** → thấy **3 ảnh PNG** (không còn khối code Mermaid).
2. Sửa schema: file [`export/*.mmd`](./database/export/) → chạy `export/export-erd.ps1`.
3. Chèn Word: PNG/SVG trong `export/`.



**Field đầy đủ / in PDF:** [`plantuml/database-full.puml`](./plantuml/database-full.puml)



---



## 2. Cấu trúc mục Word



```

2.x Thiết kế cơ sở dữ liệu

  2.x.1 MongoDB + Mongoose

  2.x.2 Lược đồ thực thể kết hợp (ERD)

    2.x.2.1 … 2.x.2.2   ← 2 hình Mermaid

  2.x.3 Bảng 32 collection  ← §3 bên dưới

```



---



## 3. Bảng mô tả collection (copy vào Word)



| STT | Collection | Miền | Mô tả ngắn |

|:---:|------------|------|------------|

| 1 | User | Core | Tài khoản, vai trò (`user` / `teacher` / `admin`), gamification |

| 2 | Notification | Auth | Thông báo in-app / push |

| 3 | Report | Auth | Báo cáo lỗi / góp ý |

| 4 | Classroom | Lớp | Lớp học, mã mời |

| 5 | ClassroomMember | Lớp | Thành viên lớp |

| 6 | ClassroomMessage | Lớp | Chat nhóm lớp |

| 7 | ClassroomActivityLog | Lớp | Nhật ký hoạt động |

| 8 | ClassroomChatReadState | Lớp | Trạng thái đã đọc chat |

| 9 | Exam | Thi | Ngân hàng đề thi |

| 10 | ExamAssignment | Thi | Giao đề cho lớp / link |

| 11 | ExamSession | Thi | Phiên thi realtime |

| 12 | ExamAttempt | Thi | Lượt làm bài + chấm |

| 13 | TeacherAssignmentPreset | Thi | Mẫu cấu hình giao bài |

| 14 | Listening | Nghe | Dictation (chép chính tả) |

| 15 | Enrollment | Nghe | Tiến độ dictation |

| 16 | DictationAttempt | Nghe | Lượt chép từng cue |

| 17 | CueComment | Nghe | Bình luận trên cue |

| 18 | ListeningComprehension | Nghe | Nghe hiểu MCQ |

| 19 | ListeningCompAttempt | Nghe | Lượt làm nghe hiểu |

| 20 | SpeakingSet | Nói | Bộ câu read-aloud |

| 21 | SpeakingEnrollment | Nói | Tiến độ speaking |

| 22 | SpeakingAttempt | Nói | Lượt nói / WER |

| 23 | Reading | Đọc | Bài đọc hiểu |

| 24 | ReadingProgress | Đọc | Tiến độ / điểm cao |

| 25 | ReadingAttempt | Đọc | Lượt làm bài đọc |

| 26 | WritingTopic | Viết | Chủ đề viết (CMS) |

| 27 | WritingSubmission | Viết | Bài viết + AI feedback |

| 28 | WritingTopicVersion | Viết | Lịch sử phiên bản topic |

| 29 | Word | Từ vựng | SRS cá nhân |

| 30 | UserDailyProgress | Tiến độ | Thống kê theo ngày |

| 31 | AdminAuditLog | Hệ thống | Nhật ký admin |

| 32 | AppRelease | Hệ thống | Phiên bản app mobile |



---



## 4. Dọn dữ liệu legacy (không migration)



Nếu Compass còn collection/field cũ sau khi đổi code, xóa **thủ công** trên Atlas/Compass (backup trước):



- Drop collection không còn model: `teacherapplications`, `role_permissions`, `classroommeetings` (nếu có).

- `$unset` field snapshot cũ trên `examattempts` / `examsessions` nếu không còn dùng.



---



## 5. Liên quan



- Mermaid ERD: [`database/database-diagrams-uml.md`](./database/database-diagrams-uml.md)

- Use case: [`use-cases/use-cases-uml.md`](./use-cases/use-cases-uml.md)

- PlantUML: [`plantuml/README.md`](./plantuml/README.md)

