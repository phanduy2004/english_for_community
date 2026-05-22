# Nghiệp vụ tổng hợp & khoảng trống chức năng (E4C)

Tài liệu này là **bản tóm tắt nghiệp vụ cấp sản phẩm** cho hai miền đang được mô tả chi tiết trong repo:

| Miền | Thư mục chi tiết |
|------|------------------|
| **Giáo viên – Lớp học – Thi trực tuyến** | [`docs/teacher-exam-system/`](teacher-exam-system/README.md) |
| **Phát hành bản app & thông báo cập nhật** | [`docs/auto-update/`](auto-update/README.md) |

**Cách dùng:** đọc file này để nắm **luồng nghiệp vụ đầy đủ** và **còn thiếu gì**; đọc các file `01–11` trong từng thư mục để có **đặc tả kỹ thuật / màn hình / API** đầy đủ.

---

## 1) Hệ thống Giáo viên – Lớp – Thi

### 1.1 Vấn đề nghiệp vụ

Nền tảng gốc tập trung **học tự chủ** và **nội dung do admin quản**. Nhu cầu thực tế: **giáo viên** có một **lớp (cohort)**, giao **bài thi hỗn hợp kỹ năng**, chạy **trực tuyến** (đồng bộ hoặc theo hạn), và **chấm** (tự động + AI + giáo viên chốt).

### 1.2 Actor & trách nhiệm

| Actor | Vai trò nghiệp vụ |
|--------|-------------------|
| **Học sinh** (`user`) | Tham gia lớp (mã/link), làm bài được phép, xem kết quả khi được phát hành. |
| **Giáo viên** (`teacher`, sau duyệt) | Tạo lớp, soạn/giao bài, điều phối phiên thi (nếu realtime), chấm/chốt điểm, phát hành kết quả. |
| **Admin** | Duyệt/từ chối đơn xin làm giáo viên; kiểm soát nền tảng, hỗ trợ khiếu nại. |
| **Hệ thống** | Hạn giờ, trạng thái nộp bài, tính điểm khách quan, hàng đợi chấm, Socket (phiên live), nhật ký kiểm toán (theo spec). |

### 1.3 Khái niệm nghiệp vụ (từ vựng chung)

| Khái niệm | Ý nghĩa |
|-----------|---------|
| **Đơn làm giáo viên** | Bản ghi `pending` → admin `approved` / `rejected`; khi duyệt, tài khoản được quyền workspace giáo viên. |
| **Lớp học (Classroom)** | Không gian do một giáo viên sở hữu; có mã mời; có danh sách thành viên (active / chờ duyệt tùy cấu hình). |
| **Đề thi (Exam template)** | **Một** dạng chuẩn: **bài kiểm tra theo kỹ năng** — giáo viên **bật/tắt** từng kỹ năng trong bốn kỹ năng (nghe, nói, đọc, viết), mỗi phần bật gắn **một** nội dung CMS tương ứng; có thể thêm phần **Ngữ pháp (Grammar)** gồm **chỉ câu trắc nghiệm** (chấm tự động). Không coi “classic builder” là sản phẩm song song cho tính năng mới. |
| **Bài giao (Assignment)** | Liên kết một đề (hoặc phiên) với **lớp** hoặc **link công khai**; kèm chế độ: tự học / theo khung giờ / realtime. |
| **Phiên thi (Exam session)** | Một “lần chạy” tập thể (đặc biệt realtime / có thể scheduled). |
| **Lượt làm (Attempt)** | Một lần làm bài của một học sinh gắn với assignment/session; trạng thái nộp/chấm/phát hành kết quả do server quyết định. |

### 1.4 Luồng nghiệp vụ chính (theo thứ tự vận hành)

1. **Đăng ký làm giáo viên** → trạng thái chờ duyệt → admin duyệt hoặc từ chối có lý do.  
2. **Tạo lớp** → hệ thống cấp mã mời (và link nếu có).  
3. **Học sinh tham gia lớp** → duyệt tự động hoặc chờ giáo viên (theo chính sách lớp — spec mặc định: tự động).  
4. **Soạn đề** — một luồng duy nhất: chọn **kỹ năng nào có trong bài** (nghe / nói / đọc / viết), gắn nội dung CMS cho từng phần được chọn; tùy chọn thêm **Grammar** (danh sách **trắc nghiệm**) → **xuất bản** khi đủ điều kiện (ít nhất một phần; mọi phần bật phải hợp lệ).  
5. **Giao bài** cho lớp và/hoặc tạo **link công khai** (giới hạn lượt, hết hạn — theo spec).  
6. **Làm bài** theo chế độ:  
   - *Tự học*: mở trước deadline, đồng hồ theo quy tắc template.  
   - *Theo lịch*: chỉ trong cửa sổ `[mở, đóng]`; có thể có chính sách vào muộn.  
   - *Realtime*: lobby → giáo viên bắt đầu → đồng bộ đếm ngược / kết thúc.  
