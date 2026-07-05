# Báo cáo EFC — CÁC MỤC VIẾT LẠI ĐẦY ĐỦ (thay nguyên đoạn) + mục thêm mới

> **Cách dùng:**
> - Mục gắn nhãn **▶ THAY THẾ** = viết lại hoàn chỉnh (đã gộp nội dung cũ + mới), **thay nguyên mục** tương ứng trong báo cáo — KHÔNG chèn thêm rời để tránh trùng ý.
> - Mục gắn nhãn **➕ THÊM MỚI** = mục hoàn toàn mới, chèn vào đúng chương.
> - Đặc tả use case và bảng CSDL nằm ở 2 file riêng (`BAO-CAO-BO-SUNG-USECASE.md`, `BAO-CAO-BO-SUNG-DB.md`) — đó là bảng thêm mới, không đụng nội dung cũ.

---

## BẢNG GAP (điều hướng nhanh)

| Chương | Mục cần thay/thêm | Loại |
|---|---|---|
| Phần mở đầu | Đối tượng nghiên cứu; Phạm vi nghiên cứu | ▶ Thay |
| Cơ sở lý thuyết | Kiến trúc tổng quan; Frontend; Backend; CSDL | ▶ Thay |
| Cơ sở lý thuyết | Phân quyền RBAC; Realtime nâng cao; CI/CD & Triển khai; Cập nhật OTA | ➕ Thêm |
| Khảo sát & Yêu cầu | Yêu cầu chức năng; Yêu cầu phi chức năng | ▶ Thay |
| Chương 4 | Danh sách Epic (Jira) | ▶ Thay |
| Chương 4 | CI/CD; Kiến trúc triển khai; Quy trình phát hành | ➕ Thêm |
| Kết luận | Kết quả ứng dụng thực tiễn; Ưu điểm; Nhược điểm; Hướng phát triển | ▶ Thay |

---

# PHẦN MỞ ĐẦU

## ▶ THAY THẾ — "2. Đối tượng nghiên cứu"

Đối tượng nghiên cứu của đề tài gồm hai nhóm chính: công nghệ và nghiệp vụ.

**Về mặt công nghệ:**
- Nghiên cứu kiến trúc phát triển ứng dụng di động đa nền tảng (Cross-platform) sử dụng Flutter Framework.
- Nghiên cứu xây dựng hệ thống Backend (API) hiệu năng cao với Node.js và ExpressJS theo mô hình phân tầng.
- Nghiên cứu cơ sở dữ liệu NoSQL (MongoDB) cho lưu trữ đám mây và SQLite cho lưu trữ cục bộ (Offline).
- Nghiên cứu tích hợp Generative AI (Google Gemini API) để xử lý ngôn ngữ tự nhiên: chấm bài, phản hồi và hội thoại luyện nói.
- Nghiên cứu giao thức WebSocket (Socket.IO) cho các tác vụ thời gian thực, tổ chức theo mô hình phòng (room) để phục vụ chat lớp học, phiên thi trực tuyến và giám sát bài thi.
- Nghiên cứu kiến trúc **phân quyền theo vai trò (RBAC)** cho hệ thống nhiều vai trò: Khách, Học viên, Giáo viên và Quản trị viên.
- Nghiên cứu bài toán **thi trực tuyến có giám sát (online proctoring)**: quản lý phiên thi, theo dõi trạng thái người học theo thời gian thực và cơ chế ghi nhận hành vi bất thường (integrity).
- Nghiên cứu quy trình **DevOps & CI/CD** (GitHub Actions) để tự động hóa việc build, phát hành và **cập nhật ứng dụng qua mạng (OTA update)**.

