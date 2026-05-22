# 12 — AI implementation guardrails

> Đọc file này **trước** khi sửa bất kỳ thứ gì liên quan UI. Mặc định bị reject nếu vi phạm.

## 1. MUST do

1. **Đọc tài liệu trước khi code.** Tối thiểu: `00` (compact v3), `02` (token), `03` hoặc `06`, `04` hoặc `07`, `11`.
2. **Mọi color** phải qua `AppColors` (không Color(0xff…) trong widget feature).
3. **Mọi spacing** phải qua `AppSpacing` hoặc constant đã có.
4. **Mọi text** mặc định `textPrimary` cho body. Khi đặt `textSecondary` cho body → bị reject.
5. **Mỗi PR UI** phải kèm cập nhật doc tương ứng nếu thêm pattern mới.
6. **Test trên 2 size**: 360×640 (mobile) hoặc 1280×800 (web), trước khi PR.
7. **Có loading + empty + error state** cho mọi list/page.
8. **Form web giáo viên** (wizard, nhiều section): tuân `07` §7.4 — nhãn **trên** ô + `TeacherWebUi.formInputDecoration` / `segmentedControlStyle`; tránh chỉ `labelText` nổi cho text/dropdown (lệch viền, ô cao mà chữ nhỏ).
9. **L10n đầy đủ**: thêm key vào cả `app_en.arb` lẫn `app_vi.arb`, chạy `flutter gen-l10n`.

## 2. MUST NOT do

1. ❌ Hardcode hex `Color(0xff...)` trong widget feature.
2. ❌ `textSecondary` / `textMuted` cho body content.
3. ❌ Tự nghĩ ra spacing 7 / 11 / 13 / 18.
4. ❌ Radius 24+ cho card mobile.
5. ❌ Shadow nặng trên list (chỉ dialog/sheet/popover được).
6. ❌ Bold cả câu để “nhấn”. Bold theo hierarchy đã có trong typography scale.
6b. ❌ `TeacherWebUi.webH1` / `headlineMedium` cho **số KPI** hoặc label card nhỏ — dùng `webKpiValue` (15) và `listTitle` (13).
6c. ❌ `fontSize: 14+` hardcode cho body web — dùng `TeacherWebUi.webBody` (13).
7. ❌ Dùng emoji trong UI thường (chỉ trong dialog chúc mừng + analytics dashboard cho admin).
8. ❌ Dùng teal `#0D9488` hoặc bất kỳ màu xanh nào làm brand. Brand là **`#0A0A0A` Editorial black**; accent duy nhất là amber `#F59E0B` cho "ăn mừng" (KPI nổi, chart highlight). Không đặt 2 màu primary cạnh nhau làm CTA.
9. ❌ Tạo "AppCard2", "MyCustomCard" — sửa `AppCard` hoặc dùng `variant` thay vì duplicate.
10. ❌ `setState` cho business logic — dùng BLoC.

## 3. Khi quyết định mobile hay web

| Tình huống | Quy tắc |
|------------|---------|
| Tính năng cho học sinh | Mobile-first. Nếu code chạy được trên web đó là bonus. |
| Tính năng cho giáo viên | Web-first. Mobile chỉ implement nếu nghiệp vụ bắt buộc (vd. notification mobile teacher). |
| Tính năng cho admin | **Chỉ web**. Không thiết kế mobile. |

## 4. Quy trình AI làm task UI

1. **Hiểu nghiệp vụ** từ `docs/00-…` + folder feature liên quan (`teacher-exam-system`, `auto-update`).
2. **Hiểu khán giả** → mobile hay web?
3. **Đọc spec màn** trong `05` hoặc `08` (nếu có). Không có → cần discussion với designer trước khi tự thiết kế.
4. **Apply token** đúng cấp (`02`).
5. **Apply component** đúng (`04` mobile / `07` web). Tạo mới chỉ khi component không tồn tại.
6. **L10n** EN + VI.
7. **State**: loading skeleton, empty với CTA, error với retry.
8. **A11y check** (`10`): tooltip icon-only, contrast, hit target.
9. **Test mock** trên 2 size đại diện.
10. **Commit message** ghi rõ doc tham chiếu: `feat(student/home): refactor stats card to spec 05§2.1`.

## 5. Checklist trước khi PR

- [ ] Không hex literal trong widget feature
- [ ] Không spacing magic number
- [ ] `textPrimary` cho mọi body
- [ ] Đã có loading state
- [ ] Đã có empty state với CTA
- [ ] Đã có error state với retry
- [ ] L10n đủ EN + VI
- [ ] `flutter gen-l10n` đã chạy
- [ ] `flutter analyze` clean
- [ ] Test ≥ 1 size mobile + 1 size web (nếu có route web)
- [ ] Không deprecate API mà không cập nhật `11` Migration log
- [ ] Doc đã cập nhật nếu thêm component / pattern mới

## 6. Khi gặp xung đột với code cũ

- Code cũ vi phạm doc → **sửa code, không “update doc theo code”**.
- Refactor lớn → mở task riêng, đừng nhét vào PR feature.
- Nếu doc thiếu → đề xuất PR doc trước (ngắn gọn vẫn được merge).

## 7. Khi tài liệu thiếu spec

- KHÔNG tự thiết kế lung tung. Hỏi câu hỏi rõ:
  - Đối tượng khán giả?
  - Web hay mobile chính?
  - Tham khảo app nào?
- Đợi câu trả lời, sau đó **đề xuất spec** → vào doc tương ứng → rồi mới code.

## 8. Self-test cho AI

> Mỗi lần kết thúc một task UI, AI agent tự trả lời:
>
> 1. Tôi đã đọc spec nào trong `docs/ui-ux-system/`?
> 2. Component này dùng token nào? Có hardcode gì không?
> 3. Trên mobile size nhỏ nhất 360×640, có bị tràn / cắt chữ không?
> 4. Loading / empty / error đã có?
> 5. L10n đã đủ?
> 6. Tôi có thêm widget mới mà chưa cập nhật `04` / `07` không?
>
> Trả `yes` / `no` cho từng mục, ghi vào commit body.
