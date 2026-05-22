# 10 — Accessibility & quality bar

## 1. Contrast

| Cặp | Tỉ lệ tối thiểu | Token |
|-----|-----------------|-------|
| `textPrimary` trên `surface` | 12.6 : 1 | ✅ |
| `textPrimary` trên `surfaceCard` | 13.4 : 1 | ✅ |
| `textSecondary` trên `surface` | 7.0 : 1 | ✅ AA |
| `textMuted` trên `surface` | 4.5 : 1 | ✅ AA |
| `onPrimary` trên `primary` | 4.6 : 1 | ✅ AA |
| `success` text trên `success-50` | ≥ 4.5 | ✅ AA |
| `danger` text trên `danger-50` | ≥ 4.5 | ✅ AA |

**Quy tắc:** body ≥ 4.5; UI element (icon, border) ≥ 3.0. Không bao giờ tô chữ `textMuted` cho nội dung quan trọng.

## 2. Hit target

- Mobile: tối thiểu **44dp**, ưu tiên **48dp**.
- Web: tối thiểu **32px** cho icon button, **36px** cho text button.
- Khoảng cách giữa 2 target: tối thiểu 8px (mobile) / 4px (web).

## 3. Focus

- **Web**: ring 2px `primary`, offset 2, radius theo radius element. Phải nhìn thấy bằng `Tab`.
- **Mobile (Flutter)**: `Focus` cho TV/keyboard accessibility nếu route có form dài; mặc định Material 3 đã hỗ trợ.

## 4. Keyboard support (web)

| Phím | Hành vi |
|------|---------|
| `Tab` | Focus next |
| `Shift+Tab` | Focus prev |
| `Enter` | Activate button / submit form |
| `Esc` | Close drawer / dialog / popover |
| `Cmd+K` | Open command palette (admin) |
| `Cmd+S` | Save current editor |
| `Cmd+Enter` | Submit / publish (where supported) |
| `?` | Open shortcut help |

## 5. Screen reader

- Mọi `IconButton` có `tooltip` (cũng dùng làm semantic label).
- Avatar có `Semantics(label: ...)` cho người dùng SR.
- Status pill: kèm text rõ (KHÔNG icon-only) hoặc thêm `Semantics(label: 'Đã nộp')`.
- Image / illustration trang trí: `excludeSemantics: true`.

## 6. Motion-reduce

- Tôn trọng `MediaQuery.disableAnimations` (Flutter) và `prefers-reduced-motion` (web): thay slide bằng fade 80ms.
- Cấm parallax / continuous bounce.

## 7. Tap feedback

- Mobile: ripple `primary 0.08`.
- Web: hover bg `surfaceSubtle` cho list/row, `primaryTint` cho selected.
- Phải có **press state** cho mọi tap-able (KHÔNG lặng thinh).

## 8. Forms

- Mỗi field: label + (helper / error) phải đi kèm.
- Required mark: `*` cuối label, **không** in đỏ riêng `*`.
- Validate **on blur** rồi **on change** sau lần đầu lỗi.
- Lỗi cấp form: banner top form `danger` 1 dòng + danh sách field lỗi (nếu nhiều).

## 9. Localization & RTL

- Hiện tại: en, vi (LTR). Future RTL → token spacing `start/end` thay vì `left/right` trong widget tự viết.

## 10. Images & media

- `cached_network_image` với placeholder skeleton + error icon.
- Audio luôn có nút play/pause với label SR `Phát`/`Tạm dừng`.
- Video không autoplay với âm thanh.

## 11. Performance budget

| Chỉ số | Ngân sách | Đo bằng |
|--------|-----------|---------|
| Mobile cold start → home render | ≤ 2.0s P75 | DevTools timeline |
| Mobile route push | ≤ 250ms | Frame timing |
| Web TTI dashboard | ≤ 2.5s | Lighthouse |
| Web list render 100 rows | ≤ 200ms | Performance API |
| Frame drop > 16ms | < 1% scroll | Skia trace |

## 12. Dùng skeleton, không spinner

- Skeleton mọi list / card lớn. Spinner toàn màn chỉ khi route mới load lần đầu và chưa có khung.
- Cấm “double loading” (skeleton + spinner trên cùng ô).

## 13. Internationalization edge

- Văn bản dài hơn 1.5 lần dự kiến → kiểm tra với từ tiếng Đức / vi dài. Đừng giả định 1 dòng.
- Số nhiều ICU đầy đủ: `0 / 1 / few / many / other` cho vi.
- Tránh ghép chuỗi runtime: `'Bạn còn ' + n + ' bài'` → dùng `homeRemainingLessons(n)`.

## 14. Quality checklist trước khi merge UI

- [ ] Mọi text dùng token / textPrimary mặc định?
- [ ] Mọi color qua `AppColors` (không hex literal trong widget)?
- [ ] Mọi spacing qua `s.*` hoặc helper (không 7/11/13)?
- [ ] Có loading + empty + error state?
- [ ] Hit target ≥ 44 mobile / 32 web?
- [ ] Focus ring web không bị clip?
- [ ] Tooltip cho icon-only button?
- [ ] Đã có l10n cho cả en & vi?
- [ ] Test trên màn nhỏ 360×640 (mobile) / 1280×800 (web)?
