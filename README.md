# 📘 English for Community (EFC)

**English for Community** là nền tảng học tiếng Anh toàn diện, kết hợp giữa ứng dụng di động (Mobile App) và hệ thống quản trị nội dung (CMS). Dự án tập trung vào việc cải thiện 4 kỹ năng: Nghe, Nói, Đọc, Viết thông qua các phương pháp tương tác, Gamification và hỗ trợ từ AI.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)
![Socket.io](https://img.shields.io/badge/Socket.io-010101?style=for-the-badge&logo=socket.io&logoColor=white)

---

## ✨ Tính năng chính

### 📱 Mobile App (User)
* **📚 Từ điển Offline:** Tra cứu từ vựng nhanh chóng với dữ liệu cục bộ (SQLite).
* **🗣️ Luyện Speaking:** Tích hợp AI để chấm điểm phát âm và luyện nói tự do.
* **🎧 Luyện Listening & Reading:** Kho bài học phong phú được cập nhật liên tục.
* **✍️ Luyện Writing:** Viết bài luận và nhận phản hồi/sửa lỗi.
* **🏆 Gamification:** Bảng xếp hạng (Leaderboard), Thống kê học tập, Huy hiệu.
* **🔔 Thông báo:** Nhắc nhở học tập thời gian thực qua Socket.io và Local Notification.

### 💻 Admin Dashboard (Quản trị viên)
* **Dashboard:** Xem thống kê tổng quan về người dùng và nội dung.
* **Quản lý User:** Xem danh sách, xử lý vi phạm (Ban/Unban).
* **CMS (Content Management System):**
    * Soạn thảo và đăng tải bài học (Listening, Reading, Speaking).
    * Quản lý báo cáo (Reports) từ người dùng.

---

## 🛠️ Cài đặt và Chạy dự án

Dự án bao gồm 2 phần chính: **Mobile App (Flutter)** và **Backend (Node.js)**.

### 1. Yêu cầu hệ thống
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (Mới nhất)
* [Node.js](https://nodejs.org/) (v16 trở lên)
* [MongoDB](https://www.mongodb.com/) (Local hoặc Cloud Atlas)

### 2. Thiết lập Backend
```bash
cd english_for_community_backend

# Cài đặt thư viện
npm install

# Tạo file .env và điền thông tin cấu hình (DB, PORT, MAIL_KEY...)
# (Liên hệ admin để lấy file mẫu)

# Chạy server
npm start
