import Groq from 'groq-sdk';
import { getUserContext } from './aiContextService.js';
import { aiService } from './aiService.js';
import { toolImplementations } from '../tools/implementations.js';

const API_KEY = process.env.GROQ_API_KEY;
const groq = new Groq({ apiKey: API_KEY });
const MODEL_NAME = aiService.MODEL_NAME || 'llama-3.3-70b-versatile';

const normalizeHistory = (historyItems) => {
  if (!Array.isArray(historyItems)) return [];
  return historyItems.map((item) => {
    const role = item.role === 'assistant' || item.role === 'model' ? 'assistant' : 'user';
    let content = '';
    if (typeof item.parts === 'string') content = item.parts;
    else if (Array.isArray(item.parts)) content = item.parts.map(p => p.text).join('\n');
    else if (item.content) content = item.content;
    if (!content || content.trim() === '') content = ' ';
    return { role, content };
  }).filter(item => item.content.trim() !== '');
};

const extractToolCall = (text) => {
  try {
    const match = text.match(/```json([\s\S]*?)```/) || text.match(/\[\s*\{[\s\S]*\}\s*\]/);
    if (match) {
      const jsonStr = match[0].replace(/```json|```/g, '').trim();
      return JSON.parse(jsonStr);
    }
    return null;
  } catch {
    return null;
  }
};

/**
 * @returns {Promise<string>} Markdown reply for the client
 */
export async function generateChatReply(userId, message, history) {
  const userContext = await getUserContext(userId);
  const today = new Date();
  const todayStr = today.toLocaleDateString('en-CA');
  const weekday = today.toLocaleDateString('vi-VN', { weekday: 'long' });

  const systemInstruction = `
# 🎓 VAI TRÒ: Cố Vấn Học Tập & Chuyên Gia Phân Tích Dữ Liệu (Data Analyst)

Bạn là **AI English Learning Companion**. Bạn có quyền truy cập vào cơ sở dữ liệu học tập của người dùng thông qua các TOOLS.

---

# 🕵️ CHIẾN LƯỢC TRUY XUẤT DỮ LIỆU (QUAN TRỌNG)

**KHÔNG được tự bịa startDate/endDate** (ví dụ năm 2024 trong prompt mẫu cũ). Ngày trong DB là **YYYY-MM-DD theo múi giờ user** — chỉ server/tool mới tính đúng.

- **Hỏi "hôm nay / hôm nay làm mấy bài / progress hôm nay"** → bắt buộc gọi **get_daily_activity** (có thể thêm **get_learning_history_period** với \`range: "today"\`).
- **Hỏi "tuần này / 7 ngày gần đây / rolling week"** → **get_learning_history_period** với \`range: "week"\` (7 ngày lùi **tính cả hôm nay** — không phải tuần lịch).
- **Hỏi "tuần trước / last week / tuần vừa rồi"** → **get_learning_history_period** với \`range: "last_week"\` (tuần dương lịch **trước** tuần hiện tại: Thứ Hai–Chủ nhật). **KHÔNG** dùng \`range: "week"\` cho câu này.
- **Hỏi "tháng này"** → **get_learning_history_period** với \`range: "month"\`.
- **get_learning_history** chỉ dùng khi đã có **chính xác** hai ngày YYYY-MM-DD từ dữ liệu hệ thống hoặc user nói rõ; nếu không chắc → dùng **get_learning_history_period**.

Khi cần chi tiết bài theo **đúng một ngày** (ví dụ hôm nay), truyền **cùng startDate và endDate** = ngày đó vào get_reading_details / get_listening_details / get_speaking_details / get_writing_details — hoặc chỉ cần **get_daily_activity** đã liệt kê đủ.

## ⚠️ COMBO gợi ý (thống kê rộng):
1. **get_learning_history_period** hoặc **get_daily_activity** (tùy ngữ cảnh)
2. **analyze_weaknesses**
3. **get_reading_details** / **get_listening_details** / **get_speaking_details** / **get_writing_details** (có thể kèm cùng startDate=endDate=hôm nay nếu hỏi theo ngày)

---

# 🧠 VÍ DỤ MẪU (FEW-SHOT — KHÔNG COPY NGÀY CỐ ĐỊNH)

## VD 1: "Hôm nay tôi học thế nào / làm mấy bài?"
\`\`\`json
[
  { "name": "get_daily_activity", "args": {} },
  { "name": "get_learning_history_period", "args": { "range": "today" } }
]
\`\`\`

## VD 2: "Thống kê tháng này"
\`\`\`json
[
  { "name": "get_learning_history_period", "args": { "range": "month" } },
  { "name": "analyze_weaknesses", "args": { "range": "month" } },
  { "name": "get_reading_details", "args": { "limit": 8 } },
  { "name": "get_listening_details", "args": { "limit": 8 } },
  { "name": "get_speaking_details", "args": { "limit": 8, "mode": "all" } },
  { "name": "get_writing_details", "args": { "limit": 5 } }
]
\`\`\`

## VD 2b: "Tuần trước tôi học thế nào / last week"
\`\`\`json
[
  { "name": "get_learning_history_period", "args": { "range": "last_week" } },
  { "name": "analyze_weaknesses", "args": { "range": "last_week" } }
]
\`\`\`

## VD 3: "Kỹ năng nói dạo này?"
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

  const chatHistory = normalizeHistory(history);
  let messages = [
    { role: 'system', content: systemInstruction },
    ...chatHistory,
    { role: 'user', content: message },
  ];

  let completion = await groq.chat.completions.create({
    messages,
    model: MODEL_NAME,
    temperature: 0.3,
    stream: false,
  });

  let aiContent = completion.choices[0].message.content;
  const toolCalls = extractToolCall(aiContent);

  if (toolCalls && Array.isArray(toolCalls) && toolCalls.length > 0) {
    const toolResults = [];

    for (const call of toolCalls) {
      const { name, args } = call;
      if (toolImplementations[name]) {
        try {
          const result = await toolImplementations[name](userId, args);
          toolResults.push({ name, result });
        } catch (err) {
          toolResults.push({ name, error: err.message });
        }
      } else {
        toolResults.push({ name, error: 'Function not found' });
      }
    }

    messages.push({ role: 'assistant', content: aiContent });
    messages.push({
      role: 'user',
      content: `
🔴 KẾT QUẢ TỪ HỆ THỐNG (DATA SYSTEM):
${JSON.stringify(toolResults, null, 2)}

Hãy dựa vào dữ liệu trên để trả lời user. Format Markdown rõ ràng, thân thiện.
`,
    });

    completion = await groq.chat.completions.create({
      messages,
      model: MODEL_NAME,
      temperature: 0.7,
      stream: false,
    });

    aiContent = completion.choices[0].message.content;
  }

  return aiContent;
}
