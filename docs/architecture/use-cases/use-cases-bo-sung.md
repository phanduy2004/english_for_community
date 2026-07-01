# Các Use Case BỔ SUNG cho báo cáo (mục 2.4.2)

> File này chỉ chứa **những use case CHƯA có** trong bản đặc tả hiện tại của báo cáo.
> Mỗi bảng đã viết đúng định dạng đặc tả của báo cáo (Tên / Mô tả / Đối tượng / Tiền điều kiện / Hậu điều kiện / Luồng cơ bản / Luồng thay thế / Luồng mở rộng) — **copy thẳng vào Word**.
> Đối chiếu: báo cáo (mục 2.4.2) ✗ thiếu ⟶ hệ thống thực tế ([use-cases-uml.md](./use-cases-uml.md)).

## Bảng đối chiếu — cái nào THIẾU

| Tác nhân | Đã có trong báo cáo | **Còn thiếu (file này bổ sung)** |
|----------|---------------------|----------------------------------|
| **Guest** | Đăng ký, Đăng nhập, Tra từ điển, Kiểm tra phiên bản | **Xem trước bài thi công khai** |
| **User** | Profile, Từ vựng, Nghe, Đọc, Viết, Nói (read-aloud), Dashboard, AI Tutor, Tham gia lớp, Làm bài thi | **Quên mật khẩu · Đăng nhập Google · Xóa tài khoản · Luyện nói tự do với AI (VAPI) · Gửi báo cáo sự cố · Nộp đơn giáo viên · Phản hồi mời co-teacher** |
| **Teacher** | ❌ *(báo cáo mới có sơ đồ, chưa có đặc tả nào)* | **Toàn bộ 6 UC: Quản lý lớp · Ngân hàng đề · Giao bài · Phiên thi realtime · Chấm điểm & công bố · Dashboard GV** |
| **Admin** | Dashboard, Quản lý user+online, Reading/Listening/Writing CMS, Xử lý báo cáo | **Quản lý nội dung Nói (Speaking CMS) · Duyệt đơn giáo viên · Phân quyền & vòng đời tài khoản · Quản lý phát hành app · Giám sát & kiểm toán** |
| **System** | ❌ *(chưa có đặc tả)* | **Gửi thông báo thông minh · Hết hạn bài thi · Tự phát hành app theo lịch · Nhận bản build CI/CD** |

---

# A. GUEST

## A1. Xem trước bài thi công khai

| Mục | Nội dung |
|-----|----------|
| **Tên** | Xem trước bài thi công khai |
| **Mô tả** | Khách mở liên kết thi công khai do giáo viên chia sẻ để xem thông tin bài thi (tiêu đề, số câu, thời lượng) trước khi quyết định đăng nhập để làm. |
| **Đối tượng** | Khách (Guest) |
| **Tiền điều kiện** | Có liên kết công khai hợp lệ và bài thi chưa hết hạn. |
| **Hậu điều kiện** | Khách xem được thông tin tổng quan; được mời đăng nhập/đăng ký để bắt đầu làm. |
| **Luồng cơ bản** | 1) Khách mở link công khai. 2) Hệ thống kiểm tra token liên kết còn hiệu lực. 3) Hiển thị thông tin bài thi và nút "Bắt đầu". 4) Khi nhấn Bắt đầu, hệ thống yêu cầu đăng nhập (nếu cấu hình bắt buộc). |
| **Luồng thay thế** | Link hết hạn/không hợp lệ: hiển thị thông báo "Bài thi không còn khả dụng". |
| **Luồng mở rộng** | Sau khi đăng nhập → chuyển sang use case **Làm bài thi** (User). |

---

# B. USER (Học viên)

## B1. Quên mật khẩu

