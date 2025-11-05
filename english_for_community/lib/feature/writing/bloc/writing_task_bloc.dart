import 'dart:convert'; // <- THÊM IMPORT NÀY
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// --- Entities (Bạn có thể đã có) ---
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart';

const String GEMINI_API_KEY = 'AIzaSyBJiswjlk11funPboyiBgdfRsJF6ptMVuE';

// --- EVENTS ---
abstract class WritingTaskEvent extends Equatable {
  const WritingTaskEvent();
  @override
  List<Object> get props => [];
}

// Event khi bắt đầu mở màn hình, dùng topic để tạo đề
class GeneratePromptAndStartTask extends WritingTaskEvent {
  final WritingTopicEntity topic;
  const GeneratePromptAndStartTask({required this.topic});
  @override
  List<Object> get props => [topic];
}

// Event khi người dùng nộp bài để chấm
class SubmitForFeedback extends WritingTaskEvent {
  final String submissionId;
  final String essayContent;
  final String taskType; // "Opinion", "Discussion", ...

  const SubmitForFeedback({
    required this.submissionId,
    required this.essayContent,
    required this.taskType,
  });
  @override
  List<Object> get props => [submissionId, essayContent, taskType];
}

// --- STATES ---
enum WritingTaskStatus { initial, loading, promptReady, submitting, success, error }

class WritingTaskState extends Equatable {
  final WritingTaskStatus status;
  final WritingTopicEntity? topic;
  final WritingSubmissionEntity? submission; // Bài làm (chứa prompt, content, id...)
  final String? errorMessage;

  const WritingTaskState({
    this.status = WritingTaskStatus.initial,
    this.topic,
    this.submission,
    this.errorMessage,
  });

  WritingTaskState copyWith({
    WritingTaskStatus? status,
    WritingTopicEntity? topic,
    WritingSubmissionEntity? submission,
    String? errorMessage,
  }) {
    return WritingTaskState(
      status: status ?? this.status,
      topic: topic ?? this.topic,
      submission: submission ?? this.submission,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, topic, submission, errorMessage];
}

// --- BLOC ---
class WritingTaskBloc extends Bloc<WritingTaskEvent, WritingTaskState> {
  // final WritingRepository _writingRepo; // Nên dùng Repo
  final GenerativeModel _geminiModel;

  WritingTaskBloc(/*this._writingRepo*/)
      : _geminiModel = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: GEMINI_API_KEY,
    generationConfig: GenerationConfig(
      temperature: 0.2, // bớt “bay bổng”
      topK: 30,
      topP: 0.9,
    ),
  ),
        super(const WritingTaskState()) {
    on<GeneratePromptAndStartTask>(_onGeneratePrompt);
    on<SubmitForFeedback>(_onSubmitForFeedback);
  }

  // Hàm dọn dẹp JSON trả về từ Gemini (gỡ bỏ ```json ... ```)
  String _cleanGeminiJson(String rawResponse) {
    final regExp = RegExp(r'```(json)?([\s\S]*)```');
    final match = regExp.firstMatch(rawResponse);
    if (match != null) {
      return match.group(2)!.trim();
    }
    return rawResponse.trim();
  }


  Future<void> _onGeneratePrompt(GeneratePromptAndStartTask event,
      Emitter<WritingTaskState> emit,) async {
    emit(state.copyWith(status: WritingTaskStatus.loading, topic: event.topic));
    try {
      // 1. Gọi Gemini (FE) để tạo đề
      final topic = event.topic;
      final promptTemplate = topic.aiConfig?.generationTemplate ??
          'Generate an IELTS Writing Task 2 prompt for the topic: "${topic
              .name}". '
              'Task type: ${topic.aiConfig?.defaultTaskType ?? "Discussion"}. '
              'Level: ${topic.aiConfig?.level ?? "Intermediate"}. '
              'Target word count: ${topic.aiConfig?.targetWordCount ??
              "250–320"}. '
              'Respond in JSON format: {"title": "...", "text": "..."}';

      final geminiResponse = await _geminiModel.generateContent([
        Content.text(promptTemplate)
      ]);

