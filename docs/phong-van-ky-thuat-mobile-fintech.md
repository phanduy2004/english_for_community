# Ôn phỏng vấn kỹ thuật Mobile / Fintech

> Tài liệu học tập độc lập — **không gắn với dự án cụ thể**.  
> Ví dụ code chủ yếu dùng **Java** (Android backend logic, OOP, collections).  
> Phù hợp: Mobile Developer, Android, hoặc vị trí Fintech yêu cầu OOP, architecture, REST, Git.

---

## Mục lục

1. [OOP — 4 tính chất + SOLID](#1-oop--4-tính-chất--solid)
2. [Cấu trúc dữ liệu (Collections)](#2-cấu-trúc-dữ-liệu-collections)
3. [Clean Architecture & DDD](#3-clean-architecture--ddd)
4. [MVVM & quản lý state trên mobile](#4-mvvm--quản-lý-state-trên-mobile)
5. [REST API, networking & bảo mật Fintech](#5-rest-api-networking--bảo-mật-fintech)
6. [Git & làm việc nhóm](#6-git--làm-việc-nhóm)
7. [Declarative UI & cross-platform](#7-declarative-ui--cross-platform)
8. [Chủ đề bổ sung hay hỏi thêm](#8-chủ-đề-bổ-sung-hay-hỏi-thêm)
9. [Câu hỏi phỏng vấn mẫu (kèm gợi ý trả lời)](#9-câu-hỏi-phỏng-vấn-mẫu-kèm-gợi-ý-trả-lời)
10. [Cheat sheet nhanh (30 phút trước PV)](#10-cheat-sheet-nhanh-30-phút-trước-pv)

---

## 1. OOP — 4 tính chất + SOLID

### 1.1 Đóng gói (Encapsulation)

**Định nghĩa:** Gom dữ liệu và hành vi vào class; che chi tiết nội bộ, chỉ expose API công khai qua method.

**Tại sao quan trọng (Fintech):** Số thẻ, PIN, token, số dư không được để UI hoặc class ngoài sửa trực tiếp.

**Ví dụ Java — tài khoản ngân hàng:**

```java
public class BankAccount {
    private final String accountNumber;
    private BigDecimal balance; // không public

    public BankAccount(String accountNumber, BigDecimal initialBalance) {
        this.accountNumber = accountNumber;
        this.balance = initialBalance;
    }

    public BigDecimal getBalance() {
        return balance;
    }

    /** Rút tiền có kiểm tra điều kiện — logic nằm trong class */
    public boolean withdraw(BigDecimal amount) {
        if (amount == null || amount.signum() <= 0) return false;
        if (balance.compareTo(amount) < 0) return false;
        balance = balance.subtract(amount);
        return true;
    }

    public void deposit(BigDecimal amount) {
        if (amount != null && amount.signum() > 0) {
            balance = balance.add(amount);
        }
    }
}
```

**Điểm PV:** UI/Activity chỉ gọi `withdraw()`, không gán `balance = ...` từ ngoài → tránh bug và dễ audit.

**Getter/setter không phải lúc nào cũng đủ:** Với field nhạy cảm (PIN, token), thường **không có setter public**, chỉ method có validate.

---

### 1.2 Kế thừa (Inheritance)

**Định nghĩa:** Class con (`extends`) nhận field/method từ class cha; có thể override hoặc mở rộng.

**Lưu ý phỏng vấn:** Ưu tiên **composition over inheritance** — kế thừa sâu (deep hierarchy) dễ coupling, khó test.

**Ví dụ Java — hierarchy thông báo lỗi:**

```java
public abstract class AppException extends Exception {
    private final String errorCode;

    protected AppException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    public String getErrorCode() {
        return errorCode;
    }
}

public class NetworkException extends AppException {
    public NetworkException(String message) {
        super("NET_001", message);
    }
}

public class InsufficientFundsException extends AppException {
    public InsufficientFundsException() {
        super("PAY_002", "Số dư không đủ");
    }
}
```

UI layer bắt `AppException` chung, map sang message user-friendly; không cần biết từng loại HTTP chi tiết.

**Khi nên / không nên kế thừa:**

| Nên | Không nên |
|-----|-----------|
| IS-A rõ ràng: `SavingsAccount extends BankAccount` | Chỉ để reuse vài method → dùng composition |
| Framework bắt buộc: `extends AppCompatActivity` | Kế thừa class concrete chỉ để lấy 1 helper |

---

### 1.3 Đa hình (Polymorphism)

**Định nghĩa:** Cùng reference kiểu cha/interface, runtime gọi implementation con — **một API, nhiều hành vi**.

**Ví dụ Java — nhiều cổng thanh toán:**

```java
public interface PaymentGateway {
    PaymentResult charge(ChargeRequest request);
}

public class MomoGateway implements PaymentGateway {
    @Override
    public PaymentResult charge(ChargeRequest request) {
        // gọi API Momo
        return PaymentResult.success("MOMO_TX_123");
    }
}

public class BankTransferGateway implements PaymentGateway {
    @Override
    public PaymentResult charge(ChargeRequest request) {
        // gọi API ngân hàng
        return PaymentResult.success("BANK_TX_456");
    }
}

// Polymorphism tại runtime
public class CheckoutService {
    private final PaymentGateway gateway; // inject qua constructor

    public CheckoutService(PaymentGateway gateway) {
        this.gateway = gateway;
    }

    public PaymentResult checkout(ChargeRequest request) {
        return gateway.charge(request);
    }
}
```

Test: inject `FakePaymentGateway` trả success/fail cố định — không cần gọi API thật.

**Overload vs Override (hay nhầm):**

| | Overload | Override |
|--|----------|----------|
| Cùng tên method, khác tham số | Subclass ghi đè method cha |
| Compile-time | Runtime (virtual method) |
| Ví dụ | `print(int)` vs `print(String)` | `@Override charge()` |

---

### 1.4 Trừu tượng (Abstraction)

**Định nghĩa:** Ẩn **cách làm** (how), chỉ để lại **hợp đồng** (what) — interface hoặc abstract class.

**Khác Encapsulation:**

| Encapsulation | Abstraction |
|---------------|-------------|
| Che **dữ liệu** (private field) | Che **quy trình** phức tạp |
| Ví dụ: balance private | Ví dụ: interface `AuthService` |

**Ví dụ Java:**

```java
public interface AuthRepository {
    LoginResult login(String username, String password);
    void logout();
    Optional<UserSession> getCurrentSession();
}

// Presentation (ViewModel) chỉ biết interface
public class LoginViewModel {
    private final AuthRepository authRepository;

    public LoginViewModel(AuthRepository authRepository) {
        this.authRepository = authRepository;
    }

    public void onLoginClicked(String user, String pass) {
        LoginResult result = authRepository.login(user, pass);
        // cập nhật LiveData / StateFlow
    }
}
```

ViewModel **không** biết OkHttp, Retrofit, SharedPreferences hay Room — đó là impl.

---

### 1.5 SOLID (thường hỏi kèm OOP)

| Nguyên tắc | Một câu | Ví dụ Fintech |
|------------|---------|--------------|
| **S** — Single Responsibility | Một class một lý do đổi | `TransferValidator` tách khỏi `TransferExecutor` |
| **O** — Open/Closed | Mở rộng bằng impl mới, ít sửa code cũ | Thêm `PaymentGateway` mới không sửa `CheckoutService` |
| **L** — Liskov Substitution | Con thay cha được, không phá hành vi | Mọi `BankAccount` con đều tuân `withdraw` hợp lệ |
| **I** — Interface Segregation | Interface nhỏ, chuyên biệt | Tách `ReadableAccount` / `TransferableAccount` |
| **D** — Dependency Inversion | Phụ thuộc abstraction, không concrete | ViewModel phụ thuộc `AuthRepository`, không `RetrofitAuthApi` |

**Câu trả lời ngắn (45 giây):**

> "Em áp dụng SOLID qua interface repository và inject dependency. Ví dụ thêm cổng thanh toán mới chỉ implement `PaymentGateway`, không sửa service checkout. ViewModel phụ thuộc abstraction nên unit test dễ."

---

### 1.6 Bảng tóm tắt 4 tính chất

| Tính chất | Một câu | Ví dụ Java |
|-----------|---------|------------|
| Encapsulation | Che data, validate qua method | `BankAccount` private balance |
| Inheritance | Tái sử dụng qua extends | `NetworkException extends AppException` |
| Polymorphism | Nhiều impl, một interface | `PaymentGateway` + Momo/Bank |
| Abstraction | Che complexity, lộ contract | `AuthRepository` interface |

---

## 2. Cấu trúc dữ liệu (Collections)

> Java: `java.util` — ArrayList, HashMap, HashSet, LinkedList, PriorityQueue.

### 2.1 Array / ArrayList

| Thao tác | Độ phức tạp | Ghi chú |
|----------|-------------|---------|
| `get(i)` / `set(i)` | O(1) | Random access |
| `add` cuối list | O(1) amortized | |
| `add(0, x)` / xóa đầu | O(n) | Phải shift phần tử |
| `contains` / tìm linear | O(n) | |
| `Collections.sort` | O(n log n) | |

**Khi dùng (mobile/Fintech):**

- Danh sách giao dịch theo thời gian (API trả array JSON).
- Lịch sử chuyển tiền scroll infinite — tích lũy page vào `List<Transaction>`.

```java
List<Transaction> history = new ArrayList<>();
history.addAll(apiResponse.getData()); // page 1
// load more → history.addAll(page2)
```

**Array vs ArrayList:** Array cố định size; ArrayList dynamic — mobile code gần như luôn dùng List interface.

---

### 2.2 HashMap

| Thao tác | Độ phức tạp trung bình |
|----------|------------------------|
| `get`, `put`, `remove`, `containsKey` | O(1) |

**Khi dùng:**

- Cache `transactionId → Transaction` để tra cứu nhanh màn chi tiết.
- Map mã lỗi API → message hiển thị.
- Dedupe notification: `Map<String, Notification>`.

```java
Map<String, Transaction> cache = new HashMap<>();
cache.put(tx.getId(), tx);
Transaction found = cache.get("TX_001"); // O(1)
```

**Lưu ý phỏng vấn:**

- Hash collision worst-case O(n) — hiếm với hash tốt.
- **Không đảm bảo thứ tự** — cần thứ tự dùng `LinkedHashMap` hoặc sort key.

---

### 2.3 HashSet

- Không trùng phần tử (`equals` + `hashCode`).
- `add`, `contains`, `remove`: O(1) trung bình.

**Ví dụ:** Set quyền user đã load; set ID giao dịch đã đồng bộ để tránh xử lý trùng.

```java
Set<String> syncedIds = new HashSet<>();
if (!syncedIds.add(incomingId)) {
    return; // đã xử lý, bỏ qua
}
```

---

### 2.4 LinkedList vs ArrayList

| | ArrayList | LinkedList |
|--|-----------|------------|
| Random access | O(1) | O(n) |
| Insert/delete đầu | O(n) | O(1) nếu có node |
| Thực tế mobile | **Dùng nhiều nhất** | Ít dùng trừ queue/deque đặc biệt |

**PV:** "Em ưu tiên ArrayList cho list UI; LinkedList khi cần queue hai đầu rõ ràng."

---

### 2.5 Stack & Queue

**Stack (LIFO):** Undo wizard chuyển tiền (bước 1 → 2 → 3, back pop stack).

**Queue (FIFO):** Hàng đợi request offline — mất mạng thì enqueue, có mạng dequeue gửi lần lượt.

```java
Queue<PendingTransfer> offlineQueue = new LinkedList<>();

public void enqueue(PendingTransfer t) {
    offlineQueue.offer(t);
}

public void flushWhenOnline() {
    while (!offlineQueue.isEmpty()) {
        PendingTransfer t = offlineQueue.poll();
        api.submit(t);
    }
}
```

---

### 2.6 TreeMap / PriorityQueue (biết thêm)

- **TreeMap:** Key sorted — timeline theo key, O(log n) mỗi thao tác.
- **PriorityQueue:** Lấy phần tử ưu tiên cao nhất — job retry theo mức độ khẩn.

---

### 2.7 Chọn cấu trúc — bảng quyết định

| Bài toán | Gợi ý |
|----------|--------|
| List UI có thứ tự | `ArrayList` |
| Tra cứu theo ID nhanh | `HashMap` |
| Loại trùng | `HashSet` |
| FIFO offline sync | `Queue` |
| Sorted theo key | `TreeMap` |
| Persist local (mobile) | SQLite/Room — B-tree index, không thay Map in-memory cho data lớn |

---

## 3. Clean Architecture & DDD

### 3.1 Ba layer (Android / mobile phổ biến)

```
┌─────────────────────────────────────────┐
│  PRESENTATION                           │
│  Activity/Fragment/Compose, ViewModel   │
└──────────────────┬──────────────────────┘
                   │ gọi UseCase / Repository interface
┌──────────────────▼──────────────────────┐
│  DOMAIN                                 │
│  Entities, Repository interfaces,       │
│  Use Cases (business rules thuần Java)  │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│  DATA                                   │
│  Repository Impl, Remote (Retrofit),    │
│  Local (Room, SharedPreferences)        │
└─────────────────────────────────────────┘
```

**Luồng chuẩn:**

```
UI → ViewModel → UseCase (optional) → Repository → DataSource → API / DB
                                              → Entity → UI state
```

**Dependency Rule:** Layer trong không import layer ngoài. Domain **không** import Android SDK (`Context`, `View`).

---

### 3.2 Ví dụ Java — Domain entity & repository

```java
// Domain — pure Java, không Android
public final class Transaction {
    private final String id;
    private final BigDecimal amount;
    private final String status; // PENDING, SUCCESS, FAILED

    public Transaction(String id, BigDecimal amount, String status) {
        this.id = id;
        this.amount = amount;
        this.status = status;
    }
    // getters...
}

public interface TransactionRepository {
    List<Transaction> getRecentTransactions(int page, int limit) throws NetworkException;
    Transaction getById(String id) throws NetworkException;
}
```

```java
// Data layer
public class TransactionRepositoryImpl implements TransactionRepository {
    private final TransactionApi api;
    private final TransactionDao localDao;

    public TransactionRepositoryImpl(TransactionApi api, TransactionDao localDao) {
        this.api = api;
        this.localDao = localDao;
    }

    @Override
    public List<Transaction> getRecentTransactions(int page, int limit) throws NetworkException {
        try {
            List<TransactionDto> dtos = api.fetchHistory(page, limit).execute().body();
            List<Transaction> entities = TransactionMapper.toEntities(dtos);
            localDao.insertAll(entities); // cache
            return entities;
        } catch (IOException e) {
            // fallback offline
            return localDao.getCached(page, limit);
        }
    }
}
```

---

### 3.3 DDD — khái niệm thực dụng (không cần thuật ngữ nặng)

| Khái niệm | Giải thích ngắn | Ví dụ Fintech |
|------------|-----------------|---------------|
| **Entity** | Có identity (id) xuyên suốt lifecycle | `Account`, `Transaction` |
| **Value Object** | So sánh theo giá trị, không id riêng | `Money(amount, currency)`, `PhoneNumber` |
| **Aggregate** | Cluster entity + rule nhất quán | `Transfer` gồm from/to + amount + fee |
| **Repository** | Truy cập aggregate như collection | `AccountRepository` |
| **Bounded Context** | Ranh giới nghiệp vụ tách module | `Payments` vs `Loyalty` vs `KYC` |

**Câu trả lời PV:**

> "Em tách module theo nghiệp vụ: payments, account, KYC mỗi phần có entity và repository riêng. Domain language thống nhất — ví dụ 'Transfer' vs 'Payment' dùng nhất quán trong code và API."

---

### 3.4 Repository Pattern & xử lý lỗi

**Repository** che nguồn data (API + cache + DB).

**Cách xử lý lỗi phổ biến:**

| Cách | Ưu | Nhược |
|------|-----|-------|
| Exception (`throws NetworkException`) | Quen Java classic | ViewModel phải try-catch nhiều |
| Result / Either wrapper | Explicit success/fail | Boilerplate hơn |
| Callback `onSuccess/onError` | Legacy Android | Dễ callback hell |

```java
public sealed interface Result<T> permits Result.Success, Result.Error {
    record Success<T>(T data) implements Result<T> {}
    record Error<T>(String message, String code) implements Result<T> {}
}

public Result<List<Transaction>> loadHistory(int page) {
    try {
        return new Result.Success<>(repository.getRecentTransactions(page, 20));
    } catch (NetworkException e) {
        return new Result.Error<>(e.getMessage(), e.getErrorCode());
    }
}
```

**Quy tắc:** Map HTTP/IO exception → domain error **ở Data layer**, ViewModel chỉ nhận Result/state sạch.

---

### 3.5 Dependency Injection

**Mục đích:** ViewModel/Service nhận dependency qua constructor — dễ test, dễ đổi impl.

**Android:** Hilt / Dagger / Koin.

```java
@HiltViewModel
public class TransferViewModel extends ViewModel {
    private final TransferRepository repository;

    @Inject
    public TransferViewModel(TransferRepository repository) {
        this.repository = repository;
    }
}
```

**Câu hỏi:** "Tại sao không `new Retrofit` trong Activity?"

> "Vi phạm Dependency Inversion, khó test, khó đổi base URL/mock. DI container quản lý singleton OkHttp, scope ViewModel."

---

## 4. MVVM & quản lý state trên mobile

### 4.1 MVVM — ba thành phần

| Thành phần | Vai trò |
|------------|---------|
| **Model** | Data + business (entity, repository, use case) |
| **View** | UI — Activity, Fragment, Compose; **không** logic nghiệp vụ |
| **ViewModel** | Giữ UI state, gọi Model, survive configuration change |

**Luồng:**

```
User tap "Chuyển tiền"
  → View gọi viewModel.submitTransfer(amount)
  → ViewModel set state Loading
  → Repository gọi API
  → ViewModel set Success hoặc Error
  → View observe state → hiển thị dialog / snackbar
```

---

### 4.2 UI state chuẩn (Loading / Success / Error)

```java
public enum UiState { IDLE, LOADING, SUCCESS, ERROR }

public class TransferUiState {
    public final UiState status;
    public final String errorMessage;
    public final TransferReceipt receipt; // null nếu chưa success

    public static TransferUiState idle() {
        return new TransferUiState(UiState.IDLE, null, null);
    }
    public static TransferUiState loading() {
        return new TransferUiState(UiState.LOADING, null, null);
    }
    // success, error factories...
}
```

**ViewModel (Java + LiveData ví dụ):**

```java
public class TransferViewModel extends ViewModel {
    private final MutableLiveData<TransferUiState> state =
            new MutableLiveData<>(TransferUiState.idle());
    private final TransferRepository repository;

    public LiveData<TransferUiState> getState() {
        return state;
    }

    public void submitTransfer(TransferRequest request) {
        state.setValue(TransferUiState.loading());
        repository.execute(request, new Callback<TransferReceipt>() {
            @Override
            public void onSuccess(TransferReceipt receipt) {
                state.setValue(TransferUiState.success(receipt));
            }
            @Override
            public void onError(String message) {
                state.setValue(TransferUiState.error(message));
            }
        });
    }
}
```

**Kotlin hiện đại:** `StateFlow` + `viewModelScope.launch` — cùng tư duy, syntax gọn hơn.

---

### 4.3 MVVM vs MVP vs MVI (biết phân biệt)

| Pattern | Đặc điểm |
|---------|----------|
| **MVP** | View ↔ Presenter (Presenter thường reference View — dễ leak nếu không cẩn) |
| **MVVM** | View observe ViewModel; ViewModel không biết View |
| **MVI** | Single state immutable, intent/action → reduce state (giống Redux) |

**PV Fintech:** MVVM + single UI state object là câu trả lời an toàn.

---

### 4.4 Không đặt business logic trong View

**Sai:**

```java
// Activity — không nên
if (amount.compareTo(balance) > 0) {
    showError("Không đủ tiền");
} else {
    retrofit.transfer(...);
}
```

**Đúng:** Validate trong UseCase/ViewModel; Activity chỉ bind UI và forward event.

---

### 4.5 Lifecycle & memory leak (hay hỏi Android)

- ViewModel **sống qua** xoay màn hình; Activity destroy không mất data đang load.
- **Không** giữ reference `Activity` trong ViewModel.
- Cancel job khi ViewModel `onCleared()` (Coroutine) hoặc dispose Rx subscription.

---

## 5. REST API, networking & bảo mật Fintech

### 5.1 HTTP methods

| Method | Mục đích | Idempotent? | Ví dụ Fintech |
|--------|----------|-------------|--------------|
| **GET** | Đọc dữ liệu | Có | `GET /accounts/{id}/transactions?page=1` |
| **POST** | Tạo / action | Không | `POST /transfers` — mỗi lần gọi có thể tạo giao dịch mới |
| **PUT** | Thay thế toàn bộ resource | Có | `PUT /users/me/profile` |
| **PATCH** | Cập nhật một phần | Không chắc | `PATCH /users/me` — đổi avatar URL |
| **DELETE** | Xóa | Có | `DELETE /devices/{deviceId}` — revoke session |

**Idempotent:** Gọi nhiều lần cùng kết quả (GET, PUT, DELETE lý tưởng). POST transfer **không** idempotent → cần **idempotency key** (header `Idempotency-Key: uuid`) để retry an toàn.

---

### 5.2 Cấu trúc response thường gặp

**Pagination:**

```json
{
  "data": [
    { "id": "TX_001", "amount": 500000, "status": "SUCCESS" }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalItems": 150,
    "hasNext": true
  }
}
```

**Error:**

```json
{
  "code": "INSUFFICIENT_FUNDS",
  "message": "Số dư không đủ để thực hiện giao dịch"
}
```

**Map sang UI:** `code` → string resource hoặc message trực tiếp; network fail → message chung "Không có kết nối".

---

### 5.3 Retrofit + OkHttp (Android stack phổ biến)

```java
public interface BankingApi {
    @GET("accounts/{accountId}/transactions")
    Call<TransactionPageResponse> getTransactions(
        @Path("accountId") String accountId,
        @Query("page") int page,
        @Query("limit") int limit
    );

    @POST("transfers")
    Call<TransferResponse> createTransfer(
        @Header("Idempotency-Key") String idempotencyKey,
        @Body TransferRequest body
    );
}
```

**Interceptor gắn token:**

```java
public class AuthInterceptor implements Interceptor {
    private final TokenProvider tokenProvider;

    @Override
    public Response intercept(Chain chain) throws IOException {
        Request original = chain.request();
        String token = tokenProvider.getAccessToken();
        if (token == null) {
            return chain.proceed(original);
        }
        Request authed = original.newBuilder()
                .header("Authorization", "Bearer " + token)
                .build();
        return chain.proceed(authed);
    }
}
```

---

### 5.4 JWT & dual-token flow

1. **Login** → server trả `accessToken` (ngắn, ~15 phút) + `refreshToken` (dài, lưu server/secure).
2. Mọi API business: `Authorization: Bearer <accessToken>`.
3. **401 Unauthorized** → gọi `POST /auth/refresh` với refresh token.
4. Refresh OK → lưu access mới, **retry** request ban đầu.
5. Refresh fail → xóa token local, navigate login.

**Fintech bắt buộc:**

| Làm | Không làm |
|-----|-----------|
| Lưu token EncryptedSharedPreferences / Keystore | Plain SharedPreferences cho refresh token |
| Certificate pinning (một số app) | Log token ra Logcat production |
| Timeout + retry có giới hạn | Retry POST transfer vô hạn không idempotency key |
| Logout xóa local token + revoke server | Hardcode API key trong APK |

---

### 5.5 Phân loại lỗi → UX

| Loại | HTTP / nguyên nhân | UX |
|------|-------------------|-----|
| Network | Timeout, no connection | "Kiểm tra mạng", nút Retry |
| Auth | 401 sau refresh fail | Về màn login |
| Forbidden | 403 | "Bạn không có quyền" |
| Validation | 400 / 422 + message | Hiển thị field error |
| Server | 5xx | "Hệ thống bận, thử lại sau" |
| Business | 200 với body `success: false` | Message từ `code` |

---

### 5.6 HTTPS, OWASP mobile (điểm cộng)

- Chỉ gọi API **HTTPS**; không cleartext (Android `networkSecurityConfig`).
- Không lưu PAN/CVV trên device; token hóa thẻ qua gateway.
- Root/jailbreak detection (tùy mức độ app).
- Obfuscation ProGuard/R8 — không coi là bảo mật chính, chỉ làm khó reverse.

---

## 6. Git & làm việc nhóm

### 6.1 Gitflow đơn giản

```
main          ← production, tag release
  └── develop ← tích hợp hàng ngày
        └── feature/TICKET-123-transfer-validation
        └── bugfix/TICKET-456-fix-401-retry
        └── hotfix/TICKET-789-critical-crash  (từ main, merge cả main + develop)
```

**Quy trình feature:**

```bash
git checkout develop
git pull origin develop
git checkout -b feature/TICKET-123-short-desc
# code, commit
git push -u origin feature/TICKET-123-short-desc
# mở Pull Request → review → merge develop
```

---

### 6.2 Conventional Commits

```
feat(transfer): add idempotency key header
fix(auth): retry requests after token refresh
refactor(domain): extract TransferValidator
test(repository): mock offline cache fallback
docs: update API error mapping
```

**Format:** `type(scope): imperative description`

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`

---

### 6.3 Pull Request checklist

- [ ] Mô tả **what** + **why** (không chỉ liệt kê file)
- [ ] Link Jira / ticket
- [ ] Screenshot / screen recording nếu đổi UI
- [ ] Test plan cụ thể: "Login → chuyển 100k → verify history"
- [ ] Không commit keystore, `.env`, API secret
- [ ] CI pass: unit test, lint

---

### 6.4 Merge conflict

```bash
git fetch origin
git merge origin/develop
# sửa file có <<<<<<< ======= >>>>>>>
git add .
git commit
git push
```

**Nguyên tắc:** Giữ logic đúng nghiệp vụ; không xóa code người khác vì không hiểu — hỏi reviewer.

**Tránh:** `git push --force` lên `main`/`develop` (trừ khi team có quy trình rebase rõ ràng và đồng ý).

---

### 6.5 Tiếp cận codebase mới (script trả lời PV)

1. **Đọc README** — cách build, env, module structure.
2. **Entry point** — `Application` class, `MainActivity`, DI module.
3. **Trace một flow end-to-end** — ví dụ login: UI → ViewModel → Repository → API interface.
4. **Convention** — package structure (`data`, `domain`, `ui`), naming, test folder.
5. **Xem 2–3 PR merged gần nhất** — style code team.
6. **Chạy app + unit test local** trước khi nhận task lớn.
7. **Hỏi** — branching strategy, release cycle, ai review architecture.

**Câu mẫu (60 giây):**

> "Em bắt đầu README và cấu trúc module để hiểu boundary. Sau đó em trace một user journey quen thuộc — login hoặc list transaction — từ UI xuống data layer. Em ghi chú cách team xử lý error, DI và test. Cuối cùng em chạy được app và một vài unit test trước khi sửa bug nhỏ để verify flow CI."

---

## 7. Declarative UI & cross-platform

### 7.1 Declarative vs Imperative

| Imperative (XML + findViewById cũ) | Declarative (Compose / SwiftUI) |
|-----------------------------------|--------------------------------|
| "Tìm TextView, set text, hide ProgressBar" | `UI = f(state)` — mô tả UI theo state |
| Dễ inconsistent state | State đơn → UI đồng bộ |

**Ví dụ tư duy Compose (Kotlin — syntax declarative, concept giống SwiftUI):**

```kotlin
@Composable
fun TransferScreen(state: TransferUiState, onSubmit: () -> Unit) {
    when (state.status) {
        UiState.LOADING -> CircularProgressIndicator()
        UiState.ERROR -> Text(state.errorMessage)
        UiState.SUCCESS -> ReceiptView(state.receipt)
        else -> TransferForm(onSubmit = onSubmit)
    }
}
```

State đổi → framework recompose phần cần thiết.

---

### 7.2 State management trên declarative UI

- **Single source of truth:** Một `TransferUiState` trong ViewModel.
- UI **không** tự giữ `isLoading` riêng lẻ scattered.
- Event một chiều: UI → ViewModel → state mới → UI.

---

### 7.3 Cross-platform (biết khái niệm PV)

| Approach | Mô tả |
|----------|--------|
| **Native** | Kotlin (Android) + Swift (iOS) — UX tốt nhất, 2 codebase |
| **Kotlin Multiplatform (KMP)** | Share business logic (network, domain); UI native hoặc Compose Multiplatform |
| **Flutter / React Native** | Share cả UI + logic — trade-off performance / ecosystem |

**Câu trả lời an toàn:**

> "Em mạnh native Android với MVVM và Compose. Em hiểu KMP phù hợp khi team muốn share domain layer giữa iOS/Android mà vẫn giữ UI native. Declarative UI trên Compose và SwiftUI cùng tư duy state-driven."

---

## 8. Chủ đề bổ sung hay hỏi thêm

### 8.1 Concurrency cơ bản (Java / Android)

| Khái niệm | Ứng dụng |
|-----------|----------|
| Main thread = UI thread | Không gọi network trên main |
| `Executor` / thread pool | Background work |
| `synchronized` / lock | Tránh race condition counter |
| Kotlin Coroutines | `Dispatchers.IO` cho API, `Main` cho UI update |

**PV:** "API call trên background thread; cập nhật LiveData/StateFlow về main. Em tránh block UI khi parse JSON lớn."

---

### 8.2 Unit test vs UI test

| Loại | Mục tiêu | Tool |
|------|----------|------|
| Unit test | ViewModel, UseCase, Validator | JUnit, Mockito |
| Integration | Repository + fake server | MockWebServer |
| UI test | Flow end-user | Espresso, Compose Test |

```java
@Test
void withdraw_insufficientBalance_returnsFalse() {
    BankAccount account = new BankAccount("ACC1", new BigDecimal("100"));
    assertFalse(account.withdraw(new BigDecimal("200")));
    assertEquals(new BigDecimal("100"), account.getBalance());
}
```

---

### 8.3 Offline-first (mobile banking)

- Cache danh sách giao dịch Room — hiển thị ngay khi mở app.
- Ghi nhận thao tác offline → queue → sync khi có mạng.
- Conflict strategy: server wins hoặc last-write-wins tùy nghiệp vụ.

---

### 8.4 Performance mobile

- Tránh overdraw, lazy list (`RecyclerView` / `LazyColumn`).
- Pagination thay vì load 10.000 transaction một lần.
- Image cache (Coil/Glide).
- ProGuard shrink release APK.

---

## 9. Câu hỏi phỏng vấn mẫu (kèm gợi ý trả lời)

### OOP

**Q: Nêu 4 tính chất OOP và ví dụ?**

> Encapsulation: `BankAccount` che balance, rút tiền qua method validate. Inheritance: `NetworkException extends AppException`. Polymorphism: nhiều class implement `PaymentGateway`, service checkout inject interface. Abstraction: ViewModel gọi `AuthRepository`, không biết Retrofit.

**Q: Composition vs Inheritance?**

> Inheritance khi quan hệ IS-A rõ và hành vi ổn định. Composition khi reuse một phần — ví dụ `TransferService` **has-a** `FeeCalculator` thay vì extends. Fintech em ưu tiên composition + interface để dễ test và thêm cổng thanh toán.

---

### Data structures

**Q: List vs Map khi nào?**

> List khi cần thứ tự hiển thị lịch sử giao dịch. Map khi tra cứu O(1) theo transactionId hoặc cache. Set khi dedupe sync. Sort O(n log n) khi cần sắp xếp client-side.

**Q: Độ phức tạp HashMap get?**

> O(1) trung bình; O(n) worst case khi collision nhiều — thực tế hiếm với hash function tốt.

---

### Architecture

**Q: Clean Architecture là gì, lợi ích?**

> Tách Presentation / Domain / Data; dependency hướng vào trong. Lợi ích: test domain không cần Android, đổi API chỉ sửa data layer, UI đổi Compose không ảnh hưởng business rule chuyển tiền.

**Q: Repository pattern?**

> Abstraction truy cập data; impl gọi API + cache Room. ViewModel không biết data từ network hay local.

---

### MVVM

**Q: Luồng từ API lên UI?**

> User action → ViewModel set Loading → Repository (Retrofit) → parse DTO → entity → ViewModel Success/Error → LiveData/StateFlow → UI render. Activity không gọi API trực tiếp.

**Q: ViewModel khác Presenter (MVP)?**

> ViewModel không reference View; survive rotation. Presenter thường gắn View interface — dễ leak nếu không detach.

---

### REST / Security

**Q: GET vs POST?**

> GET đọc, idempotent, không body nhạy cảm trên URL log. POST tạo giao dịch — không idempotent, cần idempotency key khi retry.

**Q: Xử lý token?**

> Access ngắn gắn header Bearer; refresh lưu secure; 401 → refresh → retry queue; fail → logout. Không log token production.

**Q: Lưu PIN/password trên app?**

> Không lưu plaintext PIN. Dùng biometric + token session; hoặc Keystore. Remember username có thể SharedPreferences; password không nên lưu trừ khi có Keystore và user opt-in rõ ràng.

---

### Git

**Q: Merge conflict xử lý sao?**

> Pull develop, merge/rebase, mở file conflict marker, hiểu cả hai nhánh, giữ logic đúng, test lại, commit push.

**Q: Vào project mới làm gì?**

> README, module structure, trace một flow, xem PR mẫu, chạy app + test, hỏi quy trình release.

---

### Declarative / Compose

**Q: Em có biết Compose không?**

> Compose là declarative UI trên Android — state-driven, tương tự SwiftUI. Em map từ MVVM: ViewModel expose state, Composable render theo state. Khác XML imperative ở chỗ không manually hide/show từng view.

---

## 10. Cheat sheet nhanh (30 phút trước PV)

### OOP

- **E**ncapsulation — private + validate method  
- **I**nheritance — extends, IS-A  
- **P**olymorphism — interface, runtime dispatch  
- **A**bstraction — hide implementation  

### SOLID (nhắc nhanh)

S — one job | O — extend via interface | L — subtype usable | I — small interfaces | D — depend on abstraction

### Complexity

| | get/find | add end |
|--|----------|---------|
| ArrayList | O(1) index / O(n) search | O(1) |
| HashMap | O(1) avg | O(1) avg |
| Sort | — | O(n log n) |

### HTTP

- GET read | POST create/action | PUT replace | PATCH partial | DELETE remove  
- 401 auth | 403 forbidden | 422 validation | 5xx server  

### UI state

`Idle → Loading → Success | Error`

### JWT flow

Login → access + refresh → Bearer header → 401 refresh retry → fail logout

### Git

`develop` ← `feature/xxx` → PR → merge

### MVVM one-liner

View observes ViewModel; ViewModel calls Repository; no API in Activity

---

## Phụ lục: Map chủ đề JD Mobile/Fintech ↔ Section

| Chủ đề JD thường gặp | Section |
|----------------------|---------|
| OOP 4 tính chất | §1 |
| SOLID | §1.5 |
| Array, List, HashMap, Set | §2 |
| Clean Architecture, DDD, Repository | §3 |
| MVVM, UI state | §4 |
| REST, Loading/Success/Error | §5.3, §5.5 |
| Bearer token, JWT refresh | §5.4 |
| Retrofit / OkHttp | §5.3 |
| Git, branch, PR, conflict | §6 |
| Codebase mới | §6.5 |
| Compose / declarative UI | §7 |
| Unit test, concurrency | §8 |
| Idempotency, offline | §5.1, §8.3 |

---

## Gợi ý lộ trình học (5 ngày)

| Ngày | Nội dung | Cách học |
|------|----------|----------|
| 1 | §1 OOP + SOLID | Viết class `BankAccount`, `PaymentGateway` trên giấy; nói to ví dụ |
| 2 | §2 Collections | Làm bài: list transaction + map cache + set dedupe |
| 3 | §3 + §4 | Vẽ diagram Clean Architecture + luồng MVVM transfer |
| 4 | §5 REST + JWT | Đọc doc API giả, thiết kế interceptor + error map |
| 5 | §6 + §7 + §9 | Luyện trả lời §9 to; đọc §10 trước PV |

---

*Tài liệu ôn phỏng vấn kỹ thuật Mobile/Fintech — ví dụ Java/Android, không phụ thuộc dự án cụ thể.*
