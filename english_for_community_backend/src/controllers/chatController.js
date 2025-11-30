import { GoogleGenerativeAI } from "@google/generative-ai";
import { getUserContext } from "../services/aiContextService.js";
import { geminiTools } from "../tools/definitions.js";
import { toolImplementations } from "../tools/implementations.js";

const API_KEY = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(API_KEY);

export const chatWithAI = async (req, res) => {
  const startT = Date.now();
  try {
    console.log(`\n--- 🟢 [CHAT START] ${new Date().toLocaleTimeString()} ---`);
    const { message, history } = req.body;
    const userId = req.user.id;

    // 1. Lấy Context
    const userContext = await getUserContext(userId);

    // Lấy ngày hiện tại
    const today = new Date();
    const todayStr = today.toLocaleDateString('en-CA');
    const weekday = today.toLocaleDateString('vi-VN', { weekday: 'long' });

    // 2. Cấu hình Model
    // const model = genAI.getGenerativeModel({
    //   model: "gemini-2.0-flash",
    //   systemInstruction: {
    //     parts: [
    //       { text: "VAI TRÒ: Bạn là Trợ lý Dữ liệu Học tập (Data Analyst) chuyên nghiệp của ứng dụng. Phong cách: Ngắn gọn, chính xác, dựa trên số liệu." },
    //       { text: `BỐI CẢNH THỜI GIAN: Hôm nay là ${weekday}, ngày ${todayStr}.` },
    //       { text: `DỮ LIỆU TÓM TẮT:\n${userContext}` },
    //       { text: `QUY TẮC XỬ LÝ QUAN TRỌNG:
    //         1. TỰ ĐỘNG TÍNH NGÀY: Tự suy luận startDate/endDate từ câu hỏi (vd: 'tuần này' = T2 đến nay).
    //         2. CHIẾN LƯỢC GỌI TOOL (BẮT BUỘC):
    //            - Khi user hỏi chung chung, KHÔNG ĐƯỢC CHỈ GỌI 1 TOOL.
    //            - Phải gọi ĐA DẠNG các tool: 'get_learning_history' (tổng quan) + 'get_reading_stats' (chi tiết)...
    //         3. ĐỊNH DẠNG TRẢ LỜI (MARKDOWN):
    //            - Luôn dùng Bảng (Table) để so sánh dữ liệu.
    //            - Bảng PHẢI CÓ ĐỦ CỘT: Ngày | Phút | Nghe | Nói | Đọc | Viết | Từ mới.
    //            - KHÔNG ĐƯỢC ẨN CỘT nào. Nếu dữ liệu thiếu, điền "-".
    //         `
    //       }
    //     ]
    //   },
    //   tools: geminiTools,
    //   toolConfig: { functionCallingConfig: { mode: "AUTO" } },
    // });
    const model = genAI.getGenerativeModel({
      model: "gemini-2.0-flash",
      systemInstruction: {
        parts: [
          { text: "VAI TRÒ: Bạn là Trợ lý Dữ liệu Học tập (Data Analyst). Phong cách: Vào thẳng vấn đề, dựa trên số liệu thực tế." },

          { text: `BỐI CẢNH: Hôm nay là ${weekday}, ngày ${todayStr}.\nCONTEXT NGƯỜI DÙNG:\n${userContext}` },

          { text: `⚠️ QUY TẮC CỐT LÕI (BẮT BUỘC TUÂN THỦ):
        1. ƯU TIÊN GỌI TOOL (FUNCTION CALLING):
           - Khi người dùng hỏi về dữ liệu (bài tập đã làm, điểm số, tiến độ...), BẠN PHẢI GỌI CÁC TOOL LIÊN QUAN NGAY LẬP TỨC.
           - ⛔ CẤM TRẢ LỜI text kiểu: "Vui lòng đợi...", "Để tôi kiểm tra...", "Tôi đang tổng hợp...".
           - Chỉ trả lời text SAU KHI đã có kết quả từ tool trả về.

        2. XỬ LÝ YÊU CẦU PHỨC TẠP ("Tất cả kỹ năng"):
           - Nếu user hỏi chung chung ("tình hình học tập", "tuần này học gì") hoặc "tất cả kỹ năng":
           - 👉 PHẢI GỌI NHIỀU TOOL CÙNG LÚC (hoặc lần lượt): get_learning_history + get_listening_stats + get_speaking_stats + ...
           - Không được chỉ gọi 1 tool rồi báo cáo thiếu.

        3. ĐỊNH DẠNG HIỂN THỊ (MOBILE-FIRST):
           - ⛔ KHÔNG DÙNG BẢNG (TABLE). Màn hình điện thoại sẽ bị vỡ.
           - Sử dụng danh sách (List) và Icon.
           
           MẪU FORMAT CHUẨN:
           -----------------------
           📅 **Thống kê [Thời gian]**
           
           ⏱️ **Tổng quan:** [Số phút] phút | [Số] bài học
           
           📊 **Chi tiết kỹ năng:**
           • 🎧 Nghe: [X]p (Điểm TB: [Y])
           • 🗣️ Nói: [X]p (Điểm TB: [Y])
           • 📖 Đọc: [X]p | ✍️ Viết: [X]p
           
           📝 **Từ vựng:** Đã học [Z] từ mới.
           -----------------------
           💡 *[Lời khuyên ngắn gọn 1 câu]*
        `
          }
        ]
      },
      tools: geminiTools,
      toolConfig: { functionCallingConfig: { mode: "AUTO" } },
    });

    // 3. Chat Session (Xử lý History)
    // FIX: Đảm bảo history là array và remove role 'model' đầu tiên nếu có
    let validHistory = Array.isArray(history) ? history : [];

    if (validHistory.length > 0 && validHistory[0].role === 'model') {
      console.log("⚠️ Đã loại bỏ tin nhắn chào mừng (role: model) khỏi lịch sử.");
      validHistory.shift(); // Xóa phần tử đầu tiên
    }

    // FIX: Sửa dòng bị lỗi cú pháp ở đây
    const chatSession = model.startChat({ history: validHistory });

    // 4. Gửi tin nhắn
    console.log(`💬 User: "${message}"`);
    let result = await chatSession.sendMessage(message);
    let response = result.response;

    // 5. Xử lý Function Calling
    const functionCalls = response.functionCalls();

    if (functionCalls && functionCalls.length > 0) {
      console.log(`🤖 Gemini gọi ${functionCalls.length} tools:`, functionCalls.map(f => f.name));

      const functionResponses = [];
      for (const call of functionCalls) {
        const functionName = call.name;
        const args = call.args;

        const functionToCall = toolImplementations[functionName];
        if (functionToCall) {
          try {
            const apiResponse = await functionToCall(userId, args);
            functionResponses.push({
              functionResponse: {
                name: functionName,
                response: { result: apiResponse }
              }
            });
          } catch (e) {
            functionResponses.push({
              functionResponse: {
                name: functionName,
                response: { error: e.message }
              }
            });
          }
        }
      }

      if (functionResponses.length > 0) {
        console.log(`🚀 Gửi kết quả tool về Gemini...`);
        result = await chatSession.sendMessage(functionResponses);
        response = result.response;
      }
    }

    // 6. Trả kết quả
    const textReply = response.text();
    return res.json({ reply: textReply });

  } catch (error) {
    console.error("❌ CHAT ERROR:", error);
    res.status(500).json({ message: "Lỗi hệ thống AI", error: error.message });
  }
};