# Bổ sung ĐẶC TẢ USE CASE — các chức năng mới (dán vào mục "Mô tả chi tiết Use case")

> Khung bảng bám theo báo cáo hiện có. Đánh lại số Bảng/UC cho khớp thứ tự của bạn. Nhóm theo tác nhân: **Giáo viên (Teacher)**, **Học viên – Lớp học & Thi**, **Chức năng chung mới**, **Admin mở rộng**.

---

## A. TÁC NHÂN: GIÁO VIÊN (TEACHER)

### UC-T1. Quản lý lớp học
| Mục | Nội dung |
|---|---|
| Tác nhân | Giáo viên |
| Mô tả | Tạo lớp, cấu hình thông tin lớp, quản lý thành viên (duyệt/loại), xem hoạt động lớp |
| Tiền điều kiện | Đã đăng nhập vai trò Teacher |
| Luồng chính | 1) Vào Dashboard → "Lớp học" → Tạo lớp (tên, mô tả, ảnh bìa) → hệ thống sinh **mã tham gia/liên kết mời**. 2) Chia sẻ mã cho học viên. 3) Xem danh sách thành viên, duyệt yêu cầu, loại thành viên khi cần. 4) Xem nhật ký hoạt động lớp (giao bài, thành viên mới…). |
| Luồng phụ | Chỉnh sửa/lưu trữ lớp; đồng bộ lớp từ Google Classroom (LTI). |
| Hậu điều kiện | Lớp tồn tại, học viên tham gia được |

### UC-T2. Soạn đề thi (đơn kỹ năng & tích hợp đa kỹ năng)
| Mục | Nội dung |
|---|---|
| Tác nhân | Giáo viên |
| Mô tả | Tạo ngân hàng đề: đề một kỹ năng hoặc **đề tích hợp** gồm nhiều phần (Đọc, Nghe hiểu, Nghe-chép, Viết…) |
| Tiền điều kiện | Đã đăng nhập Teacher |
| Luồng chính | 1) "Đề thi" → Tạo mới → chọn loại (đơn/ tích hợp). 2) Thêm các **phần (section)** theo kỹ năng; với mỗi phần thêm câu hỏi/ngữ liệu (audio, đoạn đọc, đề viết…), đáp án, thang điểm. 3) Đặt thời lượng, cấu hình chấm. 4) Lưu (nháp/hoàn tất). |
| Luồng phụ | Soạn khung ngữ pháp (grammar editor) cho phần Viết; lưu **nháp payload** đề kỹ năng. |
| Ngoại lệ | Thiếu đáp án/điểm → cảnh báo, không cho phát hành |
| Hậu điều kiện | Đề sẵn sàng để giao |

### UC-T3. Giao bài thi (Assignment Wizard)
| Mục | Nội dung |
|---|---|
| Tác nhân | Giáo viên |
| Mô tả | Giao một đề cho lớp/học viên với cấu hình thời gian và chế độ thi |
| Tiền điều kiện | Có đề thi và ít nhất một lớp |
| Luồng chính | 1) Chọn đề → "Giao bài". 2) Chọn lớp/nhóm học viên. 3) Đặt **thời gian mở–đóng**, thời lượng, số lần làm, chế độ: **giao thường / phiên trực tiếp (session) / công khai qua liên kết**. 4) (Tùy chọn) áp **mẫu giao bài (preset)**. 5) Xác nhận → hệ thống tạo assignment + gửi thông báo cho học viên. |
| Luồng phụ | Lưu cấu hình thành **preset** để tái sử dụng |
| Hậu điều kiện | Học viên thấy bài trong "Bài thi được giao" |

### UC-T4. Chấm điểm (tự động + AI + thủ công) và Sổ điểm
| Mục | Nội dung |
|---|---|
| Tác nhân | Giáo viên |
| Mô tả | Chấm bài làm của học viên và quản lý điểm theo lớp |
| Tiền điều kiện | Có bài làm (attempt) đã nộp |
| Luồng chính | 1) Vào "Chấm điểm" → chọn assignment → danh sách bài nộp. 2) Phần khách quan **chấm tự động**; phần Viết/Nói có **gợi ý điểm & nhận xét từ AI**; giáo viên **chấm tay / điều chỉnh** và ghi nhận xét. 3) Lưu điểm từng bài. 4) Xem **Sổ điểm (Gradebook)** tổng hợp theo lớp; **Xuất điểm** (export). |
| Luồng phụ | Chấm theo từng kỹ năng (skill work panel); chấm bài viết tích hợp |
| Hậu điều kiện | Điểm được lưu, sẵn sàng trả kết quả |

