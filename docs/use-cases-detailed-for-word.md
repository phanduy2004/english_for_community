# Mô tả chi tiết Use case — Nội dung bổ sung & chỉnh sửa cho Word

> **File gốc:** CNTT_N4_PhanTatDuy.docx — mục **2.4.2**  
> **Cách dùng:** Copy từng khối vào Word. Phần **A** sửa UC đã có; **B–E** chèn thêm.  
> **Quy ước:** Mô tả theo góc nhìn người dùng và hệ thống; **không** ghi tên file, API hay mã lập trình trong bảng đặc tả.

---

## A. Chỉnh sửa các UC đã có trong Word

### A.1. Sửa đánh số Guest (2.4.2.1)


| Hiện tại                            | Sửa thành            |
| ----------------------------------- | -------------------- |
| 2.4.2.2.2. Đăng nhập (nằm sai nhóm) | 2.4.2.1.2. Đăng nhập |


---

### A.2. 2.4.2.3.1 — Xem Dashboard Quản trị (thay toàn bộ)

**Tên**  
Xem Dashboard Quản trị

**Mô tả**  
Quản trị viên xem tổng quan hoạt động hệ thống qua các chỉ số thống kê và biểu đồ phân bổ bài nộp theo bốn kỹ năng trong khoảng thời gian được chọn.

**Đối tượng**  
Quản trị viên

**Tiền điều kiện**  
Tài khoản quản trị viên đã đăng nhập thành công và có quyền xem thống kê hệ thống.

**Hậu điều kiện**  
Dữ liệu thống kê được hiển thị trên màn hình Dashboard.

**Luồng cơ bản**  

1. Quản trị viên truy cập trang Dashboard quản trị.
2. Hệ thống truy vấn dữ liệu thống kê theo bộ lọc thời gian (Ngày / Tuần / Tháng; mặc định Tuần).
3. Hệ thống hiển thị bốn chỉ số chính:
  - **Bài nộp:** Tổng số bài học viên đã hoàn thành/nộp trong kỳ (Viết, Nói, Đọc, Nghe — gồm cả nghe chép chính tả và nghe hiểu).  
  - **Chi phí AI (ước tính):** Ước tính dựa trên số từ bài Viết và thời lượng audio bài Nói/Nghe.  
  - **Báo cáo lỗi:** Số báo cáo đang chờ xử lý trong kỳ.  
  - **Người dùng hoạt động:** Số học viên có hoạt động học tập trong kỳ (theo ngày cập nhật hoạt động gần nhất), không phải số người trực tuyến thời gian thực.
4. Hệ thống hiển thị biểu đồ cột chồng phân bổ bài tập theo bốn kỹ năng: Nghe, Nói, Đọc, Viết.
5. Quản trị viên đổi bộ lọc thời gian; hệ thống cập nhật lại chỉ số và biểu đồ.

**Luồng thay thế**  

- Lỗi tải dữ liệu hoặc mất kết nối: Hiển thị thông báo lỗi và nút **Thử lại**.

**Luồng mở rộng**  

- Hiển thị xu hướng tăng/giảm số bài nộp so với kỳ liền trước.

**Bảng 29:** Đặc tả xem Dashboard Quản trị

---

### A.3. 2.4.2.3.2 — Quản lý Người dùng (điều chỉnh)

**Thay đoạn Mô tả:**  
Quản trị viên xem danh sách người dùng, tìm kiếm, lọc, xem chi tiết hồ sơ, thay đổi vai trò (học viên / giáo viên / quản trị), khóa hoặc mở khóa tài khoản. Trạng thái trực tuyến (nếu hiển thị) được cập nhật qua kênh thời gian thực; chỉ số trên Dashboard không dùng số online realtime.

**Thay bước Luồng cơ bản (bước 2–3):**  
2. Quản trị viên mở màn hình Quản lý người dùng; hệ thống hiển thị danh sách phân trang.  
3. (Tùy chọn) Quản trị viên chọn tab/lọc người dùng đang trực tuyến; danh sách tự cập nhật khi có thay đổi trạng thái.

