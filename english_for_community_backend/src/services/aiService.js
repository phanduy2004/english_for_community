// src/services/aiService.js
import Groq from "groq-sdk";
import { jsonrepair } from 'jsonrepair';
import dotenv from 'dotenv';
dotenv.config();

// Khởi tạo Groq Client
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// Model Groq dùng chung (chat, writing prompt, feedback). Đổi một chỗ — tránh model cũ / không tồn tại.
export const GROQ_MODEL_NAME = process.env.GROQ_MODEL_NAME || "openai/gpt-oss-120b";
const MODEL_NAME = GROQ_MODEL_NAME;

// Hàm clean JSON (Loại bỏ ```json ... ```)
const cleanJson = (text) => {
  if (!text) return "{}";
  const match = text.match(/```(json)?([\s\S]*)```/);
  return match ? match[2].trim() : text.trim();
};

// Groq json_object mode có thể trả 400 code 'json_validate_failed' khi model sinh JSON
// gần-hợp-lệ (lệch bracket / token đuôi thừa). SDK throw ngay ở .create(), và trả nguyên
// văn bản sinh trong error.error.error.failed_generation (APIError.error === body {error:{...}}).
const extractFailedGeneration = (error) => {
  const body = error?.error?.error; // = response body.error = { code, failed_generation, ... }
  if (body?.code !== 'json_validate_failed') return null;
  return typeof body.failed_generation === 'string' ? body.failed_generation : null;
};

// Best-effort khôi phục 1 JSON object từ output LLM lỗi đuôi (thừa/thiếu bracket, cụt giữa chừng).
// Quét tôn trọng string/escape + stack bracket; cắt tại ranh giới value hợp lệ cuối cùng rồi
// đóng lại các bracket còn mở. Xử đúng ca Groq 'json_validate_failed' mà jsonrepair bó tay
// (vd mảng kết bằng '}' + token thừa: ..."]  ->  ..."} "} ).
const recoverJsonObject = (raw) => {
  const text = String(raw ?? '');
  const start = text.indexOf('{');
  if (start === -1) return null;
  const stack = [];
  let inStr = false, esc = false;
  let safeLen = -1, safeStack = null;
  const tokenRe = /[^\s,{}\[\]":]/; // ký tự thuộc number/true/false/null
  for (let i = start; i < text.length; i++) {
    const ch = text[i];
    if (inStr) {
      if (esc) esc = false;
      else if (ch === '\\') esc = true;
      else if (ch === '"') { inStr = false; safeLen = i + 1 - start; safeStack = stack.slice(); }
      continue;
    }
    if (ch === '"') { inStr = true; continue; }
    if (ch === '{' || ch === '[') { stack.push(ch === '{' ? '}' : ']'); continue; }
    if (ch === '}' || ch === ']') {
      if (stack.length && stack[stack.length - 1] === ch) {
        stack.pop();
        safeLen = i + 1 - start; safeStack = stack.slice();
        if (stack.length === 0) break; // đóng xong root object
      } else break; // bracket sai loại (vd '}' khi đang trong array) -> dừng tại safe point
      continue;
    }
    if (ch === ',' || ch === ':' || /\s/.test(ch)) continue;
    // number / true / false / null: đọc hết token rồi mốc safe point
    let j = i;
    while (j < text.length && tokenRe.test(text[j])) j++;
    safeLen = j - start; safeStack = stack.slice();
    i = j - 1;
  }
  if (safeLen === -1 || !safeStack) return null;
  let out = text.slice(start, start + safeLen).replace(/[\s,]+$/, '');
  for (let k = safeStack.length - 1; k >= 0; k--) out += safeStack[k];
  return out;
};

// Parse khoan dung: thử JSON.parse thẳng -> jsonrepair -> recoverJsonObject. Trả object hoặc null.
const parseLenient = (text) => {
  const attempts = [
    () => JSON.parse(text),
    () => JSON.parse(jsonrepair(text)),
    () => JSON.parse(recoverJsonObject(text)),
  ];
  for (const fn of attempts) {
    try { const o = fn(); if (o && typeof o === 'object') return o; } catch (_) { /* thử cách kế */ }
  }
  return null;
};

const countCorrectionTags = (text = "") => {
  const matches = text.match(/\{\{.*?\|\|.*?\|\|.*?\}\}/g);
  return matches ? matches.length : 0;
};

// Bỏ tag {{old||new||reason}} -> lấy lại phần "old" (bản gốc mà model coi là input).
// Dùng để kiểm tra model có chép trung thực bài gốc hay đã tự ý paraphrase (silent edit).
const stripTagsToOriginal = (text = "") =>
  String(text).replace(/\{\{(.*?)\|\|(.*?)\|\|(.*?)\}\}/g, "$1");

const tokenizeWords = (value = "") =>
  new Set(
    String(value)
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, " ")
      .split(/\s+/)
      .filter((w) => w.length >= 3),
  );