| Mục | Nội dung |
|-----|----------|
| **Tên** | Quên mật khẩu |
| **Mô tả** | Người dùng đặt lại mật khẩu thông qua mã OTP gửi về email đã đăng ký. |
| **Đối tượng** | Người dùng có tài khoản |
| **Tiền điều kiện** | Email tồn tại và đã được xác thực trong hệ thống. |
| **Hậu điều kiện** | Mật khẩu được đặt lại; người dùng đăng nhập bằng mật khẩu mới. |
| **Luồng cơ bản** | 1) Chọn "Quên mật khẩu". 2) Nhập email. 3) Hệ thống gửi OTP về email. 4) Nhập OTP. 5) Nhập mật khẩu mới và xác nhận. 6) Hệ thống cập nhật mật khẩu, báo thành công. |
| **Luồng thay thế** | Email không tồn tại: báo lỗi. OTP sai/hết hạn: cho phép gửi lại OTP. |
| **Luồng mở rộng** | `<<extend>>` của **Đăng nhập**. |

## B2. Đăng nhập bằng Google

| Mục | Nội dung |
|-----|----------|
| **Tên** | Đăng nhập bằng Google |
| **Mô tả** | Người dùng đăng nhập/đăng ký nhanh bằng tài khoản Google (OAuth). |
| **Đối tượng** | Người dùng |
| **Tiền điều kiện** | Thiết bị có kết nối mạng và tài khoản Google hợp lệ. |
| **Hậu điều kiện** | Người dùng được xác thực; nếu là lần đầu, hệ thống tạo hồ sơ mới. |
| **Luồng cơ bản** | 1) Chọn "Đăng nhập với Google". 2) Chọn tài khoản Google. 3) Hệ thống xác thực token Google với máy chủ. 4) Tạo phiên đăng nhập và vào trang chủ. |
| **Luồng thay thế** | Người dùng hủy cấp quyền: quay lại màn hình đăng nhập. |
| **Luồng mở rộng** | `<<extend>>` của **Đăng nhập**. |

## B3. Xóa tài khoản

| Mục | Nội dung |
|-----|----------|
| **Tên** | Xóa tài khoản |
| **Mô tả** | Người dùng yêu cầu xóa vĩnh viễn tài khoản và dữ liệu cá nhân khỏi hệ thống. |
| **Đối tượng** | Người dùng đã đăng nhập |
| **Tiền điều kiện** | Người dùng đang ở trang quản lý tài khoản. |
| **Hậu điều kiện** | Tài khoản bị xóa/vô hiệu hóa; người dùng bị đăng xuất. |
| **Luồng cơ bản** | 1) Chọn "Xóa tài khoản". 2) Hệ thống hiển thị cảnh báo và yêu cầu xác nhận. 3) Người dùng xác nhận. 4) Hệ thống xóa dữ liệu, hủy phiên và quay về màn hình đăng nhập. |
| **Luồng thay thế** | Người dùng hủy thao tác: đóng hộp thoại, không thay đổi. |
| **Luồng mở rộng** | Không có. |

## B4. Luyện nói tự do với Trợ lý AI (Voice-to-Voice)

| Mục | Nội dung |
|-----|----------|
| **Tên** | Luyện nói tự do với Trợ lý AI |
| **Mô tả** | Người dùng hội thoại bằng giọng nói thời gian thực với trợ lý AI (VAPI) để luyện phản xạ nói; khác với luyện phát âm theo câu mẫu. |
| **Đối tượng** | Người dùng đã đăng nhập |
| **Tiền điều kiện** | Có mạng, đã cấp quyền micro. |
| **Hậu điều kiện** | Phiên hội thoại kết thúc; ghi nhận thời lượng luyện nói. |
| **Luồng cơ bản** | 1) Mở mục "Luyện nói cùng AI". 2) Bắt đầu phiên, AI mở đầu hội thoại. 3) Người dùng nói; AI nghe (speech-to-text), phản hồi bằng giọng nói (text-to-speech). 4) Hội thoại tiếp diễn theo lượt. 5) Người dùng kết thúc phiên. |
| **Luồng thay thế** | Mất mạng/lỗi micro: hiển thị thông báo và dừng phiên an toàn. |
| **Luồng mở rộng** | `<<extend>>` của **Luyện tập Nói**. |

## B5. Gửi báo cáo sự cố

