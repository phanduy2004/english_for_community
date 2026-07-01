# DB migrations (D0+)

Chạy **chỉ trên staging** trước. Production = **[MANUAL]** sau backup.

| ID | Mô tả |
|----|--------|
| `004-speaking-set-id-objectid` | `SpeakingAttempt` / `SpeakingEnrollment`: `speakingSetId` String → ObjectId |

```bash
npm run migrate:dry    # thống kê, không ghi
npm run migrate        # chạy migration chưa apply
npm run golden:capture # chụp JSON baseline (~10 endpoint)
npm run audit:t1       # orphan / index / explain
```

Rollback: revert commit; additive fields/index có thể giữ; TTL — drop index trước khi rút hạn.
