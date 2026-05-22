# 13 — Teacher live session console layout

> **Màn:** `TeacherExamSessionConsolePage`  
> **Mục tiêu:** Giáo viên theo dõi **nhiều học sinh** trong tab Live monitor — không chiếm 30–40% viewport bởi metadata cố định.

---

## 1. Nguyên tắc (bắt buộc)

| # | Quy tắc |
|---|---------|
| L1 | **Tab bar** (`Session control` / `Live monitor`) luôn **ngay dưới page header** — không chèn card metadata phía trên. |
| L2 | **TabBarView** chiếm **toàn bộ** chiều cao còn lại (`Expanded`). |
| L3 | Metadata phiên (đề, lớp, giờ, mã phòng) → **strip thu gọn** (`TeacherExamSessionCompactStrip`), mặc định **đóng**. |
| L4 | Chi tiết đầy đủ chỉ khi GV bấm **Chi tiết** / mở rộng — không ép scroll. |
| L5 | Live monitor: toolbar tóm tắt **~56px** cố định; danh sách HS **scroll** phần còn lại. |

---

## 2. Cấu trúc layout (live)

```
┌─ Page header: Live exam session · [End session] ─────────────┐
├─ TabBar: Session control | Live monitor (active) ───────────┤
├─ Toolbar (~56px): 3 in progress · 2 submitted · … + FilterChips ┤
├─ ListView (Expanded) ────────────────────────────────────────┤
│  ┌─ Student card ~120–180px ────────────────────────────────┐ │
│  ┌─ Student card ───────────────────────────────────────────┐ │
│  ┌─ Student card ───────────────────────────────────────────┐ │
│  … (2–4+ cards visible on laptop)                          │
└────────────────────────────────────────────────────────────┘
```

**Cấm** (thiết kế cũ):

```
[ Card metadata lớn ~300px cố định ]
[ TabBar ]
[ 1 student card only visible      ]
```

---

## 3. `TeacherExamSessionCompactStrip`

| Trạng thái | Nội dung |
|------------|----------|
| **Đóng** (mặc định) | Pill trạng thái + tên đề (1 dòng) + meta `Lớp · Hết lúc · Mã phòng` |
| **Mở** | + banner trạng thái, giáo viên, các mốc thời gian, chính sách thời lượng |

- Chỉ tab **Session control** và màn **lobby** (không tab) gắn strip trong body scroll.
- Tab **Live monitor** **không** gắn strip — tối đa diện tích list.

---

## 4. Thẻ học sinh (Live monitor) — compact

| Thành phần | Spec |
|------------|------|
| Chiều cao mục tiêu | ~100–160px (có/không skill strips) |
| Header row | Tên + cờ integrity + icon **Watch** + icon Kick |
| Progress | Bar 4px + `answered/total · %` 11px |
| Strips | `TeacherExamSkillStripsPanel(compact: true)` |
| **Không** dùng | `FilledButton` full-width "Watch live screen" |

---

## 5. Session control tab

Thứ tự scroll:

1. `TeacherExamSessionCompactStrip`
2. Hint rời trang (khi live)
3. Copy link (lobby)
4. Danh sách chờ (`_rosterSection`)

---

## 6. Responsive

| Viewport | Ghi chú |
|----------|---------|
| ≥768 web | Header actions góc phải; monitor list rộng |
| &lt;768 mobile | `bottomActions` cho Start/End; tab + list full height |

---

## 7. Code map

| Widget | File |
|--------|------|
| Console + tabs | `teacher_exam_session_console_page.dart` |
| Compact strip | `teacher_exam_session_compact_strip.dart` |
| Full card (legacy lobby) | `teacher_exam_session_context_card.dart` |
| Live monitor list | `widgets/teacher_live_monitor_panel.dart` |

---

## 8. Acceptance

- [ ] Tab Live monitor: ≥2 thẻ HS nhìn thấy trên laptop 1080p không scroll (với metadata đóng).
- [ ] Metadata mặc định **đóng**; mở không đẩy tab ra khỏi viewport.
- [ ] Filter chips luôn nhìn thấy khi scroll list (toolbar cố định trong tab).
- [ ] Watch screen = icon, không full-width button.
