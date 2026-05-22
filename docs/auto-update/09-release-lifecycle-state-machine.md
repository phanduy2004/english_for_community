# 09 - State Machine vòng đời release

## 1) Trạng thái

- `pending_approval`
- `approved`
- `scheduled`
- `published`
- `rejected`
- `archived`

## 2) Luật chuyển trạng thái

- `pending_approval -> approved` (admin approve)
- `pending_approval -> rejected` (admin reject)
- `approved -> scheduled` (admin chọn lịch phát hành)
- `approved -> published` (admin publish ngay)
- `scheduled -> published` (job theo lịch hoặc admin bấm publish)
- `published -> archived` (khi có bản mới publish thay thế)
- `published -> archived + rollback published` (admin rollback)

Không hợp lệ:

- `rejected -> published`
- `archived -> published`
- `pending_approval -> published` trực tiếp bởi CI

## 3) Rule active release

Mỗi `platform + environment` tại một thời điểm chỉ có:

- 1 release `published` và `isActive=true`.

Khi publish bản mới:

1. set `isActive=false` cho bản active cũ.
2. set `isActive=true` cho bản mới.

## 4) Rule API version-check

Endpoint `version-check` chỉ đọc:

- release có `status=published`
- release có `isActive=true`
- theo đúng `platform + environment`

## 5) Rule force update

Nếu release `updateType=force`:

- app version < `minSupportedVersionCode` => force update
- hoặc admin bật force toàn bản (nếu cần override)

## 6) Audit bắt buộc

Mọi transition phải ghi:

- actor, thời gian, trạng thái trước/sau, lý do, metadata liên quan.

## 7) Biểu diễn text state diagram

```text
CI tạo candidate
  -> pending_approval
      -> approved
          -> scheduled
              -> published
          -> published
      -> rejected

published -> archived (khi có bản mới)
published -> rollback -> archived + published bản trước
```