**Về mặt nghiệp vụ:**
- Các phương pháp học từ vựng hiệu quả (Spaced Repetition System - Lặp lại ngắt quãng).
- Quy trình chấm điểm và phản hồi lỗi sai trong kỹ năng Viết và Nói tiếng Anh (kết hợp tự động, AI và chấm thủ công của giáo viên).
- Mô hình quản lý lớp học trực tuyến (LMS): tổ chức lớp, giao bài, theo dõi kết quả và tương tác giữa giáo viên và học viên.
- Hành vi và trải nghiệm người dùng (UX/UI) trong các ứng dụng giáo dục.

## ▶ THAY THẾ — "3. Phạm vi nghiên cứu"

**Phạm vi không gian (Nền tảng):**
- **Mobile App (Flutter):** ứng dụng chạy trên Android (và iOS), phục vụ **cả học viên và giáo viên**, phân luồng chức năng theo vai trò ngay khi đăng nhập.
- **Web Admin (Flutter Web):** trang quản trị chạy trên trình duyệt, triển khai trên Firebase Hosting, phục vụ Quản trị viên quản lý nội dung, người dùng và **phát hành phiên bản ứng dụng**.
- **Backend & Hạ tầng:** máy chủ Node.js/Express triển khai trên Render, cơ sở dữ liệu MongoDB Atlas; ứng dụng di động phân phối qua GitHub Releases.

**Phạm vi chức năng:**
- Hệ thống học tập tập trung vào 4 kỹ năng chính: Nghe, Nói, Đọc, Viết, kèm Từ điển và Từ vựng.
- Tính năng Từ điển Anh-Việt hoạt động hoàn toàn Offline.
- Tính năng AI: Chatbot hỏi đáp, chấm điểm bài Viết/Nói và hội thoại luyện nói (cần kết nối Internet).
- **Phân hệ Lớp học (Classroom):** giáo viên tạo lớp, học viên tham gia bằng mã/liên kết; bảng tin lớp và **chat nhóm thời gian thực**.
- **Phân hệ Thi cử (Assessment):** tạo và giao đề thi đa kỹ năng tích hợp; thi theo phiên trực tiếp hoặc thi công khai qua liên kết; chấm điểm nhiều tầng và giám sát chống gian lận.
- Các tính năng cộng đồng và tiện ích: Bảng xếp hạng, Thảo luận trong bài học, Thông báo, Quản lý tài khoản.
- **Cập nhật ứng dụng OTA:** kiểm tra phiên bản và cập nhật ngay trong ứng dụng (soft/force) không qua chợ ứng dụng.

---

# CƠ SỞ LÝ THUYẾT

## ▶ THAY THẾ — "Kiến trúc hệ thống tổng quan"

Hệ thống được xây dựng theo mô hình client-server, gồm ba thành phần chính: ứng dụng phía người dùng, dịch vụ phía máy chủ và lớp lưu trữ dữ liệu. Ở phía client, nền tảng Flutter được sử dụng để phát triển ứng dụng học tập (dùng chung cho học viên và giáo viên) và giao diện quản trị trên web. Ở phía server, Node.js kết hợp Express đảm nhiệm xử lý nghiệp vụ, cung cấp API và các tác vụ thời gian thực qua Socket.IO. Lớp dữ liệu áp dụng mô hình lai: MongoDB phục vụ dữ liệu nghiệp vụ trực tuyến và SQLite phục vụ dữ liệu cục bộ cho một số tính năng ngoại tuyến.

Hệ thống phục vụ **bốn vai trò** với ranh giới quyền rõ ràng — Khách, Học viên, Giáo viên, Quản trị viên — được kiểm soát nhất quán ở cả tầng điều hướng phía client và tầng middleware phía server. Về triển khai, backend chạy trên nền tảng đám mây (Render) kết nối MongoDB Atlas, giao diện quản trị web được triển khai tự động lên Firebase Hosting, còn ứng dụng di động được phân phối và cập nhật qua cơ chế OTA.

