import { GoogleGenerativeAI } from "@google/generative-ai";
import { getUserContext } from "../services/aiContextService.js";
import { geminiTools } from "../tools/definitions.js";
import { toolImplementations } from "../tools/implementations.js";

const API_KEY = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(API_KEY);

// --- HELPER: CHUYỂN ĐỔI HISTORY VỀ CHUẨN GEMINI {role: 'model', parts: [{text}]} ---
const normalizeHistory = (historyItems) => {
  if (!Array.isArray(historyItems)) return [];
  return historyItems.map(item => {
    // Map role cho Gemini: 'assistant' hoặc 'model' -> 'model', còn lại là 'user'
    let role = item.role === 'assistant' || item.role === 'model' ? 'model' : 'user';
    let content = "";

    // Lấy content từ các cấu trúc khác nhau
    if (typeof item.parts === 'string') {
      content = item.parts;
    } else if (Array.isArray(item.parts)) {
      content = item.parts.map(p => p.text).join("\n");
    } else if (item.content) {
      content = item.content;
    }

    // Lọc ký tự trắng/rỗng
    if (!content || content.trim() === "") content = " ";

    // Trả về format chuẩn Gemini cho history
    return { role, parts: [{ text: content }] };
  });
};

export const chatWithAI = async (req, res) => {
  const startT = Date.now();
  try {
    console.log(`\n--- 🟢 [CHAT START] ${new Date().toLocaleTimeString()} ---`);
    const {message, history} = req.body;
    const userId = req.user.id;

    if (!message) return res.status(400).json({ message: "Message required" });

    // 1. Lấy Context
    const userContext = await getUserContext(userId);

    // Lấy ngày hiện tại
    const today = new Date();
    const todayStr = today.toLocaleDateString('en-CA');
    const weekday = today.toLocaleDateString('vi-VN', {weekday: 'long'});

    // 2. Cấu hình Model với System Instruction (Tối ưu hóa)
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      systemInstruction: {
        parts: [
          // Phần 1: Định nghĩa vai trò
          {
            text: `# 🎓 VAI TRÒ CHÍNH: Cố Vấn Học Tập Dựa trên Dữ liệu (Data-Driven Learning Advisor)

Bạn là **AI English Learning Companion**. Nhiệm vụ của bạn là kết hợp giảng dạy và phân tích hiệu suất cá nhân.

## 1. 👨‍🏫 VAI TRÒ GIÁO VIÊN (Teacher Role)
- **Mục tiêu:** Giảng dạy kiến thức (Grammar, Vocab, Pronunciation), chữa lỗi, tư vấn chiến lược.
- **Quy tắc:** Giải thích súc tích (ELI5), đưa ra 1-2 ví dụ thực tế/lỗi phổ biến, và luôn kết thúc bằng GỢI Ý THỰC HÀNH.

## 2. 📊 VAI TRÒ TRỢ LÝ PHÂN TÍCH (Analysis Role)
- **Mục tiêu:** Phân tích tiến độ, xác định điểm yếu, và đề xuất lộ trình.
- **Quy tắc:** Mọi câu hỏi về tiến độ, điểm số, lịch sử, hay đề xuất cá nhân đều phải gọi TOOLS.

---

# 🧠 QUY TẮC PHẢN HỒI & HÀNH ĐỘNG

## 🚨 TYPE A: DỮ LIỆU CÁ NHÂN (ACTION REQUIRED)
- **BẮT BUỘC:** Gọi 2-3 tools liên quan nhất.
- **QUY TRÌNH PHÂN TÍCH:** Tóm tắt Tool Result → Đánh giá điểm mạnh/yếu → Đưa ra KẾ HOẠCH HÀNH ĐỘNG cụ thể.

## ✅ TYPE B: KIẾN THỨC (TRẢ LỜI TRỰC TIẾP)
- **QUY TRÌNH GIẢNG DẠY:** Bắt đầu bằng 📚 **GIẢI THÍCH** → Kết thúc bằng 🎯 **THỰC HÀNH NGAY**.
`
          },

          // Phần 2: Bối cảnh dữ liệu
          {
            text: `# BỐI CẢNH
📅 Hôm nay: **${weekday}**, ${todayStr}
${userContext}`
          },

          // Phần 3: Chiến lược gọi Tools (Sửa Linter)
          {
            text: `# 📊 CHIẾN LƯỢC GỌI TOOLS

## 🎯 QUY TẮC:
1. Phải gọi TOOLS để lấy dữ liệu.
2. Không trả lời dựa vào suy đoán hoặc dữ liệu sơ bộ.

## VD 1 (Tổng quan tuần):
\`\`\`json
[
  { "name": "get_learning_history", "args": { "startDate": "2024-12-02", "endDate": "2024-12-08" } },
  { "name": "analyze_weaknesses", "args": { "range": "week" } }
]
\`\`\`

## VD 2 (Chi tiết Kỹ năng):
\`\`\`json
[
  { "name": "get_reading_details", "args": { "limit": 10 } },
  { "name": "get_skill_statistics", "args": { "skill": "reading", "range": "week" } }
]
\`\`\`
`
          },

          // Phần 4: Format cuối cùng
          {
            text: `# 🎨 FORMAT & CẤU TRÚC PHẢN HỒI

## 📊 KHI CÓ DỮ LIỆU (TYPE A):
\`\`\`
📊 **PHÂN TÍCH DỮ LIỆU (Tuần này)**
[Tóm tắt số liệu chính xác]

🔍 **VẤN ĐỀ & ĐỀ XUẤT**
[Chỉ ra điểm yếu dựa trên phân tích]

💡 **KẾ HOẠCH HÀNH ĐỘNG**
[Các bước cụ thể, có thể bao gồm gợi ý bài tập]
\`\`\`

## 📚 KHI DẠY KIẾN THỨC (TYPE B):
\`\`\`
❓ **Câu hỏi:** [Nhắc lại ngắn gọn]

📚 **GIẢI THÍCH CHUYÊN SÂU**
[Giải thích logic, cơ bản, dễ hiểu]

🎯 **Tip Học Tập & Thực Hành**
[1-2 tips thực tiễn, có ví dụ đúng/sai]
\`\`\`
`
          }
        ]
      },
      tools: geminiTools,
      toolConfig: {functionCallingConfig: {mode: "AUTO"}},
    });

    // 3. Chuẩn bị History và Session
    const chatHistory = normalizeHistory(history);

    // Loại bỏ tin nhắn chào mừng (role: model) khỏi lịch sử nếu có
    if (chatHistory.length > 0 && chatHistory[0].role === 'model') {
      console.log("⚠️ Đã loại bỏ tin nhắn chào mừng (role: model) khỏi lịch sử.");
      chatHistory.shift();
    }

    // Khởi tạo Chat Session
    const chatSession = model.startChat({history: chatHistory});

    // 4. Gửi tin nhắn
    console.log(`💬 User: "${message}"`);

    let result = await chatSession.sendMessage(message);
    let response = result.response;

    // 5. Xử lý Function Calling (Multi-turn)
    let maxIterations = 3;
    let iteration = 0;
    let messageParts = [{ text: message }]; // Tin nhắn đầu tiên để bắt đầu loop

    while (response.functionCalls() && iteration < maxIterations) {
      const functionCalls = response.functionCalls();
      console.log(`🤖 [Iteration ${iteration + 1}] Gemini gọi ${functionCalls.length} tools:`,
        functionCalls.map(f => f.name));

      const functionResponses = [];
      for (const call of functionCalls) {
        const functionName = call.name;
        const args = call.args;

        const functionToCall = toolImplementations[functionName];
        if (functionToCall) {
          try {
            console.log(`   → Calling ${functionName}...`);
            const apiResponse = await functionToCall(userId, args);
            functionResponses.push({
              functionResponse: {
                name: functionName,
                response: {result: apiResponse}
              }
            });
          } catch (e) {
            console.error(`   ❌ Error calling ${functionName}:`, e.message);
            functionResponses.push({
              functionResponse: {
                name: functionName,
                response: {error: e.message}
              }
            });
          }
        }
      }

      if (functionResponses.length > 0) {
        console.log(`   🚀 Sending ${functionResponses.length} results back to Gemini...`);
        // Gửi kết quả tool về lại cho Gemini
        result = await chatSession.sendMessage(functionResponses);
        response = result.response;
        iteration++;
      } else {
        break;
      }
    }

    // 6. Trả kết quả
    const textReply = response.text();
    const duration = Date.now() - startT;
    console.log(`✅ Response time: ${duration}ms, Iterations: ${iteration}`);

    return res.json({reply: textReply});

  } catch (error) {
    console.error("❌ CHAT ERROR:", error);
    res.status(500).json({
      message: "Lỗi hệ thống AI",
      error: error.message
    });
  }
}