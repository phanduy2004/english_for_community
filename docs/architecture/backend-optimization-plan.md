# Kế hoạch tối ưu Backend `english_for_community_backend`

> Tài liệu hướng dẫn triển khai cho Cursor. Mỗi task có: **vị trí file**, **vấn đề**, **code before/after** (hoặc hướng dẫn rõ ràng), và **bước kiểm tra**.
> Stack: Node.js + Express (ESM) + MongoDB/Mongoose + Socket.IO. Quy mô ~23k LOC (22 controllers, 50 services, 34 models, 23 routes).

## Cách dùng tài liệu này (đọc trước khi sửa)

1. **Số dòng có thể lệch** so với thời điểm viết — luôn định vị bằng **tên hàm / đoạn code** trong mỗi task, đừng tin tuyệt đối vào số dòng.
2. Làm **tuần tự theo giai đoạn** (G0 → G4). Mỗi giai đoạn commit riêng để dễ rollback.
3. Sau mỗi giai đoạn: chạy `npm start` (hoặc `npm run dev`) kiểm tra server khởi động + smoke test vài API chính (login, list listening, mở dashboard giáo viên).
4. Các task gắn nhãn **[MANUAL]** cần con người thao tác ngoài code (rotate key, purge git history) — không giao cho Cursor.

## Bảng tổng hợp ưu tiên

| Giai đoạn | Mục tiêu | Task | Effort |
|-----------|----------|------|--------|
| **G0** | Vá bảo mật khẩn | S1, S2, S4, S5 | 0.5–1 ngày |
| **G1** | Tải dữ liệu nhanh (quick wins) | P1, P2, P6, P7 | 1–2 ngày |
| **G2** | Khử N+1 & aggregation | P3, P4, P5, P8 | 2–4 ngày |
| **G3** | Chuẩn hóa kiến trúc | A1, A2, A3, A4, A6, A5 | 3–5 ngày |
| **G4** | Hoàn thiện vận hành | S3, S6, OPS1–OPS4 | 2–3 ngày |

---

# GIAI ĐOẠN 0 — Vá bảo mật khẩn

## S1 — [Critical] Thêm `requireAdmin` cho route admin của Speaking & Reading

