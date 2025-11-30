# 📘 English for Community (EFC)

**English for Community** là nền tảng học tiếng Anh toàn diện, kết hợp giữa ứng dụng di động (Mobile App) và hệ thống quản trị nội dung (CMS). Dự án tập trung vào việc cải thiện 4 kỹ năng: Nghe, Nói, Đọc, Viết thông qua các phương pháp tương tác và AI.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)

---

## ⚠️ QUAN TRỌNG: CÀI ĐẶT DỮ LIỆU TRƯỚC KHI CHẠY (READ THIS FIRST)

Do giới hạn kích thước file của GitHub, file cơ sở dữ liệu từ điển (`dictionary.db` ~200MB) đã được nén lại. **Bạn bắt buộc phải giải nén thủ công trước khi chạy ứng dụng.**

1.  Truy cập thư mục: `english_for_community/assets/db/`
2.  Tìm file nén: **`dictionary.rar`** (hoặc `.zip`).
3.  Click chuột phải chọn **Extract Here** (Giải nén tại đây).
4.  Đảm bảo sau khi giải nén, bạn có file tên là: **`dictionary.db`** nằm ngay tại thư mục đó.

> ❌ **Nếu không có file `dictionary.db`, tính năng Từ điển sẽ bị lỗi.**

---

## ✨ Tính năng chính

### 📱 Mobile App (User)
* **📚 Từ điển Offline:** Tra cứu nhanh với dữ liệu cục bộ (Cần giải nén file DB như hướng dẫn trên).
* **🗣️ Luyện Speaking:** Tích hợp AI chấm điểm phát âm.
* **🎧 Luyện Listening & Reading:** Kho bài học đa dạng.
* **✍️ Luyện Writing:** Viết bài luận và nhận phản hồi.
* **🏆 Gamification:** Bảng xếp hạng, Thống kê, Huy hiệu.
* **🔔 Real-time:** Thông báo nhắc nhở học tập.

### 💻 Admin Dashboard (Quản trị viên)
* **Dashboard:** Thống kê người dùng và nội dung.
* **Quản lý User:** Danh sách user, ban/unban.
* **CMS:** Soạn thảo bài học, quản lý báo cáo vi phạm.

---

## 🛠️ Hướng dẫn Cài đặt (Installation)

### 1. Backend (Node.js)
```bash
cd english_for_community_backend

# Cài đặt thư viện
npm install

# Cấu hình biến môi trường (.env) và chạy server
npm start