| Mục | Nội dung |
|-----|----------|
| **Tên** | Gửi báo cáo sự cố |
| **Mô tả** | Người dùng báo lỗi nội dung/ứng dụng kèm mô tả và ảnh chụp màn hình để quản trị viên xử lý. |
| **Đối tượng** | Người dùng đã đăng nhập |
| **Tiền điều kiện** | Đang sử dụng ứng dụng. |
| **Hậu điều kiện** | Báo cáo được lưu vào hàng đợi xử lý của Admin. |
| **Luồng cơ bản** | 1) Mở chức năng "Báo cáo sự cố". 2) Nhập mô tả, chọn loại lỗi. 3) Đính kèm ảnh (tùy chọn). 4) Gửi. 5) Hệ thống lưu báo cáo, báo "Đã gửi". |
| **Luồng thay thế** | Thiếu mô tả: yêu cầu nhập trước khi gửi. |
| **Luồng mở rộng** | Liên kết tới use case Admin **Xử lý báo cáo người dùng**. |

## B6. Nộp đơn trở thành giáo viên

| Mục | Nội dung |
|-----|----------|
| **Tên** | Nộp đơn trở thành giáo viên |
| **Mô tả** | Học viên gửi đơn xin nâng quyền lên giáo viên kèm thông tin minh chứng; có thể theo dõi trạng thái hoặc rút đơn. |
| **Đối tượng** | Người dùng đã đăng nhập (role = user) |
| **Tiền điều kiện** | Chưa phải giáo viên và không có đơn đang chờ duyệt. |
| **Hậu điều kiện** | Đơn ở trạng thái "Chờ duyệt"; khi được duyệt, role chuyển thành teacher. |
| **Luồng cơ bản** | 1) Mở "Đăng ký làm giáo viên". 2) Điền thông tin/đính kèm minh chứng. 3) Gửi đơn. 4) Hệ thống lưu đơn trạng thái "Chờ duyệt". 5) Người dùng xem trạng thái đơn. |
| **Luồng thay thế** | Đã có đơn chờ: chặn nộp mới. Rút đơn: chuyển trạng thái "Đã hủy". |
| **Luồng mở rộng** | `<<extend>>` Xem trạng thái đơn · Rút đơn. Liên kết Admin **Duyệt đơn giáo viên**. |

## B7. Phản hồi lời mời đồng giảng (Co-teacher)

| Mục | Nội dung |
|-----|----------|
| **Tên** | Phản hồi lời mời co-teacher |
| **Mô tả** | Người dùng nhận lời mời làm đồng giáo viên của một lớp và chọn chấp nhận hoặc từ chối. |
| **Đối tượng** | Người dùng được mời (thường là teacher) |
| **Tiền điều kiện** | Có lời mời co-teacher trong thông báo. |
| **Hậu điều kiện** | Nếu chấp nhận, người dùng được thêm vào lớp với vai trò đồng giảng. |
| **Luồng cơ bản** | 1) Mở thông báo lời mời. 2) Xem thông tin lớp. 3) Chọn "Chấp nhận" hoặc "Từ chối". 4) Hệ thống cập nhật danh sách giáo viên của lớp và thông báo cho người mời. |
| **Luồng thay thế** | Lời mời đã hết hạn/bị thu hồi: báo không còn hiệu lực. |
| **Luồng mở rộng** | `<<extend>>` của **Quản lý thông báo**. |

---

# C. TEACHER (Giáo viên) — *toàn bộ phần này chưa có trong báo cáo*

> Teacher kế thừa mọi use case của User; dưới đây là phần nghiệp vụ bổ sung khi `role = teacher`.

## C1. Quản lý lớp học

| Mục | Nội dung |
|-----|----------|
| **Tên** | Quản lý lớp học |
| **Mô tả** | Giáo viên tạo và quản trị vòng đời lớp học cùng danh sách thành viên. |
| **Đối tượng** | Giáo viên |
| **Tiền điều kiện** | Đã đăng nhập với quyền giáo viên. |
| **Hậu điều kiện** | Lớp được tạo/cập nhật; thành viên và đồng giảng được quản lý. |
| **Luồng cơ bản** | 1) Tạo lớp (tên, mô tả, chế độ duyệt). 2) Hệ thống sinh mã mời/liên kết. 3) Duyệt học sinh xin vào (nếu bật duyệt). 4) Mời/quản lý co-teacher. 5) Xem hoạt động lớp. |
| **Luồng thay thế** | Lưu trữ lớp: lớp chuyển trạng thái archived, đổi mã mời để vô hiệu link cũ. |
| **Luồng mở rộng** | `<<extend>>` Tạo/sửa lớp · Lưu trữ & đổi mã mời · Duyệt học sinh · Quản lý co-teacher · Xem hoạt động lớp. |

