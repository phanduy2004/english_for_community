import { getUserContext } from "../services/aiContextService.js";
import { aiService } from "../services/aiService.js";
import { toolImplementations } from "../tools/implementations.js";
import Groq from "groq-sdk";

// Khởi tạo Groq Client
const API_KEY = process.env.GROQ_API_KEY;
const groq = new Groq({ apiKey: API_KEY });

// Lấy model
const MODEL_NAME = aiService.MODEL_NAME || "meta-llama/llama-4-maverick-17b-128e-instruct";

// --- HELPER: CHUYỂN ĐỔI HISTORY ---
const normalizeHistory = (historyItems) => {
  if (!Array.isArray(historyItems)) return [];
  return historyItems.map(item => {
    let role = item.role === 'assistant' || item.role === 'model' ? 'assistant' : 'user';
    let content = "";
    if (typeof item.parts === 'string') content = item.parts;
    else if (Array.isArray(item.parts)) content = item.parts.map(p => p.text).join("\n");
    else if (item.content) content = item.content;
    if (!content || content.trim() === "") content = " ";
    return { role, content };
  }).filter(item => item.content.trim() !== "");
}

// --- HELPER: TRÍCH XUẤT JSON TỪ RESPONSE CỦA AI ---
const extractToolCall = (text) => {
  try {
    const match = text.match(/```json([\s\S]*?)```/) || text.match(/\[\s*\{[\s\S]*\}\s*\]/);
    if (match) {
      const jsonStr = match[0].replace(/```json|```/g, '').trim();
      return JSON.parse(jsonStr);
    }
    return null;
  } catch (e) {
    return null;
  }
};