**Thêm Luồng mở rộng:**  

- Thay đổi vai trò người dùng.  
- Xóa mềm hoặc khôi phục tài khoản.  
- Xem chi tiết hồ sơ và lịch sử hoạt động.

---

### A.4. 2.4.2.3.6 — Xử lý Báo cáo lỗi (điều chỉnh)

**Thay trạng thái:**  

- Danh sách ưu tiên báo cáo **đang chờ xử lý** (không dùng nhãn “Mới” nếu khác với hệ thống).  
- Cập nhật trạng thái: **Đã xử lý** hoặc **Từ chối**, kèm phản hồi cho người báo cáo.

---

### A.5. Ghi chú chung cho UC User đã có

Các UC 2.4.2.2.x hiện tại vẫn giữ; bổ sung thêm mục **C** cho lớp học, bài thi, nghe hiểu, đơn giáo viên.  
Trong **Luồng mở rộng** có thể tham chiếu sơ đồ use case mục 2.4.1.2.

---

## B. Bổ sung Guest — chèn vào 2.4.2.1

### 2.4.2.1.3. Tra cứu từ điển offline

**Tên**  
Tra cứu từ điển offline

**Mô tả**  
Khách (chưa đăng nhập) tra cứu nghĩa từ tiếng Anh bằng cơ sở dữ liệu từ điển lưu sẵn trên thiết bị, không cần kết nối máy chủ.

**Đối tượng**  
Khách (Guest)

**Tiền điều kiện**  
Ứng dụng đã cài đặt và dữ liệu từ điển offline sẵn sàng.

**Hậu điều kiện**  
Kết quả tra cứu hiển thị trên màn hình.

**Luồng cơ bản**  

1. Khách mở chức năng Từ điển.
2. Khách nhập từ khóa cần tra.
3. Hệ thống tìm trong cơ sở dữ liệu cục bộ.
4. Hiển thị nghĩa, phiên âm và ví dụ (nếu có).

**Luồng thay thế**  

- Không tìm thấy từ: Hiển thị thông báo không có kết quả.

**Luồng mở rộng**  

- Sau khi đăng nhập: Lưu từ vào kho từ vựng cá nhân (chuyển sang use case học viên).

**Bảng 35:** Đặc tả tra cứu từ điển offline (Guest)

---

### 2.4.2.1.4. Kiểm tra phiên bản ứng dụng

**Tên**  
Kiểm tra phiên bản ứng dụng

**Mô tả**  
Khi mở ứng dụng, hệ thống so sánh phiên bản đang cài với phiên bản mới do quản trị viên công bố và nhắc người dùng cập nhật nếu cần.

**Đối tượng**  
Khách / Học viên

**Tiền điều kiện**  
Thiết bị có kết nối mạng để kiểm tra phiên bản.

**Hậu điều kiện**  
Người dùng biết cần cập nhật hoặc tiếp tục dùng bản hiện tại.

**Luồng cơ bản**  

1. Người dùng khởi động ứng dụng.
2. Hệ thống lấy thông tin phiên bản mới nhất từ máy chủ.
3. Nếu bản cài quá cũ hoặc bắt buộc cập nhật: hiển thị hộp thoại hướng dẫn tải bản mới.

**Luồng thay thế**  

- Không có mạng: Bỏ qua kiểm tra, vào ứng dụng bình thường.

**Luồng mở rộng**  

- Không có

**Bảng 36:** Đặc tả kiểm tra phiên bản ứng dụng

---

## C. Bổ sung User — chèn vào 2.4.2.2 (sau 2.4.2.2.28)

### 2.4.2.2.29. Luyện nghe hiểu (Listening Comprehension)

**Tên**  
Luyện nghe hiểu

**Mô tả**  
Học viên nghe toàn bộ audio bài học và trả lời câu hỏi trắc nghiệm; hệ thống chấm điểm tự động.

