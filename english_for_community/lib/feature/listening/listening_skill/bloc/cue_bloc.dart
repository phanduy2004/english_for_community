import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/cue_entity.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';
import '../../../../core/repository/cue_repository.dart';
import '../../../../core/repository/listening_repository.dart';
import 'cue_event.dart';
import 'cue_state.dart';

class CueBloc extends Bloc<CueEvent, CueState> {
  final ListeningRepository listeningRepository;

  CueBloc({required this.listeningRepository}) : super(CueState.initial()) {
    on<LoadCuesAndAttempts>(_onLoad);
    on<SelectCueByIndex>(_onSelect);
    on<NextCue>(_onNext);
    on<PrevCue>(_onPrev);
    on<UpdateUserAnswer>(_onUpdateAnswer);
  }

  Future<void> _onLoad(LoadCuesAndAttempts e, Emitter<CueState> emit) async {
    emit(state.copyWith(status: CueStatus.loading));
    try {
      final results = await Future.wait([
        listeningRepository.getListeningById(e.listeningId),
        listeningRepository.getDictationAttempts(e.listeningId)
      ]);

      final listeningResult = results[0] as dynamic;
      final attemptsResult = results[1] as dynamic;

      List<CueEntity> cues = [];
      String? errorMsg;

      listeningResult.fold((l) => errorMsg = l.message, (r) => cues = r.cues);

      if (errorMsg != null) {
        emit(state.copyWith(status: CueStatus.error, errorMessage: errorMsg));
        return;
      }

      // 1. Sort lại để đảm bảo thứ tự
      cues.sort((a, b) => (a.startMs ?? 0).compareTo(b.startMs ?? 0));

      final attempts = attemptsResult.fold(
            (l) => <DictationAttemptEntity>[],
            (r) => r as List<DictationAttemptEntity>,
      );

      final latest = <int, DictationAttemptEntity>{};
      final completedSet = <int>{};

      for (final a in attempts) {
        if (a.cueIdx != null) {
          int idx = a.cueIdx!;

          // 🔥 SỬA LỖI Ở ĐÂY: KHÔNG TRỪ 1 NỮA
          // Vì Server của bạn trả về cueIdx: 1 cho câu số 2 => Server là 0-based (Chuẩn).
          // Ta dùng trực tiếp idx.

          if (idx >= 0 && idx < cues.length) {
            latest[idx] = a;

            final isPassed = (a.score?.passed == true) || ((a.score?.wer ?? 1.0) <= 0.25);
            if (isPassed) {
              completedSet.add(idx);
            }
          }
        }
      }

      // 2. Tìm câu đầu tiên chưa làm
      int firstIncomplete = 0;
      for (int i = 0; i < cues.length; i++) {
        if (!completedSet.contains(i)) {
          firstIncomplete = i;
          break;
        }
      }
      if (completedSet.length == cues.length && cues.isNotEmpty) {
        firstIncomplete = cues.length - 1;
      }

      final initialText = latest[firstIncomplete]?.userText ?? '';

      emit(state.copyWith(
        status: CueStatus.success,
        cues: cues,
        selectedIndex: firstIncomplete,
        userAnswer: initialText,
        latestAttempts: latest,
        completedIdx: completedSet,
        justCompletedAll: completedSet.length >= cues.length,
      ));
    } catch (err) {
      emit(state.copyWith(status: CueStatus.error, errorMessage: '$err'));
    }
  }

  Future<SubmitResult> submitCue({
    required String listeningId,
    required int cueIdx, // Index hiện tại trên UI
    required String userText,
    int? playedMs,
    required int durationInSeconds,
  }) async {
    // Lấy đúng ID của câu hỏi hiện tại để gửi lên Server
    final currentCueId = state.cues[cueIdx].id;

    final result = await listeningRepository.submitAttempt(
      listeningId: listeningId,
      answers: [{'cueId': currentCueId, 'value': userText}],
      durationInSeconds: durationInSeconds,
    );

    return result.fold(
          (l) => SubmitResult(passed: false, wer: 0, cer: 0),
          (data) {
        final details = data['details'] as List? ?? [];

        // 🔥 FIX LỖI Ở ĐÂY: Tìm đúng kết quả khớp với cueId hoặc cueIdx
        final myResult = details.firstWhere(
              (e) => e['cueIdx'] == cueIdx, // Tìm phần tử có index khớp với câu đang làm
          orElse: () => {},             // Nếu không thấy thì trả về rỗng
        );

        // Kiểm tra xem backend báo đúng hay sai
        final isCorrect = myResult['isCorrect'] == true;

        // Cập nhật State Local
        final newLatest = Map<int, DictationAttemptEntity>.from(state.latestAttempts);
        newLatest[cueIdx] = DictationAttemptEntity(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          listeningId: listeningId,
          cueIdx: cueIdx,
          userText: userText,
          score: DictationScore(passed: isCorrect, wer: isCorrect ? 0.0 : 1.0),
        );

        final newCompleted = Set<int>.from(state.completedIdx);
        if (isCorrect) newCompleted.add(cueIdx);

        final isAllDone = state.cues.isNotEmpty && newCompleted.length == state.cues.length;

        emit(state.copyWith(
          latestAttempts: newLatest,
          completedIdx: newCompleted,
          justCompletedAll: isAllDone,
        ));

        // Trả về kết quả thực tế từ Backend
        return SubmitResult(passed: isCorrect, wer: 0, cer: 0);
      },
    );
  }
  void _onSelect(SelectCueByIndex event, Emitter<CueState> emit) {
    if (state.cues.isEmpty) return;
    _updateIndex(emit, event.index);
  }

  void _onNext(NextCue event, Emitter<CueState> emit) {
    if (state.cues.isEmpty) return;
    _updateIndex(emit, state.selectedIndex + 1);
  }

  void _onPrev(PrevCue event, Emitter<CueState> emit) {
    if (state.cues.isEmpty) return;
    _updateIndex(emit, state.selectedIndex - 1);
  }

  // Hàm chuyển câu chuẩn: Cập nhật index VÀ lấy lại text cũ từ lịch sử
  void _updateIndex(Emitter<CueState> emit, int rawIdx) {
    final idx = rawIdx.clamp(0, state.cues.length - 1);
    final savedText = state.latestAttempts[idx]?.userText ?? '';

    emit(state.copyWith(
      selectedIndex: idx,
      userAnswer: savedText,
    ));
  }

  void _onUpdateAnswer(UpdateUserAnswer event, Emitter<CueState> emit) {
    emit(state.copyWith(userAnswer: event.text));
  }
}