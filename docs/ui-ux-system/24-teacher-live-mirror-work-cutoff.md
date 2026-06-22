# 24 — Teacher live mirror: bài làm học sinh bị che/cắt

> **Phạm vi:** màn "Live — mirroring student screen" (giáo viên giám sát bài học sinh đang làm).
> **Vấn đề:** lưới số câu (bản đồ câu hỏi của TẤT CẢ section) chiếm gần hết màn, **đẩy phần bài làm thật của học sinh xuống đáy và bị cắt** → không giám sát được.
> **Mục tiêu:** bài làm học sinh **luôn chiếm phần lớn** không gian; bản đồ câu hỏi gọn/giới hạn/thu gọn. Cursor code theo + audit.
> **Nguồn:** đọc code 06/2026.

---

## 1. Triệu chứng

Vào màn giám sát: thấy lưới số câu **Grammar 1–30 + Reading 1–4 + Listening Dictation 1–12 + Comprehension 1–5 + Speaking 1–8** xếp chồng dọc, chiếm ~60–70% chiều cao; phần bài làm ("29. Put fragments in order…") chỉ còn một dải mỏng ở đáy và **bị cắt cụt**.

---

## 2. Chẩn đoán root-cause

| # | Nguyên nhân | `file:dòng` | Vì sao gây cắt |
|---|-------------|-------------|----------------|
| V1 | **Khoá cứng chiều cao 72% màn** cho cả mirror | `teacher_student_live_screen_page.dart:136-138` `SizedBox(height: MediaQuery.sizeOf(context).height * 0.72)` | Phí ~28% màn, bóp toàn bộ nội dung vào hộp nhỏ |
| V2 | **Bản đồ câu hỏi (mọi section) đặt TRÊN `Expanded` bài làm, KHÔNG giới hạn chiều cao** | `student_exam_live_mirror_view.dart:211-217` (`TeacherExamSkillStripsPanel`) ngay trước `Expanded` `:219-227` | Strip stack của 5 section ăn hết chiều cao → `Expanded` chỉ còn dải mỏng → bài làm bị cắt |
| V3 | Bản đồ hiển thị **tất cả section** dù đã có **tab chọn section** (Grammar/Reading/…) | tabs `:191-210`; panel `:213` | Dư thừa: tab đã chọn section, nhưng vẫn vẽ lưới mọi section |

> **Bản chất:** thứ tự ưu tiên không gian bị ngược — "bản đồ câu hỏi" (phụ trợ) chiếm chỗ của "bài làm học sinh" (nội dung chính giáo viên cần xem).

---

## 3. Giải pháp

> Nguyên tắc: **bài làm = `Expanded` (chiếm phần lớn)**; **bản đồ câu hỏi = phụ, bị giới hạn/thu gọn/đồng bộ tab**.

### S1 · Cho mirror dùng HẾT chiều cao khả dụng (V1)
- Bỏ `SizedBox(height: 0.72 * screenHeight)` ở `teacher_student_live_screen_page.dart`. `TeacherPageScaffold(scrollable:false)` đã đặt body trong `Expanded` → cho khung mirror **fill** chiều cao còn lại.
- Cấu trúc lại body: `Column(children:[ Expanded(child: DecoratedBox(... child: StudentExamLiveMirrorView)) ])` hoặc `SizedBox.expand` để DecoratedBox cao hết phần còn lại (thay vì 72%).

### S2 · Giới hạn + đồng bộ bản đồ câu hỏi (V2, V3) — chọn 1, khuyến nghị A+C
**A. Chỉ hiện strip của SECTION ĐANG CHỌN** (đồng bộ tab `active`/`idx`), không vẽ cả 5 section.
- Lọc `skillStrips` theo section của `active` part trước khi đưa vào `TeacherExamSkillStripsPanel`. Grammar tab → chỉ lưới Grammar; Reading tab → chỉ Reading…
**B. Giới hạn chiều cao bản đồ + cuộn trong** (an toàn cho section dài như Grammar 30):
- Bọc panel trong `ConstrainedBox(maxHeight: 96–120)` + cuộn dọc nội bộ; phần dư của màn dành cho bài làm.
**C. Thu gọn được (collapsible)** — nút/chip "Bản đồ câu hỏi ▾", **mặc định thu gọn** (hoặc chỉ 1 hàng), bung khi cần.
> **Khuyến nghị:** **A (chỉ section đang chọn) + C (thu gọn, mặc định gọn 1–2 hàng)**. Khi đó bản đồ chỉ chiếm ~1 hàng; bài làm chiếm gần hết. B làm fallback nếu một section vẫn quá nhiều câu.

### 3.1 Mockup (sau khi sửa)
```
┌───────────────────────────────────────────────┐
│ ● Live — mirroring student screen             │  (banner, mỏng)
│ [Grammar][Reading][Listening][Writing][Speak] │  (tabs)
│ Bản đồ câu hỏi ▾   ① ② 3 4 5 … (1 hàng, cuộn) │  (chỉ section đang chọn, gọn/thu gọn)
│ ┌───────────────────────────────────────────┐ │
│ │ 29. Put fragments in order                │ │
│ │  1  by the committee.                      │ │  ← BÀI LÀM = Expanded, chiếm phần lớn,
│ │  2  …                                      │ │     cuộn đầy đủ, KHÔNG bị cắt
│ │  …                                         │ │
│ └───────────────────────────────────────────┘ │
└───────────────────────────────────────────────┘
```

---

## 4. Audit checklist

- [ ] Mirror dùng **hết** chiều cao khả dụng (bỏ `0.72 * screenHeight`).
- [ ] Bài làm học sinh ở `Expanded`, **không bị cắt**, cuộn được đầy đủ tới câu cuối.
- [ ] Bản đồ câu hỏi: chỉ hiện **section đang chọn** (đồng bộ tab); chiều cao giới hạn (≤ ~120) hoặc thu gọn mặc định.
- [ ] Section dài (Grammar 30): bản đồ cuộn nội bộ, KHÔNG đẩy bài làm.
- [ ] Đổi tab → bản đồ + bài làm đổi theo section, vẫn không bị cắt.
- [ ] Thử màn cao thấp khác nhau (laptop 768 cao, desktop 1080) đều thấy đủ bài làm.
- [ ] `dart analyze lib` 0 lỗi mới.

---

## 5. Bản đồ file ↔ việc

| File | Việc | Mục |
|------|------|-----|
| `teacher_student_live_screen_page.dart` | bỏ `SizedBox(0.72h)`; cho DecoratedBox/mirror fill chiều cao (`Expanded`/`SizedBox.expand`) | V1 / S1 |
| `student_exam_live_mirror_view.dart` | lọc `skillStrips` theo `active` section; bọc `TeacherExamSkillStripsPanel` trong `ConstrainedBox(maxHeight)` + collapsible; giữ bài làm trong `Expanded` | V2,V3 / S2 |
| `teacher_exam_question_strip.dart` (`TeacherExamSkillStripsPanel`) | hỗ trợ render 1 section + chế độ compact/thu gọn nếu cần | S2 |

> Ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md) "Migration log". Liên quan live console [`13`](13-teacher-live-session-console-layout.md), [`16`](16-teacher-live-participant-status.md).
</content>
