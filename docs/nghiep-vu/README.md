# 📘 Mô tả nghiệp vụ các chức năng chính — E4C

Thư mục này mô tả **nghiệp vụ** (chức năng để làm gì, ai dùng, luồng chạy, quy tắc) **kèm cách làm kỹ thuật** của từng chức năng trọng yếu trong dự án **English for Community (E4C)**. Mục tiêu: giúp bạn **hiểu sâu và trình bày lại cho người khác**.

- **Mỗi file = một chức năng.** Mọi khẳng định bám mã nguồn thật; chỗ quan trọng có dẫn `file:dòng`.
- **Bắt đầu ở [`00-tong-quan-he-thong.md`](00-tong-quan-he-thong.md)** để nắm bức tranh lớn (E4C là gì, 3 vai trò, kiến trúc, công nghệ).

## Cấu trúc mỗi file
Mỗi file theo khung 8 mục thống nhất: (1) Mục đích nghiệp vụ → (2) Vai trò & tiền điều kiện → (3) Luồng nghiệp vụ chính → (4) Quy tắc nghiệp vụ → (5) Cách làm kỹ thuật → (6) Điểm nhấn để trình bày → (7) **Giới hạn & lưu ý trung thực** → (8) Dẫn chứng mã nguồn.

> 💡 Mục (6) là những gì nên nhấn khi khoe; mục (7) là những gì nên **chủ động nói thẳng** để không bị "bắt bẻ" khi bảo vệ.

## Danh mục

| # | Nhóm | Chức năng |
|---|------|-----------|
| [00](00-tong-quan-he-thong.md) | — | **Tổng quan hệ thống** (đọc trước) |
| [01](01-xac-thuc-va-phan-quyen.md) | Nền tảng | Xác thực & Phân quyền |
| [02](02-hoc-nghe-chep-chinh-ta-dictation.md) | Học kỹ năng | Nghe – Chép chính tả |
| [03](03-hoc-nghe-hieu-listening-comprehension.md) | Học kỹ năng | Nghe hiểu |
| [04](04-hoc-noi-speaking.md) | Học kỹ năng | Nói (WER + VAPI + AI) |
| [05](05-hoc-doc-hieu-reading.md) | Học kỹ năng | Đọc hiểu |
| [06](06-hoc-viet-va-ai-cham-ielts.md) | Học kỹ năng | Viết + AI chấm IELTS |
| [07](07-tu-vung-tu-dien-offline-va-srs.md) | Học kỹ năng | Từ vựng · Từ điển offline · SRS |
| [08](08-tro-ly-hoc-tap-ai.md) | Nền tảng | Trợ lý học tập AI |
| [09](09-gamification-va-tien-do-hoc-tap.md) | Nền tảng | Gamification & Tiến độ |
| [10](10-quan-ly-lop-hoc.md) | Lớp & Thi | Quản lý lớp học |
| [11](11-chat-lop-hoc-realtime.md) | Lớp & Thi | Chat lớp realtime |
| [12](12-soan-de-thi-exam-builder.md) | Lớp & Thi | Soạn đề thi |
| [13](13-giao-bai-va-link-cong-khai.md) | Lớp & Thi | Giao bài & Link công khai |
| [14](14-lam-bai-thi-student-runner.md) | Lớp & Thi | Làm bài thi |
| [15](15-phien-thi-truc-tiep-va-giam-sat.md) | Lớp & Thi | ⭐ Phiên thi trực tiếp & Giám sát |
| [16](16-chong-gian-lan-thi.md) | Lớp & Thi | ⭐ Chống gian lận thi |
| [17](17-cham-diem-so-diem-va-tra-ket-qua.md) | Lớp & Thi | Chấm điểm · Sổ điểm · Trả kết quả |
| [18](18-thong-ke-lop-hoc-analytics.md) | Lớp & Thi | Thống kê lớp học |
| [19](19-thong-bao.md) | Nền tảng | Thông báo |
| [20](20-tu-cap-nhat-app-va-quan-ly-phat-hanh.md) | Vận hành | Tự cập nhật app & Phát hành |
| [21](21-quan-tri-he-thong-admin.md) | Vận hành | Quản trị hệ thống |

## Gợi ý thứ tự trình bày (kể chuyện)
1. **Mở đầu:** file `00` — E4C là gì, 3 vai trò, kiến trúc một-codebase-ba-mặt-tiền.
2. **Điểm nhấn số 1 (độc đáo nhất):** `15` → `16` → `17` (thi realtime + chống gian lận + chấm AI/giáo viên chốt).
3. **Điểm nhấn số 2 (AI đi vào chấm bài):** `06` (Viết) → `04` (Nói) → `08` (Trợ lý AI).
4. **Chiều sâu học tập:** `02`–`05`, `07` (4 kỹ năng + từ vựng offline).
5. **Nền tảng sản phẩm thật:** `01` (auth), `20` (tự cập nhật + phát hành), `21` (admin + audit).
6. **Vòng đời lớp học:** `10` → `12` → `13` → `14` → `18`.

> ⭐ = phần khó/độc đáo nhất, nên dành nhiều thời gian nhất khi trình bày.
