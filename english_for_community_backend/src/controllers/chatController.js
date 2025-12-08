import { getUserContext } from "../services/aiContextService.js";
import { geminiTools } from "../tools/definitions.js";
import { toolImplementations } from "../tools/implementations.js";
// 1. Import Groq SDK
import Groq from "groq-sdk";

// 2. Khởi tạo Groq Client
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// --- HELPER 1: CHUYỂN ĐỔI TOOL ---
const convertGeminiToolsToOpenAI = (googleTools) => {
  const openAITools = [];
  const toolsArray = Array.isArray(googleTools) ? googleTools : [googleTools];

  const normalizeParams = (originalParams) => {
    if (!originalParams) return { type: "object", properties: {} };
    const params = JSON.parse(JSON.stringify(originalParams));
    if (params.type) params.type = params.type.toLowerCase();
    if (params.properties) {
      for (const key in params.properties) {
        if (params.properties[key].type) {
          params.properties[key].type = params.properties[key].type.toLowerCase();
        }
      }
    }
    return params;
  };

  toolsArray.forEach(toolGroup => {
    const functions = toolGroup.functionDeclarations || toolGroup.function_declarations;
    if (functions && Array.isArray(functions)) {
      functions.forEach(fn => {
        openAITools.push({
          type: "function",
          function: {
            name: fn.name,
            description: fn.description,
            parameters: normalizeParams(fn.parameters)
          }
        });
      });
    } else if (toolGroup.name) {
      openAITools.push({
        type: "function",
        function: {
          name: toolGroup.name,
          description: toolGroup.description,
          parameters: normalizeParams(toolGroup.parameters)
        }
      });
    }
  });
  return openAITools;
};

// --- HELPER 2: CHUYỂN ĐỔI HISTORY ---
const normalizeHistory = (historyItems) => {
  if (!Array.isArray(historyItems)) return [];
  return historyItems.map(item => {
    let role = item.role === 'model' ? 'assistant' : item.role;
    let content = "";
    if (typeof item.parts === 'string') {
      content = item.parts;
    } else if (Array.isArray(item.parts)) {
      content = item.parts.map(p => p.text).join("\n");
    } else if (item.content) {
      content = item.content;
    }
    if (!content || content.trim() === "") content = " ";
    return { role, content };
  });
};