## C2. Quản lý ngân hàng đề thi

| Mục | Nội dung |
|-----|----------|
| **Tên** | Quản lý ngân hàng đề thi |
| **Mô tả** | Giáo viên soạn, lưu, xuất bản và tái sử dụng các đề thi. |
| **Đối tượng** | Giáo viên |
| **Tiền điều kiện** | Đã đăng nhập với quyền giáo viên. |
| **Hậu điều kiện** | Đề thi được lưu ở trạng thái nháp/đã xuất bản, sẵn sàng để giao. |
| **Luồng cơ bản** | 1) Tạo đề nháp (chọn kỹ năng, thêm câu hỏi). 2) (Tùy chọn) Dùng AI gợi ý đề writing. 3) Xuất bản đề. 4) Nhân bản đề có sẵn để chỉnh sửa nhanh. |
| **Luồng thay thế** | Lưu trữ đề cũ: chuyển trạng thái archived. |
| **Luồng mở rộng** | `<<extend>>` Tạo đề nháp · Xuất bản/lưu trữ · AI gợi ý đề writing · Nhân bản đề. |

## C3. Giao bài thi

| Mục | Nội dung |
|-----|----------|
| **Tên** | Giao bài thi |
| **Mô tả** | Giáo viên phân phối đề thi cho lớp hoặc qua liên kết công khai, thiết lập thời hạn và cấu hình làm bài. |
| **Đối tượng** | Giáo viên |
| **Tiền điều kiện** | Có đề thi đã xuất bản và (với giao cho lớp) có lớp học. |
| **Hậu điều kiện** | Bài thi được giao (assignment) và học sinh nhận được. |
| **Luồng cơ bản** | 1) Chọn đề và đối tượng (lớp / link công khai). 2) Thiết lập thời hạn, thời lượng, số lần làm. 3) (Tùy chọn) Lưu preset để tái sử dụng. 4) Xác nhận giao. 5) Hệ thống thông báo cho học sinh. |
| **Luồng thay thế** | Đóng/sửa assignment đang mở: cập nhật trạng thái hoặc cấu hình. |
| **Luồng mở rộng** | `<<extend>>` Giao cho lớp · Tạo link công khai · Đóng/sửa assignment · Lưu preset. |

## C4. Điều hành phiên thi realtime

| Mục | Nội dung |
|-----|----------|
| **Tên** | Điều hành phiên thi trực tiếp |
| **Mô tả** | Giáo viên tổ chức một phiên thi đồng bộ thời gian thực, giám sát học sinh và kiểm soát tiến trình qua kết nối socket. |
| **Đối tượng** | Giáo viên |
| **Tiền điều kiện** | Có bài thi cấu hình ở chế độ realtime. |
| **Hậu điều kiện** | Phiên thi kết thúc; bài làm được thu để chấm. |
| **Luồng cơ bản** | 1) Tạo phiên thi, mở phòng chờ (lobby). 2) Học sinh vào lobby. 3) Giáo viên bắt đầu phiên. 4) Theo dõi tiến độ qua live monitor, xem màn hình từng học sinh. 5) Kết thúc phiên, hệ thống tự thu bài. |
| **Luồng thay thế** | Đuổi học sinh vi phạm khỏi phiên; học sinh mất kết nối có thể vào lại trước khi hết giờ. |
| **Luồng mở rộng** | `<<extend>>` Tạo phiên & lobby · Bắt đầu/kết thúc · Live monitor · Xem màn hình học sinh · Đuổi học sinh. |

## C5. Chấm điểm và công bố kết quả