7. **Chấm**: Grammar (trắc nghiệm) và phần khách quan khác (nếu có) chấm tự động; bài viết / nói có thể có nháp AI; giáo viên chỉnh và **phát hành kết quả** cho học sinh.  

### 1.5 Quy tắc nghiệp vụ bắt buộc (integrity & tin cậy)

- **Server là nguồn sự thật** cho thời gian, cửa sổ thi, trạng thái nộp; client chỉ hiển thị.  
- Học sinh chỉ thấy bài **được phân quyền** (thành viên lớp + assignment, hoặc token link hợp lệ).  
- Đề thuộc **giáo viên tạo** (admin hỗ trợ theo RBAC nếu có).  
- Dữ liệu nhạy cảm (ghi âm nói): chỉ giáo viên lớp / admin theo chính sách lưu trữ.

### 1.6 KPI / NFR (tham chiếu)

Thời gian tới lớp đầu tiên, tỷ lệ bài chỉ auto-chấm, thời gian trung vị tới khi phát hành điểm; độ trễ Socket cho realtime; giới hạn tốc độ API công khai; audit khi cấp quyền giáo viên — chi tiết trong [`teacher-exam-system/01-business-requirements.md`](teacher-exam-system/01-business-requirements.md).

---

## 2) Hệ thống Phát hành bản app & cập nhật

### 2.1 Vấn đề nghiệp vụ

Khi có bản build mới, cần **thông báo đúng mức độ** (khuyến nghị vs bắt buộc), **không phụ thuộc vào release backend mới** cho mỗi lần đổi copy, và tách **build tự động** khỏi **quyết định cho user nhận bản nào** (duyệt admin).

### 2.2 Actor

| Actor | Vai trò |
|--------|---------|
| **Developer** | Merge `main`, theo dõi CI, changelog. |
| **CI/CD** | Build artifact; (theo spec) tạo **release candidate** `pending_approval` qua API có token. |
| **Admin phát hành** | Duyệt / từ chối / lên lịch / publish / rollback; chọn soft vs force. |
| **App người dùng** | Gọi kiểm tra phiên bản; hiển thị dialog/banner theo `up_to_date` / `soft_update` / `force_update`. |

### 2.3 Luồng nghiệp vụ chuẩn (tóm tắt)

1. CI build thành công → POST tạo **candidate** (bảo vệ bằng `CI_RELEASE_TOKEN`).  
2. Release ở trạng thái chờ → admin xem metadata → **approve** → **publish** (hoặc **schedule** → job đến giờ publish).  
3. App gọi **`/api/app/version-check`** → chỉ **bản published** mới nhất (theo platform/environment) quyết định gợi ý cập nhật.  
4. Policy: nếu `versionCode` client &lt; `minSupportedVersionCode` → **force**; nếu &lt; latest → **soft** (trừ khi cờ force trên release) — logic chi tiết trong service backend.

### 2.4 Trạng thái release (nghiệp vụ)

Theo model `AppRelease`: `pending_approval` → `approved` / `rejected`; có thể `scheduled` → `published`; có thể `archived`; hỗ trợ **rollback** qua API admin. Chi tiết chuyển trạng thái: [`auto-update/09-release-lifecycle-state-machine.md`](auto-update/09-release-lifecycle-state-machine.md).

### 2.5 Triển khai trong repo (thực tế, để tránh hiểu nhầm)

- Backend: `/api/app/version-check`, `/api/app/releases/ci-candidates`, `/api/admin/app-releases/*` (danh sách, duyệt, lịch, publish, rollback), job `appReleaseSchedulerJob`.  
- Flutter: luồng kiểm tra phiên bản (`app_update` bloc, datasource).  
→ Phần giả định “chưa có module app version” trong [`auto-update/README.md`](auto-update/README.md) **đã lỗi thời**; README sẽ được chỉnh để phản ánh trạng thái hiện tại.

---

## 3) Ma trận: đã có trong spec vs còn thiếu / chưa đủ

Bảng dưới đây **tổng hợp khoảng trống** đã được phân tích trong [`teacher-exam-system/11-detailed-feature-implementation-plan.md`](teacher-exam-system/11-detailed-feature-implementation-plan.md) và bổ sung quan sát **hệ thống cập nhật app**. Trạng thái mang tính **nghiệp vụ sản phẩm** (không thay cho test từng PR).

### 3.1 Giáo viên – Lớp – Thi

