# 05 - Checklist And Acceptance

## 1) Functional checklist

- [ ] Backend trả về đúng `up_to_date` khi app đã mới nhất.
- [ ] Backend trả về đúng `soft_update` khi có bản mới nhưng không bắt buộc.
- [ ] Backend trả về đúng `force_update` khi app quá cũ.
- [ ] Flutter hiển thị đúng UI cho từng status.
- [ ] Nút "Cập nhật" mở đúng URL store/download.
- [ ] Force update chặn truy cập các màn hình học tập.

## 2) CI/CD checklist

- [ ] Push nhánh release kích hoạt build pipeline.
- [ ] Build artifact thành công và upload được.
- [ ] Pipeline gọi được API publish release metadata.
- [ ] Release metadata tạo thành công và có audit log.

## 3) Test scenarios tối thiểu

- [ ] Scenario A: current = latest -> không hiện popup.
- [ ] Scenario B: current < latest, current >= minSupported -> soft update popup.
- [ ] Scenario C: current < minSupported -> force update popup.
- [ ] Scenario D: API timeout -> fallback không crash app.
- [ ] Scenario E: storeUrl null -> fallback downloadUrl.

## 4) Acceptance criteria

- [ ] Tỷ lệ false-positive force update = 0 trong UAT.
- [ ] Không crash app liên quan đến app-update flow.
- [ ] Team có thể publish metadata release trong < 5 phút.
- [ ] Có tài liệu hướng dẫn và rollback rõ ràng.

## 5) Rollback plan

Nếu release metadata sai:

1. Admin disable record release (`isActive = false`).
2. Re-publish metadata đúng.
3. Kiểm tra lại endpoint version-check.
4. Ghi audit incident và nguyên nhân.

## 6) Tài liệu liên quan

- `docs/auto-update/README.md`
- `docs/auto-update/01-business-requirements.md`
- `docs/auto-update/02-technical-architecture.md`
- `docs/auto-update/03-ci-cd-release-pipeline.md`
- `docs/auto-update/04-implementation-roadmap-for-ai.md`
