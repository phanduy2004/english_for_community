// bloc/cue_bloc.dart
import 'package:english_for_community/core/entity/cue_entity.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repository/cue_repository.dart';
import 'cue_event.dart';
import 'cue_state.dart';

class CueBloc extends Bloc<CueEvent, CueState> {
  final CueRepository cueRepository;

  CueBloc({required this.cueRepository}) : super(CueState.initial()) {
    on<FetchCuesByListeningId>(_onFetch);
    on<LoadCuesAndAttempts>(_onLoad);

    on<SelectCueByIndex>(_onSelect);
    on<NextCue>(_onNext);
    on<PrevCue>(_onPrev);
    on<UpdateUserAnswer>(_onUpdateAnswer);
  }

  // ===== Load cues + attempts (latest per cue) để đánh dấu pass & auto-fill =====
  Future<void> _onLoad(LoadCuesAndAttempts e, Emitter<CueState> emit) async {
    emit(state.copyWith(status: CueStatus.loading, errorMessage: null));
    try {
      // 1) Lấy cues (Either)
      final cuesEither = await cueRepository.getCuesByListeningId(e.listeningId);
      List<CueEntity> cues = const [];

      final cuesOk = cuesEither.fold<bool>(
            (l) {
          emit(state.copyWith(status: CueStatus.error, errorMessage: l.message));
          return false;
        },
            (r) {
          cues = r;
          return true;
        },
      );
      if (!cuesOk) return;

      // 2) Lấy attempts (Either)
      final attemptsEither = await cueRepository.listDictationAttempt(e.listeningId);
      final attempts = attemptsEither.fold<List<DictationAttemptEntity>>(
            (_) => const <DictationAttemptEntity>[],
            (list) => list,
      );

      // 3) Map attempt mới nhất theo cueIdx
      final latest = <int, DictationAttemptEntity>{
        for (final a in attempts) a.cueIdx!: a,
      };

      // 4) Những cue đã pass (chip xanh)
      final passed = latest.entries.where((kv) => kv.value.score!.wer! <= 0.25).map((kv) => kv.key).toSet();

      // 5) Chọn cue đầu & auto-fill
      final sel = cues.isEmpty ? 0 : 0;
      final initialText = latest[sel]?.userText ?? '';

      emit(state.copyWith(
        status: CueStatus.success,
        cues: cues,
        selectedIndex: sel,
        userAnswer: initialText,
        latestAttempts: latest,
        completedIdx: passed,
        justCompletedAll: cues.isNotEmpty && passed.length >= cues.length,
      ));
    } catch (err) {
      emit(state.copyWith(status: CueStatus.error, errorMessage: '$err'));
    }
  }

  // ===== Chỉ load cues (theo format cũ của bạn) =====
  Future _onFetch(FetchCuesByListeningId event, Emitter<CueState> emit) async {
    emit(state.copyWith(status: CueStatus.loading, errorMessage: null));
    final result = await cueRepository.getCuesByListeningId(
      event.listeningId,
      from: event.from,
      limit: event.limit,
    );
    result.fold(
          (l) => emit(state.copyWith(status: CueStatus.error, errorMessage: l.message)),
          (r) => emit(state.copyWith(status: CueStatus.success, cues: r, selectedIndex: 0)),
    );
  }

  // ===== Chọn cue -> auto-fill lại câu trả lời cũ =====
  void _onSelect(SelectCueByIndex event, Emitter<CueState> emit) {
    if (state.cues.isEmpty) return;
    final idx = event.index.clamp(0, state.cues.length - 1);
    final auto = state.latestAttempts[idx]?.userText ?? '';
    emit(state.copyWith(selectedIndex: idx, userAnswer: auto));
  }

  void _onNext(NextCue event, Emitter<CueState> emit) {
    if (state.cues.isEmpty) return;
    final idx = (state.selectedIndex + 1).clamp(0, state.cues.length - 1);
    final auto = state.latestAttempts[idx]?.userText ?? '';
    emit(state.copyWith(selectedIndex: idx, userAnswer: auto));
  }

  void _onPrev(PrevCue event, Emitter<CueState> emit) {
    if (state.cues.isEmpty) return;
    final idx = (state.selectedIndex - 1).clamp(0, state.cues.length - 1);
    final auto = state.latestAttempts[idx]?.userText ?? '';
    emit(state.copyWith(selectedIndex: idx, userAnswer: auto));
  }

  void _onUpdateAnswer(UpdateUserAnswer event, Emitter<CueState> emit) {
    emit(state.copyWith(userAnswer: event.text));
  }

  /// Submit + cập nhật tiến độ (chip xanh) + cache latestAttempts để auto-fill
  Future<SubmitResult> submitCue({
    required String listeningId,
    required int cueIdx,
    required String userText,
    int? playedMs,


  }) async {
    final either = await cueRepository.submitCue(
      listeningId: listeningId,
      cueIdx: cueIdx,
      userText: userText,
      playedMs: playedMs,
    );

    return either.fold(
          (err) {
        return SubmitResult(passed: false, wer: 0, cer: 0);
      },
          (ok) {
        final newLatest = Map<int, DictationAttemptEntity>.from(state.latestAttempts)
          ..[cueIdx] = DictationAttemptEntity(
            id: '',
            listeningId: listeningId,
            cueIdx: cueIdx,
            userText: userText,
            score: DictationScore(wer: ok.wer, cer: ok.cer),
          );

        var done = Set<int>.from(state.completedIdx);
        var completedAll = state.justCompletedAll;
        if (ok.passed) {
          done.add(cueIdx);
          completedAll = done.length == state.cues.length && state.cues.isNotEmpty;
        }

        emit(state.copyWith(
          latestAttempts: newLatest,
          completedIdx: done,
          justCompletedAll: completedAll,
        ));

        return ok;
      },
    );
  }
}
