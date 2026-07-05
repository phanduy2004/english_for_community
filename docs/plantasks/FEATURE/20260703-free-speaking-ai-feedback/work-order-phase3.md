# Work Order — Free Speaking Phase 3: Chấm phát âm + Thích ứng + Giáo viên

> Tuân theo [`docs/AI-Working-Process-vi.md`](../../../AI-Working-Process-vi.md). **Loại:** FEATURE · **Platform:** full-stack (student mobile + backend + teacher web) · **Cỡ:** T2 lớn → **tách role-folder** khi thực thi.
>
> ⚠️ **Bắt buộc trước khi code:** chạy lại **Ground-truth analysis** cho hạ tầng Phase 1+2 đã land + hệ **Classroom** (`ClassroomMember`, teacher web) + khả năng lấy audio của **Vapi**. Đây là **nghiệp vụ + kế hoạch định hướng**; phần audio là rủi ro cao nhất, phải POC trước.

---

## 1. Bối cảnh & nghiệp vụ (vì sao cần Phase 3)

Phase 1–2 chấm từ **transcript** → thiếu tiêu chí **Phát âm** (Pronunciation) mà Phase 1 đã cố tình chừa "sắp có". Phase 3 bổ sung lớp **chất lượng cao nhất & khó nhất**: chấm phát âm ở mức âm vị (cần audio), luyện **thích ứng** theo điểm yếu, và mở dữ liệu cho **giáo viên** theo dõi/giao bài trong lớp.

**User stories:**
- *"Tôi muốn biết mình phát âm từ nào sai để sửa"* → điểm phát âm + highlight từ/âm sai + nghe lại.
- *"Tôi muốn app tự cho bài luyện đúng điểm yếu của tôi"* → drill tự sinh + độ khó thích ứng.
- *(Giáo viên)* *"Tôi muốn xem lớp mình luyện nói tới đâu và giao bài"* → dashboard lớp + assign kịch bản.

---

## 2. Các module (nghiệp vụ chi tiết)

### 3A. Chấm phát âm (Pronunciation Assessment) — trọng tâm
**Nghiệp vụ:** khi/kết thúc buổi nói, chấm phát âm: **điểm Accuracy / Fluency / Completeness / Prosody**, danh sách **từ phát âm sai** + âm vị lỗi, đánh dấu **từ cần luyện**. Bổ sung tiêu chí **Pronunciation** vào rubric → đủ **5 tiêu chí IELTS Speaking**. Cho **nghe lại** đoạn của mình + **luyện từng từ** (nối màn shadowing `speaking_skills_page.dart` sẵn có).

**Kỹ thuật (rủi ro cao — POC trước):**
1. **Nguồn audio:** ưu tiên kiểm tra **Vapi có xuất audio/recording** của user không (webhook/end-of-call). Nếu không → **ghi âm phía client** bằng package `record` (đang comment sẵn trong `pubspec.yaml`; quyền `RECORD_AUDIO` đã có trong AndroidManifest) — cần xử lý ghi song song với Vapi giữ mic (rủi ro tranh chấp mic → POC).
2. **Lưu tạm:** upload audio lên storage (Firebase Storage/S3) — **xoá sau khi chấm** (chính sách riêng tư).
3. **Chấm:** gọi **Azure Pronunciation Assessment** (khuyến nghị — phoneme-level, có sẵn API; hoặc Google) → nhận điểm + word/phoneme. Backend service riêng, không nhét vào `aiService` (Groq) hiện tại.
4. Ghép điểm phát âm vào `SpeakingConversation.feedback` (thêm nhánh `pron{...}`).

### 3B. Độ khó thích ứng + Drill tự sinh theo điểm yếu
**Nghiệp vụ:** từ **error bank (Phase 2C)** + lịch sử điểm → hệ thống **đề xuất buổi/kịch bản tiếp theo** đúng điểm yếu và **tự sinh mini-drill** (câu luyện nhắm lỗi hay gặp, từ cần dùng, âm cần sửa). Tự **nâng/hạ CEFR** theo phong độ gần đây.