      // -----------------------------------------------------------------
      // SỬA LỖI: Phân tích JSON thật, không dùng "GIẢ LẬP"
      // -----------------------------------------------------------------
      if (geminiResponse.text == null) {
        throw Exception('Gemini returned no data for prompt');
      }
// THÊM DÒNG NÀY ĐỂ XEM AI TRẢ VỀ GÌ
      print('--- GEMINI RESPONSE (PROMPT) ---');
      print(geminiResponse.text);
      final cleanJson = _cleanGeminiJson(geminiResponse.text!);
      final Map<String, dynamic> generatedPromptMap = jsonDecode(cleanJson);

      final generatedPrompt = {
        "title": generatedPromptMap['title'] as String?,
        "text": generatedPromptMap['text'] as String?,
        "taskType": topic.aiConfig?.defaultTaskType ?? "Discussion",
        "level": topic.aiConfig?.level ?? "Intermediate",
      };
      // -----------------------------------------------------------------

      // 2. Gọi API /:id/start của backend để tạo submission
      // Đây là lúc bạn gọi API POST /api/writing/:id/start
      // const startResponse = await _writingRepo.startWritingForTopic(
      //   topic.id,
      //   generatedPrompt,
      // );

      // GIẢ LẬP RESPONSE TỪ API START (Vẫn giữ vì chưa có API thật)
      final startResponse = {
        "submissionId": "mock_submission_id_123",
        "generatedPrompt": generatedPrompt,
        "resumed": false
      };

      final submission = WritingSubmissionEntity(
        id: startResponse['submissionId'] as String,
        topicId: topic.id,
        generatedPrompt: GeneratedPrompt.fromJson(
            startResponse['generatedPrompt'] as Map<String, dynamic>),
        status: 'draft',
        userId: '', // Tạm thời, bạn nên lấy userId từ AuthBloc/AuthService
      );

      emit(state.copyWith(
        status: WritingTaskStatus.promptReady,
        submission: submission,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: WritingTaskStatus.error,
          errorMessage: "Failed to parse prompt: ${e.toString()}"));
    }
  }

  bool isLikelyGibberish(String s) {
    final text = s.trim();

    // 1) Tối thiểu 150–200 từ cho IELTS Task 2
    final words = text.isEmpty ? [] : text.split(RegExp(r'\s+'));
    if (words.length < 150) return true;

    // 2) Tỷ lệ ký tự chữ cái (VN/EN) tối thiểu 60%
    final alpha = RegExp(r'[A-Za-zÀ-ỹ]');
    final alphaCount = alpha
        .allMatches(text)
        .length;
    final total = text.runes.length;
    final alphaRatio = total == 0 ? 0 : alphaCount / total;
    if (alphaRatio < 0.6) return true;

    // 3) Tỷ lệ ký tự lặp bất thường (ví dụ 'aaaaaa', '!!!!')
    final repeated = RegExp(r'(.)\1{6,}'); // 7 ký tự giống nhau liên tiếp
    if (repeated.hasMatch(text)) return true;

    // 4) Từ trung bình quá ngắn (nghi ngờ spam ký tự)
    final avgLen = words.isEmpty ? 0 : text
        .replaceAll(RegExp(r'\s+'), '')
        .length / words.length;
    if (avgLen < 3) return true;

    return false;
  }

  Future<void> _onSubmitForFeedback(SubmitForFeedback event,
      Emitter<WritingTaskState> emit,) async {
    emit(state.copyWith(status: WritingTaskStatus.submitting));
    if (isLikelyGibberish(event.essayContent)) {
      emit(state.copyWith(
        status: WritingTaskStatus.error,
        errorMessage: "Bài nộp không hợp lệ",
      ));
      return;
    }
    try {
      // 1. Lấy prompt chấm bài (đã sửa để yêu cầu JSON)
      final feedbackPrompt = _buildFeedbackPrompt(
        essayText: event.essayContent,
        taskType: event.taskType,
      );

      // 2. Gọi Gemini (FE) để chấm bài
      final geminiResponse = await _geminiModel.generateContent([
        Content.text(feedbackPrompt)
      ]);

      if (geminiResponse.text == null) {
        throw Exception('Gemini returned no data for feedback');
      }

      // -----------------------------------------------------------------
      // SỬA LỖI: Phân tích JSON thật, không dùng "GIẢ LẬP"
      // -----------------------------------------------------------------
      // 3. Parse text feedback (JSON) thành FeedbackEntity
      final cleanJson = _cleanGeminiJson(geminiResponse.text!);
      final Map<String, dynamic> feedbackMap = jsonDecode(cleanJson);
      final FeedbackEntity feedback = FeedbackEntity.fromJson(feedbackMap);
      // -----------------------------------------------------------------


      // 4. Gọi API /submit của backend để lưu kết quả
      // final updatedSubmission = await _writingRepo.submitForReview(
      //   event.submissionId,
      //   event.essayContent,
      //   feedback,
      // );

      // GIẢ LẬP SUBMISSION ĐÃ UPDATE (Vẫn giữ vì chưa có API thật)
      final updatedSubmission = state.submission!.copyWith(
        status: 'reviewed',
        content: event.essayContent,
        feedback: feedback, // <- Gán feedback THẬT
        score: feedback.overall, // <- Gán điểm THẬT
      );

      emit(state.copyWith(
        status: WritingTaskStatus.success,
        submission: updatedSubmission,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: WritingTaskStatus.error,
          errorMessage: "Failed to parse feedback: ${e.toString()}"));
    }
  }

  // -----------------------------------------------------------------
  // SỬA LỖI: Sửa prompt để yêu cầu Gemini trả về JSON
  // -----------------------------------------------------------------