| Mục | Nội dung |
|-----|----------|
| **Tên** | Chấm điểm và công bố kết quả |
| **Mô tả** | Giáo viên chấm bài nộp (thủ công hoặc có AI hỗ trợ), kiểm tra dấu hiệu gian lận, công bố và xuất điểm. |
| **Đối tượng** | Giáo viên |
| **Tiền điều kiện** | Bài thi đã được giao và có bài nộp. |
| **Hậu điều kiện** | Điểm được chốt và học sinh xem được kết quả. |
| **Luồng cơ bản** | 1) Mở danh sách bài nộp. 2) Chấm thủ công hoặc dùng AI hỗ trợ chấm. 3) Chấm hàng loạt cho câu trắc nghiệm. 4) Xem báo cáo integrity (gian lận). 5) Công bố & chốt điểm. 6) Xuất sổ điểm CSV/XLSX. |
| **Luồng thay thế** | Trả bài cho học sinh làm lại (nếu cho phép). |
| **Luồng mở rộng** | `<<extend>>` Chấm thủ công · AI hỗ trợ chấm · Chấm hàng loạt · Xem integrity · Công bố/chốt · Xuất sổ điểm. |

## C6. Xem dashboard giáo viên

| Mục | Nội dung |
|-----|----------|
| **Tên** | Xem dashboard giáo viên |
| **Mô tả** | Giáo viên xem tổng quan công việc giảng dạy: việc cần làm, thống kê lớp/bài thi và lịch deadline. |
| **Đối tượng** | Giáo viên |
| **Tiền điều kiện** | Đã đăng nhập với quyền giáo viên. |
| **Hậu điều kiện** | Hiển thị tổng quan và điều hướng nhanh tới việc cần xử lý. |
| **Luồng cơ bản** | 1) Mở dashboard. 2) Hệ thống tổng hợp action items (bài chờ chấm, đơn chờ duyệt). 3) Hiển thị analytics lớp/bài thi và lịch deadline/phiên thi. |
| **Luồng thay thế** | Chưa có lớp/bài thi: hiển thị trạng thái trống và gợi ý tạo mới. |
| **Luồng mở rộng** | `<<extend>>` Action items · Analytics lớp & bài thi · Lịch deadline & phiên thi. |

---

# D. ADMIN — *các phần bổ sung*

## D1. Quản lý nội dung Nói (Speaking CMS)

| Mục | Nội dung |
|-----|----------|
| **Tên** | Quản lý nội dung Nói (Speaking CMS) |
| **Mô tả** | Quản trị viên thêm/sửa/xóa bộ bài luyện nói (câu mẫu, chủ đề). *Bổ sung cho nhóm CMS đã có Reading/Listening/Writing.* |
| **Đối tượng** | Quản trị viên |
| **Tiền điều kiện** | Đã đăng nhập với quyền admin. |
| **Hậu điều kiện** | Nội dung bài nói được cập nhật và phát hành cho người học. |
| **Luồng cơ bản** | 1) Mở quản lý bài nói. 2) Tạo/sửa bộ câu (nội dung, phiên âm gợi ý). 3) Lưu & phát hành. |
| **Luồng thay thế** | Ẩn/xóa bài: chuyển trạng thái, có thể khôi phục. |
| **Luồng mở rộng** | `<<extend>>` của **Quản lý nội dung học tập**. |

## D2. Duyệt đơn giáo viên

| Mục | Nội dung |
|-----|----------|
| **Tên** | Duyệt đơn giáo viên |
| **Mô tả** | Quản trị viên xét duyệt các đơn xin trở thành giáo viên: chấp thuận (nâng role) hoặc từ chối. |
| **Đối tượng** | Quản trị viên |
| **Tiền điều kiện** | Có đơn ở trạng thái "Chờ duyệt". |
| **Hậu điều kiện** | Đơn được duyệt (role → teacher) hoặc bị từ chối; người nộp được thông báo. |
| **Luồng cơ bản** | 1) Mở danh sách đơn chờ. 2) Xem chi tiết & minh chứng. 3) Chọn Duyệt/Từ chối (kèm lý do). 4) Hệ thống cập nhật role và gửi thông báo. |
| **Luồng thay thế** | Đơn đã bị người dùng rút: bỏ qua. |
| **Luồng mở rộng** | Liên kết User **Nộp đơn trở thành giáo viên**. |

## D3. Quản lý phân quyền & vòng đời tài khoản