// Jaccard similarity giữa 2 khối text (0..1).
const wordSimilarity = (a, b) => {
  const sa = tokenizeWords(a);
  const sb = tokenizeWords(b);
  if (!sa.size || !sb.size) return 0;
  let inter = 0;
  for (const w of sa) if (sb.has(w)) inter++;
  const union = sa.size + sb.size - inter;
  return union === 0 ? 0 : inter / union;
};

// Guard MỚI (nới lỏng độ nghiêm ngặt): chỉ chạy repair khi model KHÔNG trung thực với
// bài gốc — thiếu paragraphs, hoặc tự ý paraphrase/summarize thay vì chép nguyên + gắn tag.
// KHÔNG còn ép sửa chỉ vì "ít tag": bài tốt có 0 lỗi => 0 tag là kết quả HỢP LỆ.
const needsRewriteRepair = (feedback = {}, essayText = "") => {
  const paragraphs = Array.isArray(feedback.paragraphs) ? feedback.paragraphs : [];
  if (!paragraphs.length) return true;

  // Ghép lại "bản gốc" mà model đã dựng (bỏ tag về phía old) rồi so với bài thật.
  const reconstructedOriginal = paragraphs
    .map((p) => stripTagsToOriginal(p?.rewrite || ""))
    .join("\n");

  // Similarity cao => model chép trung thực (chỉ đánh dấu chỗ sai) => KHÔNG cần repair
  // dù có 0 tag. Similarity thấp => model đã viết lại/tóm tắt => repair để ép giữ gốc + tag.
  const similarity = wordSimilarity(reconstructedOriginal, essayText);
  return similarity < 0.6;
};

const repairParagraphRewrites = async (essayText, feedback, taskType) => {
  const safeFeedback = feedback || {};
  const paragraphs = Array.isArray(safeFeedback.paragraphs) ? safeFeedback.paragraphs : [];

  const systemContent = `
You are a strict IELTS correction formatter.
Your ONLY task is to repair "paragraphs[].rewrite" so each rewrite:
1) copies the ORIGINAL paragraph text VERBATIM (do NOT paraphrase, summarize, or add sentences),
2) only tags REAL mistakes (spelling, grammar, wrong word/collocation, punctuation that changes meaning),
3) marks every edit with EXACT inline token: {{old||new||reason_in_Vietnamese}}, wrapping the SMALLEST wrong span (usually 1 word / short phrase — NEVER a whole sentence just for one fix).

CRITICAL:
- Do NOT summarize or shorten.
- Do NOT omit sentences from the original paragraph.
- Do NOT "improve" style: a grammatically correct, understandable sentence must be copied verbatim with 0 tags even if a nicer wording exists (the nicer version belongs in Samples, not here). Only touch style when a sentence is so wrong it is unintelligible.
- Keep rewrite in ENGLISH.
- Keep reason in VIETNAMESE (very short).
- Output JSON only.
`;

  const userContent = `
TaskType: ${taskType}

Original essay:
${essayText}

Current feedback paragraphs:
${JSON.stringify(paragraphs, null, 2)}

Return JSON:
{
  "paragraphs": [
    { "title": "...", "comment": "...", "rewrite": "..." }
  ]
}

Rules:
- Keep title/comment unchanged.
- Rewrite must preserve full paragraph meaning and coverage (no shortening).
- Any changed/deleted/inserted wording must be represented by {{old||new||reason}} tokens.
`;

  const completion = await groq.chat.completions.create({
    messages: [
      { role: "system", content: systemContent },
      { role: "user", content: userContent },
    ],
    model: MODEL_NAME,
    temperature: 0,
    response_format: { type: "json_object" },
  });

  const repairedJson = JSON.parse(cleanJson(completion.choices[0].message.content));
  const repairedParagraphs = Array.isArray(repairedJson?.paragraphs) ? repairedJson.paragraphs : [];
  if (!repairedParagraphs.length) return safeFeedback;

  return {
    ...safeFeedback,
    paragraphs: repairedParagraphs.map((p, idx) => ({
      title: p?.title ?? paragraphs[idx]?.title ?? "",
      comment: p?.comment ?? paragraphs[idx]?.comment ?? "",
      rewrite: p?.rewrite ?? paragraphs[idx]?.rewrite ?? "",
    })),
  };
};