**Kỹ thuật:** logic chọn scenario/difficulty từ error bank + điểm trung bình; sinh drill qua `aiService` (Groq JSON); có thể tái dùng cấu trúc drill của `speaking_skills`.

### 3C. Giáo viên theo dõi trong lớp (Classroom)
**Nghiệp vụ:** giáo viên xem **tiến bộ nói của học viên trong lớp**: điểm theo tiêu chí, số buổi/phút, lỗi hay gặp, (tuỳ chọn, có quyền) **nghe lại** đoạn ghi. **Giao bài luyện nói** (assign kịch bản/CEFR) cho lớp/cá nhân; theo dõi hoàn thành.

**Kỹ thuật:** nối hệ **Classroom/ClassroomMember** sẵn có; endpoint teacher (RBAC `requirePermissions`); UI teacher web trong classroom detail.

---

## 3. Quyết định thiết kế + cảnh báo

| Quyết định | Lý do / cảnh báo |
|-----------|------------------|
| **POC audio trước tiên** (Vapi export vs client `record`) | Rủi ro tranh chấp mic với Vapi + kích thước/độ trễ upload. Chưa POC xong → KHÔNG cam kết timeline 3A. |
| **Azure Pronunciation Assessment** (mặc định) | Phoneme-level, tài liệu tốt. Cảnh báo: chi phí/độ trễ; cần key & quota; fallback Google. |
| **Audio auto-delete sau chấm** | Riêng tư/pháp lý (giọng nói là dữ liệu cá nhân). Cần **consent** rõ ràng trước khi ghi. |
| Điểm phát âm là service **riêng** (không dùng Groq) | Groq không chấm âm học; tách biệt để bảo trì. |
| Teacher nghe lại audio **chỉ khi có quyền + học viên đồng ý** | Quyền riêng tư + RBAC; mặc định ẩn audio. |

---

## 4. Scope

**IN:** 3A pronunciation (POC audio → assessment → ghép feedback + luyện từ), 3B adaptive + drill tự sinh, 3C teacher classroom view + assign; consent & auto-delete audio; l10n; loading/empty/error.

**OUT (chạm là DỪNG & hỏi):** đổi provider LLM chấm text (giữ Groq), làm lại Vapi, tính năng ngoài speaking, lưu audio vĩnh viễn, chia sẻ audio ra ngoài lớp.

---

## 5. Kế hoạch file-level (Ý ĐỊNH — Codex tự viết; chốt sau POC + ground-truth)

| Khu vực | File dự kiến | Ý định | Nghiệm thu |
|--------|--------------|--------|-----------|
| POC | (nhánh thử) | Xác minh nguồn audio + ghi song song Vapi | có/không có audio dùng được; kết luận rõ |
| Client | bật `record` trong `pubspec.yaml`; service ghi âm | ghi audio buổi nói (nếu chọn hướng client) | ghi/nghe lại được; không tranh chấp mic |
| Client | consent dialog trước ghi | xin đồng ý ghi âm + giải thích auto-delete | không ghi nếu từ chối |
| BE | storage util + `pronunciationService.js` (Azure/Google) | upload tạm → chấm → trả điểm → xoá | điểm phoneme trả đúng; audio bị xoá |
| BE | mở rộng `SpeakingConversation.feedback.pron` + endpoint chấm phát âm | ghép điểm vào buổi | feedback có tab Phát âm |
| BE | adaptive: `speakingService.recommendNext()` + drill generator | gợi ý buổi + sinh drill | trả kịch bản/drill hợp điểm yếu |
| BE (teacher) | route/ctrl/service classroom speaking + assign | RBAC teacher; list học viên | teacher xem/giao được, học viên khác không thấy |
| Client UI | tab **Phát âm** trong feedback (highlight từ sai + nghe lại + luyện) | nối shadowing | hiển thị đúng, phát âm lại được |
| Client UI | "Luyện điểm yếu" (drill tự sinh) | vào drill từ gợi ý | chạy được |
| Teacher web | mục Speaking trong classroom detail + assign | dashboard lớp | đúng archetype teacher web |
| l10n | EN+VI | keys `speakingPron*`, `speakingDrill*`, `speakingTeacher*`, `speakingConsent*` | gen-l10n |