**Đối tượng**  
Học viên

**Tiền điều kiện**  
Đã đăng nhập; bài nghe hiểu tồn tại và đang được phát hành.

**Hậu điều kiện**  
Bài làm được lưu; điểm và đáp án hiển thị theo cấu hình bài.

**Luồng cơ bản**  

1. Học viên mở danh sách bài nghe hiểu.
2. Chọn một bài và vào màn hình làm bài.
3. Nghe audio và trả lời từng câu hỏi trắc nghiệm.
4. Học viên nộp bài.
5. Hệ thống hiển thị kết quả.

**Luồng thay thế**  

- Thoát giữa chừng: Bài chưa nộp hoặc không lưu kết quả (tùy thiết kế màn hình).

**Luồng mở rộng**  

- Thuộc use case cha **Luyện tập kỹ năng nghe**.

**Bảng 37:** Đặc tả luyện nghe hiểu

---

### 2.4.2.2.30. Tham gia lớp học

**Tên**  
Tham gia lớp học

**Mô tả**  
Học viên tham gia lớp do giáo viên tạo bằng mã mời hoặc liên kết mời; xem danh sách lớp đã tham gia và các bài thi được giao.

**Đối tượng**  
Học viên

**Tiền điều kiện**  
Đã đăng nhập; có mã lớp hoặc liên kết mời hợp lệ.

**Hậu điều kiện**  
Học viên trở thành thành viên lớp (chờ duyệt hoặc đã được duyệt, tùy cấu hình lớp).

**Luồng cơ bản**  

1. Học viên mở màn hình **Lớp của tôi**.
2. Nhập mã lớp hoặc mở liên kết mời.
3. Hệ thống ghi nhận tham gia; nếu lớp yêu cầu duyệt, học viên chờ giáo viên chấp thuận.
4. Học viên xem chi tiết lớp: bài thi được giao, thông báo liên quan.

**Luồng thay thế**  

- Mã hoặc liên kết sai/hết hạn: Hiển thị thông báo lỗi.  
- Đã là thành viên: Chuyển thẳng vào lớp.

**Luồng mở rộng**  

- Tham gia bằng mã mời.  
- Tham gia bằng liên kết mời.  
- Xem danh sách lớp đã ghi danh.

**Bảng 38:** Đặc tả tham gia lớp học

---

### 2.4.2.2.31. Làm bài thi

**Tên**  
Làm bài thi

**Mô tả**  
Học viên làm bài thi do giáo viên giao, tham gia phiên thi trực tiếp hoặc thi qua liên kết công khai; nộp bài và xem kết quả khi được công bố.

**Đối tượng**  
Học viên

**Tiền điều kiện**  
Đã đăng nhập (một số liên kết công khai có thể yêu cầu đăng nhập sau); bài thi còn hiệu lực và chưa quá hạn.

**Hậu điều kiện**  
Bài làm được ghi nhận trạng thái đã nộp hoặc đã chấm, tùy loại đề.

**Luồng cơ bản**  

1. Học viên mở bài thi từ lớp học hoặc danh sách bài được giao.
2. Vào phòng chờ nếu là phiên thi trực tiếp, hoặc vào thẳng màn hình làm bài.
3. Học viên trả lời các phần: trắc nghiệm, tự luận, nghe, nói… theo cấu hình đề.
4. Học viên nộp bài.
5. Xem điểm và nhận xét khi giáo viên công bố kết quả.

**Luồng thay thế**  

- Hết thời gian làm bài: Hệ thống tự khóa hoặc tự nộp bài.  
- Bị giáo viên mời rời phiên thi trực tiếp: Thoát màn hình làm bài.

**Luồng mở rộng**  

- Làm bài thi được giao trong lớp.  
- Tham gia phiên thi trực tiếp.  
- Tham gia thi qua liên kết công khai.  
- Xem kết quả bài thi sau khi được công bố.