Về tổ chức phần mềm, hệ thống định hướng phân tầng nhằm tách biệt giao diện, nghiệp vụ và truy cập dữ liệu. Cách tổ chức này giúp tăng khả năng bảo trì, mở rộng chức năng và giảm phụ thuộc giữa các thành phần.

## ▶ THAY THẾ — "Công nghệ Frontend (Mobile App & Admin Web)"

Frontend được phát triển bằng Flutter với ngôn ngữ Dart. Việc sử dụng cùng một nền tảng cho ứng dụng di động và giao diện quản trị web giúp tái sử dụng đáng kể cấu trúc dữ liệu, quy tắc nghiệp vụ và thành phần giao diện.

Hệ thống quản lý trạng thái chủ đạo theo mô hình BLoC. Luồng xử lý được tổ chức theo hướng sự kiện: giao diện phát sinh sự kiện, BLoC xử lý nghiệp vụ thông qua repository/datasource, sau đó trả về trạng thái để cập nhật giao diện. Cách tiếp cận này giúp mã nguồn rõ trách nhiệm và thuận lợi cho kiểm thử.

Điều hướng ứng dụng được triển khai bằng cơ chế định tuyến tập trung (go_router) có kiểm tra trạng thái xác thực và vai trò người dùng. Bộ định tuyến tự động điều hướng người dùng về đúng không gian làm việc theo vai trò (Học viên → Trang chủ học tập, Giáo viên → Bảng điều khiển giáo viên, Quản trị viên → Trang quản trị) và ngăn truy cập chéo giữa các nhóm chức năng.

Về lưu trữ cục bộ, hệ thống sử dụng SQLite cho dữ liệu từ điển và cơ chế lưu trữ an toàn (secure storage) cho thông tin phiên đăng nhập. Ngoài ra, ứng dụng có thành phần Socket client để xử lý các tương tác thời gian thực như thông báo, chat lớp học, đồng bộ phiên thi và giám sát bài thi.

## ▶ THAY THẾ — "Công nghệ Backend (Server Side)"

Backend sử dụng Node.js và Express theo mô hình phân tầng route – controller – service – model. Trong đó, route chịu trách nhiệm định tuyến yêu cầu, controller xử lý đầu vào/đầu ra HTTP, service chứa nghiệp vụ lõi, và model quản lý ánh xạ dữ liệu MongoDB thông qua Mongoose.

Cơ chế xác thực được xây dựng trên JWT, gồm access token và refresh token; refresh token được quản lý theo người dùng để duy trì phiên đăng nhập an toàn. Hệ thống áp dụng **phân quyền theo vai trò và quyền hạn (RBAC)** thông qua các middleware kiểm tra xác thực và vai trò cho từng nhóm API (người học, giáo viên, quản trị).

Đối với tác vụ thời gian thực, Socket.IO được sử dụng theo mô hình **phòng (room)** để cô lập luồng sự kiện theo ngữ cảnh: room theo lớp học (chat nhóm, hoạt động lớp), room theo phiên thi (đồng bộ trạng thái làm bài), và room giám sát (đẩy trạng thái người học và cảnh báo gian lận về giáo viên). Bên cạnh đó, hệ thống có cơ chế tác vụ định kỳ (cron job) phục vụ nhắc học, phát hành phiên bản theo lịch và các tác vụ vận hành nền.

## ▶ THAY THẾ — "Công nghệ Cơ sở dữ liệu"

MongoDB được chọn làm cơ sở dữ liệu chính do phù hợp với dữ liệu nghiệp vụ linh hoạt và dễ mở rộng theo mô-đun chức năng (lớp học, đề thi, thông báo…). Tầng truy cập dữ liệu được triển khai qua Mongoose để chuẩn hóa schema, ràng buộc dữ liệu và thao tác truy vấn; một số cấu trúc động (nội dung đề đa kỹ năng, cấu hình giao bài, payload thông báo) được lưu ở dạng tài liệu linh hoạt.