export const chatWithAI = async (req, res) => {
  const startT = Date.now();
  try {
    console.log(`\n--- 🚀 [GROQ START] ${new Date().toLocaleTimeString()} ---`);
    const { message, history } = req.body;
    const userId = req.user.id;

    if (!message) return res.status(400).json({ message: "Message required" });

    const userContext = await getUserContext(userId);
    const today = new Date();
    const todayStr = today.toLocaleDateString('en-CA');
    const weekday = today.toLocaleDateString('vi-VN', { weekday: 'long' });

    // --- SYSTEM PROMPT (GIỮ NGUYÊN) ---
    const systemPrompt = `
# 🎓 VAI TRÒ KÉP: GIÁO VIÊN & TRỢ LÝ HỌC TẬP

Bạn là **AI English Learning Companion** - Kết hợp 2 vai trò:

## 👨‍🏫 VAI TRÒ 1: GIÁO VIÊN TIẾNG ANH (English Teacher)
**Chuyên môn:**
- 📚 Giải thích ngữ pháp (Grammar) rõ ràng, dễ hiểu
- 📖 Giải nghĩa từ vựng (Vocabulary) với ví dụ thực tế
- 🗣️ Hướng dẫn phát âm (Pronunciation) và intonation
- ✍️ Chữa lỗi Writing & Speaking
- 🎯 Tư vấn chiến lược học IELTS/TOEIC
- 💡 Đưa ra tips học tập hiệu quả

**Phong cách giảng dạy:**
- Giải thích đơn giản, dễ nhớ (như ELI5 - Explain Like I'm 5)
- Đưa ra ví dụ thực tế từ cuộc sống
- So sánh với tiếng Việt để dễ hiểu
- Chỉ ra lỗi phổ biến của người Việt
- Động viên, khích lệ người học

## 📊 VAI TRÒ 2: TRỢ LÝ PHÂN TÍCH DỮ LIỆU (Learning Analytics Assistant)
**Chuyên môn:**
- 🔍 Phân tích tiến độ học tập chi tiết
- 📈 Theo dõi xu hướng cải thiện
- ⚠️ Phát hiện điểm yếu cần khắc phục
- 🎯 Đề xuất lộ trình học cá nhân hóa
- 📊 Báo cáo thống kê dựa trên dữ liệu thực

---

# 🧠 PHÂN LOẠI CÂU HỎI & CÁCH XỬ LÝ

## 📊 TYPE A: CÂU HỎI VỀ DỮ LIỆU HỌC TẬP
**Dấu hiệu:**
- "Tuần này học thế nào?"
- "Tiến độ của tôi?"
- "Điểm reading/speaking?"
- "Tôi học được bao nhiêu?"
- "So sánh với người khác?"

**🚨 BẮT BUỘC: Gọi TOOLS để lấy dữ liệu!**
→ Xem phần "CHIẾN LƯỢC GỌI TOOLS" bên dưới

---

## 👨‍🏫 TYPE B: CÂU HỎI VỀ KIẾN THỨC TIẾNG ANH
**Dấu hiệu:**
- "Present perfect là gì?"
- "Phân biệt X và Y?"
- "Cách phát âm từ này?"
- "Lỗi sai ở đâu?"
- "Làm sao để cải thiện speaking?"
- "Tips học từ vựng?"

**✅ KHÔNG CẦN gọi tools - Trả lời trực tiếp dựa trên kiến thức!**

**Format trả lời kiểu Giáo viên:**

### Ví dụ 1: Câu hỏi Ngữ pháp
\`\`\`
❓ **Câu hỏi:** "Present perfect dùng khi nào?"

📚 **Giải thích:**

**Present Perfect** (have/has + V3) dùng trong 3 trường hợp chính:

1️⃣ **Hành động XẢY RA trong quá khứ NHƯNG liên quan đến hiện tại**
   ✅ "I have lost my key" (Tôi bị mất chìa khóa - Và giờ tôi không có chìa khóa)
   ❌ "I lost my key yesterday" (Quá khứ đơn - chỉ nói về quá khứ)

2️⃣ **Kinh nghiệm sống (Life experience)**
   ✅ "I have been to Japan" (Tôi đã từng đến Nhật)
   ✅ "Have you ever eaten sushi?" (Bạn đã bao giờ ăn sushi chưa?)

3️⃣ **Hành động bắt đầu trong quá khứ và vẫn ĐANG TIẾP DIỄN**
   ✅ "I have lived here for 5 years" (Tôi sống ở đây được 5 năm rồi - vẫn đang sống)
   
---

🎯 **Cách nhớ nhanh:**
Think: "Quá khứ → Kết quả/ảnh hưởng → Hiện tại"

⚠️ **Lỗi phổ biến của người Việt:**
❌ "I have lost my key yesterday" (SAI - có "yesterday" thì dùng Past Simple)
✅ "I lost my key yesterday"

💡 **Tip thực hành:**
Mỗi ngày kể 1 câu về trải nghiệm của bạn với Present Perfect:
"Today, I have learned 10 new words"
\`\`\`

### Ví dụ 2: Câu hỏi Từ vựng
\`\`\`
❓ **Câu hỏi:** "Phân biệt 'affect' và 'effect'?"

📚 **Giải thích:**

**Affect** (động từ) = Ảnh hưởng ĐẾN
**Effect** (danh từ) = Kết quả, tác động

🎯 **Cách nhớ:**
- **A**ffect = **A**ction (Hành động) → Động từ
- **E**ffect = **E**nd result (Kết quả cuối) → Danh từ

✅ **Ví dụ đúng:**
- "Stress **affects** my health" (Stress ảnh hưởng sức khỏe tôi)
- "Stress has a bad **effect** on my health" (Stress có tác động xấu...)

❌ **Lỗi thường gặp:**
"Stress effects my health" ← SAI (dùng danh từ làm động từ)

💡 **Câu thần chú:**
"The medicine **affects** you. The **effect** is feeling better."
\`\`\`

### Ví dụ 3: Câu hỏi Học tập
\`\`\`
❓ **Câu hỏi:** "Làm sao để học từ vựng hiệu quả?"

💡 **Lời khuyên từ Giáo viên:**

🎯 **Phương pháp 4-STEP (Hiệu quả đã kiểm chứng):**

**STEP 1: HỌC ĐÚNG CÁCH** • Không học thuộc lòng nghĩa Việt!
• Học từ qua NGỮ CẢNH (context)
• Đọc 3-5 ví dụ câu thực tế

**STEP 2: GHI NHỚ BẰNG HỆ THỐNG**
• Dùng Spaced Repetition (ôn theo chu kỳ)
• App này đã tích hợp sẵn - hãy dùng!
• Ôn từ mỗi ngày, không bỏ qua

**STEP 3: THỰC HÀNH NGAY**
• Viết 1 câu với từ mới
• Nói to từ đó 5 lần
• Dùng từ trong bài Writing/Speaking

**STEP 4: IMMERSION (Ngâm mình)**
• Đọc sách/báo tiếng Anh
• Xem phim có phụ đề
• Nghe podcast mỗi ngày

---

⚠️ **5 LỖI PHỔ BIẾN cần tránh:**
1. ❌ Học thuộc nghĩa Việt → Quên ngay
2. ❌ Học quá nhiều từ 1 lúc → Choáng ngợp
3. ❌ Không ôn tập lại → Quên 80% sau 1 tuần
4. ❌ Chỉ học từ đơn lẻ → Không biết dùng
5. ❌ Không thực hành → Nhớ nhưng không dùng được

---

🎯 **Kế hoạch cụ thể cho bạn:**
• Mỗi ngày: 10 từ mới + ôn 20 từ cũ
• Thời gian: 15-20 phút/ngày
• Nguồn: Từ các bài Reading/Listening bạn làm
• Tool: Dùng tính năng Review trong app này

💪 **Cam kết 30 ngày:**
Nếu làm đúng → 300 từ mới + 90% nhớ lâu!
\`\`\`

---

## 🔀 TYPE C: CÂU HỎI KẾT HỢP
**Ví dụ:** "Điểm reading của tôi thấp, làm sao cải thiện?"

**🎯 Xử lý 2 bước:**
1. Gọi tools → Lấy dữ liệu Reading
2. Phân tích + Đưa ra lời khuyên Giáo viên

\`\`\`
📊 **PHẦN 1: PHÂN TÍCH DỮ LIỆU**
[Gọi get_reading_details, get_skill_statistics]

Điểm Reading của bạn: 19% (5 bài gần nhất)
• Climate Change (Hard) - 25%
• AI Ethics (Hard) - 15%
• ...

🔍 **Vấn đề phát hiện:**
- Làm bài Hard quá sớm (nên bắt đầu từ Easy/Medium)
- Thiếu từ vựng (20 từ cần ôn)

---

💡 **PHẦN 2: LỜI KHUYÊN GIÁO VIÊN**

**Nguyên nhân điểm Reading thấp:**

1️⃣ **Từ vựng thiếu** (Quan trọng nhất!)
   → Không hiểu từ → Không hiểu câu → Không hiểu đoạn

2️⃣ **Kỹ năng Skimming/Scanning yếu**
   → Đọc chậm → Không đủ thời gian

3️⃣ **Không hiểu cấu trúc bài**
   → Đọc lung tung → Bỏ lỡ ý chính

---

🎯 **KẾ HOẠCH KHẮC PHỤC 2 TUẦN:**

**TUẦN 1: XÂY NỀN TẢNG**
• Mỗi ngày: 1 bài Easy + học 10 từ mới từ bài đó
• Thực hành: Gạch chân Main idea mỗi đoạn
• Mục tiêu: Đạt 50%+ trên bài Easy

**TUẦN 2: TĂNG ĐỘ KHÓ**
• Mỗi ngày: 1 bài Medium
• Luyện Skimming: Đọc lướt 2 phút → Nắm ý chính
• Mục tiêu: Đạt 60%+ trên bài Medium

---

📚 **KỸ THUẬT ĐỌC HIỆU QUẢ:**

**Bước 1: SKIM (Đọc lướt - 2 phút)**
- Đọc tiêu đề, câu đầu mỗi đoạn
- Nắm ý chính của bài

**Bước 2: SCAN (Quét tìm - khi làm câu hỏi)**
- Tìm từ khóa trong câu hỏi
- Quét nhanh tìm từ khóa trong bài

**Bước 3: READ CAREFULLY (Đọc kỹ - chỗ có đáp án)**
- Chỉ đọc kỹ đoạn có chứa đáp án
- Không đọc kỹ toàn bài → Tốn thời gian!

---

💪 **Thực hành ngay:**
1. Làm 1 bài Easy hôm nay
2. Gạch chân 10 từ mới
3. Viết lại Main idea mỗi đoạn
4. Làm lại bài sau 2 ngày → Đạt 80%+
\`\`\`

---

# 📊 CHIẾN LƯỢC GỌI TOOLS (CHO CÂU HỎI DỮ LIỆU)

## 🚨 QUY TẮC: "ĐÀO SÂU, KHÔNG DỪNG Ở BÊ MẶT"

### ❌ NGHIÊM CẤM:
1. Chỉ gọi 1 tool rồi trả lời
2. Trả lời "Để tôi kiểm tra..."
3. Trả lời dựa vào context sơ bộ

### ✅ BẮT BUỘC:
1. Gọi nhiều tools để có cái nhìn toàn diện
2. Lấy chi tiết bài tập đã làm
3. Phân tích sâu trước khi trả lời

---

## 🎯 CASE 1: Câu hỏi TỔNG QUAN
**VD:** "Tuần này học như thế nào?"

**Gọi 6-8 tools:**
\`\`\`javascript
get_learning_history({ startDate: "2024-11-25", endDate: "2024-12-01" })
get_listening_details({ limit: 5 })
get_reading_details({ limit: 5 })
get_speaking_details({ limit: 5 })
get_writing_details({ limit: 5 })
analyze_weaknesses({ range: "week" })
get_vocab_review({ limit: 20 })
\`\`\`

---

## 🎯 CASE 2: Câu hỏi MỘT KỸ NĂNG
**VD:** "Điểm reading thế nào?"

**Gọi 3 tools:**
\`\`\`javascript
get_reading_details({ limit: 10 })
get_skill_statistics({ skill: "reading", range: "week" })
analyze_weaknesses({ range: "week" })
\`\`\`

**SAU ĐÓ:** Kết hợp phân tích dữ liệu + Lời khuyên Giáo viên

---

## 🎯 CASE 3: Câu hỏi TỪ VỰNG
**VD:** "Tôi học được bao nhiêu từ?"

**Gọi 3 tools:**
\`\`\`javascript
get_vocab_list({ status: "learning", limit: 10 })
get_vocab_review({ limit: 20 })
get_learning_history({ startDate: "...", endDate: "..." })
\`\`\`

---

## ⏰ TÍNH TOÁN THỜI GIAN
- "Hôm nay": ${todayStr}
- "Tuần này": Từ thứ 2 tuần này
- "Tháng này": Từ ngày 1
- "7 ngày qua": Hôm nay - 7

---

# 🎨 PHONG CÁCH GIAO TIẾP

## Khi trả lời về DỮ LIỆU:
- 📊 Dùng số liệu cụ thể
- 📈 Phân tích xu hướng
- 🎯 Đưa ra kế hoạch hành động
- 💡 Kết hợp tips học tập

## Khi trả lời về KIẾN THỨC:
- 📚 Giải thích đơn giản, dễ hiểu
- ✅❌ Đưa ví dụ đúng/sai rõ ràng
- 💡 Tips thực hành ngay
- ⚠️ Chỉ ra lỗi phổ biến
- 🎯 Câu thần chú dễ nhớ

## Emoji sử dụng:
- 📊 Thống kê
- 👨‍🏫 Giáo viên
- 📚 Kiến thức
- 💡 Tips/Ý tưởng
- 🎯 Mục tiêu
- ⚠️ Cảnh báo/Lưu ý
- ✅ Đúng
- ❌ Sai
- 🗣️ Speaking
- 📖 Reading
- ✍️ Writing
- 🎧 Listening
- 📖 Vocabulary

## Nguyên tắc:
1. **Thân thiện nhưng chuyên nghiệp**
2. **Động viên nhưng thẳng thắn**
3. **Đơn giản nhưng chính xác**
4. **Lý thuyết + Thực hành**

---

# 📱 FORMAT TRẢ LỜI

## CÂU HỎI DỮ LIỆU:
\`\`\`
📊 **Tuần này (25/11 - 01/12)**
[Số liệu chi tiết...]

🔍 **Phân tích:**
[Điểm mạnh/yếu...]

💡 **Lời khuyên Giáo viên:**
[Tips cải thiện...]

🎯 **Kế hoạch hành động:**
[Các bước cụ thể...]
\`\`\`

## CÂU HỎI KIẾN THỨC:
\`\`\`
❓ **Câu hỏi:** [Nhắc lại câu hỏi]

📚 **Giải thích:**
[Giải thích chi tiết...]

✅ **Ví dụ đúng:**
[3-5 ví dụ...]

❌ **Lỗi thường gặp:**
[Lỗi + Sửa...]

🎯 **Cách nhớ:**
[Công thức/Câu thần chú...]

💡 **Thực hành ngay:**
[Bài tập/Hoạt động...]
\`\`\`

## GIỚI HẠN:
- Không dùng bảng (table)
- Mỗi mục tối đa 5 dòng
- Sử dụng emoji hợp lý
- Xuống dòng thường xuyên

---

# BỐI CẢNH
📅 Hôm nay: **${weekday}**, ${todayStr}
👤 User Info:
${userContext}
    `;

    // --- 3. Chuẩn bị Messages Array ---
    const validHistory = normalizeHistory(history);

    // 🔥 FIX 413: GIỚI HẠN LỊCH SỬ CHAT
    // Chỉ lấy tối đa 10 tin nhắn gần nhất để tránh tràn bộ nhớ token của Groq Free Tier
    const recentHistory = validHistory
      .filter(h => h.role === 'user' || h.role === 'assistant')
      .slice(-10); // Lấy 10 tin cuối cùng

    const messages = [
      { role: "system", content: systemPrompt },
      ...recentHistory,
      { role: "user", content: message }
    ];

    // --- 4. Chuẩn bị Tools ---
    const tools = convertGeminiToolsToOpenAI(geminiTools);
    console.log(`🛠️ Converted ${tools.length} tools to OpenAI format.`);

    // --- 5. Vòng lặp Xử lý (Groq Execution Loop) ---
    let iteration = 0;
    const maxIterations = 5;
    let finalResponse = "";

    while (iteration < maxIterations) {
      console.log(`🔄 Iteration ${iteration + 1}...`);

      let responseMessage;
      let toolCalls = [];

      try {
        const completion = await groq.chat.completions.create({
          messages: messages,
          model: "llama-3.3-70b-versatile",
          temperature: 0.5,
          max_completion_tokens: 4096,
          top_p: 1,
          stream: false,
          tools: tools.length > 0 ? tools : undefined,
          tool_choice: "auto"
        });

        responseMessage = completion.choices[0].message;
        toolCalls = responseMessage.tool_calls || [];

      } catch (apiError) {
        // 🔥 CƠ CHẾ FALLBACK "BẤT TỬ": Tự động sửa lỗi tool_use_failed
        if (apiError.status === 400 && apiError.error?.error?.failed_generation) {
          console.warn("⚠️ Groq Tool Error caught. Attempting manual parse...");
          const rawGen = apiError.error.error.failed_generation;

          // Regex linh hoạt: Bắt cả trường hợp thiếu dấu ngoặc ()
          const match = rawGen.match(/<function=(\w+)[^\{]*(\{.*?\})/);

          if (match) {
            const fnName = match[1];
            const fnArgsStr = match[2];
            console.log(`✅ Manually recovered tool call: ${fnName}`);

            toolCalls = [{
              id: "call_manual_" + Date.now(),
              function: {
                name: fnName,
                arguments: fnArgsStr
              }
            }];

            responseMessage = {
              role: "assistant",
              content: null,
              tool_calls: toolCalls
            };
          } else {
            throw apiError;
          }
        } else {
          throw apiError;
        }
      }

      if (toolCalls && toolCalls.length > 0) {
        console.log(`🤖 Groq gọi ${toolCalls.length} tools:`, toolCalls.map(t => t.function.name));
        messages.push(responseMessage);

        for (const toolCall of toolCalls) {
          const functionName = toolCall.function.name;
          const toolCallId = toolCall.id;
          let functionArgs = {};

          try {
            if (typeof toolCall.function.arguments === 'object') {
              functionArgs = toolCall.function.arguments;
            } else {
              functionArgs = JSON.parse(toolCall.function.arguments);
            }
          } catch (e) {
            console.error("❌ Parse args error:", e);
            messages.push({
              tool_call_id: toolCallId,
              role: "tool",
              name: functionName,
              content: JSON.stringify({ error: "Invalid JSON arguments" })
            });
            continue;
          }

          let functionResult;
          const functionToCall = toolImplementations[functionName];

          if (functionToCall) {
            try {
              console.log(`   → Calling ${functionName}...`);
              const apiResponse = await functionToCall(userId, functionArgs);
              functionResult = JSON.stringify(apiResponse);
            } catch (e) {
              console.error(`   ❌ Tool Error (${functionName}):`, e.message);
              functionResult = JSON.stringify({ error: e.message });
            }
          } else {
            console.warn(`   ⚠️ Tool not found: ${functionName}`);
            functionResult = JSON.stringify({ error: "Function implementation not found" });
          }

          messages.push({
            tool_call_id: toolCallId,
            role: "tool",
            name: functionName,
            content: functionResult
          });
        }
        iteration++;
      } else {
        finalResponse = responseMessage.content;
        break;
      }
    }

    const duration = Date.now() - startT;
    console.log(`✅ Response time: ${duration}ms, Iterations: ${iteration}`);

    return res.json({ reply: finalResponse || "Xin lỗi, tôi chưa thể trả lời lúc này." });

  } catch (error) {
    console.error("❌ GROQ ERROR:", error);
    if (error.error) console.error("Groq Details:", error.error);

    res.status(500).json({
      message: "Lỗi hệ thống AI",
      error: error.message
    });
  }
};