---

## 6. GATE áp dụng

- **BACKEND GATE (có — nặng):** service layer, **Zod validate**, RBAC teacher đúng (`requirePermissions`), external API (Azure) có timeout/retry/xử lý lỗi & quota, **storage tạm + auto-delete**, không N+1 khi list lớp. **Bảo mật/riêng tư = tiêu chí chặn.**
- **PERF GATE (có):** upload audio (nén, giới hạn thời lượng, upload nền), teacher list học viên (pagination/builder), không block UI khi chờ chấm phát âm (async + trạng thái).
- **UI/UX GATE (có):** student mobile (tab phát âm, audio player) + **teacher web** (đọc `ui-ux-system` `06`,`07`,`08`,`18`), loading/empty/error, hit target; audio player component.
- **L10N GATE (có):** EN+VI, gồm chuỗi consent.
- **PRIVACY GATE (đặc thủ Phase 3):** consent trước ghi; audio auto-delete; teacher chỉ xem khi có quyền; ghi rõ chính sách trong work-order/PR.

---

## 7. Hồi quy tối thiểu + account test
- Phase 1–2 không regression (feedback text, dashboard, tình huống, sổ tay vẫn chạy).
- Nói có ghi âm → tab Phát âm hiện điểm + từ sai; audio bị xoá sau chấm.
- Từ chối consent → vẫn nói & chấm text bình thường, không ghi âm.
- Teacher (account `docs/dev/seeds/`) xem được lớp; student khác không thấy dữ liệu chéo.

## 8. Lệnh verify
- Client: `flutter analyze`, `flutter test`, smoke ghi âm + tab phát âm + drill.
- Backend: test endpoint pronunciation (audio mẫu) + teacher classroom (RBAC âm/dương tính) + xác minh audio bị xoá.

## 9. HANDOFF PROMPT (giao Cursor — chốt sau POC)
> Khung: "Implement Free Speaking **Phase 3** theo `work-order-phase3.md`. **POC audio trước** (mục 5). ĐỌC TRƯỚC: work-order này + artifact Phase 1–2 + hệ Classroom + `speaking_skills_page.dart` (shadowing) + `ui-ux-system` teacher. Giữ quyết định khoá §3; PRIVACY GATE bắt buộc (consent + auto-delete). Chỉ sửa file mục 5; ngoài → DỪNG hỏi. L10n EN+VI. Tự audit + liệt kê file, KHÔNG commit/push."

## 10. Checklist OPUS AUDIT (Phase 4)
- [ ] POC audio kết luận rõ; hướng ghi âm không tranh chấp mic Vapi.
- [ ] Audio **auto-delete** sau chấm; có **consent**; không lưu vĩnh viễn.
- [ ] Azure/Google service: timeout/retry/xử lý lỗi & quota; điểm ghép đúng buổi.
- [ ] Teacher RBAC chặt (không rò dữ liệu học viên chéo lớp); audio ẩn mặc định.
- [ ] Không block UI khi chấm phát âm; upload nền có trạng thái.
- [ ] Không regression Phase 1–2; l10n EN+VI; loading/empty/error đủ.
- [ ] Verdict: APPROVED | CHANGES REQUESTED (ghi tracker).

## 11. Phụ thuộc & rủi ro
Cần Phase 1–2 land + **error bank (2C)** cho 3B + **Classroom** cho 3C. **Rủi ro cao nhất = 3A audio** (nguồn audio, tranh chấp mic, chi phí/độ trễ Azure, riêng tư) → **POC là cổng chặn**, chưa POC xong không cam kết phạm vi/timeline 3A. Thứ tự đề xuất: **POC audio → 3A → 3B → 3C**.