### UC-T5. Mở & giám sát phiên thi trực tiếp (Live Proctoring)
| Mục | Nội dung |
|---|---|
| Tác nhân | Giáo viên |
| Mô tả | Mở phiên thi thời gian thực và giám sát học viên trong lúc thi |
| Tiền điều kiện | Có assignment chế độ "phiên trực tiếp" |
| Luồng chính | 1) Mở phiên (session) → học viên tham gia. 2) Bảng điều khiển hiển thị tiến độ từng học viên theo thời gian thực. 3) Xem **màn hình/trạng thái học viên (live view)**. 4) Nhận **cảnh báo gian lận (integrity event)** khi học viên rời màn hình/chuyển app. 5) Kết thúc phiên. |
| Ngoại lệ | Học viên mất kết nối → đánh dấu, cho phép khôi phục |
| Hậu điều kiện | Có dữ liệu bài làm + nhật ký giám sát |

### UC-T6. Trả kết quả cho học viên
| Mục | Nội dung |
|---|---|
| Tác nhân | Giáo viên |
| Mô tả | Công bố điểm & lời giải cho học viên (từng bài hoặc theo lô) |
| Luồng chính | 1) Sau khi chấm xong → "Trả kết quả" (release) cho một bài hoặc **batch cả assignment**. 2) Hệ thống gửi thông báo; học viên **xem lại đáp án, nhận xét, lời giải**. |
| Hậu điều kiện | Học viên thấy điểm & xem lại được |

### UC-T7. Thống kê lớp, Lịch, Hộp thư
| Mục | Nội dung |
|---|---|
| Tác nhân | Giáo viên |
| Mô tả | Xem **Analytics** (biểu đồ kết quả/tham gia của lớp), **Calendar** (lịch bài thi/hạn nộp), **Inbox** (thông báo & tương tác) |
| Luồng chính | Chọn tab tương ứng trên Teacher Shell → xem dữ liệu tổng hợp/biểu đồ; lọc theo lớp/thời gian. |

---

## B. TÁC NHÂN: HỌC VIÊN — LỚP HỌC & THI (mới)

### UC-S1. Tham gia lớp học
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên |
| Mô tả | Tham gia lớp bằng mã/liên kết mời |
| Tiền điều kiện | Đã đăng nhập |
| Luồng chính | 1) "Lớp học của tôi" → Tham gia → nhập **mã lớp** hoặc mở **liên kết mời**. 2) Hệ thống ghi danh (Enrollment) → lớp xuất hiện trong danh sách. |
| Ngoại lệ | Mã sai/hết hạn → báo lỗi |
| Hậu điều kiện | Học viên là thành viên lớp |

### UC-S2. Xem chi tiết lớp & bảng tin
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên |
| Mô tả | Xem thành viên, bài được giao, thông báo/hoạt động lớp |
| Luồng chính | Mở lớp → tab thành viên / bài tập–bài thi / bảng tin hoạt động. |

### UC-S3. Chat nhóm lớp (thời gian thực)
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên, Giáo viên |
| Mô tả | Trò chuyện nhóm trong lớp theo thời gian thực |
| Tiền điều kiện | Là thành viên lớp |
| Luồng chính | 1) Mở "Chat lớp" → tham gia room Socket.IO của lớp. 2) Gửi/nhận **tin nhắn văn bản, hình ảnh/tệp** realtime. 3) Hệ thống cập nhật **trạng thái đã đọc**; đẩy thông báo tin nhắn mới. |
| Ngoại lệ | Mất mạng → tự kết nối lại, đồng bộ tin chưa đọc |
| Hậu điều kiện | Lịch sử chat được lưu |

### UC-S4. Xem & làm bài thi được giao (đa kỹ năng, có tính giờ)
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên |
| Mô tả | Làm bài thi tích hợp nhiều phần, tự lưu tiến độ, nộp bài |
| Tiền điều kiện | Có assignment còn hạn |
| Luồng chính | 1) "Bài thi được giao" → chọn bài → xác nhận bắt đầu (tạo **attempt** + đồng hồ). 2) Làm lần lượt các phần (Đọc, Nghe hiểu, Nghe-chép, Viết…); hệ thống **tự lưu** câu trả lời. 3) Nộp bài (hoặc hết giờ → tự nộp). 4) Chấm tự động phần khách quan; phần tự luận chờ chấm. |
| Ngoại lệ | Rời app → ghi **integrity event**; mất mạng → khôi phục attempt khi vào lại |
| Hậu điều kiện | Có bài làm; xem lại khi được trả kết quả |

### UC-S5. Tham gia phiên thi trực tiếp
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên |
| Mô tả | Vào phòng thi thời gian thực do giáo viên mở |
| Luồng chính | 1) Vào **sảnh phiên thi (lobby)** → chờ giáo viên mở. 2) Tham gia phiên → làm bài đồng bộ thời gian; trạng thái được đẩy về giáo viên (live view). 3) Nộp bài khi xong/hết giờ. |

### UC-S6. Thi công khai qua liên kết
| Mục | Nội dung |
|---|---|
| Tác nhân | Khách/Học viên |
| Mô tả | Làm bài thi công khai bằng liên kết/token, không cần được giao trước |
| Luồng chính | 1) Mở liên kết → **xem trước** thông tin đề. 2) Bắt đầu/tham gia → làm bài → nộp. |
| Ghi chú | Có giới hạn tần suất (rate limit) chống lạm dụng |