| Mục | Nội dung |
|-----|----------|
| **Tên** | Quản lý phân quyền & vòng đời tài khoản |
| **Mô tả** | Quản trị viên đổi vai trò người dùng, xóa mềm và khôi phục tài khoản. *Bổ sung cho UC "Quản lý người dùng" đã có (mới dừng ở ban/online).* |
| **Đối tượng** | Quản trị viên |
| **Tiền điều kiện** | Đã đăng nhập với quyền admin. |
| **Hậu điều kiện** | Vai trò/trạng thái tài khoản được cập nhật. |
| **Luồng cơ bản** | 1) Mở chi tiết user. 2) Đổi role (user/teacher/admin). 3) Hoặc xóa mềm tài khoản. 4) Khôi phục tài khoản đã xóa mềm khi cần. |
| **Luồng thay thế** | Không thể tự hạ quyền admin cuối cùng: chặn thao tác. |
| **Luồng mở rộng** | `<<extend>>` của **Quản lý người dùng**. |

## D4. Quản lý phát hành ứng dụng (Release)

| Mục | Nội dung |
|-----|----------|
| **Tên** | Quản lý phát hành ứng dụng |
| **Mô tả** | Quản trị viên quản lý phiên bản ứng dụng: duyệt bản build, lên lịch/đăng phát hành và rollback khi cần. |
| **Đối tượng** | Quản trị viên |
| **Tiền điều kiện** | Có bản build do CI/CD cung cấp. |
| **Hậu điều kiện** | Phiên bản được công bố tới người dùng (gắn với UC Guest "Kiểm tra phiên bản"). |
| **Luồng cơ bản** | 1) Xem danh sách bản build. 2) Duyệt bản release. 3) Lên lịch hoặc publish ngay. 4) (Khi sự cố) Rollback về phiên bản trước. |
| **Luồng thay thế** | Bản build lỗi: từ chối, không phát hành. |
| **Luồng mở rộng** | `<<extend>>` Duyệt release · Lên lịch & publish · Rollback. Liên kết System **Tự phát hành theo lịch**. |

## D5. Giám sát & Kiểm toán hệ thống

| Mục | Nội dung |
|-----|----------|
| **Tên** | Giám sát & Kiểm toán hệ thống |
| **Mô tả** | Quản trị viên theo dõi hoạt động toàn hệ thống: thống kê, hàng đợi kiểm duyệt, nhật ký kiểm toán, người dùng online và xuất dữ liệu. |
| **Đối tượng** | Quản trị viên |
| **Tiền điều kiện** | Đã đăng nhập với quyền admin. |
| **Hậu điều kiện** | Nắm được tình trạng hệ thống; có thể xuất báo cáo. |
| **Luồng cơ bản** | 1) Mở dashboard thống kê. 2) Xem lịch sử hoạt động học viên. 3) Xử lý hàng đợi moderation. 4) Tra audit log. 5) Theo dõi user online. 6) Export CSV. |
| **Luồng thay thế** | Không có dữ liệu trong khoảng lọc: hiển thị trống. |
| **Luồng mở rộng** | `<<extend>>` Dashboard · Lịch sử học viên · Moderation · Audit log · Online · Export CSV. |

---

# E. SYSTEM (Hệ thống) — *toàn bộ phần này chưa có trong báo cáo*

## E1. Gửi thông báo thông minh

| Mục | Nội dung |
|-----|----------|
| **Tên** | Gửi thông báo thông minh |
| **Mô tả** | Hệ thống tự động gửi nhắc nhở học tập đúng thời điểm dựa trên mục tiêu, lịch ôn SRS và streak của người dùng. |
| **Đối tượng** | Hệ thống (tự động, theo lịch) |
| **Tiền điều kiện** | Người dùng đã bật nhận thông báo và có dữ liệu học tập. |
| **Hậu điều kiện** | Thông báo được gửi tới thiết bị người dùng. |
| **Luồng cơ bản** | 1) Bộ lập lịch kích hoạt theo thời điểm. 2) Hệ thống tính người dùng cần nhắc (từ vựng đến hạn ôn, chưa đạt mục tiêu ngày, sắp mất streak). 3) Soạn và gửi thông báo. |
| **Luồng thay thế** | Người dùng tắt thông báo: bỏ qua. |
| **Luồng mở rộng** | `<<extend>>` Nhắc từ vựng hằng ngày · Nhắc ôn SRS · Nudge mục tiêu · Cứu streak. |