**Bảng 39:** Đặc tả làm bài thi

---

### 2.4.2.2.32. Nộp đơn trở thành giáo viên

**Tên**  
Nộp đơn trở thành giáo viên

**Mô tả**  
Học viên gửi đơn xin được cấp quyền giáo viên, theo dõi trạng thái duyệt và có thể rút đơn khi còn chờ xử lý.

**Đối tượng**  
Học viên

**Tiền điều kiện**  
Đang là tài khoản học viên; chưa có quyền giáo viên hoặc quản trị.

**Hậu điều kiện**  
Đơn ở trạng thái chờ duyệt, đã duyệt, bị từ chối hoặc đã rút.

**Luồng cơ bản**  

1. Học viên mở trang **Đăng ký làm giáo viên**.
2. Điền thông tin theo yêu cầu và gửi đơn.
3. Hệ thống xác nhận đã tiếp nhận; học viên xem trạng thái đơn trên cùng màn hình.

**Luồng thay thế**  

- Quản trị viên từ chối: Học viên nhận thông báo và có thể nộp lại (theo quy định).

**Luồng mở rộng**  

- Rút đơn khi còn chờ duyệt.  
- Xem trạng thái đơn.

**Bảng 40:** Đặc tả nộp đơn trở thành giáo viên

---

### 2.4.2.2.33. Xem bảng xếp hạng

**Tên**  
Xem bảng xếp hạng

**Mô tả**  
Học viên xem thứ hạng điểm kinh nghiệm so với người học khác trong hệ thống gamification.

**Đối tượng**  
Học viên

**Tiền điều kiện**  
Đã đăng nhập.

**Hậu điều kiện**  
Danh sách xếp hạng và vị trí của bản thân được hiển thị.

**Luồng cơ bản**  

1. Học viên mở màn hình Tiến độ hoặc Bảng xếp hạng.
2. Hệ thống tải danh sách người có điểm cao nhất.
3. Hiển thị thứ hạng của học viên hiện tại.

**Luồng thay thế**  

- Lỗi mạng: Hiển thị thông báo lỗi hoặc dữ liệu đã lưu tạm (nếu có).

**Luồng mở rộng**  

- Xem thông tin công khai của người học khác trên bảng xếp hạng.

**Bảng 41:** Đặc tả xem bảng xếp hạng

---

## D. Nhóm Teacher — chèn mục 2.4.2.4

> Giáo viên **kế thừa** toàn bộ use case Học viên (2.4.2.2). Phần dưới mô tả chức năng bổ sung khi tài khoản có vai trò giáo viên.

---

### 2.4.2.4.1. Xem Dashboard giáo viên

**Tên**  
Xem Dashboard giáo viên

**Mô tả**  
Giáo viên xem tổng quan số lớp, bài đã giao, phiên thi trực tiếp, đề nháp/đã xuất bản, bài chờ chấm; truy cập nhanh các chức năng chính.

**Đối tượng**  
Giáo viên

**Tiền điều kiện**  
Tài khoản giáo viên đã đăng nhập thành công.

**Hậu điều kiện**  
Dashboard hiển thị tổng hợp và danh sách việc cần làm.

**Luồng cơ bản**  

1. Giáo viên mở trang Dashboard giáo viên.
2. Hệ thống tải danh sách lớp, đề thi, bài đã giao và hàng đợi chấm bài.
3. Hệ thống hiển thị các việc cần làm: hạn nộp sắp tới, bài chờ chấm, phiên thi sắp diễn ra.
4. Hiển thị thẻ tổng quan: số lớp, số bài đang giao, phiên trực tiếp, đề nháp/đã xuất bản, số bài cần chấm.
5. Giáo viên chọn lối tắt: Ngân hàng đề, Tạo đề mới, Lịch biểu, v.v.

**Luồng thay thế**  

- Chưa có lớp hoặc đề: Hiển thị gợi ý tạo mới.

**Luồng mở rộng**  

