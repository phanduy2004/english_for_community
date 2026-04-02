// src/services/aiService.js
import Groq from "groq-sdk";
import dotenv from 'dotenv';
dotenv.config();

// Khởi tạo Groq Client
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// Model khuyến nghị
const MODEL_NAME = "llama-3.3-70b-versatile";

// Hàm clean JSON (Loại bỏ ```json ... ```)
const cleanJson = (text) => {
  if (!text) return "{}";
  const match = text.match(/```(json)?([\s\S]*)```/);
  return match ? match[2].trim() : text.trim();
};

export const aiService = {
  // --- 1. LOGIC TẠO ĐỀ (Giữ nguyên) ---
  generateWritingPrompt: async (topicName, aiConfig, taskType) => {
    try {
      // System: Định nghĩa vai trò chặt chẽ hơn
      const systemContent = `
        You are an expert IELTS Writing Task 2 Question Generator (Exam Creator).
        Your ONLY job is to create the exam prompt (the question).
        
        ⛔ CRITICAL RULES:
        1. Do NOT write the essay.
        2. Do NOT provide sample answers, outlines, or introductions.
        3. Output valid JSON only.
      `;

      // User: Hướng dẫn chi tiết cấu trúc JSON và nhắc lại lệnh cấm
      const userContent = `
        Generate a unique IELTS Writing Task 2 prompt.
        
        - Topic: "${topicName}"
        - Task Type: ${taskType} (e.g., Agree/Disagree, Discuss both views, etc.)
        - Difficulty Level: ${aiConfig?.level || "Intermediate"}
        
        REQUIRED JSON FORMAT:
        {
          "title": "Short topic title (e.g., Technology in Education)",
          "text": "The full exam question statement. Include the background context and the specific question instructions."
        }
        
        IMPORTANT: Just output the question JSON. Do not write the essay response.
      `;

      const completion = await groq.chat.completions.create({
        messages: [
          { role: "system", content: systemContent },
          { role: "user", content: userContent }
        ],
        model: MODEL_NAME,
        temperature: 0.6, // Tăng nhẹ để đề bài sáng tạo hơn (nhưng vẫn tuân thủ format)
        response_format: { type: "json_object" }
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

  // --- 2. LOGIC CHẤM BÀI (FULL PROMPT) ---
  generateFeedback: async (essayText, taskType) => {
    try {
      // PROMPT CHI TIẾT ĐẦY ĐỦ
      const systemInstruction = `
Bạn là giám khảo IELTS Writing Task 2 khó tính và chuyên nghiệp.
Nhiệm vụ: Chấm điểm, nhận xét chi tiết, sửa lỗi ngữ pháp/từ vựng và viết bài mẫu.
Format Output: JSON Object (Tuyệt đối không dùng Markdown, chỉ trả về JSON thuần).

=== 1. QUY ĐỊNH VỀ NGÔN NGỮ & ĐỊNH DẠNG ===
- **Phân tích (Bullets, Tips, Notes):** Viết bằng **Tiếng Việt**.
- **Rewrite & Samples:** Viết bằng **Tiếng Anh**.
- **JSON Strict:** Đảm bảo cấu trúc JSON hợp lệ, thoát các ký tự đặc biệt nếu cần.

=== 2. QUY ĐỊNH VỀ SỬA LỖI (REWRITE) - QUAN TRỌNG ===
- MỤC TIÊU: Giữ nguyên toàn bộ văn bản gốc. CHỈ sửa khi có lỗi sai thật sự (ngữ pháp, chính tả, sai ngữ cảnh). KHÔNG sửa chỉ để câu văn hay hơn.
- QUY TẮC ĐÁNH DẤU (BẮT BUỘC): Nếu bạn thay đổi, thêm, hoặc bớt BẤT KỲ từ nào so với bản gốc, bạn PHẢI bọc nó trong tag {{từ_cũ||từ_mới||lý_do_ngắn_gọn_bằng_tiếng_Việt}}.
- LỆNH CẤM: TUYỆT ĐỐI KHÔNG ĐƯỢC "SỬA NGẦM" (Tức là sửa lỗi nhưng không dùng tag). 

🔴 VÍ DỤ THỰC TẾ:
- Input gốc: "It is accessible sand convenient. It nows allows users to learn."
- Output SAI (Bị cấm vì sửa ngầm không dùng tag): "It is accessible and convenient. It now allows users to learn."
- Output CHUẨN (BẮT BUỘC): "It is accessible {{sand||and||Lỗi chính tả dư chữ s}} convenient. It {{nows allows||now allows||Sai ngữ pháp}} users to learn."

- BẮT BUỘC PHẢI TRẢ VỀ TOÀN BỘ ĐOẠN VĂN GỐC. Chép y nguyên các câu đúng, và CHỈ dùng tag ở những chữ bị sai.

=== 3. QUY ĐỊNH VỀ BÀI MẪU (SAMPLES) - QUAN TRỌNG ===
- **sampleMid (Band 7.0-8.0):** Viết lại bài của user (giữ ý tưởng chính) thành một bài luận hoàn chỉnh, sửa hết lỗi, flow trôi chảy.
- **sampleHigh (Band 9.0):** Viết một bài luận HOÀN TOÀN MỚI, ý tưởng sâu sắc, từ vựng Academic cao cấp.
- **YÊU CẦU ĐẶC BIỆT:** 1. Phải viết **FULL ESSAY** (Tối thiểu 250 từ). KHÔNG ĐƯỢC tóm tắt hay cắt bớt.
  2. BẮT BUỘC dùng ký tự **\\n\\n** (xuống dòng kép) để tách rõ ràng giữa các đoạn văn (Mở bài, Thân bài 1, Thân bài 2, Kết bài).

=== 4. CẤU TRÚC JSON MONG MUỐN ===
Hãy điền thông tin vào mẫu JSON sau dựa trên bài làm của học viên:

{
  "overall": <number 0.0-9.0>,
  "tr": <number>, "cc": <number>, "lr": <number>, "gra": <number>,

  "trBullets": [
    "Relevance: [Điểm] - Nhận xét tiếng Việt...",
    "Position: [Điểm] - Nhận xét tiếng Việt...",
    "Ideas: [Điểm] - Nhận xét tiếng Việt...",
    "Examples: [Điểm] - Nhận xét tiếng Việt..."
  ],
  "ccBullets": [
    "Paragraphing: [Điểm] - Nhận xét tiếng Việt...",
    "Topic Sentences: [Điểm] - Nhận xét tiếng Việt...",
    "Logical Flow: [Điểm] - Nhận xét tiếng Việt...",
    "Cohesive Devices: [Điểm] - Nhận xét tiếng Việt..."
  ],
  "lrBullets": [
    "Range: [Điểm] - Nhận xét tiếng Việt...",
    "Precision: [Điểm] - Nhận xét tiếng Việt...",
    "Collocations: [Điểm] - Nhận xét tiếng Việt...",
    "Spelling: [Điểm] - Nhận xét tiếng Việt..."
  ],
  "graBullets": [
    "Variety: [Điểm] - Nhận xét tiếng Việt...",
    "Tenses: [Điểm] - Nhận xét tiếng Việt...",
    "Punctuation: [Điểm] - Nhận xét tiếng Việt...",
    "Accuracy: [Điểm] - Nhận xét tiếng Việt..."
  ],

  "keyTips": [
    "Lời khuyên cải thiện 1 (Tiếng Việt)",
    "Lời khuyên cải thiện 2 (Tiếng Việt)",
    "Lời khuyên cải thiện 3 (Tiếng Việt)"
  ],

  "paragraphs": [
    {
      "title": "INTRODUCTION",
      "comment": "Nhận xét ngắn về mở bài (Tiếng Việt)",
      "rewrite": "Câu văn gốc có chèn tag {{old||new||reason}}..."
    },
    {
      "title": "BODY PARAGRAPH 1",
      "comment": "Nhận xét ngắn về thân bài 1 (Tiếng Việt)",
      "rewrite": "Câu văn gốc có chèn tag {{old||new||reason}}..."
    },
    {
      "title": "BODY PARAGRAPH 2",
      "comment": "Nhận xét ngắn về thân bài 2 (Tiếng Việt)",
      "rewrite": "Câu văn gốc có chèn tag {{old||new||reason}}..."
    },
    {
      "title": "CONCLUSION",
      "comment": "Nhận xét ngắn về kết bài (Tiếng Việt)",
      "rewrite": "Câu văn gốc có chèn tag {{old||new||reason}}..."
    }
  ],

  "trNote": "Nhận xét chi tiết Task Response (4-6 câu Tiếng Việt)",
  "ccNote": "Nhận xét chi tiết Coherence & Cohesion (4-6 câu Tiếng Việt)",
  "lrNote": "Nhận xét chi tiết Lexical Resource (4-6 câu Tiếng Việt)",
  "graNote": "Nhận xét chi tiết Grammatical Range & Accuracy (4-6 câu Tiếng Việt)",

  "sampleMid": "VIẾT BÀI MẪU BAND 7.0 - 9.0 ĐẦY ĐỦ VÀO ĐÂY (TIẾNG ANH). NHỚ DÙNG \\n\\n ĐỂ TÁCH ĐOẠN.",
  "sampleHigh": "VIẾT BÀI MẪU BAND 9.0 ĐẦY ĐỦ VÀO ĐÂY (TIẾNG ANH). NHỚ DÙNG \\n\\n ĐỂ TÁCH ĐOẠN.",

  "taskType": "${taskType}"
}

VALIDATION:
Nếu bài làm quá ngắn hoặc spam, hãy trả về JSON với điểm 0 và lý do trong keyTips.
`;

      // USER MESSAGE
      const userMessage = `essay_text:\n${essayText}`;

      // Gọi API
      const completion = await groq.chat.completions.create({
        messages: [
          { role: "system", content: systemInstruction },
          { role: "user", content: userMessage }
        ],
        model: MODEL_NAME,
        temperature: 0.3, // 0.3 để AI đủ sáng tạo cho bài mẫu nhưng vẫn tuân thủ format JSON
        response_format: { type: "json_object" }
      });

      const content = completion.choices[0].message.content;
      const jsonStr = cleanJson(content);const hehe = JSON.parse(jsonStr);

      console.log(`User Login: ${JSON.stringify(hehe, null, 2)}`);
// 3. Trả về biến đã parse, KHÔNG parse lại lần 2
      return hehe;

    } catch (error) {
      console.error("AI Feedback Error (Groq):", error);
      if (error.error) console.error("Groq Error Detail:", error.error);
      throw new Error("Failed to generate feedback from AI");
    }
  }
};
