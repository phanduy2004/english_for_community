# 17 — Chấm điểm · Sổ điểm · Trả kết quả (Grading Hub)

> **Một câu:** Phần khách quan/Grammar/nghe/đọc chấm tự động; Viết & Nói có nháp AI để giáo viên chốt; hệ thống **không phát điểm khi còn phần chưa chấm**; tổng hợp sổ điểm và xuất Excel.

---

## 1. Mục đích nghiệp vụ
Đưa bài làm về điểm số một cách công bằng và hiệu quả: **tự chấm** phần khách quan, **AI đưa nháp** cho phần tự luận, **giáo viên là người chốt điểm cuối**, đảm bảo **không phát điểm "thổi phồng"** khi còn phần chưa chấm, tổng hợp **sổ điểm** theo lớp và **xuất Excel/CSV**, rồi **trả kết quả** cho học viên.

## 2. Vai trò & tiền điều kiện
- **GV chủ assignment** (mọi thao tác chấm/phát đều kiểm quyền sở hữu).
- Bài phải đã `submitted` mới chạy AI/chốt điểm.

## 3. Luồng nghiệp vụ chính
1. **Tự chấm lúc nộp:** chấm tự động Grammar + Listening + Reading (thang 0–10/kỹ năng); Writing/Speaking để **chờ chấm**.
2. **GV mở Grading Hub** theo assignment: danh sách bài + thống kê (đã nộp / chờ chấm tay / đã chốt / đã phát hành / nộp một phần…).
3. **Chấm AI (nháp):** từng bài hoặc hàng loạt.
4. **GV chốt điểm tay** (Viết/Nói) hoặc **Apply** nháp AI.
5. **Chốt (finalize) → Trả kết quả (release):** từng bài hoặc theo lô.
6. **Sổ điểm lớp** + **xuất Excel/CSV**.

## 4. Quy tắc nghiệp vụ quan trọng
- **Trạng thái điểm cuối:** `finalized` (mọi phần đã có điểm) / `partial` (có điểm nhưng còn phần chờ) / `pending` (chưa có gì). Điểm cuối = trung bình các thành phần (thang 10).
- **Chốt an toàn — KHÔNG phát điểm khi còn phần chưa chấm (điểm hay nhất):** thao tác trả kết quả/chốt hàng loạt chỉ lấy bài **không ở trạng thái `partial`/`pending`**. Truy vấn còn tự động cho phép đề khách quan (đã tự chấm hết) đi qua. Mục đích: *"tránh phát điểm final thổi phồng cho học sinh"*.
- **AI = nháp, GV = người chốt:** AI ghi điểm/nhận xét nháp nhưng đẩy bài về "chờ chấm tay" → buộc GV xác nhận.
- **Trả kết quả:** đánh dấu đã phát hành + lưu mức chi tiết (chỉ điểm / đầy đủ) + **thông báo học viên** (chỉ lần đầu).

## 5. Cách làm (kỹ thuật)
- **Chấm AI Writing:** lấy bài viết → gọi AI chấm IELTS → quy đổi band sang thang 10 → ghi làm **nháp** (kèm nhận xét), trạng thái về "chờ chấm tay".
- **Chốt điểm tay:** kẹp 0–10, đánh dấu nguồn "manual", tính lại tổng.
- **Bảo toàn override:** khi rebuild điểm tự động, **giữ nguyên** điểm Viết/Nói do GV/AI đã chốt.
- **Sổ điểm:** ma trận học viên × assignment, mỗi ô lấy **bài tốt nhất**, có % + cờ "cần chấm"; tính trung bình theo hàng/cột.
- **Xuất Excel (ExcelJS):** freeze header, tiêu đề đề/lớp, thống kê, **sắp tên theo tiếng Việt** đúng dấu; xuất CSV có BOM UTF-8.
- **Cưỡng chế từ phiên live:** kết thúc phiên tự chạy đúng pipeline chấm (không cần thao tác riêng).

## 6. Điểm nhấn để trình bày
- **"Chốt an toàn" bằng một truy vấn** vừa chặn phát điểm khi còn phần chờ, vừa tự cho đề khách quan đi qua — thiết kế gọn, đúng cả hai loại đề.
- **AI là nháp, con người chốt** → giữ trách nhiệm sư phạm ở giáo viên.
- Điểm cuối chuẩn hoá thang 10 giữa nhiều kỹ năng + Grammar.
- Xuất Excel đẹp, sắp tên tiếng Việt đúng dấu.

## 7. Giới hạn & lưu ý trung thực
- AI phụ thuộc Groq API key; thiếu key → báo "AI grading unavailable".
- Batch chạy song song — lỗi từng bài được gom lại, không rollback toàn cục.
- Phần chưa hoàn thành khi nộp một phần = **0 điểm** trong pool tương ứng (không phạt thêm).
- Điểm cuối là **trung bình cộng không trọng số** (xem file `14`).

## 8. Dẫn chứng mã nguồn
- `services/examGradingService.js` (chấm AI `81-198`, chốt tay `200-277`, release `279-322`, **chốt an toàn `363-403`**).
- `services/teacherGradebookService.js` (sổ điểm `66-252`); `services/teacherAssignmentScoresExportService.js:95-186` (Excel).
- Chấm tích hợp: `services/examIntegratedScoring.js`.
- Client: `feature/teacher/integrated_writing_grading_panel.dart`, `bloc/grading_hub/`.
- Doc: `docs/teacher-exam-system/13-partial-submit-and-grading-hub-spec.md`.