- Xem thống kê lớp và bài thi.  
- Xem lịch hạn nộp và phiên thi.

**Bảng 42:** Đặc tả xem Dashboard giáo viên

---

### 2.4.2.4.2. Quản lý lớp học

**Tên**  
Quản lý lớp học

**Mô tả**  
Giáo viên tạo, chỉnh sửa, lưu trữ lớp; quản lý mã mời; duyệt học sinh; thêm giáo viên đồng hành; xem hoạt động lớp và giao bài thi.

**Đối tượng**  
Giáo viên

**Tiền điều kiện**  
Tài khoản có quyền quản lý lớp học.

**Hậu điều kiện**  
Thông tin lớp và thành viên được cập nhật trên hệ thống.

**Luồng cơ bản**  

1. Giáo viên mở danh sách lớp hoặc chi tiết một lớp.
2. **Tạo lớp:** Nhập tên, mô tả, cấu hình có/không duyệt thành viên mới.
3. **Chia sẻ mã mời:** Hiển thị mã hoặc liên kết; có thể đổi mã mới khi cần.
4. **Duyệt học sinh:** Chấp thuận hoặc từ chối yêu cầu tham gia.
5. **Giáo viên đồng hành:** Tìm và thêm hoặc gỡ giáo viên phụ trách chung.
6. **Lưu trữ lớp:** Ẩn lớp khỏi danh sách đang hoạt động.

**Luồng thay thế**  

- Gỡ học sinh khỏi lớp: Cập nhật danh sách thành viên.

**Luồng mở rộng**  

- Tạo và chỉnh sửa thông tin lớp.  
- Lưu trữ lớp và đổi mã mời.  
- Duyệt học sinh vào lớp.  
- Quản lý giáo viên đồng hành.  
- Xem hoạt động gần đây trong lớp.

**Bảng 43:** Đặc tả quản lý lớp học

---

### 2.4.2.4.3. Quản lý ngân hàng đề thi

**Tên**  
Quản lý ngân hàng đề thi

**Mô tả**  
Giáo viên tạo đề thi nháp (một kỹ năng hoặc đề tích hợp), soạn câu hỏi, xuất bản, lưu trữ, nhân bản; có thể dùng trợ lý AI gợi ý đề bài Viết.

**Đối tượng**  
Giáo viên

**Tiền điều kiện**  
Tài khoản có quyền quản lý đề thi.

**Hậu điều kiện**  
Đề ở trạng thái nháp, đã xuất bản hoặc đã lưu trữ.

**Luồng cơ bản**  

1. Giáo viên mở Ngân hàng đề thi.
2. Tạo đề mới hoặc mở đề tích hợp để soạn.
3. Thêm câu trắc nghiệm, câu tự luận; cấu hình thời gian và quy tắc công bố điểm.
4. (Tùy chọn) Yêu cầu AI gợi ý chủ đề/câu hỏi Viết.
5. Xuất bản đề để dùng giao bài.
6. Lưu trữ, khôi phục hoặc xóa đề khi không còn dùng.

**Luồng thay thế**  

- Xuất bản khi thiếu nội dung bắt buộc: Hệ thống báo lỗi và yêu cầu bổ sung.

**Luồng mở rộng**  

- Nhân bản đề thi có sẵn.  
- Xuất bản và lưu trữ đề.

**Bảng 44:** Đặc tả quản lý ngân hàng đề thi

---

### 2.4.2.4.4. Giao bài thi

**Tên**  
Giao bài thi

**Mô tả**  
Giáo viên gán đề đã xuất bản cho lớp; cấu hình hạn nộp, chế độ thi trực tiếp; tạo liên kết thi công khai; lưu mẫu giao bài để tái sử dụng.

**Đối tượng**  
Giáo viên

**Tiền điều kiện**  
Có ít nhất một đề đã xuất bản; có quyền giao bài thi.

**Hậu điều kiện**  
Bài thi được giao; học sinh thấy trên ứng dụng.

