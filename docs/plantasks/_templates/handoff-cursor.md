# Template — HANDOFF cho Cursor/Codex (copy-paste, biên giới cứng)

> Khối bàn giao dán thẳng cho implementer. Đi kèm work-order (nguồn sự thật). Nguyên tắc: **Codex đọc work-order §5
> CONTEXT BUNDLE là đủ code — không phải đi grep lại.** Handoff = biên giới + trình tự + verify, KHÔNG thay cho việc đọc file.
>
> Điền `<...>`. Giữ **BƯỚC 0** ở đầu (bài học: handoff chỉ-inline làm Codex mất context → lệch scope). Xem
> [`work-order.md`](work-order.md) §8 để đồng bộ.

---

## Khối handoff (copy nguyên khối)

```text
Bạn là implementer (Cursor/Codex). Làm đúng phạm vi, biên giới cứng.
Repo: <repo — vd english_for_community (Flutter) | english_for_community_backend (Node ESM)>.

━━━ BƯỚC 0 — ĐỌC WORK-ORDER TRƯỚC (bắt buộc) ━━━
Mở & đọc HẾT: docs/plantasks/<Loại>/<TaskID>/work-order.md
Nắm: §1 nguyên nhân gốc · §2 audit downstream · §4 Scope IN/OUT · §5 CONTEXT BUNDLE · §6 GATE · §7 verify/smoke.
QUY TẮC: code cần sửa lấy NGUYÊN từ §5 (anchor + BEFORE/AFTER + symbol table) — KHÔNG tự grep lại rồi đoán.
         Nếu file thực tế lệch với BEFORE trong §5, hoặc doc mâu thuẫn khối này → DỪNG & hỏi Opus (doc thắng prompt).

━━━ PHẠM VI ━━━
SỬA (chỉ những file này): <liệt kê chính xác path — khớp §4 IN>
TUYỆT ĐỐI KHÔNG:
  - Đụng file/khu vực §4 OUT: <liệt kê>
  - Schema/migration không có trong plan; đổi public signature; mở rộng scope; hardcode secret/key.
  - <ràng buộc riêng của task: đổi prompt/model/response_format; đổi ngưỡng; đổi dispose order; ...>

━━━ LÀM ━━━
Theo §5 CONTEXT BUNDLE, từng Site: tìm anchor-string → áp AFTER → xử lý GOTCHA.
Symbol [THÊM] trong §5: tạo đủ (l10n → thêm app_en.arb + app_vi.arb rồi `flutter gen-l10n`; route → AppRouter; DI → get_it).
Bám convention: <file convention cụ thể, vd .cursor/rules/project.mdc; docs/dev/flutter-coding-structure.md; Route→Controller→Service→Model>.
GATE bắt buộc (chỉ cái §6 đánh rủi ro):
  - PERF: ListView.builder/lazy/debounce≥300ms/BlocSelector-buildWhen/dispose subscription/không API trong build.
  - UI/UX: token-only, component có sẵn, skeleton/empty/error, đối chiếu màn tham chiếu + brief.
  - BACKEND: logic ở service, Zod validate, không logic nặng trong controller, index nếu list lớn.

━━━ VERIFY (chạy hết, dán kết quả) ━━━
<dán nguyên §7: lệnh analyze/build + smoke 1..n với kỳ vọng; ⭐ = ca nghiệm thu chính>

━━━ XONG ━━━
- Dán kết quả verify + smoke (đủ các bước) vào chat.
- Tự liệt kê file đã tạo/sửa + chỗ còn nghi ngờ (self-audit ngắn: file · rủi ro · checklist tự chấm).
- KHÔNG tự commit/push (để working tree cho review).
- Báo Opus: "implementer đã xong, audit đi" → Opus Phase 4.
```

---

## Ghi chú khi điền
- **BƯỚC 0 không được bỏ** — đó là điểm khác biệt so với handoff cũ (chỉ-inline làm Codex thiếu §2/§4/§7).
- **Không lặp lại toàn bộ code trong handoff** — code sống ở work-order §5; handoff chỉ trỏ tới. Tránh 2 nguồn sự thật lệch nhau.
- **Ràng buộc "TUYỆT ĐỐI KHÔNG"** phải cụ thể theo task (không chỉ câu chung) — đây là hàng rào chống scope-creep.
- **VERIFY phải copy-paste chạy được** + mỗi smoke có kỳ vọng đo được; đánh dấu ⭐ ca nghiệm thu chính để Codex biết ưu tiên.
