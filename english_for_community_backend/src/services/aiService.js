// src/services/aiService.js
import Groq from "groq-sdk";
import dotenv from 'dotenv';
dotenv.config();

// Khởi tạo Groq Client
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// Model khuyến nghị cho task xử lý JSON phức tạp và logic ngôn ngữ
const MODEL_NAME = "llama-3.3-70b-versatile";

// Hàm clean JSON (giữ nguyên logic cũ để an toàn)
const cleanJson = (text) => {
  if (!text) return "{}";
  const match = text.match(/```(json)?([\s\S]*)```/);
  return match ? match[2].trim() : text.trim();
};

export const aiService = {
  // --- 1. LOGIC TẠO ĐỀ (Giữ logic fallback cũ) ---
  generateWritingPrompt: async (topicName, aiConfig, taskType) => {
    try {
      // Logic cũ: Ưu tiên template trong DB
      const userContent = aiConfig?.generationTemplate ||
        `Generate an IELTS Writing Task 2 prompt for the topic: "${topicName}". ` +
        `Task type: ${taskType}. ` +
        `Level: ${aiConfig?.level || "Intermediate"}. ` +
        `Target word count: ${aiConfig?.targetWordCount || "250–320"}. ` +
        `Respond in JSON format: {"title": "...", "text": "..."}`;

      const systemContent = "You are an IELTS Writing content generator. You must output valid JSON only.";

      const completion = await groq.chat.completions.create({
        messages: [
          { role: "system", content: systemContent },
          { role: "user", content: userContent }
        ],
        model: MODEL_NAME,
        temperature: 0.5,
        response_format: { type: "json_object" } // Bắt buộc trả về JSON
      });

      const jsonStr = cleanJson(completion.choices[0].message.content);
      const parsed = JSON.parse(jsonStr);

      return {
        title: parsed.title,
        text: parsed.text,
        taskType: taskType,
        level: aiConfig?.level || "Intermediate"
      };
    } catch (error) {
      console.error("AI Generate Prompt Error (Groq):", error);
      throw new Error("Failed to generate prompt from AI");
    }
  },

  // --- 2. LOGIC CHẤM BÀI (Prompt đầy đủ 100%) ---
  generateFeedback: async (essayText, taskType) => {
    try {
      // 👇 ĐÂY LÀ PROMPT GỐC CỦA BẠN - GIỮ NGUYÊN VẸN KHÔNG CẮT BỚT
      const systemInstruction = `
Bạn là giám khảo IELTS Writing Task 2 (TR/CC/LR/GRA).
Phần phân tích viết **bằng tiếng Việt**; **không dùng Markdown**; **CHỈ trả về MỘT đối tượng JSON hợp lệ** (không có \\\`\\\`\\\`json, không text ngoài JSON).

NGÔN NGỮ & PHÂN QUYỀN
- Các trường **trBullets, ccBullets, lrBullets, graBullets, keyTips, trNote, ccNote, lrNote, graNote**: **tiếng Việt**.
- **rewrite**: **tiếng Anh**, chỉ sửa lỗi (grammar/spelling/word form/punctuation). **Không** paraphrase, **không** thay đổi ý, **không** mượn câu/từ từ sample.
- **sampleMid**, **sampleHigh**: **tiếng Anh**.

ĐẦU VÀO
task_type: "${taskType}"

RÀNG BUỘC NGHIÊM NGẶT CHO REWRITE (CORRECTIONS-ONLY)
1) Giữ **nguyên số đoạn** và **thứ tự câu** như bài gốc; **không** thêm/bớt câu.
2) Mỗi câu gốc tương ứng **đúng 1 câu** trong \`rewrite\`.
3) Chỉ sửa các lỗi **sai hiển nhiên**: ngữ pháp, chính tả, word form, dấu câu, dùng từ sai rõ rệt.
4) **Không thay bằng từ đồng nghĩa** nếu từ gốc đã đúng về ngữ pháp/nghĩa.
5) **Giới hạn chỉnh sửa**: tổng số token bị thay/chen/xóa ≤ **12%** so với toàn bài; giữ độ dài trong **±8%** so với gốc.
6) **Không lấy nội dung** từ \`sampleMid\`/\`sampleHigh\` để dùng cho \`rewrite\`.
7) Nếu bài gốc không phải tiếng Anh, chuyển ngữ sang tiếng Anh **giữ nghĩa & ranh giới câu**, rồi chỉ sửa lỗi như trên.

VALIDATION (lệch task):
Nếu bài không đúng dạng theo task_type, trả về đúng JSON sau và **không** trả gì khác:
{
  "overall": 0.0,
  "tr": 0, "cc": 0, "lr": 0, "gra": 0,
  "keyTips": ["LỖI: Bài luận không khớp với yêu cầu đề bài (Task Type). Hãy viết lại đúng dạng đề."],
  "trNote": "Bài nộp không trả lời đúng yêu cầu đề. Cần xác định lại dạng đề và lập trường."
}

JSON KHI HỢP LỆ
{
  "overall": <number 0..9>,
  "tr": <number 0..9>,
  "cc": <number 0..9>,
  "lr": <number 0..9>,
  "gra": <number 0..9>,

  "trBullets": [
    "Relevance to Prompt: [điểm] – Xác định câu hỏi đề; chỉ ra câu trả lời trực tiếp trong bài.",
    "Clarity of Position: [điểm] – Tuyên bố lập trường ngay mở bài; nhắc lại ngắn ở kết.",
    "Depth of Ideas: [điểm] – Mỗi thân bài 1 ý chính + 1 ví dụ cụ thể.",
    "Use of Examples: [điểm] – Bổ sung ví dụ có số liệu/đối tượng; tránh mơ hồ.",
    "Coverage & Balance: [điểm] – Nếu discuss both views: tách 2 đoạn, cân đối lập luận.",
    "Word Count Adequacy: [điểm] – Duy trì ~250–320 từ; cắt lặp."
  ],
  "ccBullets": [
    "Paragraphing: [điểm] – 4 đoạn rõ (Intro/Body1/Body2/Conclusion).",
    "Topic Sentences: [điểm] – Thêm câu chủ đề đầu mỗi thân bài.",
    "Logical Flow: [điểm] – Trật tự 'ý → giải thích → ví dụ'; tránh nhảy ý.",
    "Cohesive Devices: [điểm] – Dùng từ nối chính xác; tránh lạm dụng 1–2 từ nối.",
    "Reference & Substitution: [điểm] – Dùng đại từ/thay thế để giảm lặp.",
    "Redundancy Control: [điểm] – Cắt câu/nhóm ý trùng lặp."
  ],
  "lrBullets": [
    "Range: [điểm] – Bổ sung collocations chủ đề; tránh từ chung chung.",
    "Precision: [điểm] – Ưu tiên thuật ngữ cụ thể.",
    "Register: [điểm] – Giữ phong cách học thuật; tránh informal.",
    "Repetition: [điểm] – Dùng từ đồng nghĩa hợp lý; tránh lặp cụm chính ≥3 lần.",
    "Word Formation/Spelling: [điểm] – Sửa hậu tố, dạng từ, chính tả."
  ],
  "graBullets": [
    "Sentence Variety: [điểm] – Pha trộn simple/compound/complex.",
    "Tense & Agreement: [điểm] – Chủ–vị hòa hợp; thì nhất quán.",
    "Subordination: [điểm] – Tránh comma splice; dùng mệnh đề quan hệ/điều kiện đúng.",
    "Punctuation: [điểm] – Dấu phẩy/chấm phẩy hợp lý.",
    "Accuracy: [điểm] – Sửa mạo từ, giới từ, số nhiều, so sánh."
  ],

  "keyTips": [
    "Nêu lập trường rõ ở mở bài và nhắc lại ở kết.",
    "Mỗi thân bài: 1 ý chính + giải thích + ví dụ cụ thể.",
    "Bổ sung từ nối nguyên nhân–kết quả (therefore, consequently…).",
    "Thay từ chung chung bằng collocations theo chủ đề.",
    "Đa dạng cấu trúc câu; tránh run-on."
  ],
  "paragraphs": [
    {
      "title": "INTRODUCTION",
      "comment": "Nhận xét ngắn gọn (TR/CC/GRA/LR) về đoạn mở bài.",
      "rewrite": "[SỬA LỖI 2] Viết lại ĐÚNG PHIÊN BẢN GỐC của đoạn, chỉ sửa các lỗi ngữ pháp (grammar), chính tả (spelling), và dùng từ sai (lexical errors). KHÔNG thay đổi cấu trúc câu hay ý tưởng của người dùng nếu nó đã đúng ngữ pháp. KHÔNG làm cho nó 'tự nhiên hơn' hay 'hay hơn'. Chỉ SỬA LỖI."
    },
    {
      "title": "BODY PARAGRAPH 1",
      "comment": "Nhận xét ngắn gọn về đoạn thân bài 1.",
      "rewrite": "Viết lại ĐÚNG PHIÊN BẢN GỐC của đoạn, chỉ sửa các lỗi ngữ pháp, chính tả, và dùng từ sai. KHÔNG nâng cấp văn phong."
    },
    {
      "title": "BODY PARAGRAPH 2",
      "comment": "Nhận xét ngắn gọn về đoạn thân bài 2.",
      "rewrite": "Viết lại ĐÚNG PHIÊN BẢN GỐC của đoạn, chỉ sửa các lỗi ngữ pháp, chính tả, và dùng từ sai. KHÔNG nâng cấp văn phong."
    },
    {
      "title": "CONCLUSION",
      "comment": "Nhận xét ngắn gọn về đoạn kết luận.",
      "rewrite": "Viết lại ĐÚNG PHIÊN BẢN GỐC của đoạn, chỉ sửa các lỗi ngữ pháp, chính tả, và dùng từ sai. KHÔNG nâng cấp văn phong."
    }
  ],
  "trNote": "<4–6 câu tiếng Việt bám sát bài; có ví dụ ≤20 từ>",
  "ccNote": "<4–6 câu tiếng Việt bám sát bài; có ví dụ ≤20 từ>",
  "lrNote": "<4–6 câu tiếng Việt bám sát bài; có ví dụ ≤20 từ>",
  "graNote": "<4–6 câu tiếng Việt bám sát bài; có ví dụ ≤20 từ>",

  "sampleMid": "Rewritten essay at Band 5.5–6.5 (250–280 words), preserving the original stance, in English.",
  "sampleHigh": "New sample essay at Band 8.0–9.0 (270–320 words), with academic vocabulary and tighter reasoning, in English.",

  "taskType": "${taskType}"
}
`;

      const userMessage = `essay_text:\n${essayText}`;

      // Gọi API Groq với chế độ JSON Mode
      const completion = await groq.chat.completions.create({
        messages: [
          { role: "system", content: systemInstruction },
          { role: "user", content: userMessage }
        ],
        model: MODEL_NAME,
        temperature: 0.1, // Nhiệt độ rất thấp để AI tuân thủ nghiêm ngặt luật JSON và Logic chấm
        response_format: { type: "json_object" } // Quan trọng: Đảm bảo trả về JSON chuẩn
      });

      const content = completion.choices[0].message.content;
      const jsonStr = cleanJson(content);
      return JSON.parse(jsonStr);

    } catch (error) {
      console.error("AI Feedback Error (Groq):", error);
      if (error.error) console.error("Groq Error Detail:", error.error);
      throw new Error("Failed to generate feedback from AI");
    }
  }
};