**Luồng cơ bản**  

1. Giáo viên chọn **Giao bài** từ lớp hoặc Dashboard.
2. Chọn đề, lớp (hoặc phạm vi), hạn nộp và tùy chọn phiên trực tiếp.
3. Xác nhận giao bài.
4. Học sinh nhận thông báo và thấy bài trên danh sách.

**Luồng thay thế**  

- Sửa thông tin giao bài khi phiên chưa bắt đầu.  
- Đóng bài giao khi không còn cho làm.

**Luồng mở rộng**  

- Giao bài cho lớp cụ thể.  
- Tạo liên kết thi công khai.  
- Lưu và dùng lại mẫu giao bài.

**Bảng 45:** Đặc tả giao bài thi

---

### 2.4.2.4.5. Điều hành phiên thi realtime

**Tên**  
Điều hành phiên thi trực tiếp

**Mô tả**  
Giáo viên mở phiên thi trực tiếp, chờ học sinh ở phòng chờ, bắt đầu/kết thúc phiên, giám sát tiến độ, xem màn hình học sinh, mời rời phiên nếu vi phạm.

**Đối tượng**  
Giáo viên

**Tiền điều kiện**  
Bài giao ở chế độ thi trực tiếp; giáo viên là chủ lớp hoặc giáo viên đồng hành.

**Hậu điều kiện**  
Phiên chuyển trạng thái: chờ → đang diễn ra → đã kết thúc; bài làm được đồng bộ.

**Luồng cơ bản**  

1. Giáo viên mở bảng điều khiển phiên thi.
2. **Phòng chờ:** Học sinh vào chờ; danh sách có mặt cập nhật theo thời gian thực.
3. Giáo viên **Bắt đầu** — học sinh vào làm bài đồng thời.
4. **Giám sát:** Theo dõi tiến độ từng học sinh.
5. **Xem màn hình học sinh:** Xem nội dung học sinh đang làm (nếu bật).
6. **Kết thúc phiên** hoặc **mời học sinh rời** khi cần.

**Luồng thay thế**  

- Học sinh mất kết nối: Hiển thị trạng thái ngắt kết nối trên bảng giám sát.

**Luồng mở rộng**  

- Tạo phiên thi, phòng chờ, bắt đầu/kết thúc, giám sát, xem màn hình, mời rời phiên.

**Bảng 46:** Đặc tả điều hành phiên thi trực tiếp

---

### 2.4.2.4.6. Chấm điểm và công bố kết quả

**Tên**  
Chấm điểm và công bố kết quả

**Mô tả**  
Giáo viên xem bài nộp, chấm thủ công hoặc nhờ AI hỗ trợ, chấm hàng loạt, công bố điểm, xuất sổ điểm, xem báo cáo trung thực thi.

**Đối tượng**  
Giáo viên

**Tiền điều kiện**  
Có quyền chấm bài; có bài đã nộp.

**Hậu điều kiện**  
Điểm và nhận xét được lưu; học sinh xem được sau khi công bố.

**Luồng cơ bản**  

1. Giáo viên mở màn hình Chấm bài hoặc Trung tâm chấm điểm.
2. Chọn bài đã giao → danh sách bài nộp.
3. Mở từng bài: xem nội dung, nhập điểm và nhận xét.
4. (Tùy chọn) Dùng AI hỗ trợ chấm phần Viết/Nói.
5. Công bố kết quả theo quy tắc đề thi.
6. Xuất sổ điểm ra file bảng tính nếu cần.

**Luồng thay thế**  

- Bài chưa nộp: Không cho chấm.

**Luồng mở rộng**  

- Chấm thủ công, AI hỗ trợ, chấm hàng loạt, công bố và chốt điểm, xuất sổ điểm, báo cáo trung thực thi.

**Bảng 47:** Đặc tả chấm điểm và công bố kết quả

---

### 2.4.2.4.7. Xem sổ điểm lớp

