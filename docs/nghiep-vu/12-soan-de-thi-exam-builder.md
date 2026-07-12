# 12 — Soạn đề thi (Exam Builder)

> **Một câu:** Giáo viên soạn một đề bằng cách bật/tắt từng kỹ năng trong 4 kỹ năng, mỗi kỹ năng gắn một nội dung có sẵn từ CMS, cộng thêm phần Grammar chấm tự động; đề là template tách khỏi bài làm học viên.

---

## 1. Mục đích nghiệp vụ
Cho giáo viên (GV) một công cụ soạn đề thi **linh hoạt theo kỹ năng**: chọn bài thi gồm kỹ năng nào (nghe/nói/đọc/viết), gắn nội dung tương ứng, và thêm phần **Ngữ pháp (Grammar)** gồm các câu chấm tự động. Đề là **template dùng lại được** cho nhiều lớp/kỳ, tách biệt khỏi bài làm của học viên.

## 2. Vai trò & tiền điều kiện
- **GV** có quyền quản lý đề.
- Cần có sẵn nội dung CMS để gắn (bài dictation/comprehension, bộ nói, bài đọc, chủ đề viết) — được **kiểm tra tồn tại thật** khi publish.

## 3. Luồng nghiệp vụ chính
1. **Tạo bản nháp** (status `draft`).
2. Ở màn editor, GV **bật một kỹ năng** → chọn nội dung CMS cho kỹ năng đó (Writing có thể gắn chủ đề hoặc nhập/generate "đề cố định").
3. Thêm câu **Grammar** (nhiều loại — xem mục 7).
4. Lưu nháp (mỗi lần lưu tăng số phiên bản nội dung).
5. **Publish** → hệ thống validate; đủ điều kiện thì chuyển `published`.
6. Ngân hàng đề: liệt kê, **nhân bản (duplicate)**, archive/restore/xoá.

## 4. Quy tắc nghiệp vụ quan trọng (điều kiện publish)
Backend là "cửa chặn" cuối cùng:
- Phải có **ít nhất 1 kỹ năng có nội dung HOẶC ít nhất 1 câu Grammar**.
- **Thứ tự kỹ năng bắt buộc:** reading → listening → writing → speaking.
- **Listening đặc biệt:** cho tối đa 2 phần listening (1 dictation + 1 comprehension), không trùng loại.
- Mỗi kỹ năng bật phải có định danh phần ổn định + một nội dung được **verify tồn tại thật** trong CMS.
- **Writing:** cần chủ đề liên kết **hoặc** đề viết cố định.
- **Grammar:** tổng điểm ≤ 100 khi đề có kèm kỹ năng.
- Biến thể "đủ 4 kỹ năng" (`integrated_four_skills`) siết hơn: bắt buộc đủ speaking + reading + writing + 1–2 listening.

## 5. Cách làm (kỹ thuật)
- **Cấu trúc Exam:** schema rất "lỏng" (`sections`, `settings` kiểu Mixed) — mọi ngữ nghĩa nằm ở tầng service. `examFormat` (trong settings) quyết định nhánh validate/chấm.
- **Đề trỏ tới CMS (content-linked):** đề không nhồi nội dung mà **trỏ tới** bản ghi CMS rồi verify khi publish → tránh trùng lặp dữ liệu; tự sửa nhầm dictation↔comprehension dựa trên collection thật của nội dung.
- **Grammar** không phải "section" mà nằm trong `settings.grammarItems`; validate chỉ số đáp án MCQ nằm trong khoảng hợp lệ (chặn "đáp án không thể đúng").
- **Chấm tự động Grammar** khi nộp: MCQ chấm **tất-cả-hoặc-không** (chọn đúng y hệt tập đáp án mới có điểm).

## 6. Điểm nhấn để trình bày
- Kiến trúc "content-linked" + verify runtime → không trùng lặp dữ liệu, đề luôn trỏ tới nội dung thật.
- Validate publish chặt chẽ ở backend (không tin client).
- Tự sửa nhầm loại listening dựa trên dữ liệu thật (chống lỗi legacy).

## 7. Giới hạn & lưu ý trung thực
- **Grammar KHÔNG chỉ là MCQ:** ngoài trắc nghiệm, code hỗ trợ **6 loại** đều chấm tự động (MCQ đơn/đa, điền chỗ trống, nối, sắp xếp…). → Khi trình bày nên nói "phần Grammar tự chấm gồm nhiều dạng, MCQ là một trong số đó".
- Editor **không autosave** — lưu bằng nút Save (thiết kế v1).
- Thời lượng ở editor chỉ là **mặc định template**; thời gian thi thật lấy từ cấu hình **assignment** (xem file `13`).
- Schema Mixed = không ràng buộc ở DB; sai cấu trúc chỉ bị bắt khi publish.

## 8. Dẫn chứng mã nguồn
- `services/teacherExamService.js` (validate `267-345`, `102-161`; grammar `175-257`; publish/draft `423-477`).
- Chấm MCQ/Grammar: `services/examAttemptService.js:121-131, 228-237`; `examSkillSectionResources.js`.
- Model: `models/Exam.js`.
- Client: `feature/teacher/bloc/integrated_exam_editor/`, `teacher_exam_editor_page.dart`.
- Doc: `docs/teacher-exam-system/04-exam-builder-design.md`.