SQLite được sử dụng cho các dữ liệu cần truy cập nhanh ở phía thiết bị, đặc biệt là kho từ điển ngoại tuyến (>100.000 từ) có tối ưu chỉ mục (Indexing). Mô hình kết hợp online/offline giúp cải thiện trải nghiệm người dùng và giảm gián đoạn trong quá trình học tập.

## ➕ THÊM MỚI — "Phân quyền theo vai trò (RBAC)"

Hệ thống định nghĩa bốn vai trò với ranh giới quyền rõ ràng:
- **Khách (Guest):** tra từ điển ngoại tuyến, xem giới thiệu, kiểm tra phiên bản, đăng ký/đăng nhập.
- **Học viên (Student):** học đủ 4 kỹ năng, từ vựng, tham gia lớp học, làm bài thi được giao, chat lớp, trợ lý AI, thống kê tiến độ.
- **Giáo viên (Teacher):** quản lý lớp, soạn/giao/chấm đề thi, sổ điểm, thống kê lớp, lịch, hộp thư, giám sát thi trực tuyến.
- **Quản trị viên (Admin):** quản trị người dùng, nội dung, báo cáo, vận hành hệ thống và phát hành phiên bản.

Quyền được kiểm soát hai lớp: phía server dùng middleware xác thực JWT và kiểm tra vai trò/quyền cho từng nhóm route; phía client dùng cơ chế điều hướng có điều kiện để chặn truy cập chéo vai trò và đưa người dùng về đúng không gian làm việc.

## ➕ THÊM MỚI — "Xử lý thời gian thực nâng cao (Socket.IO)"

Ngoài thông báo và trạng thái online, hệ thống dùng mô hình room để phân tách luồng sự kiện: (1) room lớp học phát tin nhắn chat nhóm và hoạt động lớp; (2) room phiên thi đồng bộ trạng thái làm bài và thời gian còn lại; (3) room giám sát đẩy trạng thái/màn hình người học tới giáo viên và phát cảnh báo gian lận. Việc cô lập theo room giúp giảm nhiễu sự kiện, tăng bảo mật và khả năng mở rộng khi nhiều lớp/phiên thi hoạt động đồng thời.

## ➕ THÊM MỚI — "Tự động hóa CI/CD và Triển khai"

Hệ thống áp dụng quy trình tích hợp và phát hành liên tục bằng GitHub Actions. Mỗi lần cập nhật mã nguồn ứng dụng lên nhánh chính, quy trình tự động build APK đã ký số, tải lên GitHub Releases và tạo một bản ứng viên (release candidate) trên backend để chờ phê duyệt. Giao diện quản trị web (Flutter Web) cũng được build và triển khai tự động lên Firebase Hosting. Backend và cơ sở dữ liệu vận hành trên nền tảng đám mây (Render, MongoDB Atlas). Cách tiếp cận này khép kín vòng đời phần mềm từ mã nguồn đến sản phẩm tới tay người dùng, đồng thời vẫn giữ điểm kiểm soát của con người ở khâu phê duyệt phát hành.

## ➕ THÊM MỚI — "Cập nhật ứng dụng qua mạng (OTA Update)"

Do phân phối ngoài chợ ứng dụng, hệ thống tự triển khai cơ chế cập nhật OTA. Ứng dụng gọi API kiểm tra phiên bản (public) và gửi số hiệu bản dựng (versionCode) hiện tại; server so sánh với bản đã phát hành để trả về một trong ba trạng thái: đã mới nhất, cập nhật mềm (nhắc, cho bỏ qua) hoặc cập nhật bắt buộc (khi phiên bản thấp hơn ngưỡng tối thiểu được hỗ trợ). Cơ chế so sánh dựa trên số hiệu bản dựng nguyên và đơn điệu tăng, tránh lỗi so sánh chuỗi phiên bản; nhờ đó việc phát hành phiên bản mới được đẩy tới người dùng một cách chủ động và có kiểm soát.