| Mã | Chủ đề | Nghiệp vụ mong đợi (tóm tắt) | Ghi chú “còn thiếu / chưa đủ” (định hướng) |
|----|--------|------------------------------|-------------------------------------------|
| **F1** | Onboarding giáo viên + admin | Đơn, duyệt/từ chối, audit, chống leo quyền | Hoàn thiện audit log theo UC-2; filter/lý do trên UI admin/applicant |
| **F2** | Lớp & thành viên | Tabs Overview / Members / Assignments; xóa thành viên; xoay mã; archive | **Đã có trên Flutter** (tab Members, Settings chỉnh tên/mô tả, rotate mã, archive); tinh chỉnh UX theo `03`/`08` nếu cần |
| **F3** | **Soạn đề chuẩn (skills + Grammar)** | Một luồng: chọn **kỹ năng** (nghe/nói/đọc/viết), gắn CMS; tùy chọn **Grammar** (MCQ); publish theo subset | Cần UI/BE cho **toggle từng kỹ năng**, block Grammar MCQ, validation publish; hiện repo vẫn gần với “đủ cả 4 slot” — cần chỉnh cho đúng nghiệp vụ mới |
| **F4** | *(Đã gộp vào F3)* | — | Không còn là hạng mục song song “integrated vs classic” trên mặt bằng sản phẩm |
| **F5** | Giao bài & link công khai | maxUses, expiresAt, rotate token, đóng assignment; UX đầy đủ | **Đã bổ sung** wizard (public link + token dialog), dashboard (copy / rotate / đóng); tiếp tục hardening & copy hướng dẫn học sinh nếu cần |
| **F6** | Runner học sinh | Hub theo **phần đã bật**; CMS skill như hiện tại; **Grammar** làm MCQ trong luồng thi | Cần màn MCQ Grammar + autosave; đồng bộ trọng số điểm với backend; classic runner chỉ còn giá trị legacy nếu còn đề cũ |
| **F7** | Scheduled | UI cửa sổ giờ địa phương, disable Start + copy lỗi đồng nhất server | Kiểm tra đồng bộ copy/trạng thái nút với `lateEntryPolicy` |
| **F8** | Realtime + Socket | Máy trạng thái lobby→live→closed; reconnect | Khung có; cần **hardening + E2E** theo `05` |
| **F9** | Chấm & phát hành | Grammar + MCQ auto; AI/manual cho viết/nói; batch release nếu cần | Hoàn thiện ma trận theo phần đã bật; batch release |
| **F10** | Toàn vẹn & rate limit | Telemetry tab blur (tuỳ chọn), rate limit join/start công khai | **Preview/start public exam** dùng `examPublicJoinLimiter` (24 req/phút/IP); các hạng mục khác xem Phase 8 |
| **F11** | Analytics & polish | Metrics tối thiểu, empty states | Theo `09` / KPI `01` |

### 3.2 Phát hành & cập nhật app

| Chủ đề | Nghiệp vụ mong đợi | Ghi chú “còn thiếu / chưa đủ” |
|--------|-------------------|------------------------------|
| **Client policy** | Soft/force, copy changelog, store URL | Rà soát **tần suất gọi**, cache, iOS vs Android parity trong Flutter |
| **Admin UI** | Màn quản lý release trong admin console | Spec trong `07`; cần đối chiếu với màn Flutter admin thực tế |
| **CI** | Workflow `main` → candidate | Theo `08`; cần xác nhận pipeline repo có gọi đúng `ci-candidates` + secret |
| **Observability** | Đếm check / hiện popup / click cập nhật (`01` NFR) | Có thể chưa đủ instrumentation — nằm trong khoảng trống vận hành |
| **Audit** | Mọi approve/reject/publish (`06` §4) | Xác nhận đã ghi `AdminAuditLog` đủ sự kiện theo spec |

---

## 4) Định nghĩa “xong nghiệp vụ” (mức tổ chức)

### 4.1 Miền Giáo viên – Thi

- Đủ **UC-1…UC-8** trong [`01-business-requirements.md`](teacher-exam-system/01-business-requirements.md) với **một** luồng soạn đề skills + Grammar MCQ và **bằng chứng acceptance** trong `11`.  
- Không phá vỡ luồng `user` / `admin` hiện có.

### 4.2 Miền Cập nhật app

- User chỉ nhận gợi ý từ release **published**; admin có đủ thao tác duyệt/lịch/rollback; CI không tự publish cho end-user.  
- Nghiệm thu theo [`auto-update/05-checklist-and-acceptance.md`](auto-update/05-checklist-and-acceptance.md).

---

## 5) Bảo trì tài liệu

- Khi ship một mảng (ví dụ F6 xong hết gap), cập nhật [`11-detailed-feature-implementation-plan.md`](teacher-exam-system/11-detailed-feature-implementation-plan.md): **Gap → Done** và ghi commit/PR.  
- File **này** (`00-nghiep-vu-tong-hop-va-khoang-trong.md`) nên chỉnh **định kỳ** (ví dụ mỗi sprint) để ma trận mục 3 phản ánh đúng backlog thực tế.