**Vấn đề:** Toàn bộ route tạo/sửa/xóa/khôi phục nội dung Speaking & Reading chỉ có `authenticate`, **thiếu `requireAdmin`** → mọi user thường đăng nhập đều CRUD được nội dung. (Listening đã làm đúng — dùng làm mẫu: [listeningRoutes.js:43-46](../../english_for_community_backend/src/routes/listeningRoutes.js#L43-L46).)

**File 1:** `src/routes/speakingRoutes.js`

```js
// BEFORE
import { authenticate } from '../middleware/auth.js';
...
router.get('/admin/list', authenticate, speakingController.admin.getList);
router.get('/admin/deleted', authenticate, speakingController.admin.getDeleted);
router.get('/admin/:id', authenticate, speakingController.admin.getDetail);
router.post('/admin/:id/restore', authenticate, speakingController.admin.restore);
router.post('/admin', authenticate, speakingController.admin.create);
router.put('/admin/:id', authenticate, speakingController.admin.update);
router.delete('/admin/:id', authenticate, speakingController.admin.delete);
```

```js
// AFTER
import { authenticate, requireAdmin } from '../middleware/auth.js';
...
router.get('/admin/list', authenticate, requireAdmin, speakingController.admin.getList);
router.get('/admin/deleted', authenticate, requireAdmin, speakingController.admin.getDeleted);
router.get('/admin/:id', authenticate, requireAdmin, speakingController.admin.getDetail);
router.post('/admin/:id/restore', authenticate, requireAdmin, speakingController.admin.restore);
router.post('/admin', authenticate, requireAdmin, speakingController.admin.create);
router.put('/admin/:id', authenticate, requireAdmin, speakingController.admin.update);
router.delete('/admin/:id', authenticate, requireAdmin, speakingController.admin.delete);
```

**File 2:** `src/routes/readingRoutes.js` — file dùng `router.use(authenticate)` ở đầu, cần thêm `requireAdmin` cho từng route ghi/quản trị:

```js
// AFTER
import { authenticate, requireAdmin } from '../middleware/auth.js';
...
router.get('/admin/deleted', requireAdmin, readingController.getDeletedReadings);
router.post('/:id/restore', requireAdmin, readingController.restoreReading);
router.post('/', requireAdmin, readingController.createReading);
router.delete('/:id', requireAdmin, readingController.deleteReading);
// Giữ nguyên (user thường được phép): GET '/', GET '/:id', GET '/history/:readingId', POST '/submit'
```

> Lưu ý thứ tự route: `/admin/deleted` và `/:id/restore` phải đặt **trước** `GET '/:id'` để không bị nuốt param (Listening đã xử lý đúng).

**Kiểm tra:** Đăng nhập bằng tài khoản `role: 'user'`, gọi `POST /api/speaking/admin` và `POST /api/reading/` → phải trả **403**. Tài khoản `admin` vẫn 200/201.

---

## S2 — [Critical][MANUAL] Rotate toàn bộ secrets đã từng commit vào git

**Vấn đề:** File `.env` (Mongo URI có credentials, JWT secret, Cloudinary/Firebase/Groq keys) đã từng được commit (lịch sử git: `bc040b8`, `a5a2eb7`, `59f4fc9`). Hiện đã `.gitignore` nhưng vẫn nằm trong history → ai có quyền đọc repo đều khôi phục được.

**Hành động (con người làm, ngoài Cursor):**
1. **Coi như tất cả key đã lộ → rotate ngay:**
   - MongoDB Atlas: đổi password user DB, cập nhật `MONGO_URI`.
   - `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET`: tạo chuỗi ngẫu nhiên mới (≥ 32 bytes). *Lưu ý: đổi sẽ logout toàn bộ session hiện tại — chấp nhận được.*
   - Cloudinary `api_secret`, Firebase service account (tạo key mới + thu hồi key cũ), `GROQ_API_KEY`, OpenAI/Google GenAI keys, VAPI keys.
2. **Purge khỏi history** (nếu repo còn dùng lâu dài): dùng [`git filter-repo`](https://github.com/newren/git-filter-repo) hoặc BFG để xóa `english_for_community_backend/.env`, rồi force-push. Nếu không rewrite được history thì ít nhất phải rotate (bước 1) là bắt buộc.
3. Xác nhận `.env` vẫn nằm trong `.gitignore` (đang đúng ở [.gitignore](../../.gitignore)).

---

## S4 — [High] Gom xử lý lỗi tập trung, ngừng rò rỉ `err.message` ra client

**Vấn đề:** Hàng chục controller trả thẳng `error.message` (lộ schema/query nội bộ), ví dụ `'Server error: ' + err.message`. Cần global error handler trả thông điệp generic cho 5xx, chỉ echo message cho lỗi chủ động (`statusCode < 500`).

> Task này gắn liền với **A1 (global error handler)** ở G3. Để tiết kiệm công, **làm A1 ngay tại G0** rồi G3 chỉ còn dọn `try/catch` thừa. Xem code đầy đủ ở **A1**.

**Tối thiểu cần đạt sau G0:** mọi response 5xx trả `{ message: 'Server error' }` (không kèm `error.message`), lỗi thật log ở server bằng `console.error`.

---

## S5 — [High] Thêm middleware hardening + giới hạn upload

### S5a — helmet + compression + request logging

**Cài package:**
```bash
npm install helmet compression morgan
```

**File:** `src/app.js` — thêm vào đầu chuỗi middleware (trước các route):

```js
// BEFORE
import cors from 'cors';
...
const app = express();
...
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(mongoSanitize);
app.use('/api/auth', authRoutes);
```

```js
// AFTER
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
...
const app = express();

app.use(helmet());                 // security headers
app.use(compression());            // gzip JSON → giảm payload, tải nhanh hơn trên mobile
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}
... // phần CORS giữ nguyên
app.use(express.json({ limit: '1mb' }));   // chặn body khổng lồ
app.use(express.urlencoded({ extended: true, limit: '1mb' }));
app.use(mongoSanitize);
... // các route giữ nguyên
```

> **compression** là phần ảnh hưởng trực tiếp tới "tải dữ liệu nhanh hơn" — payload JSON list sẽ nhỏ hơn nhiều.

### S5b — Giới hạn kích thước & loại file upload (multer)

**Vấn đề:** `uploadCloud = multer({ storage })` không có `limits`/`fileFilter` → client có thể đẩy file rất lớn xuyên qua server (DoS băng thông/bộ nhớ).

**File:** `src/config/cloudinary.js`

```js
// BEFORE
const uploadCloud = multer({ storage });
```

```js
// AFTER
const ALLOWED_MIME = new Set([
  'image/jpeg', 'image/png', 'image/jpg', 'image/webp',
  'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 'audio/m4a', 'audio/mp4',
]);

const uploadCloud = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB; chỉnh theo nhu cầu audio
  fileFilter: (req, file, cb) => {
    if (ALLOWED_MIME.has(file.mimetype)) return cb(null, true);
    cb(new Error('Unsupported file type'));
  },
});
```

**Kiểm tra:** Upload avatar > 25MB hoặc file `.exe` → bị từ chối; ảnh/audio hợp lệ vẫn upload được.

---

# GIAI ĐOẠN 1 — Quick wins tải dữ liệu nhanh

## P1 — [Rất cao] Tối ưu query auth chạy mỗi request

**Vấn đề:** `authenticate` gọi `User.findById(userId)` lấy **full document** (gồm `refreshToken`, `fcmTokens[]`, `resetOtp*`…) trên **mọi** request có token. Đây là query nóng nhất hệ thống.

**File:** `src/middleware/auth.js`

```js
// BEFORE
const user = await User.findById(userId);
if (!user) return res.status(401).json({ message: 'User not found' });
if (user._destroy) return res.status(403).json({ message: 'Account disabled' });
req.user = user;
req.userId = user._id;
```

```js
// AFTER — chỉ lấy field cần cho authz + những field controller hay đọc
const user = await User.findById(userId).select(
  '_id role _destroy isBanned banExpiresAt fullName username email avatarUrl'
);
if (!user) return res.status(401).json({ message: 'User not found' });
if (user._destroy) return res.status(403).json({ message: 'Account disabled' });
req.user = user;
req.userId = user._id;
```

> **Cảnh báo:** KHÔNG thêm `.lean()` một cách máy móc. Trước khi thêm `.lean()`, hãy grep toàn repo xem có controller nào gọi `req.user.save()` không:
> ```bash
> grep -rn "req.user.save\|req\.user\." src/controllers | grep -i "save\|\.set("
> ```
> Nếu **không** chỗ nào mutate rồi `.save()` `req.user`, có thể thêm `.lean()` để bỏ chi phí hydrate (thêm lợi ích). Nếu có, giữ nguyên (không lean) nhưng vẫn cần tự bổ sung field vào `.select(...)` mà controller đó dùng.
> Ngoài ra rà soát các field mà controller/service đọc từ `req.user` (vd `req.user.timezone`, `req.user.fcmTokens`) và bổ sung vào `.select(...)` cho đủ.

**Kiểm tra:** Login → gọi vài API cần auth → vẫn 200, không lỗi "undefined field". Đo thời gian phản hồi giảm dưới tải.

---

## P2 — [Cao] Bổ sung index còn thiếu

> Sau khi thêm index, deploy lên môi trường có dữ liệu thật cần đảm bảo Mongoose `autoIndex` bật (mặc định bật ở dev; ở production nên build index có kiểm soát). Với Atlas có thể tạo index thủ công để tránh blocking khi collection lớn.

### P2a — `Enrollment` (hiện KHÔNG có index nào)

**File:** `src/models/Enrollment.js` — thêm trước dòng `mongoose.model(...)`:

```js
EnrollmentSchema.index({ userId: 1, lastAccessedAt: -1 });
EnrollmentSchema.index({ userId: 1, isCompleted: 1, lastAccessedAt: -1 });
EnrollmentSchema.index({ updatedAt: -1 }); // cho query admin history theo khoảng thời gian
```

### P2b — `Notification` (unread count đang quét toàn bộ)

**File:** `src/models/Notification.js` — bổ sung cạnh index hiện có:

```js
notificationSchema.index({ recipientId: 1, createdAt: -1 }); // đã có, giữ
notificationSchema.index({ recipientId: 1, isRead: 1 });      // THÊM: cho countDocuments unread
```

### P2c — Các collection progress/history khác

Thêm compound index `{userId, <ngày>}` cho các model mà query lọc `userId` + sort/lọc theo ngày (xác nhận tên field ngày trong từng model):

| Model | Index thêm |
|-------|-----------|
| `WritingSubmission` | `{ userId: 1, submittedAt: -1 }` |
| `SpeakingEnrollment` | `{ userId: 1, lastAccessedAt: -1 }` |
| `SpeakingAttempt` | `{ userId: 1, speakingSetId: 1, createdAt: -1 }` |
| `ListeningCompAttempt` | `{ userId: 1, createdAt: -1 }` |
| `User` | `{ isOnline: 1, lastActivityDate: -1 }` (cho admin user list) |

**Kiểm tra:** Dùng `.explain('executionStats')` trên các query progress/notification → `stage` chuyển từ `COLLSCAN` sang `IXSCAN`, `totalDocsExamined` giảm mạnh.

---

## P6 — [Trung bình] Cấu hình kết nối MongoDB

**Vấn đề:** `mongoose.connect(MONGO_URI)` không có option → pool không kiểm soát, không timeout (stall mặc định 30s khi DB chập chờn).

**File:** `src/server.js`

```js
// BEFORE
await mongoose.connect(MONGO_URI);
```

```js
// AFTER
await mongoose.connect(MONGO_URI, {
  maxPoolSize: 20,
  minPoolSize: 5,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  retryWrites: true,
});
```

**Kiểm tra:** Server khởi động bình thường, log "Connected to MongoDB" vẫn hiện.

---

## P7 — [Trung bình] Thêm `.lean()` cho list read-only + bound các `.find()` không giới hạn

### P7a — `.lean()` cho danh sách notification

**File:** `src/services/notificationService.js`, hàm `listForUser`

```js
// BEFORE
const notifications = await Notification.find({ recipientId: userId })
  .sort({ createdAt: -1 })
  .skip((page - 1) * limit)
  .limit(limit)
  .populate('senderId', 'fullName avatarUrl');
```

```js
// AFTER
const notifications = await Notification.find({ recipientId: userId })
  .sort({ createdAt: -1 })
  .skip((page - 1) * limit)
  .limit(limit)
  .populate('senderId', 'fullName avatarUrl')
  .lean();
```

> Áp dụng cùng kiểu cho các list read-only khác: `classroomService.listMineAsTeacher` / `listEnrolledStudent`, `teacherDashboardService.getCalendarEvents`. Chỉ thêm `.lean()` khi kết quả **không** được `.save()` lại.

### P7b — Bound các `.find()` không có limit

Rà soát và thêm `.limit()` / điều kiện thu hẹp cho:
- `teacherDashboardService.getCalendarEvents` — thêm `$match` cửa sổ ngày (`config.opensAt`/`dueAt` trong khoảng truy vấn) + `.lean()`.
- `readingService` — `ReadingProgress.find({ userId })` nên thêm `readingId: { $in: readingIds }` (chỉ lấy progress của trang hiện tại thay vì toàn bộ).

**Kiểm tra:** Danh sách vẫn trả đúng dữ liệu; payload và thời gian phản hồi giảm.

---

# GIAI ĐOẠN 2 — Khử N+1 & aggregation

## P3 — [Cao] Gộp N+1 ở Chat Inbox

**Vấn đề:** `getChatInbox` lặp theo từng classroom, mỗi vòng ~5–6 query (`Classroom.findById`, `ClassroomMessage.findOne` last message, `countDocuments` unread, đếm member). User trong 20 lớp ⇒ ~100+ query.

**File:** `src/services/classroomChatService.js`, hàm `getChatInbox` (khoảng dòng 600–640 — định vị theo tên hàm).

**Hướng tái cấu trúc (mục tiêu ~3 query thay cho ~100):**
1. Lấy danh sách `classroomIds` của user (1 query trên `ClassroomMember`).
2. Lấy thông tin lớp 1 lần: `Classroom.find({ _id: { $in: classroomIds } }).lean()`.
3. **Last message mỗi lớp** bằng 1 aggregation:
   ```js
   ClassroomMessage.aggregate([
     { $match: { classroomId: { $in: classroomIds } } },
     { $sort: { createdAt: -1 } },
     { $group: { _id: '$classroomId', last: { $first: '$$ROOT' } } },
   ]);
   ```
4. **Unread count mỗi lớp** bằng 1 aggregation `$group` dựa trên read-state của user (so `createdAt` message với `lastReadAt` trong `ClassroomChatReadState`), thay vì `countDocuments` từng lớp.
5. **Member count mỗi lớp** bằng 1 aggregation `$group` trên `ClassroomMember` thay vì gọi `countActiveMembers` từng lớp.
6. Ghép kết quả trong JS theo `classroomId`.

**Kiểm tra:** So sánh response trước/sau phải **giống nhau** (last message, unread, member count). Bật mongoose debug (`mongoose.set('debug', true)`) đếm số query giảm rõ rệt.

---

## P4 — [Cao] Gộp N+1 ở History (tính duration)

**Vấn đề:** `historyService` chạy `Promise.all` trên từng dòng lịch sử, mỗi dòng 1 `aggregate` cộng duration (`ReadingAttempt`/`SpeakingAttempt`/`DictationAttempt`). N dòng ⇒ N aggregation.

**File:** `src/services/historyService.js` (các đoạn `Promise.all` quanh dòng 146, 183, 213, 240).

**Hướng tái cấu trúc:** Với mỗi loại attempt, thu thập toàn bộ `(userId, contentId)` cần tính → **1 aggregation `$group`** cho cả batch:
```js
ReadingAttempt.aggregate([
  { $match: { userId, readingId: { $in: readingIds } } },
  { $group: { _id: '$readingId', totalDuration: { $sum: '$durationSeconds' } } },
]);
```
Rồi map kết quả về từng dòng trong JS (tạo `Map<contentId, totalDuration>`).

**Kiểm tra:** Tổng duration mỗi dòng khớp với kết quả cũ; số query từ N về 1/loại.

---

## P5 — [Cao] Tối ưu Grading Queue của dashboard giáo viên

**Vấn đề:** `getGradingQueue` / `countNeedsGrading` `$match` trên `{status, gradingState}` (không index) → quét toàn bộ `ExamAttempt`; filter theo teacher chỉ áp dụng **sau** `$lookup`. Chạy mỗi lần mở dashboard giáo viên.

**File:** `src/models/ExamAttempt.js` + `src/services/teacherDashboardService.js`

**Bước 1 (nhanh):** thêm index hỗ trợ stage `$match` đầu tiên:
```js
// ExamAttempt.js
ExamAttemptSchema.index({ status: 1, gradingState: 1, resultsReleased: 1 });
```

**Bước 2 (tốt hơn, nếu chấp nhận thay đổi schema):** **denormalize `teacherId`** vào `ExamAttempt` (ghi lúc tạo attempt) để aggregation `$match` lọc theo teacher **ngay từ đầu** thay vì sau `$lookup`:
```js
{ $match: { teacherId, status: 'submitted', gradingState: { $in: [...] } } }
```
kèm index `{ teacherId: 1, status: 1, gradingState: 1 }`.

**Kiểm tra:** `.explain()` pipeline → stage đầu dùng index; thời gian mở dashboard giảm khi số attempt lớn.

---

## P8 — [Trung bình] Thêm lớp cache nhỏ cho dữ liệu ít đổi

**Vấn đề:** Không có cache nào. Dữ liệu ít đổi (role permissions, content summaries, exam definitions, và user trong auth) bị query lặp lại liên tục.

**Cách làm gọn nhẹ (không cần Redis):** tạo util TTL cache in-memory.

**File mới:** `src/utils/ttlCache.js`
```js
// Cache in-memory đơn giản với TTL. Đủ cho single-instance.
// Nếu chạy nhiều instance/scale ngang, cân nhắc chuyển sang Redis.
export function createTTLCache(defaultTtlMs = 30_000) {
  const store = new Map(); // key -> { value, expires }
  return {
    get(key) {
      const hit = store.get(key);
      if (!hit) return undefined;
      if (hit.expires < Date.now()) { store.delete(key); return undefined; }
      return hit.value;
    },
    set(key, value, ttlMs = defaultTtlMs) {
      store.set(key, { value, expires: Date.now() + ttlMs });
    },
    del(key) { store.delete(key); },
    clear() { store.clear(); },
  };
}
```
> Lưu ý: `Date.now()` ở đây chạy bình thường (đây là code app, không phải workflow script).

**Áp dụng ưu tiên:**
- **Auth user cache (lợi ích lớn):** trong `auth.js`, cache user theo `userId` TTL ngắn (5–10s) để giảm `User.findById` trùng lặp trong các burst request. **Bắt buộc** invalidate khi user bị ban/đổi role/disable (gọi `cache.del(userId)` ở chỗ cập nhật user). Nếu lo lệch trạng thái, bỏ qua phần này và chỉ giữ P1.
- Role permissions (`ROLE_PERMISSIONS`) hầu như tĩnh — có thể đọc thẳng, không cần cache.
- Content summaries trong `adminService` (dashboard) — TTL 30–60s.

**Kiểm tra:** Ban một user đang đăng nhập → trong vòng TTL vẫn có thể truy cập (rủi ro chấp nhận được nếu TTL ngắn) hoặc invalidate ngay nếu đã thêm `cache.del`. Cân nhắc kỹ trước khi bật cache cho auth.

---

# GIAI ĐOẠN 3 — Chuẩn hóa kiến trúc

## A1 — [High] Global error handler + `asyncHandler` (gồm luôn S4)

**Vấn đề:** Không có error-handling middleware; async handler không wrap → unhandled rejection có thể crash. ~250 `try/catch` lặp tay, nhiều chỗ rò `err.message`.

**File mới:** `src/utils/AppError.js`
```js
// Lỗi nghiệp vụ có status code chủ động (thay cho các bản httpError copy-paste).
export class AppError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
  }
}
export const httpError = (statusCode, message) => new AppError(statusCode, message);
```

**File mới:** `src/utils/asyncHandler.js`
```js
// Bọc async route handler để mọi rejection đẩy về error middleware, khỏi try/catch.
export const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);
```

**File mới:** `src/middleware/errorHandler.js`
```js
export function notFoundHandler(req, res) {
  res.status(404).json({ message: 'Not found' });
}

// Phải đặt CUỐI CÙNG trong app.js, sau tất cả route.
export function errorHandler(err, req, res, _next) {
  const status = err.statusCode || 500;
  // Lỗi nghiệp vụ (4xx) được phép trả message; lỗi 5xx ẩn chi tiết nội bộ.
  const message = status < 500 ? err.message : 'Server error';
  if (status >= 500) console.error('💥 Unhandled error:', err);
  res.status(status).json({ message });
}
```

**File:** `src/app.js` — đăng ký **sau** tất cả route:
```js
import { notFoundHandler, errorHandler } from './src/middleware/errorHandler.js';
...
app.use('/api/classroom-chat/:classroomId', classroomChatRoutes); // route cuối hiện có
app.use(notFoundHandler);  // 404 JSON
app.use(errorHandler);     // error middleware — BẮT BUỘC đặt cuối cùng
export default app;
```

**Cách migrate controller (làm dần, không cần một lần):**
- Bọc handler bằng `asyncHandler(...)` và **bỏ try/catch**, để lỗi `throw` ra ngoài:
  ```js
  // BEFORE
  export const createClassroom = async (req, res) => {
    try {
      const doc = await classroomService.createClassroom(req.user._id, req.body);
      return res.status(201).json(doc);
    } catch (error) {
      return res.status(getStatusCode(error)).json({ message: error.message });
    }
  };
  // AFTER
  import { asyncHandler } from '../utils/asyncHandler.js';
  export const createClassroom = asyncHandler(async (req, res) => {
    const doc = await classroomService.createClassroom(req.user._id, req.body);
    res.status(201).json(doc);
  });
  ```
- Service `throw httpError(404, 'Not found')` thay cho `res.status(...)` (service không bao giờ chạm `res`).

**Kiểm tra:** Gọi API tới resource không tồn tại → nhận đúng 404 với `{message}`; gây lỗi 500 cố ý → client chỉ nhận `{message:'Server error'}`, server log chi tiết.

---

## A2 — [High] Thống nhất cơ chế báo lỗi (xóa copy-paste)

**Vấn đề:** Tồn tại 3 kiểu: `httpError` copy-paste trong **14 service**, gán `e.statusCode=` trong **20 file**, và `throw new Error()` trống. Controller cũ (listening/writing/speaking/vocab) **ép mọi lỗi về 500**.

**Hành động (sau khi có A1):**
1. Xóa định nghĩa `httpError` cục bộ ở từng service (vd `classroomService.js:7-11`, `examSessionService.js`, `teacherExamService.js`, `examGradingService.js`, `examAttemptService.js`…), import từ `../utils/AppError.js` thay thế:
   ```js
   import { httpError } from '../utils/AppError.js';
   ```
2. Xóa hàm `getStatusCode` copy-paste trong 8 controller (`classroomController.js:5`, `examStudentController.js`, `teacherExamController.js`…) — không cần nữa vì error middleware tự đọc `err.statusCode`.
3. Controller cũ hardcode `res.status(500)` (listening/writing/speaking/vocab): chuyển sang `asyncHandler` + `throw httpError(...)` để giữ đúng status code service muốn trả.

**Kiểm tra:** Một service `throw httpError(404,...)` → controller (kể cả listening/writing) trả đúng 404, không còn bị ép 500.

---

## A3 — [Med] Gộp thư mục `untils/` (lỗi gõ) vào `utils/`

**Vấn đề:** Tồn tại cả `src/untils/` (gõ sai) và `src/utils/`. `untils/` chứa `progressTracker.js`, `scoring.js`, `sendMailUtil.js` (header file `progressTracker.js` còn ghi `// src/utils/...`). 8 file import từ `../untils/`.

**Hành động:**
1. Di chuyển 3 file `src/untils/*.js` → `src/utils/`.
2. Cập nhật import ở 8 nơi: `listeningController.js`, `readingController.js`, `speakingController.js`, `vocabController.js`, `listeningCompController.js`, `authService.js`, `examAttemptService.js`, `writingTopicService.js` — đổi `../untils/` → `../utils/` (và `../../untils/` nếu có).
   ```bash
   grep -rn "untils/" src        # liệt kê toàn bộ chỗ cần sửa
   ```
3. Xóa thư mục rỗng `src/untils/`.

**Kiểm tra:** `npm start` không lỗi "Cannot find module"; `grep -rn "untils" src` trả về rỗng.

---

## A4 — [Med] Xóa code chết & gãy import

**Vấn đề:**
- `src/routes/lessonRoutes.js` import `../controllers/lessionController.js` — **file không tồn tại** (route này không được mount nên chưa nổ).
- Chuỗi `dictation*` (`dictationRoutes.js`, `dictationController.js`, `dictationService.js`) đã bị thay bằng `listeningService.submitAttempt` (xem comment trong `listeningController.js`).
- `cueRoutes.js` + `cueController.js` không được mount, không nơi nào tham chiếu.

**Hành động:** Xác nhận lại các file **không** được import ở bất kỳ đâu rồi xóa:
```bash
# Với mỗi file nghi ngờ, kiểm tra không còn ai import:
grep -rn "lessonRoutes\|lessionController" src app.js
grep -rn "dictationRoutes\|dictationController\|dictationService" src app.js
grep -rn "cueRoutes\|cueController" src app.js
```
Xóa: `lessonRoutes.js`, `cueRoutes.js`, `cueController.js`, `dictationRoutes.js`, `dictationController.js`, `dictationService.js` (chỉ khi grep xác nhận không còn tham chiếu sống — `app.js` không mount chúng).

> Cẩn trọng: `dictationService.js` có hàm WER/Levenshtein trùng với `utils/scoring.js`. Đảm bảo nơi đang dùng là `utils/scoring.js` (qua `examAttemptService.js`), không phải bản trong dictation.

**Kiểm tra:** `npm start` ok; không API nào gãy (các route này vốn đã không hoạt động).

---

## A6 — [Med] Chuẩn hóa validation (zod) & response envelope

**Vấn đề:** `zod` đã cài nhưng gần như chỉ dùng ở `appVersionService`. Validation rải rác `if(!x) return 400`. Response shape không nhất quán (`{data}` / `{success}` / raw).

**Hành động (làm dần):**
1. **Validation middleware** dùng zod:
   ```js
   // src/middleware/validate.js
   export const validate = (schema, source = 'body') => (req, res, next) => {
     const result = schema.safeParse(req[source]);
     if (!result.success) {
       return res.status(400).json({ message: 'Validation failed', issues: result.error.issues });
     }
     req[source] = result.data; // dữ liệu đã parse/coerce
     next();
   };
   ```
   Áp dụng cho các endpoint POST/PUT quan trọng trước (auth, classroom, exam) bằng cách định nghĩa schema cạnh route.
2. **Pagination helper** (xóa copy-paste `parseInt(req.query.page)...`):
   ```js
   // src/utils/pagination.js
   export const parsePagination = (req, { defLimit = 20, maxLimit = 100 } = {}) => {
     const page = Math.max(1, parseInt(req.query.page) || 1);
     const limit = Math.min(maxLimit, Math.max(1, parseInt(req.query.limit) || defLimit));
     return { page, limit, skip: (page - 1) * limit };
   };
   ```
3. **Response envelope thống nhất** (tùy chọn, ảnh hưởng client — phối hợp với team Flutter trước khi đổi): chốt một dạng, ví dụ `{ success, data, pagination?, message? }`, rồi refactor dần.

**Kiểm tra:** Endpoint có validate trả 400 với payload sai; pagination dùng chung helper.

---

## A5 — [Med] Tách god file `examAttemptService.js` (~1830 LOC)

**Vấn đề:** 50+ hàm trộn nhiều mối quan tâm (scoring, deadline, batch-fetch, grading attach) trong 1 file.

**Hành động (refactor cơ học, giữ nguyên hành vi):** tách thành các module theo nhóm hàm, re-export để không vỡ import hiện có:
- `examScoring.js` — `scoreMcq`, `scoreFillBlank`, `scoreGrammar*`…
- `examRecordFetchers.js` — các `batchFetch*RecordsMap`.
- `examGrading.js` — `attachSkillWorkForGrading`, logic chấm.
- `examAttemptService.js` giữ vai trò orchestrator + re-export để API public không đổi.

> Đây là refactor rủi ro thấp nhưng tốn công nhất G3 → làm **sau cùng**, mỗi lần tách 1 nhóm + chạy test.

**Kiểm tra:** `node --test` (test hiện có) + smoke test luồng nộp/chấm bài exam vẫn hoạt động.

---

# GIAI ĐOẠN 4 — Hoàn thiện vận hành

## S3 — [High] Hash + rotate refresh token

**Vấn đề:** `refreshToken` lưu **plaintext** trên User; `/refresh` không rotate → lộ DB = token 7 ngày dùng được, không phát hiện được reuse.

**File:** `src/models/User.js`, `src/services/authService.js`

**Hành động:**
1. Khi phát hành refresh token: lưu **SHA-256 hash** thay vì token gốc.
   ```js
   import crypto from 'crypto';
   const hashToken = (t) => crypto.createHash('sha256').update(t).digest('hex');
   // lúc login/refresh:
   user.refreshToken = hashToken(newRefreshToken);
   ```
2. Khi `/refresh`: verify chữ ký (đang làm) **và** so khớp `hashToken(incoming) === user.refreshToken`. Sau đó **rotate**: phát hành refresh token mới, lưu hash mới (token cũ vô hiệu).
3. (Nâng cao) Token family / reuse detection: nếu nhận token cũ đã bị rotate → coi như bị đánh cắp, revoke toàn bộ session của user.

**Kiểm tra:** Login → refresh → refresh token cũ không dùng lại được; token mới hoạt động.

---

## S6 — [Med] Cứng hóa seed/OTP/bcrypt

**File:** `src/seeds/seedAdmin.js`, `src/scripts/repairSeedLogins.js`, `src/services/authService.js`

1. **Seed admin password từ env, không hardcode:**
   ```js
   const adminPassword = process.env.SEED_ADMIN_PASSWORD;
   if (!adminPassword) throw new Error('Set SEED_ADMIN_PASSWORD before seeding admin.');
   ```
   Đảm bảo seed chỉ chạy ở môi trường dev.
2. **OTP dùng crypto an toàn:**
   ```js
   // BEFORE: Math.floor(Math.random() * 10)
   import crypto from 'crypto';
   const digit = () => crypto.randomInt(0, 10);
   ```
3. **bcrypt rounds 10 → 12:** `bcrypt.genSalt(12)` (cấu hình qua env nếu muốn).
4. **Gỡ log nhạy cảm:** xóa các `console.log` in OTP/`req.body` trong `authService.js` và `userController.js`.

**Kiểm tra:** Đăng ký/quên mật khẩu vẫn nhận OTP; seed yêu cầu env password.

---

## OPS1 — Graceful shutdown + health check + 404

**File:** `src/server.js` (+ `/healthz` đã gợi ý ở A1's notFound).

```js
// thêm route health trước khi mount notFound (đặt trong app.js trước notFoundHandler)
app.get('/healthz', (req, res) => res.json({ status: 'ok' }));

// trong server.js, sau httpServer.listen(...)
const shutdown = async (signal) => {
  console.log(`\n${signal} received — shutting down...`);
  httpServer.close(async () => {
    await mongoose.connection.close();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref(); // ép thoát nếu treo
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
```

**Kiểm tra:** `GET /healthz` → `{status:'ok'}`; Ctrl+C → server đóng gọn, không treo.

---

## OPS2 — Global rate limit baseline + siết AI/chat

**File:** `src/app.js`, `src/middleware/authRateLimit.js`

1. Thêm limiter nền cho toàn API (ngoài auth/exam đã có):
   ```js
   import rateLimit from 'express-rate-limit';
   const apiLimiter = rateLimit({ windowMs: 60_000, max: 120, standardHeaders: true, legacyHeaders: false });
   app.use('/api', apiLimiter);
   ```
2. Limiter chặt hơn cho endpoint AI/chat (chống lạm dụng chi phí): áp riêng cho `/api/chat` (vd `max: 20/phút`).

**Kiểm tra:** Spam request vượt ngưỡng → nhận 429.

---

## OPS3 — Sanitize cả `req.params`

**File:** `src/middleware/sanitize.js`

```js
export function mongoSanitize(req, _res, next) {
  scrub(req.body);
  scrub(req.query);
  scrub(req.params); // THÊM: defense-in-depth cho route params
  next();
}
```

**Kiểm tra:** Request bình thường vẫn hoạt động (params là string nên không ảnh hưởng).

---

## OPS4 — Cursor pagination cho list nóng (tùy chọn nâng cao)

**Vấn đề:** Offset pagination (`.skip()`) chậm dần ở trang sâu trên collection lớn (Notification, User, ExamAttempt). Chat đã dùng cursor đúng cách — nhân rộng mô hình đó.

**Hành động:** Với list nóng, chuyển sang cursor theo `createdAt`:
```js
// thay skip/limit:
const filter = { recipientId: userId };
if (cursor) filter.createdAt = { $lt: new Date(cursor) };
const items = await Notification.find(filter).sort({ createdAt: -1 }).limit(limit + 1).lean();
const hasMore = items.length > limit;
const data = hasMore ? items.slice(0, limit) : items;
const nextCursor = hasMore ? data[data.length - 1].createdAt.toISOString() : null;
```

> Phối hợp với team Flutter vì đổi cách phân trang ảnh hưởng client.

---

# Phụ lục

## Packages cần cài
```bash
npm install helmet compression morgan
# (express-rate-limit, zod, bcrypt đã có sẵn trong dependencies)
```

## Biến môi trường cần bổ sung/đảm bảo
| Biến | Mục đích |
|------|----------|
| `MONGO_URI` | đã có (rotate sau S2) |
| `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | đã có (rotate sau S2) |
| `CORS_ALLOWED_ORIGINS` | bắt buộc set ở production (fail-closed cho web admin) |
| `NODE_ENV` | `production` ở môi trường thật (kích hoạt guard JWT, morgan combined) |
| `SEED_ADMIN_PASSWORD` | THÊM (S6) — bỏ password hardcode |
| `BCRYPT_ROUNDS` | (tùy chọn) cấu hình rounds, mặc định 12 |

## Checklist verify tổng thể sau mỗi giai đoạn
- [ ] `npm start` khởi động không lỗi, log "Connected to MongoDB".
- [ ] Login → access/refresh token hoạt động.
- [ ] List 1 nội dung (listening/reading) + mở dashboard giáo viên không lỗi.
- [ ] Tài khoản `user` KHÔNG truy cập được route admin (sau S1).
- [ ] Lỗi 5xx không lộ chi tiết nội bộ (sau A1).
- [ ] `node --test` pass (test hiện có).

## Thứ tự thực thi đề xuất (impact/effort)
1. **G0** (bảo mật khẩn) → 2. **G1** (tải nhanh, rủi ro thấp) → 3. **G2** (N+1, cần test kỹ) → 4. **G3** (kiến trúc) → 5. **G4** (vận hành).

> Mẹo đo hiệu năng: bật `mongoose.set('debug', true)` ở dev để đếm số query trước/sau khi sửa N+1; dùng `.explain('executionStats')` để xác nhận index ăn (`IXSCAN` thay vì `COLLSCAN`).