// Sinh riêng 2 bài mẫu. Dùng làm fallback khi call chấm điểm chính bỏ trống
// sampleMid/sampleHigh (rất dễ xảy ra vì JSON chấm điểm quá lớn) -> đảm bảo tab
// Samples luôn có nội dung mà không làm phình call chính.
const generateWritingSamples = async (essayText, taskType) => {
  const systemContent = `
Bạn là giám khảo IELTS Writing. Dựa trên bài của học viên, viết 2 bài mẫu bằng Tiếng Anh.
Chỉ trả về JSON thuần (không markdown):
{
  "sampleMid": "Bài mẫu Band 7.0-8.0: viết lại theo ý chính của học viên, sửa hết lỗi, mạch lạc. FULL ESSAY tối thiểu 250 từ, dùng \\n\\n để tách đoạn.",
  "sampleHigh": "Bài mẫu Band 9.0: ý tưởng sâu sắc, từ vựng academic cao cấp. FULL ESSAY tối thiểu 250 từ, dùng \\n\\n để tách đoạn."
}
KHÔNG tóm tắt, KHÔNG cắt bớt. Chỉ trả JSON.
`;
  const completion = await groq.chat.completions.create({
    messages: [
      { role: "system", content: systemContent },
      { role: "user", content: `TaskType: ${taskType}\n\nessay_text:\n${essayText}` },
    ],
    model: MODEL_NAME,
    temperature: 0.4,
    response_format: { type: "json_object" },
  });

  const parsed = parseLenient(cleanJson(completion.choices[0].message.content)) || {};
  return {
    sampleMid: typeof parsed.sampleMid === "string" ? parsed.sampleMid : "",
    sampleHigh: typeof parsed.sampleHigh === "string" ? parsed.sampleHigh : "",
  };
};

const toNumberBand = (value, fallback = 0) => {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(0, Math.min(9, Math.round(n * 2) / 2));
};

const ensureStringArray = (value, fallback = []) => {
  if (!Array.isArray(value)) return fallback;
  return value.map((item) => `${item ?? ''}`.trim()).filter(Boolean);
};

const ensureObjectArray = (value, mapper) => {
  if (!Array.isArray(value)) return [];
  return value.map(mapper).filter(Boolean);
};