---

# KHẢO SÁT HIỆN TRẠNG VÀ MÔ HÌNH HÓA YÊU CẦU

## ▶ THAY THẾ — "Yêu cầu chức năng"

**Nhóm chức năng Bảo mật & Tài khoản:**
- Đăng ký tài khoản (xác thực OTP qua Email), Đăng nhập/Đăng xuất (quản lý phiên).
- Quên mật khẩu và Đặt lại mật khẩu.
- Quản lý thông tin cá nhân và Ảnh đại diện (Profile); Xóa tài khoản vĩnh viễn.
- Kiểm tra phiên bản và cập nhật ứng dụng (OTA).

**Nhóm chức năng Học tập (Học viên):**
- Luyện Nghe (Listening): Nghe Audio, Chép chính tả (Dictation), Xem phụ đề (Transcript), Thảo luận/Bình luận theo phân đoạn bài học.
- Luyện Nghe hiểu (Listening Comprehension): nghe và trả lời trắc nghiệm hiểu nội dung.
- Luyện Nói (Speaking): Luyện phát âm theo câu mẫu và Hội thoại luyện nói cùng AI theo kịch bản, có chấm điểm và phản hồi chi tiết.
- Luyện Đọc (Reading): Đọc hiểu song ngữ, Làm bài tập trắc nghiệm.
- Luyện Viết (Writing): Viết bài luận theo chủ đề, Tự động lưu nháp (Autosave), Chấm điểm và nhận xét chi tiết bằng AI (so sánh sửa lỗi trực quan).
- Từ vựng (Vocabulary): Tra cứu từ điển Offline, Lưu từ vựng, Ôn tập bằng Flashcard (Lặp lại ngắt quãng).

**Nhóm chức năng Lớp học (Học viên):**
- Tham gia lớp bằng mã lớp/liên kết mời; xem danh sách lớp đang học.
- Xem chi tiết lớp: thành viên, bài tập/bài thi được giao, bảng tin hoạt động.
- Chat nhóm lớp thời gian thực (văn bản, hình ảnh/tệp; trạng thái đã đọc).
- Nhận thông báo tương tác (được giao bài, tin nhắn mới, phản hồi bài học, trả kết quả).

**Nhóm chức năng Thi cử (Học viên):**
- Xem danh sách bài thi được giao và trạng thái làm bài.
- Làm bài thi đa kỹ năng tích hợp, có tính giờ, tự lưu tiến độ.
- Tham gia phiên thi trực tiếp do giáo viên mở, hoặc thi công khai qua liên kết.
- Tuân thủ cơ chế chống gian lận; xem lại đáp án và lời giải sau khi được trả kết quả.

**Nhóm chức năng Tiện ích & Gamification (Học viên):**
- Trợ lý AI: hỏi đáp kiến thức và tra cứu tiến độ học tập.
- Thống kê: Dashboard tổng quan và biểu đồ chi tiết quá trình học.
- Thi đua: Bảng xếp hạng (Leaderboard).
- Cài đặt mục tiêu học tập hằng ngày và nhắc nhở giờ học (Notification).

**Nhóm chức năng Giáo viên (Teacher):**
- Quản lý lớp học: tạo lớp, quản lý thành viên, xem hoạt động lớp.
- Soạn đề: đề đơn kỹ năng và đề tích hợp đa kỹ năng; lưu mẫu giao bài (preset).
- Giao bài: chọn lớp/học viên, đặt thời gian và chế độ (giao thường / phiên trực tiếp / công khai).
- Chấm điểm: tự động, hỗ trợ AI và chấm thủ công; sổ điểm và xuất điểm.
- Giám sát thi trực tiếp: theo dõi tiến độ, trạng thái/màn hình học viên theo thời gian thực và cảnh báo gian lận.
- Thống kê lớp (Analytics), Lịch (Calendar), Hộp thư (Inbox); trả kết quả cho học viên.

