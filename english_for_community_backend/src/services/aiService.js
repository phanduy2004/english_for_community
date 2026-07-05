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

const needsRewriteRepair = (feedback = {}) => {
  const paragraphs = Array.isArray(feedback.paragraphs) ? feedback.paragraphs : [];
  if (!paragraphs.length) return true;

  // Nếu phần lớn paragraph không có tag sửa, coi như model không tuân thủ.
  const tagCounts = paragraphs.map((p) => countCorrectionTags(p?.rewrite || ""));
  const withTags = tagCounts.filter((n) => n > 0).length;

  // Trường hợp rất dễ xảy ra ở log của bạn: model chỉ paraphrase/summarize, không có inline correction tags.
  return withTags < Math.max(1, Math.ceil(paragraphs.length / 2));
};

const repairParagraphRewrites = async (essayText, feedback, taskType) => {
  const safeFeedback = feedback || {};
  const paragraphs = Array.isArray(safeFeedback.paragraphs) ? safeFeedback.paragraphs : [];

  const systemContent = `
You are a strict IELTS correction formatter.
Your ONLY task is to repair "paragraphs[].rewrite" so each rewrite:
1) keeps the original paragraph content as much as possible,
2) only edits real mistakes,
3) marks every edit with EXACT inline token format: {{old||new||reason_in_Vietnamese}}.

CRITICAL:
- Do NOT summarize.
- Do NOT omit sentences from the original paragraph.
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
- ƯU TIÊN PHÁT HIỆN LỖI CHÍNH TẢ / GÕ NHẦM (ví dụ: "alternastives", "tsshey", "ffor") và BẮT BUỘC gắn tag sửa.
- KHÔNG được xóa câu chỉ vì câu đúng; chỉ sửa lỗi thực sự.

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
      const jsonStr = cleanJson(content);
      let hehe = JSON.parse(jsonStr);

      // Guardrail: nếu model không tuân thủ rewrite-tag format, chạy pass repair.
      if (needsRewriteRepair(hehe)) {
        try {
          hehe = await repairParagraphRewrites(essayText, hehe, taskType);
        } catch (repairError) {
          console.error("AI rewrite repair failed:", repairError?.message || repairError);
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