**Tên**  
Xem sổ điểm lớp

**Mô tả**  
Giáo viên xem ma trận điểm theo học sinh và bài đã giao trong một lớp; lọc và xuất dữ liệu.

**Đối tượng**  
Giáo viên

**Tiền điều kiện**  
Giáo viên có quyền trên lớp đó.

**Hậu điều kiện**  
Sổ điểm hiển thị đúng dữ liệu đã chấm và đã công bố.

**Luồng cơ bản**  

1. Từ chi tiết lớp, giáo viên mở **Sổ điểm**.
2. Hệ thống tải điểm các bài đã giao trong lớp.
3. Giáo viên lọc theo bài hoặc theo học sinh; xuất file nếu cần.

**Luồng thay thế**  

- Chưa giao bài nào: Hiển thị trạng thái trống.

**Luồng mở rộng**  

- Chuyển sang chấm chi tiết từng bài nộp.

**Bảng 48:** Đặc tả xem sổ điểm lớp

---

## E. Bổ sung Admin — chèn vào 2.4.2.3 (sau 2.4.2.3.6)

### 2.4.2.3.7. Quản lý bài nghe hiểu

**Tên**  
Quản lý bài nghe hiểu (CMS)

**Mô tả**  
Quản trị viên thêm, sửa, xóa bài nghe hiểu: file audio, câu hỏi trắc nghiệm, mức độ, trạng thái phát hành.

**Đối tượng**  
Quản trị viên

**Tiền điều kiện**  
Có quyền quản trị nội dung; truy cập module Nghe hiểu trên trang quản trị.

**Hậu điều kiện**  
Bài hiển thị trên ứng dụng học viên (khi đã phát hành).

**Luồng cơ bản**  

1. Quản trị viên mở danh sách bài nghe hiểu.
2. Thêm mới hoặc sửa bài → màn hình biên tập.
3. Nhập tiêu đề, liên kết audio, danh sách câu hỏi và đáp án.
4. Lưu và phát hành bài.

**Luồng thay thế**  

- Thiếu audio hoặc câu hỏi: Hệ thống báo lỗi, không cho lưu.

**Luồng mở rộng**  

- Thuộc use case cha **Quản lý nội dung học tập**.

**Bảng 49:** Đặc tả quản lý bài nghe hiểu

---

### 2.4.2.3.8. Quản lý bài nói

**Tên**  
Quản lý bài nói (CMS)

**Mô tả**  
Quản trị viên tạo và sửa bộ bài luyện nói: câu mẫu, audio tham chiếu, cấu hình chấm điểm bằng AI.

**Đối tượng**  
Quản trị viên

**Tiền điều kiện**  
Truy cập module Nói trên trang quản trị nội dung.

**Hậu điều kiện**  
Bộ bài nói sẵn sàng cho học viên luyện tập.

**Luồng cơ bản**  

1. Quản trị viên mở danh sách bài nói.
2. Vào màn hình biên tập — thêm câu, tải hoặc gắn audio.
3. Lưu thay đổi.

**Luồng thay thế**  

- Xóa bài đã có người làm: Hệ thống cảnh báo hoặc không cho xóa.

**Luồng mở rộng**  

- Thêm, sửa, xóa bộ bài nói.

**Bảng 50:** Đặc tả quản lý bài nói

---

### 2.4.2.3.9. Duyệt đơn giáo viên

**Tên**  
Duyệt đơn giáo viên

**Mô tả**  
Quản trị viên xem đơn xin làm giáo viên, duyệt hoặc từ chối; cấp quyền giáo viên khi duyệt.

**Đối tượng**  
Quản trị viên

**Tiền điều kiện**  
Truy cập màn hình Duyệt đơn giáo viên.

**Hậu điều kiện**  
Đơn được duyệt hoặc từ chối; người được duyệt có vai trò giáo viên.

**Luồng cơ bản**  