## E2. Hết hạn bài thi quá deadline

| Mục | Nội dung |
|-----|----------|
| **Tên** | Hết hạn bài thi quá deadline |
| **Mô tả** | Hệ thống tự động đóng các bài thi/assignment đã quá thời hạn và thu các bài đang làm dở. |
| **Đối tượng** | Hệ thống (tự động) |
| **Tiền điều kiện** | Tồn tại assignment có thời hạn. |
| **Hậu điều kiện** | Assignment chuyển trạng thái đã đóng; bài dở được nộp tự động. |
| **Luồng cơ bản** | 1) Bộ lập lịch quét các assignment tới hạn. 2) Đóng assignment. 3) Tự nộp các bài đang làm dở. 4) Cập nhật trạng thái để giáo viên chấm. |
| **Luồng thay thế** | Giáo viên đã gia hạn: bỏ qua lần đóng này. |
| **Luồng mở rộng** | Không có. |

## E3. Tự động phát hành ứng dụng theo lịch

| Mục | Nội dung |
|-----|----------|
| **Tên** | Tự động phát hành ứng dụng theo lịch |
| **Mô tả** | Hệ thống tự công bố phiên bản đã được Admin duyệt và đặt lịch, tới đúng thời điểm. |
| **Đối tượng** | Hệ thống (tự động) |
| **Tiền điều kiện** | Có bản release đã duyệt và đặt lịch phát hành. |
| **Hậu điều kiện** | Phiên bản được đánh dấu "mới nhất" cho client kiểm tra cập nhật. |
| **Luồng cơ bản** | 1) Tới thời điểm đã lên lịch. 2) Hệ thống đánh dấu bản release là phiên bản hiện hành. 3) Client nhận được khi kiểm tra phiên bản. |
| **Luồng thay thế** | Bản release bị Admin hủy trước giờ: không phát hành. |
| **Luồng mở rộng** | Liên kết Admin **Quản lý phát hành ứng dụng**. |

## E4. Nhận bản build từ CI/CD

| Mục | Nội dung |
|-----|----------|
| **Tên** | Nhận bản build từ CI/CD |
| **Mô tả** | Hệ thống tiếp nhận artifact (APK/bản web) do pipeline CI/CD đẩy lên và tạo bản release ở trạng thái chờ duyệt. |
| **Đối tượng** | Hệ thống (tự động) |
| **Tiền điều kiện** | Pipeline CI build thành công và gọi webhook/endpoint. |
| **Hậu điều kiện** | Bản build xuất hiện trong danh sách chờ Admin duyệt. |
| **Luồng cơ bản** | 1) CI build xong, đẩy artifact. 2) Hệ thống lưu metadata (phiên bản, ghi chú). 3) Tạo bản release trạng thái "Chờ duyệt". |
| **Luồng thay thế** | Artifact lỗi/không hợp lệ: từ chối, ghi log. |
| **Luồng mở rộng** | Liên kết Admin **Quản lý phát hành ứng dụng**. |

---

## Tổng kết

**Đã bổ sung đặc tả cho ~23 use case còn thiếu:**

- **Guest (1):** Xem trước bài thi công khai
- **User (7):** Quên mật khẩu · Đăng nhập Google · Xóa tài khoản · Luyện nói tự do với AI · Gửi báo cáo sự cố · Nộp đơn giáo viên · Phản hồi co-teacher
- **Teacher (6):** Quản lý lớp · Ngân hàng đề · Giao bài · Phiên thi realtime · Chấm điểm & công bố · Dashboard GV
- **Admin (5):** Speaking CMS · Duyệt đơn GV · Phân quyền & vòng đời TK · Phát hành app · Giám sát & kiểm toán
- **System (4):** Thông báo thông minh · Hết hạn bài thi · Tự phát hành theo lịch · Nhận build CI/CD

> Lưu ý: chương 3.1 (Lược đồ tuần tự) cũng nên bổ sung SD cho **Teacher** và **phiên thi realtime** tương ứng — hiện chương 3.1 mới có SD cho nhóm User/Admin cũ.