### UC-S7. Xem lại đáp án & lời giải
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên |
| Mô tả | Sau khi được trả kết quả, xem điểm từng phần, đáp án đúng, nhận xét |
| Luồng chính | Mở bài đã có kết quả → xem **đối chiếu đáp án (review)** theo từng kỹ năng, nhận xét của giáo viên/AI. |

---

## C. CHỨC NĂNG CHUNG MỚI

### UC-C1. Luyện Nghe hiểu (Listening Comprehension)
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên |
| Mô tả | Nghe đoạn hội thoại/bài và trả lời trắc nghiệm hiểu nội dung (khác Nghe-chép chính tả) |
| Luồng chính | 1) Chọn bài nghe hiểu theo độ khó. 2) Nghe audio → trả lời các câu trắc nghiệm. 3) Nộp → chấm & lưu **ListeningCompAttempt**; xem kết quả/giải thích. |

### UC-C2. Thảo luận trong bài học (Cue Comment)
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên |
| Mô tả | Bình luận, hỏi–đáp tại từng phân đoạn (cue) của bài nghe |
| Luồng chính | 1) Mở tab Thảo luận trong bài nghe. 2) Viết bình luận gắn với cue; **trả lời** bình luận khác. 3) Người liên quan **nhận thông báo tương tác**. |

### UC-C3. Nhận thông báo (in-app & push)
| Mục | Nội dung |
|---|---|
| Tác nhân | Học viên, Giáo viên |
| Mô tả | Nhận thông báo hệ thống/tương tác: được giao bài, có tin nhắn/bình luận, trả kết quả, nhắc học |
| Luồng chính | 1) Sự kiện phát sinh → server tạo **Notification** + đẩy realtime/push. 2) Người dùng xem danh sách, **bấm để điều hướng** tới nội dung liên quan (action). |

### UC-C4. Kiểm tra & cập nhật phiên bản (OTA)
| Mục | Nội dung |
|---|---|
| Tác nhân | Khách/Học viên/Giáo viên (mọi phiên bản app) |
| Mô tả | App tự kiểm tra bản mới và nhắc/buộc cập nhật |
| Tiền điều kiện | Có kết nối mạng |
| Luồng chính | 1) Khi mở app/quay lại/đăng nhập → gọi `version-check` gửi `versionCode`. 2) Server so sánh với bản **published** → trả `up_to_date / soft_update / force_update`. 3) Nếu có bản mới → hộp thoại **Cập nhật ngay**: soft (bỏ qua được) / force (bắt buộc). 4) Bấm → tải & cài APK. |
| Ngoại lệ | Lỗi mạng → bỏ qua im lặng, thử lại lần sau |
| Hậu điều kiện | Người dùng cập nhật lên bản mới |

---

## D. TÁC NHÂN: ADMIN (mở rộng)

### UC-A1. Quản lý phát hành phiên bản (Release Management)
| Mục | Nội dung |
|---|---|
| Tác nhân | Admin |
| Mô tả | Duyệt và phát hành các bản ứng viên do CI tạo; rollback khi cần |
| Tiền điều kiện | Có bản **candidate** (CI đã build) |
| Luồng chính | 1) Vào "Quản lý phiên bản" → xem theo trạng thái (Chờ duyệt / Đã duyệt / Đã phát hành / Từ chối / Lưu trữ). 2) **Duyệt (approve)** → **Phát hành (publish)** (hoặc **lên lịch**). 3) Khi phát hành, hệ thống đặt bản mới `isActive`, lưu trữ bản cũ. 4) **Rollback** về bản trước nếu lỗi. |
| Ngoại lệ | Chuyển trạng thái không hợp lệ → chặn (state machine) |
| Hậu điều kiện | Client nhận được bản phát hành mới qua `version-check` |

### UC-A2. Trung tâm vận hành (Ops Center) & Nhật ký kiểm toán
| Mục | Nội dung |
|---|---|
| Tác nhân | Admin |
| Mô tả | Theo dõi vận hành hệ thống và tra **nhật ký thao tác quản trị (Audit Log)** |
| Luồng chính | Xem chỉ số vận hành; tra cứu hành động admin (ai làm gì, khi nào) qua **AdminAuditLog**. |

### UC-A3. Quản lý nội dung mở rộng
| Mục | Nội dung |
|---|---|
| Tác nhân | Admin |
| Mô tả | Bổ sung CMS cho **Nghe hiểu (Listening Comprehension)** và **Nói (Speaking)**; **phiên bản hóa chủ đề Viết** (versioning + rollback) |
| Luồng chính | Thêm/sửa/xóa nội dung các kỹ năng; với chủ đề Viết, xem lịch sử phiên bản và **khôi phục (rollback)**. |

---

### Ghi chú
- Mỗi bảng trên tương ứng một use case — tạo tiêu đề "Bảng N: Đặc tả …" như các bảng hiện có trong báo cáo và đánh số tiếp.
- Cần bổ sung **luồng thay thế/ngoại lệ** chi tiết hơn cho từng UC thì báo mình.