1. Quản trị viên xem danh sách đơn chờ duyệt.
2. Xem chi tiết hồ sơ ứng viên.
3. **Duyệt:** Cập nhật vai trò và gửi thông báo.
4. **Từ chối:** Ghi lý do và thông báo cho người nộp đơn.

**Luồng thay thế**  

- Đơn đã bị rút: Không thao tác.

**Luồng mở rộng**  

- Duyệt đơn; Từ chối đơn.

**Bảng 51:** Đặc tả duyệt đơn giáo viên

---

### 2.4.2.3.10. Quản lý phát hành ứng dụng

**Tên**  
Quản lý phát hành ứng dụng

**Mô tả**  
Quản trị viên duyệt bản cài mới, lên lịch phát hành, quay lại phiên bản cũ; ứng dụng học viên tự kiểm tra và nhắc cập nhật.

**Đối tượng**  
Quản trị viên

**Tiền điều kiện**  
Truy cập màn hình Quản lý phát hành.

**Hậu điều kiện**  
Phiên bản đang áp dụng thay đổi; người dùng nhận nhắc cập nhật phù hợp.

**Luồng cơ bản**  

1. Quản trị viên xem danh sách bản cài chờ duyệt.
2. Duyệt bản mới — cấu hình phiên bản tối thiểu, ghi chú, đường dẫn tải.
3. Phát hành ngay hoặc lên lịch.
4. Quay lại phiên bản trước nếu phát hiện lỗi.

**Luồng thay thế**  

- Bản cài từ hệ thống tích hợp lỗi: Không đưa vào hàng đợi duyệt.

**Luồng mở rộng**  

- Tự phát hành theo lịch; quay lại phiên bản cũ (tác nhân Hệ thống).

**Bảng 52:** Đặc tả quản lý phát hành ứng dụng

---

### 2.4.2.3.11. Xem lịch sử hoạt động học viên

**Tên**  
Xem lịch sử hoạt động học viên

**Mô tả**  
Quản trị viên tra cứu lịch sử làm bài và hoạt động của học viên để hỗ trợ kiểm duyệt và giám sát.

**Đối tượng**  
Quản trị viên

**Tiền điều kiện**  
Truy cập màn hình Lịch sử hoạt động hoặc chi tiết người dùng.

**Hậu điều kiện**  
Danh sách hoạt động hiển thị theo bộ lọc.

**Luồng cơ bản**  

1. Quản trị viên tìm học viên theo email hoặc tên.
2. Xem dòng thời gian: bài nộp, đăng nhập, báo cáo…
3. Xuất báo cáo dạng bảng nếu cần.

**Luồng thay thế**  

- Không tìm thấy người dùng: Hiển thị thông báo.

**Luồng mở rộng**  

- Liên kết nhật ký kiểm tra của quản trị viên.

**Bảng 53:** Đặc tả xem lịch sử hoạt động học viên

---

## F. Gợi ý mục lục Word

- 2.4.2.1.3 – 2.4.2.1.4 (Guest)  
- 2.4.2.2.29 – 2.4.2.2.33 (User)  
- 2.4.2.4.1 – 2.4.2.4.7 (Teacher)  
- 2.4.2.3.7 – 2.4.2.3.11 (Admin)

Sơ đồ 2.4.1: tham chiếu tài liệu use case UML trong thư mục docs của dự án.

---

## G. Bảng tổng hợp


| Nhóm                 | Cũ     | Bổ sung | Tổng   |
| -------------------- | ------ | ------- | ------ |
| Guest                | 2      | +2      | 4      |
| User                 | 28     | +5      | 33     |
| Teacher              | 0      | +7      | 7      |
| Admin                | 6      | +5      | 11     |
| **Tổng bảng đặc tả** | **36** | **+19** | **55** |


---

*Quy ước văn phong: mô tả hành vi người dùng và phản hồi hệ thống; chi tiết kỹ thuật triển khai (API, mã nguồn) nêu ở chương Thiết kế / Cài đặt.*