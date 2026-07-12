# 07 — Từ vựng · Từ điển offline · Ôn tập ngắt quãng (SRS)

> **Một câu:** Tra từ điển tiếng Anh hoàn toàn offline (SQLite ~225MB), lưu từ vào sổ tay theo 3 trạng thái, và ôn tập ngắt quãng (flashcard hard/good/easy) với lịch ôn tự tính theo thuật toán quên lãng Ebbinghaus.

---

## 1. Mục đích nghiệp vụ
Cho học viên: (1) **tra từ điển không cần mạng** sau lần cài đầu (hữu ích ở nơi sóng yếu); (2) **lưu từ vào sổ tay** cá nhân; (3) **ôn tập ngắt quãng** để ghi nhớ dài hạn thay vì học vẹt rồi quên. Đồng thời feed số liệu ôn từ vào tiến độ học hằng ngày.

## 2. Vai trò & tiền điều kiện
- **Học viên** (đã đăng nhập) để lưu sổ tay/ôn tập; có chế độ **khách** chỉ tra từ điển.
- File từ điển SQLite (~225MB, 50k+ từ) đã bundle trong app và được copy ra vùng ghi được ở lần mở đầu.

## 3. Luồng nghiệp vụ chính

**A. Tra từ điển offline**
1. Gõ từ khoá (có debounce) → tra **SQLite cục bộ trên máy**.
2. Tìm theo 2 tầng: **prefix trước** (khớp đầu từ), rỗng mới **full-text**.
3. Bấm một kết quả → nếu không phải khách, **âm thầm ghi vào "recent"** rồi mở màn chi tiết (headword, IPA, loại từ, nghĩa + ví dụ, phát âm TTS, nút "Học"/"Lưu").

**B. Lưu vào sổ tay (3 trạng thái)**
- **recent:** tự tạo khi tra từ (`learningLevel = 0`, không có lịch ôn).
- **saved:** bấm "Lưu" (đánh dấu để dành, không vào SRS).
- **learning:** bấm "Học" → **bắt đầu vào SRS** (`learningLevel = 1`, có `nextReviewDate`).

**C. Ôn tập SRS (flashcard)**
1. Bấm "Ôn ngay" → server trả các từ `learning` **đã đến hạn** (`nextReviewDate <= hôm nay`), cũ nhất trước.
2. Lật flashcard (mặt trước = từ, mặt sau = IPA + nghĩa), chọn **Hard / Good / Easy**.
3. Mỗi lựa chọn gửi lên **server** để cập nhật lịch ôn; client chỉ chuyển thẻ kế **khi lưu thành công** (lỗi mạng thì **giữ nguyên thẻ**, không mất kết quả).
4. Hết danh sách → màn hoàn thành + confetti.

## 4. Quy tắc nghiệp vụ quan trọng
- **Thuật toán SRS chạy ở BACKEND**; client chỉ gửi nhãn `hard/good/easy` + thời lượng.
  - `hard` → về **level 1** (reset).
  - `good` → **+1 level**.
  - `easy` → **+2 level**.
- **Lịch ôn theo mảng khoảng cách tăng dần** (Ebbinghaus): `[1, 3, 7, 16, 35, 90, 180]` ngày; `nextReviewDate = hôm nay + interval[level]`.
- **"Chỉ tính là học được khi thực sự nhớ":** chọn `good/easy` mới cộng "từ đã học" vào tiến độ; chọn `hard` chỉ cộng thời gian học, **không** cộng từ đã học.
- Chỉ từ trạng thái `learning` mới có lịch ôn; `saved`/`recent` không vào hàng đợi ôn.

## 5. Cách làm (kỹ thuật)
- **Từ điển offline — 3 lớp phòng thủ toàn vẹn:**
  - **Versioning:** so số phiên bản DB trong code với số lưu ở SharedPreferences; đổi file DB thì tăng số → buộc copy lại.
  - **Copy nguyên tử:** ghi ra file `.tmp` rồi rename — app bị kill giữa chừng không để lại DB cắt dở bị tưởng hợp lệ.
  - **Kiểm tra hợp lệ:** file phải tồn tại, đủ lớn, mở được và có bảng dữ liệu. (Xử đúng bug thật: cờ version có thể bị Android Auto Backup khôi phục trong khi file thật đã mất.)
  - **Full-text search (FTS):** dùng bảng FTS nếu có, không thì fallback LIKE; tự dò tên bảng/cột để linh hoạt schema.
- **Sổ tay (backend):** collection `Word`, khoá duy nhất `(user, headword)` — một người không lưu trùng một từ; mọi thao tác lưu dùng upsert.
- **Chung dữ liệu với trợ lý AI:** công cụ "từ cần ôn hôm nay" của chatbot (file `08`) truy vấn **cùng model `Word`** với điều kiện due giống hệt màn ôn.

## 6. Điểm nhấn để trình bày
- Tra 50k+ từ **chi phí 0, không cần mạng** — phù hợp học ở nơi sóng yếu.
- **3 lớp phòng thủ toàn vẹn DB** (versioning + validate + copy nguyên tử) xử đúng bug Android Auto Backup — chi tiết production hiếm gặp.
- SRS phân biệt "nhớ thật" vs "phải học lại".
- Lưu ôn thất bại **không chuyển thẻ** → không mất tiến độ.

## 7. Giới hạn & lưu ý trung thực
- **SRS chạy 100% ở backend**; client chỉ gửi phản hồi + hiển thị lịch.
- SRS là biến thể Ebbinghaus **đơn giản hoá** (level + mảng interval cứng), **không phải SM-2/Anki** (không có ease factor cá thể hoá); `hard` reset thẳng về level 1 (phạt khá nặng).
- `nextReviewDate` tính theo **giờ server**, không theo múi giờ người dùng như một số phần khác.
- Không giới hạn số từ ôn/ngày; đến hạn là hiện hết.

## 8. Dẫn chứng mã nguồn
- SRS + sổ tay: `services/vocabularyService.js:3-69`; model `models/Word.js:3-27`; controller `controllers/vocabController.js:102-132`; feed tiến độ `utils/progressTracker.js:75-77`.
- Từ điển offline: `core/sqflite/dict_db.dart:21-175` (versioning/copy/validate/FTS); UI `feature/vocabulary/dict_demo_page.dart:166-175`, `dict_detail_page.dart:267-287`.
- Ôn tập: `feature/vocabulary/review_session_page.dart:210-266`; bloc `bloc_review/review_bloc.dart:47-78`.