const normalizeSpeakingFeedback = (raw = {}) => {
  const fc = toNumberBand(raw.fc);
  const lr = toNumberBand(raw.lr);
  const gra = toNumberBand(raw.gra);
  const ia = toNumberBand(raw.ia);
  const taskAchievement = raw.taskAchievement == null
    ? null
    : toNumberBand(raw.taskAchievement);
  const computedOverall = Math.round(((fc + lr + gra + ia) / 4) * 2) / 2;
  const overall = toNumberBand(raw.overall, computedOverall);
  const cefr = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].includes(raw.cefr) ? raw.cefr : cefrFromBand(overall);

  return {
    overall,
    cefr,
    summary: `${raw.summary ?? 'Bạn đã hoàn thành một lượt luyện nói. Hãy nói dài hơn và dùng nhiều câu đầy đủ hơn ở lần sau.'}`.trim(),
    fc,
    fcBullets: ensureStringArray(raw.fcBullets),
    fcNote: `${raw.fcNote ?? ''}`.trim(),
    lr,
    lrBullets: ensureStringArray(raw.lrBullets),
    lrNote: `${raw.lrNote ?? ''}`.trim(),
    gra,
    graBullets: ensureStringArray(raw.graBullets),
    graNote: `${raw.graNote ?? ''}`.trim(),
    ia,
    iaBullets: ensureStringArray(raw.iaBullets),
    iaNote: `${raw.iaNote ?? ''}`.trim(),
    taskAchievement,
    taskBullets: ensureStringArray(raw.taskBullets),
    taskNote: `${raw.taskNote ?? ''}`.trim(),
    scenarioTitle: `${raw.scenarioTitle ?? ''}`.trim(),
    strengths: ensureStringArray(raw.strengths),
    improvements: ensureObjectArray(raw.improvements, (item) => ({
      issue: `${item?.issue ?? ''}`.trim(),
      before: `${item?.before ?? ''}`.trim(),
      after: `${item?.after ?? ''}`.trim(),
      explain: `${item?.explain ?? ''}`.trim(),
    })).filter((item) => item.issue || item.before || item.after || item.explain),
    corrections: ensureObjectArray(raw.corrections, (item) => ({
      type: `${item?.type ?? 'grammar'}`.trim(),
      before: `${item?.before ?? ''}`.trim(),
      after: `${item?.after ?? ''}`.trim(),
      reason: `${item?.reason ?? ''}`.trim(),
    })).filter((item) => item.before || item.after || item.reason),
    vocabUpgrades: ensureObjectArray(raw.vocabUpgrades, (item) => ({
      said: `${item?.said ?? ''}`.trim(),
      better: `${item?.better ?? ''}`.trim(),
      note: `${item?.note ?? ''}`.trim(),
    })).filter((item) => item.said || item.better),
    modelAnswers: ensureObjectArray(raw.modelAnswers, (item) => ({
      context: `${item?.context ?? ''}`.trim(),
      yourTurn: `${item?.yourTurn ?? ''}`.trim(),
      modelTurn: `${item?.modelTurn ?? ''}`.trim(),
    })).filter((item) => item.yourTurn || item.modelTurn),
    nextSteps: ensureStringArray(raw.nextSteps),
  };
};

const cefrFromBand = (band) => {
  if (band >= 8.5) return 'C2';
  if (band >= 7) return 'C1';
  if (band >= 5.5) return 'B2';
  if (band >= 4) return 'B1';
  if (band >= 2.5) return 'A2';
  return 'A1';
};

const repairSpeakingFeedbackJson = async ({ turns, level, stats, scenario, badContent, parseError }) => {
  const transcript = turns
    .map((turn) => `${turn.role === 'user' ? 'USER' : 'AI'}: ${turn.text}`)
    .join('\n');

  const completion = await groq.chat.completions.create({
    messages: [
      {
        role: 'system',
        content: `
You repair IELTS Speaking feedback JSON.
Return valid JSON only, with every required key present.
Vietnamese fields: summary, *Note, *Bullets, issue, explain, reason, note, nextSteps.
English fields: before, after, said, better, yourTurn, modelTurn.
Do not invent statistics and do not change transcript quotes.
`,
      },
      {
        role: 'user',
        content: `
Target level: ${level || 'not specified'}
Scenario:
${scenario ? JSON.stringify({
  title: scenario.title,
  goals: scenario.goals || [],
  successCriteria: scenario.successCriteria || [],
}, null, 2) : 'free chat'}

Stats already computed by code:
${JSON.stringify(stats, null, 2)}

Transcript:
${transcript}

Broken content:
${badContent || ''}

Parse error:
${parseError || ''}

Return this JSON shape:
{
  "overall": 0,
  "cefr": "A1",
  "summary": "",
  "fc": 0, "fcBullets": [], "fcNote": "",
  "lr": 0, "lrBullets": [], "lrNote": "",
  "gra": 0, "graBullets": [], "graNote": "",
  "ia": 0, "iaBullets": [], "iaNote": "",
  "taskAchievement": null, "taskBullets": [], "taskNote": "", "scenarioTitle": "",
  "strengths": [],
  "improvements": [{"issue":"","before":"","after":"","explain":""}],
  "corrections": [{"type":"grammar","before":"","after":"","reason":""}],
  "vocabUpgrades": [{"said":"","better":"","note":""}],
  "modelAnswers": [{"context":"","yourTurn":"","modelTurn":""}],
  "nextSteps": []
}
`,
      },
    ],
    model: MODEL_NAME,
    temperature: 0,
    response_format: { type: 'json_object' },
  });

  return JSON.parse(cleanJson(completion.choices[0].message.content));
};