**Nhóm chức năng Quản trị (Admin):**
- Thống kê hệ thống: Dashboard (người dùng, bài nộp, chi phí AI, báo cáo).
- Quản lý người dùng: xem danh sách, giám sát trạng thái Online, khóa (Ban) tài khoản.
- Quản lý nội dung: Thêm/Sửa/Xóa bài học các kỹ năng (gồm cả Nghe hiểu, Nói) và Từ vựng; phiên bản hóa và khôi phục chủ đề Viết.
- Xử lý sự cố: xem và xử lý Báo cáo lỗi từ người dùng; tra nhật ký thao tác quản trị (Audit Log).
- Vận hành & phát hành: theo dõi vận hành (Ops Center) và **phát hành phiên bản ứng dụng** (duyệt, phát hành, lên lịch, rollback).

## ▶ THAY THẾ — "Yêu cầu phi chức năng"

- Ứng dụng phản hồi nhanh với thao tác của người dùng; giao diện thân thiện, đơn giản, dễ thao tác.
- Tốc độ tìm kiếm (từ điển, nội dung) nhanh và chính xác.
- Bảo mật thông tin người dùng; phân tách vai trò an toàn, không rò rỉ chức năng chéo vai trò.
- Xử lý thời gian thực độ trễ thấp cho chat lớp và giám sát thi.
- Bảo đảm tính toàn vẹn bài thi (integrity): ghi nhận và cảnh báo hành vi bất thường.
- Khả năng phát hành liên tục (CI/CD) và cập nhật không gián đoạn (OTA); khả năng mở rộng theo mô-đun.

---

# CHƯƠNG 4: QUẢN LÝ DỰ ÁN PHẦN MỀM

## ▶ THAY THẾ — Danh sách "Epics" trong mục Quản lý tiến độ (Jira)

Dự án được phân rã theo cấu trúc phân cấp của Jira. Các Epic chính (nhóm chức năng lớn) phản ánh thực tế triển khai gồm 12 Epic:
- **INFRA & SETUP** — Khởi tạo dự án & hạ tầng.
- **AUTH** — Xác thực & người dùng.
- **DICTIONARY** — Từ điển Offline.
- **LEARNING CORE** — Học tập: Nghe, Nghe hiểu, Đọc, Viết.
- **SPEAKING & AI** — Luyện nói thông minh (phát âm + hội thoại AI).
- **GAMIFICATION** — Thi đua & thông báo.
- **CLASSROOM & LMS** — Lớp học, ghi danh, bảng tin, chat lớp.
- **ASSESSMENT/EXAM** — Đề thi, giao bài, chấm điểm, phiên thi, giám sát.
- **REALTIME & CHAT** — Chat lớp, thông báo, giám sát thời gian thực.
- **ADMIN DASHBOARD** — Trang quản trị (người dùng, nội dung, báo cáo, vận hành).
- **RELEASE & OTA** — CI/CD, phát hành phiên bản, cập nhật trong ứng dụng.
- **DEPLOYMENT** — Đóng gói & triển khai (Render, Firebase Hosting, GitHub Releases).

## ➕ THÊM MỚI — "Tự động hóa CI/CD"

Dự án sử dụng GitHub Actions cho tích hợp và phát hành liên tục:
- **Quy trình build ứng viên (auto-build-candidate):** kích hoạt khi đẩy mã nguồn ứng dụng lên nhánh chính. Các bước: cài Flutter → chạy kiểm thử → tự tăng số hiệu bản dựng → build APK release đã ký số → tải APK lên GitHub Releases → gọi API backend tạo bản ứng viên ở trạng thái chờ duyệt.
- **Quy trình triển khai web (firebase-hosting):** tự build Flutter Web và triển khai giao diện quản trị lên Firebase Hosting khi có thay đổi trên nhánh chính.