export const chatWithAI = async (req, res) => {
  const startT = Date.now();
  try {
    console.log(`\n--- 🟢 [CHAT START - GROQ] ${new Date().toLocaleTimeString()} ---`);
    const { message, history } = req.body;
    const userId = req.user.id;

    if (!message) return res.status(400).json({ message: "Message required" });

    // 1. Lấy Context & Thời gian
    const userContext = await getUserContext(userId);
    const today = new Date();
    const todayStr = today.toLocaleDateString('en-CA');
    const weekday = today.toLocaleDateString('vi-VN', { weekday: 'long' });

    // 2. System Instruction
    // SỬA NHẸ: Bỏ yêu cầu dùng ASCII complex borders (║) để tránh lỗi hiển thị trên mobile/flutter
    const systemInstruction = `
# 🎓 VAI TRÒ: Cố Vấn Học Tập & Chuyên Gia Phân Tích Dữ Liệu (Data Analyst)

Bạn là **AI English Learning Companion**. Bạn có quyền truy cập vào cơ sở dữ liệu học tập của người dùng thông qua các TOOLS.

---

# 🕵️ CHIẾN LƯỢC TRUY XUẤT DỮ LIỆU (QUAN TRỌNG)

Khi người dùng hỏi về "Thống kê", "Lịch sử", "Tiến độ", hoặc "Tháng này/Tuần này thế nào", bạn **KHÔNG ĐƯỢC** chỉ gọi một hàm tổng quát. Bạn phải lấy chi tiết từng kỹ năng để báo cáo đầy đủ.

## ⚠️ QUY TẮC GỌI "COMBO" TOOLS:
Để có bức tranh toàn cảnh, bạn phải gọi 1 mảng JSON chứa nhiều hàm cùng lúc:

1.  **get_learning_history**: Để lấy tổng phút, tổng quan.
2.  **analyze_weaknesses**: Để tìm điểm yếu.
3.  **get_reading_details**: Để xem chi tiết bài Đọc gần đây.
4.  **get_listening_details**: Để xem chi tiết bài Nghe gần đây.
5.  **get_speaking_details**: Để xem chi tiết bài Nói gần đây.
6.  **get_writing_details**: Để xem bài Viết đã nộp.

---

# 🧠 VÍ DỤ MẪU (FEW-SHOT PROMPTING)

## VD 1: User hỏi "Thống kê việc học tháng này của tôi"
-> Bạn phải gọi toàn bộ các hàm liên quan để có dữ liệu viết báo cáo chi tiết.
\`\`\`json
[
  { "name": "get_learning_history", "args": { "startDate": "2024-12-01", "endDate": "2024-12-31" } },
  { "name": "analyze_weaknesses", "args": { "range": "month" } },
  { "name": "get_reading_details", "args": { "limit": 5 } },
  { "name": "get_speaking_details", "args": { "limit": 5 } },
  { "name": "get_writing_details", "args": { "limit": 3 } }
]
\`\`\`

## VD 2: User hỏi "Kỹ năng nói của tôi dạo này thế nào?"
-> Chỉ gọi các hàm liên quan đến Speaking.
\`\`\`json
[
  { "name": "get_skill_statistics", "args": { "skill": "speaking", "range": "month" } },
  { "name": "get_speaking_details", "args": { "limit": 10, "mode": "all" } }
]
\`\`\`

---

# 🎨 CẤU TRÚC BÁO CÁO (SAU KHI CÓ DỮ LIỆU)

Khi đã nhận được dữ liệu từ hệ thống, hãy trình bày câu trả lời theo format Markdown chuyên nghiệp:

### 1. 📊 Tổng Quan Tháng Này
- Tổng thời gian: ... phút
- Số từ mới: ... từ
- Nhận xét chung: (Dựa trên learning_history)

### 2. 🔍 Chi Tiết Từng Kỹ Năng (Dựa trên *_details)
**📖 Reading:**
- Bài gần nhất: [Tên bài] - [Điểm số]
- Xu hướng: Đang tăng hay giảm?

**🗣️ Speaking:**
- Bài gần nhất: [Tên bài] - [Độ chính xác]
- Vấn đề: (Dựa trên analyze_weaknesses)

**✍️ Writing:**
- Bài gần nhất: [Tên bài] - [Điểm]

### 3. 💡 Lời Khuyên & Kế Hoạch Tiếp Theo
- (Dựa trên analyze_weaknesses để đưa ra bài tập cụ thể)

---

# BỐI CẢNH
📅 Hôm nay: **${weekday}**, ${todayStr}
${userContext}
`;

    // 3. Chuẩn bị Messages ban đầu
    const chatHistory = normalizeHistory(history);
    let messages = [
      { role: "system", content: systemInstruction },
      ...chatHistory,
      { role: "user", content: message }
    ];

    // --- BƯỚC 1: GỌI AI LẦN 1 ---
    console.log(`💬 User: "${message}"`);
    let completion = await groq.chat.completions.create({
      messages: messages,
      model: MODEL_NAME,
      temperature: 0.3,
      stream: false,
    });

    let aiContent = completion.choices[0].message.content;
    const toolCalls = extractToolCall(aiContent);

    // --- BƯỚC 2: NẾU CÓ TOOL CALL -> THỰC THI HÀM ---
    if (toolCalls && Array.isArray(toolCalls) && toolCalls.length > 0) {
      console.log(`🤖 AI yêu cầu gọi ${toolCalls.length} tools:`, toolCalls.map(t => t.name));

      const toolResults = [];

      for (const call of toolCalls) {
        const { name, args } = call;
        if (toolImplementations[name]) {
          try {
            console.log(`   → Đang chạy: ${name}...`);
            const result = await toolImplementations[name](userId, args);
            toolResults.push({ name, result });
          } catch (err) {
            console.error(`   ❌ Lỗi tool ${name}:`, err.message);
            toolResults.push({ name, error: err.message });
          }
        } else {
          toolResults.push({ name, error: "Function not found" });
        }
      }

      // --- BƯỚC 3: GỬI KẾT QUẢ VỀ LẠI CHO AI ---
      console.log(`   🚀 Đã có dữ liệu, gửi lại cho AI tổng hợp...`);

      messages.push({ role: "assistant", content: aiContent });
      messages.push({
        role: "user",
        content: `
🔴 KẾT QUẢ TỪ HỆ THỐNG (DATA SYSTEM):
${JSON.stringify(toolResults, null, 2)}

Hãy dựa vào dữ liệu trên để trả lời user. Format Markdown rõ ràng, thân thiện.
`
      });

      completion = await groq.chat.completions.create({
        messages: messages,
        model: MODEL_NAME,
        temperature: 0.7,
        stream: false,
      });

      aiContent = completion.choices[0].message.content;
    }

    // 4. Trả kết quả (FIX ENCODING ERROR)
    const duration = Date.now() - startT;
    console.log(`✅ Response time: ${duration}ms`);

    // 🔥 QUAN TRỌNG: Ép kiểu charset=utf-8 để Flutter không bị lỗi font/emoji
    res.setHeader('Content-Type', 'application/json; charset=utf-8');

    return res.json({ reply: aiContent });

  } catch (error) {
    console.error("❌ CHAT ERROR:", error);
    res.status(500).json({ message: "Lỗi hệ thống AI", error: error.message });
  }
};