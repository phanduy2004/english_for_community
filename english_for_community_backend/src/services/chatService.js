import Groq from 'groq-sdk';
import { getUserContext } from './aiContextService.js';
import { aiService } from './aiService.js';
import { chatTools } from '../tools/definitions.js';
import { toolImplementations } from '../tools/implementations.js';

const API_KEY = process.env.GROQ_API_KEY;
const groq = new Groq({ apiKey: API_KEY });
const MODEL_NAME = aiService.MODEL_NAME || 'openai/gpt-oss-120b';
const MAX_TOOL_ROUNDS = 5;

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

const buildSystemPrompt = (userContext) => {
  const today = new Date();
  const todayStr = today.toLocaleDateString('en-CA');
  const weekday = today.toLocaleDateString('vi-VN', { weekday: 'long' });

  return `
# VAI TRO: Co van hoc tap & chuyen gia phan tich du lieu

Ban la AI English Learning Companion. Ban co quyen truy cap du lieu hoc tap cua nguoi dung qua native tools.

---

# CHIEN LUOC TRUY XUAT DU LIEU

Khong tu bia startDate/endDate. Ngay trong DB la YYYY-MM-DD theo timezone user, nen uu tien tool co range de server tinh ngay dung.

- Hoi "hom nay / progress hom nay / lam may bai hom nay" -> goi get_daily_activity, co the them get_learning_history_period voi range "today".
- Hoi "tuan nay / 7 ngay gan day / rolling week" -> goi get_learning_history_period voi range "week".
- Hoi "tuan truoc / last week / tuan vua roi" -> goi get_learning_history_period voi range "last_week"; khong dung "week".
- Hoi "thang nay" -> goi get_learning_history_period voi range "month".
- get_learning_history chi dung khi da co chinh xac startDate va endDate YYYY-MM-DD.
- Khi can chi tiet bai theo mot ngay, truyen cung startDate va endDate vao get_reading_details/get_listening_details/get_speaking_details/get_writing_details, hoac dung get_daily_activity neu chi can danh sach hoat dong.
- Hoi thong tin tai khoan/muc tieu/level/streak -> goi get_profile.
- Hoi lop hoc/giao vien -> goi get_classrooms.
- Hoi bai tap lop/homework/deadline/han nop/bai sap toi/bai chua lam -> goi get_classroom_assignments (status="todo" cho bai chua lam con han, "done" cho bai da nop/da cham, mac dinh "all"). Co the loc theo classroomName.
- Hoi thong bao lop/lop co gi moi/moi giao bai gi/ket qua da tra chua/hoat dong lop -> goi get_classroom_activity (unreadOnly=true neu chi hoi thong bao chua doc).
- Hoi diem/bai thi/bai kiem tra/ket qua exam/ket qua grading gan day -> bat buoc goi get_exam_results truoc khi tra loi. Khong tra loi generic ve kha nang cua AI khi user dang hoi diem cua chinh ho.
- Hoi xu huong hoc tap theo ngay/streak -> goi get_progress_trend.

Combo goi y cho thong ke rong:
1. get_learning_history_period hoac get_daily_activity
2. analyze_weaknesses
3. get_reading_details / get_listening_details / get_speaking_details / get_writing_details
4. Neu can thong tin ca nhan/lop/exam/trend, goi them 4 tool profile/classrooms/exam_results/progress_trend phu hop.

---

# CAU TRUC BAO CAO SAU KHI CO DU LIEU

Khi da nhan du lieu tu tools, tra loi bang Markdown ro rang, than thien:

### 1. Tong quan
- Thoi gian hoc / bai hoan thanh / tu vung / diem noi bat neu co.
- Nhan xet ngan dua tren du lieu.

### 2. Chi tiet theo ky nang hoac theo muc user hoi
**Reading / Listening / Speaking / Writing / Exam / Classrooms / Assignments / Activity / Profile**:
- Dua so lieu cu the tu tool.
- Neu du lieu thieu, noi ro "chua co du lieu" thay vi bia.

### 3. Loi khuyen & ke hoach tiep theo
- Dua ra 2-4 buoc cu the dua tren weaknesses/trend/recent results.

---

# BOI CANH
Hom nay: ${weekday}, ${todayStr}
${userContext}
`;
};

/**
 * @returns {Promise<string>} Markdown reply for the client
 */
export async function generateChatReply(userId, message, history) {
  const userContext = await getUserContext(userId);
  const messages = [
    { role: 'system', content: buildSystemPrompt(userContext) },
    ...normalizeHistory(history),
    { role: 'user', content: message },
  ];

  for (let round = 0; round < MAX_TOOL_ROUNDS; round += 1) {
    const completion = await groq.chat.completions.create({
      messages,
      model: MODEL_NAME,
      tools: chatTools,
      tool_choice: 'auto',
      temperature: 0.4,
      stream: false,
    });

    const msg = completion.choices[0].message;
    messages.push(msg);
    const calls = msg.tool_calls || [];
    if (calls.length === 0) return msg.content || '';

    console.log(
      `[chatService] tool_calls round=${round + 1}: ${calls
        .map((call) => call.function?.name || 'unknown')
        .join(', ')}`
    );

    for (const call of calls) {
      const name = call.function?.name;
      let args = {};
      try {
        args = JSON.parse(call.function?.arguments || '{}');
      } catch {
        args = {};
      }

      let result;
      try {
        result = toolImplementations[name]
          ? await toolImplementations[name](userId, args)
          : { error: 'Function not found' };
      } catch (err) {
        result = { error: err?.message || 'Tool execution failed' };
      }

      messages.push({
        role: 'tool',
        tool_call_id: call.id,
        content: JSON.stringify(result),
      });
    }
  }

  const final = await groq.chat.completions.create({
    messages,
    model: MODEL_NAME,
    temperature: 0.5,
    stream: false,
  });
  return final.choices[0].message.content || '';
}