String _buildFeedbackPrompt({
    required String essayText,
    required String taskType,
  }) {
    return """
Bạn là giám khảo IELTS Writing Task 2 (TR/CC/LR/GRA).
Phần phân tích viết **bằng tiếng Việt**; **không dùng Markdown**; **CHỈ trả về MỘT đối tượng JSON hợp lệ** (không có \\\`\\\`\\\`json, không text ngoài JSON).

NGÔN NGỮ & PHÂN QUYỀN
- Các trường **trBullets, ccBullets, lrBullets, graBullets, keyTips, trNote, ccNote, lrNote, graNote**: **tiếng Việt**.
- **rewrite**: **tiếng Anh**, chỉ sửa lỗi (grammar/spelling/word form/punctuation). **Không** paraphrase, **không** thay đổi ý, **không** mượn câu/từ từ sample.
- **sampleMid**, **sampleHigh**: **tiếng Anh**.

ĐẦU VÀO
task_type: "$taskType"
essay_text:
$essayText

RÀNG BUỘC NGHIÊM NGẶT CHO REWRITE (CORRECTIONS-ONLY)
1) Giữ **nguyên số đoạn** và **thứ tự câu** như bài gốc; **không** thêm/bớt câu.
2) Mỗi câu gốc tương ứng **đúng 1 câu** trong `rewrite`.
3) Chỉ sửa các lỗi **sai hiển nhiên**: ngữ pháp, chính tả, word form, dấu câu, dùng từ sai rõ rệt.
4) **Không thay bằng từ đồng nghĩa** nếu từ gốc đã đúng về ngữ pháp/nghĩa.
5) **Giới hạn chỉnh sửa**: tổng số token bị thay/chen/xóa ≤ **12%** so với toàn bài; giữ độ dài trong **±8%** so với gốc.
6) **Không lấy nội dung** từ `sampleMid`/`sampleHigh` để dùng cho `rewrite`.
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
  // Mỗi Note 4–6 câu (VI), nêu: điểm mạnh → khoảng trống → việc cần làm → ví dụ ≤20 từ → cảnh báo lỗi hay lặp
  "trNote": "<4–6 câu tiếng Việt bám sát bài; có ví dụ ≤20 từ>",
  "ccNote": "<4–6 câu tiếng Việt bám sát bài; có ví dụ ≤20 từ>",
  "lrNote": "<4–6 câu tiếng Việt bám sát bài; có ví dụ ≤20 từ>",
  "graNote": "<4–6 câu tiếng Việt bám sát bài; có ví dụ ≤20 từ>",

  // MẪU (EN)
  "sampleMid": "Rewritten essay at Band 5.5–6.5 (250–280 words), preserving the original stance, in English.",
  "sampleHigh": "New sample essay at Band 8.0–9.0 (270–320 words), with academic vocabulary and tighter reasoning, in English.",

  "taskType": "<nhắc lại dạng đề>"
}
""";
  }
}