## ➕ THÊM MỚI — "Kiến trúc triển khai (Deployment)"

| Thành phần | Nền tảng | Ghi chú |
|---|---|---|
| Backend API + Socket.IO | Render | Node.js/Express, biến môi trường bảo mật |
| Cơ sở dữ liệu | MongoDB Atlas | CSDL đám mây |
| Web Admin | Firebase Hosting (tên miền `english4community.online`) | Flutter Web, triển khai qua CI |
| Mobile App (APK) | GitHub Releases | Phân phối trực tiếp + cập nhật OTA |

## ➕ THÊM MỚI — "Quy trình phát hành phiên bản (Release Workflow)"

1. Lập trình viên đẩy mã nguồn lên nhánh chính → CI tự build APK và tạo bản ứng viên (trạng thái *chờ duyệt*).
2. Quản trị viên vào màn Quản lý phiên bản trên Web Admin → duyệt và phát hành (hoặc lên lịch phát hành).
3. Ứng dụng client định kỳ/khi khởi động gọi API kiểm tra phiên bản → nếu có bản mới hơn thì hiện hộp thoại cập nhật (mềm/bắt buộc) → tải và cài đặt.
4. Hệ thống hỗ trợ rollback về bản phát hành trước khi cần.

Đây là điểm nhấn kỹ thuật của dự án: khép kín vòng đời *mã nguồn → build → duyệt → phát hành → cập nhật người dùng* theo chuẩn DevOps, có kiểm soát của con người ở khâu phê duyệt.

---

# PHẦN KẾT LUẬN

## ▶ THAY THẾ — "1.2. Về kết quả ứng dụng thực tiễn"

Hệ thống English for Community (EFC) đã hoàn thiện và vận hành ổn định trên môi trường kiểm thử với đầy đủ các phân hệ:

**A. Phân hệ Người học (Mobile App - Flutter)**
- Hệ thống học tập đa kỹ năng (Nghe, Nghe hiểu, Nói, Đọc, Viết) với kho dữ liệu phong phú; Từ điển Offline tích hợp sâu (tra cứu, đánh dấu, xem lịch sử khi không có mạng).
- Tương tác thông minh với AI: AI Writing Assistant (phát hiện lỗi ngữ pháp/từ vựng, sửa lỗi so sánh trực quan), AI Speaking Coach (ghi âm, chuyển giọng nói thành văn bản, chấm điểm và **hội thoại luyện nói theo kịch bản**), AI Chatbot hỏi đáp 24/7.
- Cơ chế Gamification: điểm kinh nghiệm, chuỗi ngày học liên tục, Bảng xếp hạng và nhắc nhở học tập tự động.

**B. Phân hệ Lớp học & Cộng đồng (mới)**
- Tham gia lớp qua mã/liên kết, xem chi tiết lớp và bảng tin; **chat nhóm thời gian thực** (hình ảnh/tệp, trạng thái đã đọc); thảo luận theo phân đoạn bài học; hệ thống thông báo tương tác.

**C. Phân hệ Giáo viên (mới)**
- Quản lý lớp; soạn/giao/chấm đề thi (tự động + AI + thủ công); sổ điểm và xuất điểm; thống kê lớp, lịch, hộp thư; **giám sát thi trực tuyến** (theo dõi tiến độ và màn hình học viên theo thời gian thực, cảnh báo gian lận); trả kết quả.

**D. Phân hệ Thi trực tuyến (mới)**
- Đề thi đa kỹ năng tích hợp, thi có tính giờ theo phiên hoặc công khai qua liên kết; chấm điểm nhiều tầng; chống gian lận (đếm chuyển tab, thời gian rời màn hình…); xem lại đáp án và lời giải.