export const aiService = {
  MODEL_NAME: GROQ_MODEL_NAME,
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
Bạn là giám khảo IELTS Writing Task 2 công bằng, thực tế và mang tính xây dựng (KHÔNG bắt bẻ).
Nhiệm vụ: Chấm điểm hợp lý, nhận xét chi tiết, CHỈ sửa những lỗi THẬT SỰ, và viết bài mẫu.
Format Output: JSON Object (Tuyệt đối không dùng Markdown, chỉ trả về JSON thuần).

=== 1. QUY ĐỊNH VỀ NGÔN NGỮ & ĐỊNH DẠNG ===
- **Phân tích (Bullets, Tips, Notes):** Viết bằng **Tiếng Việt**.
- **Rewrite & Samples:** Viết bằng **Tiếng Anh**.
- **JSON Strict:** Đảm bảo cấu trúc JSON hợp lệ, thoát các ký tự đặc biệt nếu cần.

=== 2. QUY ĐỊNH VỀ SỬA LỖI (REWRITE) - QUAN TRỌNG NHẤT ===
- TRIẾT LÝ: Tab "Rewrites" CHỈ để SỬA LỖI, KHÔNG phải để "viết cho hay hơn". Bản nâng cấp/hay hơn đã có riêng ở phần Samples (sampleMid/sampleHigh) — TUYỆT ĐỐI không nâng cấp văn phong ở "rewrite".
- CHỈ SỬA khi có LỖI THẬT SỰ (ưu tiên đúng nhóm này):
  • Chính tả / gõ nhầm (typo).
  • Ngữ pháp: chia thì, số ít/số nhiều, hoà hợp chủ ngữ–động từ, mạo từ (a/an/the), giới từ, dạng từ (word form).
  • Dùng sai từ / sai nghĩa / sai collocation RÕ RÀNG (sai "từ điển").
  • Dấu câu gây SAI NGHĨA.
- VĂN PHONG (cách diễn đạt, chọn từ, cấu trúc câu): CHỈ được đụng trong DUY NHẤT trường hợp câu sai NẶNG tới mức KHÓ HIỂU / gần như vô nghĩa (unintelligible). Câu chỉ "chưa hay" nhưng vẫn ĐÚNG ngữ pháp và HIỂU ĐƯỢC → GIỮ NGUYÊN.
- TUYỆT ĐỐI KHÔNG (dù bạn nghĩ có cách hay hơn):
  • Đổi một từ ĐÚNG sang từ đồng nghĩa "xịn"/academic hơn.
  • Viết lại câu cho mượt/hay hơn khi câu gốc đã đúng ngữ pháp và hiểu được.
  • THÊM câu mới không có trong bài gốc (topic sentence, câu nối, ví dụ, câu dẫn dắt...).
  → Chuẩn "vừa đủ, đúng ngữ pháp, hiểu được" = GIỮ NGUYÊN, không tối ưu.
- BỌC TỐI THIỂU: mỗi tag chỉ bọc ĐÚNG cụm sai NHỎ NHẤT (thường 1 từ hoặc cụm ngắn). CẤM bọc cả câu chỉ vì sửa 1 từ — điều đó làm nguyên câu bị tô là "đã sửa".
- QUY TẮC ĐÁNH DẤU (BẮT BUỘC): mỗi chỗ THẬT SỰ sửa PHẢI bọc trong tag {{từ_cũ||từ_mới||lý_do_ngắn_gọn_bằng_tiếng_Việt}}. Cấm "sửa ngầm" (đổi chữ mà không dùng tag).

🔴 VÍ DỤ:
- Input: "It is accessible sand convenient. Technology nows allows users to learn. On the one hand, it offers benefits."
- CHUẨN: "It is accessible {{sand||and||Lỗi chính tả dư chữ s}} convenient. Technology {{nows||now||Sai ngữ pháp}} allows users to learn. On the one hand, it offers benefits."
  → Câu cuối ĐÚNG ngữ pháp và hiểu được → chép NGUYÊN, 0 tag (dù có thể viết academic hơn).
- SAI (BỊ CẤM — đây là nâng cấp văn phong, không phải sửa lỗi):
  "... {{On the one hand, it offers benefits||On the one hand, everyday technology offers undeniable benefits that make life easier and more enjoyable||viết hay hơn}}."
  Cũng CẤM chèn thêm câu mới kiểu "Furthermore, smartphones and the internet provide..." nếu bài gốc không có.

- BẮT BUỘC chép lại TOÀN BỘ đoạn văn gốc y nguyên: câu đúng thì copy nguyên văn (KHÔNG tag, KHÔNG xoá, KHÔNG thêm).
- QUAN TRỌNG NHẤT: đoạn (hoặc cả bài) không có lỗi thật → chép nguyên văn với 0 tag. Bài tốt HOÀN TOÀN có thể có rất ít hoặc 0 tag — đó là kết quả ĐÚNG và ĐƯỢC MONG ĐỢI.

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
      // parseLenient: thử JSON.parse -> jsonrepair -> recover JSON cụt, tránh fail cả feedback.
      let hehe = parseLenient(cleanJson(content));
      if (!hehe) throw new Error("AI feedback JSON parse failed");

      // Guardrail: chỉ repair khi model KHÔNG chép trung thực bài gốc (paraphrase/summarize),
      // KHÔNG còn ép sửa chỉ vì ít tag -> bài tốt giữ nguyên, hết cảnh "bịa lỗi để sửa".
      if (needsRewriteRepair(hehe, essayText)) {
        try {
          hehe = await repairParagraphRewrites(essayText, hehe, taskType);
        } catch (repairError) {
          console.error("AI rewrite repair failed:", repairError?.message || repairError);
        }
      }

      // Fallback bài mẫu: nếu call chính bỏ trống sampleMid/sampleHigh, sinh riêng để tab
      // Samples luôn có nội dung. Lỗi ở đây KHÔNG làm hỏng feedback (chỉ log lại).
      const missingMid = !hehe.sampleMid || !String(hehe.sampleMid).trim();
      const missingHigh = !hehe.sampleHigh || !String(hehe.sampleHigh).trim();
      if (missingMid || missingHigh) {
        try {
          const samples = await generateWritingSamples(essayText, taskType);
          if (missingMid && samples.sampleMid) hehe.sampleMid = samples.sampleMid;
          if (missingHigh && samples.sampleHigh) hehe.sampleHigh = samples.sampleHigh;
        } catch (sampleError) {
          console.error("AI sample fallback failed:", sampleError?.message || sampleError);
        }
      }

      console.log(`User Login: ${JSON.stringify(hehe, null, 2)}`);
// 3. Trả về biến đã parse, KHÔNG parse lại lần 2
      return hehe;

    } catch (error) {
      console.error("AI Feedback Error (Groq):", error);
      if (error.error) console.error("Groq Error Detail:", error.error);
      throw new Error("Failed to generate feedback from AI");
    }
  },

  generateSpeakingFeedback: async ({ turns, level, stats, scenario = null }) => {
    const transcript = turns
      .map((turn) => `${turn.role === 'user' ? 'USER' : 'AI'}: ${turn.text}`)
      .join('\n');

    const systemInstruction = `
Bạn là giám khảo IELTS Speaking kiêm gia sư tiếng Anh cho người Việt.
Chấm CHỈ phần lời của học viên (USER) trong hội thoại nói. Lời AI chỉ là ngữ cảnh.
Transcript có thể có lỗi nhận dạng giọng nói; bỏ qua lỗi chính tả nhỏ do STT nếu ý nói vẫn rõ.

Rubric:
- fc: Fluency & Coherence, band 0-9.
- lr: Lexical Resource, band 0-9.
- gra: Grammatical Range & Accuracy, band 0-9.
- ia: Interaction & Task, band 0-9.
- overall là trung bình 4 tiêu chí, làm tròn 0.5.
- cefr là A1/A2/B1/B2/C1/C2.

Quy định ngôn ngữ bắt buộc:
- summary, mọi *Note, mọi *Bullets, issue, explain, reason, note, nextSteps viết bằng TIẾNG VIỆT.
- before/after/said/better/yourTurn/modelTurn và ví dụ/câu mẫu giữ bằng TIẾNG ANH.
- improvements phải trích before CÓ THẬT từ lời USER, không dùng câu của AI.
- Không bịa thống kê; stats đã được tính bằng code.
- Không chấm phát âm.
- Trả JSON thuần, không Markdown.
`;

    const userContent = `
Target CEFR/level: ${level || 'not specified'}

Scenario:
${scenario ? JSON.stringify({
  title: scenario.title,
  group: scenario.group,
  goals: scenario.goals || [],
  successCriteria: scenario.successCriteria || [],
}, null, 2) : 'free chat'}

Stats computed by server:
${JSON.stringify(stats, null, 2)}

Transcript:
${transcript}

Return exactly this JSON object shape:
{
  "overall": <number 0..9>,
  "cefr": "A1|A2|B1|B2|C1|C2",
  "summary": "Nhận xét ngắn bằng tiếng Việt, có thể kèm 1 cụm tiếng Anh nếu là ví dụ",
  "fc": <number>, "fcBullets": ["..."], "fcNote": "...",
  "lr": <number>, "lrBullets": ["..."], "lrNote": "...",
  "gra": <number>, "graBullets": ["..."], "graNote": "...",
  "ia": <number>, "iaBullets": ["..."], "iaNote": "...",
  "taskAchievement": <number 0..9 or null for free chat>,
  "taskBullets": ["nhận xét tiếng Việt theo goals của scenario"],
  "taskNote": "nhận xét tiếng Việt, rỗng nếu free chat",
  "scenarioTitle": "${scenario?.title || ''}",
  "strengths": ["2-3 điểm mạnh bằng tiếng Việt, trích câu USER tốt trong dấu ngoặc kép nếu có"],
  "improvements": [
    {"issue":"vấn đề bằng tiếng Việt","before":"exact USER sentence/phrase in English","after":"better English version","explain":"giải thích tiếng Việt"}
  ],
  "corrections": [
    {"type":"grammar|vocab|collocation","before":"English phrase","after":"English phrase","reason":"lý do tiếng Việt"}
  ],
  "vocabUpgrades": [
    {"said":"English word/phrase USER used","better":"better English word/phrase","note":"ghi chú tiếng Việt"}
  ],
  "modelAnswers": [
    {"context":"ngữ cảnh tiếng Việt ngắn","yourTurn":"USER turn in English","modelTurn":"native-like English response"}
  ],
  "nextSteps": ["2-3 gợi ý luyện tiếp bằng tiếng Việt"]
}
`;

    try {
      const completion = await groq.chat.completions.create({
        messages: [
          { role: 'system', content: systemInstruction },
          { role: 'user', content: userContent },
        ],
        model: MODEL_NAME,
        temperature: 0.3,
        response_format: { type: 'json_object' },
      });

      const content = completion.choices[0].message.content;
      let parsed;
      try {
        parsed = JSON.parse(cleanJson(content));
      } catch (parseError) {
        parsed = await repairSpeakingFeedbackJson({
          turns,
          level,
          stats,
          scenario,
          badContent: content,
          parseError: parseError.message,
        });
      }

      const feedback = normalizeSpeakingFeedback(parsed);
      feedback.stats = stats;
      feedback.modelInfo = { provider: 'groq', model: MODEL_NAME };
      feedback.evaluatedAt = new Date();
      return feedback;
    } catch (error) {
      const failed = extractFailedGeneration(error);
      if (failed) {
        // Tầng 1: repair deterministic (direct -> jsonrepair -> recoverJsonObject), không gọi API.
        let parsed = parseLenient(cleanJson(failed));
        // Tầng 2: nhờ LLM sửa (chỉ khi tầng 1 vẫn thất bại).
        if (!parsed) {
          try {
            parsed = await repairSpeakingFeedbackJson({
              turns, level, stats, scenario,
              badContent: failed,
              parseError: 'json_validate_failed',
            });
          } catch (_) {
            parsed = null;
          }
        }
        if (parsed) {
          const feedback = normalizeSpeakingFeedback(parsed);
          feedback.stats = stats;
          feedback.modelInfo = { provider: 'groq', model: MODEL_NAME };
          feedback.evaluatedAt = new Date();
          return feedback;
        }
      }
      console.error('AI Speaking Feedback Error (Groq):', error);
      if (error.error) console.error('Groq Error Detail:', error.error);
      throw new Error('Failed to generate speaking feedback from AI');
    }
  }
};
