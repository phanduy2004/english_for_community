# App Update Notification - Documentation Set

Bộ tài liệu này mô tả đầy đủ phạm vi, kiến trúc, và kế hoạch triển khai tính năng:

- Tự động build APK khi có thay đổi source ở nhánh `main`.
- Tạo bản ghi release mới (version metadata).
- Backend thông báo cho app có bản cập nhật mới.
- App Flutter hiện popup/banner yêu cầu người dùng cập nhật.
- Có quy trình **Admin duyệt release** trước khi user nhận cập nhật.

## Mục tiêu

- Tạo "nguồn sự thật" để AI và dev đọc là có thể implement đúng.
- Chia nhỏ theo phase để triển khai an toàn.
- Chuẩn hóa quy trình CI/CD và release.

## Cấu trúc tài liệu

- `docs/auto-update/01-business-requirements.md`
  - Yêu cầu nghiệp vụ, actor, use case, policy cập nhật.
- `docs/auto-update/02-technical-architecture.md`
  - Kiến trúc backend + mobile + dữ liệu version.
- `docs/auto-update/03-ci-cd-release-pipeline.md`
  - Luồng từ push code -> build artifact -> update metadata.
- `docs/auto-update/04-implementation-roadmap-for-ai.md`
  - Kế hoạch implement theo phase, task-level cho AI.
- `docs/auto-update/05-checklist-and-acceptance.md`
  - Checklist test, acceptance criteria, rollback.
- `docs/auto-update/06-admin-approval-business-flow.md`
  - Nghiệp vụ duyệt release bởi admin (pending/approved/rejected/published).
- `docs/auto-update/07-admin-release-management-spec.md`
  - Đặc tả API backend + màn hình admin quản lý phiên bản.
- `docs/auto-update/08-main-branch-cicd-auto-build.md`
  - Workflow CI/CD tự động khi `main` thay đổi source code.
- `docs/auto-update/09-release-lifecycle-state-machine.md`
  - State machine và rule chuyển trạng thái release.
- `docs/auto-update/10-ai-implementation-prompts-admin-approval.md`
  - Prompt sẵn cho AI để implement đầy đủ theo nghiệp vụ mới.

## Giả định hiện tại

- Mobile app: Flutter (`english_for_community/`).
- Backend API: Node.js (`english_for_community_backend/`).
- Notification stack: FCM đã sẵn có trong project.
- **Đã có** module quản lý phiên bản ở mức backend + client kiểm tra: model `AppRelease`, `/api/app/version-check`, `/api/app/releases/ci-candidates` (token CI), `/api/admin/app-releases/*`, job lịch publish; Flutter có luồng `app_update`. Cần tiếp tục hoàn thiện theo checklist `05` và UI admin trong `07` nếu chưa đủ so với spec.

## Tóm tắt nghiệp vụ chéo miền

- Bản tổng hợp nghiệp vụ + ma trận khoảng trống (Giáo viên–Thi **và** Cập nhật app): [`../product/nghiep-vu-tong-hop-va-khoang-trong.md`](../product/nghiep-vu-tong-hop-va-khoang-trong.md).

## Định hướng cập nhật

Hệ thống hỗ trợ 2 chế độ:

- `soft_update`: Khuyến nghị cập nhật, có thể "Để sau".
- `force_update`: Bắt buộc cập nhật để tiếp tục sử dụng app.

## Quy tắc đặt version

- Version app theo semantic version: `major.minor.patch+buildNumber`.
- Android:
  - `versionName`: chuỗi hiển thị (ví dụ `1.5.0`).
  - `versionCode`: số tăng dần (ví dụ `10500`).

## Đọc theo thứ tự để implement

0. **`../product/nghiep-vu-tong-hop-va-khoang-trong.md`** — tóm tắt nghiệp vụ + khoảng trống chéo miền (nếu cần).
1. Đọc `01-business-requirements.md`.
2. Đọc `02-technical-architecture.md`.
3. Đọc `06-admin-approval-business-flow.md`.
4. Đọc `07-admin-release-management-spec.md`.
5. Đọc `08-main-branch-cicd-auto-build.md`.
6. Đọc `09-release-lifecycle-state-machine.md`.
7. Chạy task trong `10-ai-implementation-prompts-admin-approval.md`.
8. Nghiệm thu theo `05-checklist-and-acceptance.md`.
