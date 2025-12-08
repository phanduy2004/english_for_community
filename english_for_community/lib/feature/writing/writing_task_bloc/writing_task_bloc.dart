import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart';
import 'package:english_for_community/core/repository/writing_repository.dart';

import 'writing_task_event.dart';
import 'writing_task_state.dart';

class WritingTaskBloc extends Bloc<WritingTaskEvent, WritingTaskState> {
  final WritingRepository _writingRepo;

  WritingTaskBloc({required WritingRepository writingRepository})
      : _writingRepo = writingRepository,
        super(const WritingTaskState()) {
    on<GeneratePromptAndStartTask>(_onGeneratePrompt);
    on<SubmitForFeedback>(_onSubmitForFeedback);
    on<DiscardDraftAndStartNew>(_onDiscardDraftAndStartNew);
    on<SaveDraftEvent>(_onSaveDraft);
  }

  // --- 1. LƯU NHÁP (GIỮ NGUYÊN) ---
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

  // --- 2. XÓA NHÁP CŨ & TẠO MỚI (GIỮ NGUYÊN LOGIC) ---
  Future<void> _onDiscardDraftAndStartNew(
      DiscardDraftAndStartNew event,
      Emitter<WritingTaskState> emit,
      ) async {
    emit(state.copyWith(status: WritingTaskStatus.loading));

    final deleteResult =
    await _writingRepo.deleteSubmission(event.oldSubmissionId);

    await deleteResult.fold(
          (failure) async {
        emit(state.copyWith(
            status: WritingTaskStatus.error,
            errorMessage: "Cannot delete old draft: ${failure.message}"));
      },
          (success) async {
        // Sau khi xóa xong, gọi lại event tạo đề mới
        add(GeneratePromptAndStartTask(
          topic: event.topic,
          userId: event.userId,
          taskType: event.taskType,
        ));
      },
    );
  }

  // --- 3. TẠO ĐỀ (LOGIC MỚI: GỌI SERVER XỬ LÝ) ---
  Future<void> _onGeneratePrompt(
      GeneratePromptAndStartTask event,
      Emitter<WritingTaskState> emit,
      ) async {
    emit(state.copyWith(status: WritingTaskStatus.loading, topic: event.topic));

    try {
      // Gọi xuống Repo -> Datasource -> API Backend
      // Backend sẽ tự check Draft cũ, hoặc gọi AI Service để tạo đề mới
      final startResultEither = await _writingRepo.startWriting(
        topicId: event.topic.id,
        userId: event.userId,
        taskType: event.taskType, // Chỉ cần gửi taskType
      );

      await startResultEither.fold(
            (failure) {
          emit(state.copyWith(
            status: WritingTaskStatus.error,
            errorMessage: failure.message,
          ));
        },
            (result) async {
          // Server trả về cấu trúc gồm submissionId, generatedPrompt, content (nếu resume)
          final submission = WritingSubmissionEntity(
            id: result.submissionId,
            topicId: event.topic.id,
            generatedPrompt: result.generatedPrompt,
            status: 'draft',
            userId: event.userId,
            content: result.content, // Content cũ nếu là resume draft
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
          errorMessage: "Failed to start task: ${e.toString()}"));
    }
  }

  // --- 4. CHẤM BÀI (LOGIC MỚI: GỌI SERVER XỬ LÝ) ---
  Future<void> _onSubmitForFeedback(
      SubmitForFeedback event,
      Emitter<WritingTaskState> emit,
      ) async {
    // 1. Client-side validation để đỡ tốn resource server
    if (isLikelyGibberish(event.essayContent)) {
      emit(state.copyWith(
        status: WritingTaskStatus.error,
        errorMessage: "Bài nộp không hợp lệ (quá ngắn hoặc spam).",
      ));
      return;
    }

    emit(state.copyWith(status: WritingTaskStatus.submitting));

    try {
      // Gọi xuống Repo -> API Backend
      // Backend sẽ tự gọi AI Service chấm điểm và lưu vào DB
      final updatedSubmissionEither = await _writingRepo.submitForReview(
        submissionId: event.submissionId,
        content: event.essayContent,
        durationInSeconds: event.durationInSeconds,
      );

      await updatedSubmissionEither.fold(
            (failure) {
          emit(state.copyWith(
              status: WritingTaskStatus.error, errorMessage: failure.message));
        },
            (updatedSubmission) {
          // Thành công: Server trả về submission đã có điểm và feedback
          emit(state.copyWith(
            status: WritingTaskStatus.success,
            submission: updatedSubmission,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
          status: WritingTaskStatus.error,
          errorMessage: "Failed to submit: ${e.toString()}"));
    }
  }

  // --- HELPER METHODS ---

  // Giữ nguyên logic check spam ở client để tiết kiệm request rác lên server
  bool isLikelyGibberish(String s) {
    final text = s.trim();
    final words = text.isEmpty ? [] : text.split(RegExp(r'\s+'));

    // Nếu quá ngắn (< 30 từ chẳng hạn, tùy bạn chỉnh) thì chặn luôn
    // Logic cũ của bạn là < 150 words -> Tùy nhu cầu, mình giữ nguyên logic cũ
    if (words.length < 50) return true; // Mình giảm xuống 50 để test cho dễ, bạn có thể để 150

    final alpha = RegExp(r'[A-Za-zÀ-ỹ]');
    final alphaCount = alpha.allMatches(text).length;
    final total = text.runes.length;
    final alphaRatio = total == 0 ? 0 : alphaCount / total;
    if (alphaRatio < 0.6) return true; // Ký tự lạ quá nhiều

    final repeated = RegExp(r'(.)\1{6,}'); // Ký tự lặp lại aaaaaaa
    if (repeated.hasMatch(text)) return true;

    final avgLen = words.isEmpty
        ? 0
        : text.replaceAll(RegExp(r'\s+'), '').length / words.length;
    if (avgLen < 3) return true; // Từ quá ngắn, vô nghĩa (e.g. "a b c d")

    return false;
  }
}