# 11 — Chat lớp học realtime (Classroom Chat)

> **Một câu:** Nhóm chat realtime của mỗi lớp (kiểu Messenger), cho giáo viên + học viên trao đổi text/ảnh/video/tệp, có reply, reaction, "đang nhập…", trạng thái đã xem và inbox tổng hợp nhiều lớp với badge chưa đọc.

---

## 1. Mục đích nghiệp vụ
Tạo kênh trao đổi tức thời trong mỗi lớp: hỏi bài, thông báo nhanh, chia sẻ tài liệu. Có đầy đủ tính năng của một chat hiện đại (reply, reaction, @mention, ghim tin, chỉnh/xoá, "đang nhập…", đã xem) và một **inbox tổng hợp** để theo dõi nhiều lớp cùng lúc.

## 2. Vai trò & tiền điều kiện
- Chỉ **thành viên active** (student, co-teacher) và **GV chủ lớp** mới chat.
- Một số thao tác chỉ GV chủ lớp: đổi tên/ảnh nhóm, ghim/bỏ ghim.
- Xoá tin: người gửi hoặc GV chủ lớp; sửa tin: chỉ người gửi, chỉ tin text.

## 3. Luồng nghiệp vụ chính
1. **Mở phòng:** join room Socket.IO của lớp; tải 25 tin mới nhất + thành viên, hiển thị từ cache trước, merge tin đến qua socket trong lúc fetch (không mất tin), rồi đánh dấu đã đọc.
2. **Gửi tin:** validate (text ≤ 4000 ký tự, media phải có URL); reply thì **nhúng snapshot** tin gốc; tạo bản ghi, emit tin mới tới phòng + cập nhật inbox mọi thành viên. Client gửi **optimistic** (hiện ngay, khi server trả thì thay thế).
3. **Gửi media:** upload Cloudinary trước (ảnh/video/tệp), rồi gửi tin kèm media.
4. **Reaction:** toggle emoji (8 emoji whitelist); nếu là reaction **mới** cho tin của người khác → báo **chủ tin qua chat inbox** (không qua chuông).
5. **Xoá/Sửa/Ghim:** xoá là soft-delete (giữ bản ghi cho reply preview); ghim lưu vào lớp.
6. **"Đang nhập…":** báo cả trong phòng lẫn ngoài inbox, tự tắt sau vài giây.
7. **Inbox tổng hợp:** gom mọi lớp của user, tính tin cuối + số chưa đọc + số thành viên + online + ghim/muted; sắp ghim→mới nhất.

## 4. Quy tắc nghiệp vụ quan trọng
- **Ai được nhắn:** thành viên active + GV chủ lớp (người `removed`/`pending` không nhắn được).
- **Tin nhắn/reaction đi kênh CHAT INBOX, KHÔNG đi chuông** (xem thêm file `19`).
- **Badge inbox bỏ qua hội thoại muted.**
- **Reaction chỉ báo đúng chủ tin** (không báo cả lớp) và chỉ khi là reaction mới.

## 5. Cách làm (kỹ thuật)
- **Socket room:** `classroom_chat_<id>` cho các sự kiện tin/reaction/typing/read; ngoài ra có **room cá nhân** (theo userId) để đẩy cập nhật inbox tới cả người **không mở phòng**.
- **Lưu "đã đọc":** model `ClassroomChatReadState` (mốc đọc cuối, muted, pinned). Unread = số tin sau mốc đọc cuối từ người khác. Đọc tin → cập nhật mốc + hiện ✓✓ "Đã xem" cho phòng.
- **Idempotency:** chống gửi trùng khi retry bằng `clientId`.
- **Reply snapshot:** nhúng preview người gửi/nội dung → còn nguyên dù tin gốc bị xoá.
- **Bridge listener (Flutter):** gắn socket listener một lần rồi dispatch theo lớp — tránh chồng listener khi mở nhiều lớp.

## 6. Điểm nhấn để trình bày
- Reply lưu **snapshot nhúng** → preview còn nguyên dù tin gốc bị xoá.
- Idempotency + optimistic UI mượt; merge tin đến-khi-đang-fetch để không mất tin.
- "Đang nhập…" hai lớp (trong phòng + ngoài inbox); presence online tính ngay trong inbox.

## 7. Giới hạn & lưu ý trung thực
- Tin nhắn/reaction chat **không có push FCM khi app đóng** (chỉ realtime socket + badge inbox khi mở app) — khác với chuông (có FCM). @mention được lưu nhưng chưa có luồng gửi push mention.
- Unread inbox quét toàn bộ tin chưa đọc mỗi lần load (có thể nặng với lớp lớn).
- Sửa tin chỉ áp dụng text; không lưu lịch sử chỉnh sửa.

## 8. Dẫn chứng mã nguồn
- `services/classroomChatService.js` (gửi `210-273`, media `277-326`, reaction `368-417`, inbox `652-817`, đã đọc `819-839`).
- Model: `models/ClassroomMessage.js`, `ClassroomChatReadState.js`; socket `socket/socketManager.js:352-374`.
- Client: `feature/classroom_chat/bloc/classroom_chat_bloc.dart`, `dock/classroom_chat_dock_controller.dart`, `core/socket/handlers/socket_classroom_chat_handler.dart`.