**E. Phân hệ Quản trị (Admin Dashboard - Web)**
- Dashboard trực quan (chỉ số hệ thống, tăng trưởng người dùng); quản lý người dùng thời gian thực (giám sát Online, khóa tài khoản); trình soạn bài học (Rich Text, upload Audio, đồng bộ Transcript); xử lý báo cáo; **quản lý phát hành phiên bản (duyệt/phát hành/rollback)** và nhật ký kiểm toán.

## ▶ THAY THẾ — "2. Ưu điểm"

- **Trải nghiệm người dùng (UX) vượt trội:** giao diện hiện đại, mượt mà nhờ Flutter; chuyển đổi linh hoạt giữa chế độ Online và Offline.
- **Tính năng toàn diện:** không chỉ là ứng dụng tự học mà là một nền tảng học tập trực tuyến (LMS) có lớp học, thi cử có giám sát và tương tác thời gian thực giữa giáo viên – học viên.
- **Khả năng mở rộng (Scalability):** kiến trúc backend module hóa rõ ràng, dễ mở rộng theo chức năng; dữ liệu tổ chức linh hoạt cho các nghiệp vụ mới.
- **Vận hành hiện đại:** quy trình CI/CD tự động và cập nhật OTA có kiểm soát giúp phát hành nhanh, an toàn và đưa bản mới đến người dùng kịp thời.
- **Tính bảo mật:** xác thực JWT, phân quyền theo vai trò nhiều lớp và cơ chế bảo vệ toàn vẹn bài thi.

## ▶ THAY THẾ — "3. Nhược điểm và hạn chế"

- **Dung lượng bộ cài lớn:** do tích hợp sẵn cơ sở dữ liệu từ điển Offline chất lượng cao, tệp cài đặt (APK) còn khá lớn, có thể gây ngại cho người dùng thiết bị dung lượng thấp.
- **Phụ thuộc bên thứ ba:** tính năng AI phụ thuộc API bên ngoài; khi mạng kém hoặc nhà cung cấp thay đổi chính sách, tính năng có thể gián đoạn.
- **Phụ thuộc hạ tầng thời gian thực:** chất lượng chat lớp và giám sát thi giảm khi mạng yếu; backend trên gói dịch vụ miễn phí có độ trễ khởi động nguội.
- **Cập nhật OTA vẫn cần cài thủ công (sideload):** chưa cập nhật nền hoàn toàn như khi phân phối qua chợ ứng dụng chính thức.

## ▶ THAY THẾ — "4. Hướng phát triển"

Nhiều hạng mục từng dự kiến đã được hiện thực trong phiên bản này (hội thoại luyện nói với AI; bước đầu của học tập cộng đồng qua chat lớp và thảo luận bài học). Định hướng phát triển tiếp theo:
- **Gọi video/voice trực tiếp trong lớp học** để tổ chức buổi học/thi trực tuyến sinh động hơn.
- **Nâng cấp đề thi thích ứng (adaptive)** và phân tích học tập chuyên sâu dựa trên dữ liệu.
- **Mở rộng học tập cộng đồng (Social Learning):** kết bạn, thách đấu từ vựng (PvP), diễn đàn theo chủ đề.
- **Đưa ứng dụng lên Google Play/App Store** để cập nhật nền tự động; tách backend thành microservices khi lượng người dùng tăng cao; phát triển phiên bản Web/Desktop cho người học.

---

## ➕ THÊM MỚI — Cập nhật thông tin cuối báo cáo (thay/thêm ở mục "Thông tin mã nguồn")
- **Tên hiển thị ứng dụng:** đã đổi thành **E4C** (bộ nhận diện mới). Giữ "English for Community (EFC)" làm tên đề tài; ghi chú tên thương hiệu hiển thị là **E4C**.
- **Tài khoản test:** bổ sung tài khoản Giáo viên (`teacher@englishapp.com`) cạnh User/Admin.
- **Phân phối & cập nhật:** APK phân phối qua GitHub Releases; ứng dụng tự kiểm tra và cập nhật phiên bản (OTA), luôn lấy bản phát hành mới nhất.
