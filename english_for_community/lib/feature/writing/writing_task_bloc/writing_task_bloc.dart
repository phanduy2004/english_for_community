import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart';
import 'package:english_for_community/core/repository/writing_repository.dart';

// Import 2 file vừa tách
import 'writing_task_event.dart';
import 'writing_task_state.dart';

const String GEMINI_API_KEY = 'AIzaSyBQ8dueXPQyHPfjg2-mPgB8BP6E5wbVVF0';

class WritingTaskBloc extends Bloc<WritingTaskEvent, WritingTaskState> {
  final WritingRepository _writingRepo;
  final GenerativeModel _geminiModel;

  WritingTaskBloc({required WritingRepository writingRepository})
      : _writingRepo = writingRepository,
        _geminiModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: GEMINI_API_KEY,
          generationConfig: GenerationConfig(
            temperature: 0.2,
            topK: 30,
            topP: 0.9,
          ),
        ),
        super(const WritingTaskState()) {
    on<GeneratePromptAndStartTask>(_onGeneratePrompt);
    on<SubmitForFeedback>(_onSubmitForFeedback);
    on<DiscardDraftAndStartNew>(_onDiscardDraftAndStartNew);
    on<SaveDraftEvent>(_onSaveDraft);
  }

  // --- 1. LƯU NHÁP ---
  Future<void> _onSaveDraft(
      SaveDraftEvent event,
      Emitter<WritingTaskState> emit,
      ) async {
    final result = await _writingRepo.saveDraft(
      submissionId: event.submissionId,
      content: event.content,
    );

    result.fold(
          (failure) {
        emit(state.copyWith(
          status: WritingTaskStatus.error,
          errorMessage: "Failed to save draft: ${failure.message}",
        ));
      },
          (success) {
        emit(state.copyWith(status: WritingTaskStatus.savedSuccess));
      },
    );
  }

  // --- 2. XÓA NHÁP CŨ & TẠO MỚI ---
  Future<void> _onDiscardDraftAndStartNew(
      DiscardDraftAndStartNew event,
      Emitter<WritingTaskState> emit,
      ) async {
    emit(state.copyWith(status: WritingTaskStatus.loading));

    final deleteResult = await _writingRepo.deleteSubmission(event.oldSubmissionId);

    await deleteResult.fold(
          (failure) async {
        emit(state.copyWith(
            status: WritingTaskStatus.error,
            errorMessage: "Cannot delete old draft: ${failure.message}"
        ));
      },
          (success) async {
        add(GeneratePromptAndStartTask(
          topic: event.topic,
          userId: event.userId,
          taskType: event.taskType,
        ));
      },
    );
  }

  // --- 3. TẠO ĐỀ ---
  Future<void> _onGeneratePrompt(GeneratePromptAndStartTask event,
      Emitter<WritingTaskState> emit,) async {
    emit(state.copyWith(status: WritingTaskStatus.loading, topic: event.topic));
    try {
      final topic = event.topic;

      // 👇 GIỮ NGUYÊN PROMPT CŨ CỦA BẠN
      final promptTemplate = topic.aiConfig?.generationTemplate ??
          'Generate an IELTS Writing Task 2 prompt for the topic: "${topic.name}". '
              'Task type: ${event.taskType}. '
              'Level: ${topic.aiConfig?.level ?? "Intermediate"}. '
              'Target word count: ${topic.aiConfig?.targetWordCount ?? "250–320"}. '
              'Respond in JSON format: {"title": "...", "text": "..."}';

      final geminiResponse = await _geminiModel.generateContent([
        Content.text(promptTemplate)
      ]);

      if (geminiResponse.text == null) {
        throw Exception('Gemini returned no data for prompt');
      }

      final cleanJson = _cleanGeminiJson(geminiResponse.text!);
      final Map<String, dynamic> generatedPromptMap = jsonDecode(cleanJson);

      final generatedPromptEntity = GeneratedPrompt(
        title: generatedPromptMap['title'] as String?,
        text: generatedPromptMap['text'] as String?,
        taskType: event.taskType,
        level: topic.aiConfig?.level ?? "Intermediate",
      );

      final startResultEither = await _writingRepo.startWriting(
        topicId: topic.id,
        userId: event.userId,
        generatedPrompt: generatedPromptEntity,
      );

      await startResultEither.fold(
            (failure) {
          emit(state.copyWith(
            status: WritingTaskStatus.error,
            errorMessage: failure.message,
          ));
        },
            (result) async {
          final submission = WritingSubmissionEntity(
            id: result.submissionId,
            topicId: topic.id,
            generatedPrompt: result.generatedPrompt,
            status: 'draft',
            userId: event.userId,
            content: result.content, // Lấy nội dung từ API (quan trọng cho Resume)
          );

          emit(state.copyWith(
            status: WritingTaskStatus.promptReady,
            submission: submission,
          ));
        },
      );

    } catch (e) {
      emit(state.copyWith(
          status: WritingTaskStatus.error,
          errorMessage: "Failed to parse prompt: ${e.toString()}"));
    }
  }

  // --- 4. CHẤM BÀI (FEEDBACK) ---
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
      final feedbackPrompt = _buildFeedbackPrompt(
        essayText: event.essayContent,
        taskType: event.taskType,
      );

      final geminiResponse = await _geminiModel.generateContent([
        Content.text(feedbackPrompt)
      ]);

      if (geminiResponse.text == null) {
        throw Exception('Gemini returned no data for feedback');
      }

      final cleanJson = _cleanGeminiJson(geminiResponse.text!);
      final Map<String, dynamic> feedbackMap = jsonDecode(cleanJson);
      final FeedbackEntity feedback = FeedbackEntity.fromJson(feedbackMap);

      final updatedSubmissionEither = await _writingRepo.submitForReview(
        submissionId: event.submissionId,
        content: event.essayContent,
        feedback: feedback,
        durationInSeconds: event.durationInSeconds,
      );

      await updatedSubmissionEither.fold(
              (failure) {
            emit(state.copyWith(
                status: WritingTaskStatus.error,
                errorMessage: failure.message
            ));
          },
              (updatedSubmission) {
            emit(state.copyWith(
              status: WritingTaskStatus.success,
              submission: updatedSubmission,
            ));
          }
      );

    } catch (e) {
      emit(state.copyWith(
          status: WritingTaskStatus.error,
          errorMessage: "Failed to parse feedback: ${e.toString()}"));
    }
  }

  // --- HELPER METHODS ---

  String _cleanGeminiJson(String rawResponse) {
    final regExp = RegExp(r'```(json)?([\s\S]*)```');
    final match = regExp.firstMatch(rawResponse);
    if (match != null) {
      return match.group(2)!.trim();
    }
    return rawResponse.trim();
  }

  bool isLikelyGibberish(String s) {
    final text = s.trim();
    final words = text.isEmpty ? [] : text.split(RegExp(r'\s+'));
    if (words.length < 150) return true;

    final alpha = RegExp(r'[A-Za-zÀ-ỹ]');
    final alphaCount = alpha.allMatches(text).length;
    final total = text.runes.length;
    final alphaRatio = total == 0 ? 0 : alphaCount / total;
    if (alphaRatio < 0.6) return true;

    final repeated = RegExp(r'(.)\1{6,}');
    if (repeated.hasMatch(text)) return true;

    final avgLen = words.isEmpty ? 0 : text.replaceAll(RegExp(r'\s+'), '').length / words.length;
    if (avgLen < 3) return true;

    return false;
  }

  // 👇 GIỮ NGUYÊN PROMPT CŨ CỦA BẠN KHÔNG SỬA ĐỔI
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