import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/cue_entity.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';
import 'package:english_for_community/core/entity/comment_entity.dart';
import '../../../../core/repository/listening_repository.dart';
import 'cue_event.dart';
import 'cue_state.dart';

class SubmitResult {
  final bool passed;
  final double wer;
  final double cer;

  SubmitResult({required this.passed, required this.wer, required this.cer});
}

class CueBloc extends Bloc<CueEvent, CueState> {
  final ListeningRepository listeningRepository;

  CueBloc({required this.listeningRepository}) : super(CueState.initial()) {
    on<LoadCuesAndAttempts>(_onLoad);
    on<SelectCueByIndex>(_onSelect);
    on<NextCue>(_onNext);
    on<PrevCue>(_onPrev);
    on<UpdateUserAnswer>(_onUpdateAnswer);
    on<LoadCommentsEvent>(_onLoadComments);
    on<PostCommentEvent>(_onPostComment);
    on<IncomingSocketComment>(_onIncomingSocketComment);
    on<ReactToCommentEvent>(_onReactToComment);
    on<IncomingSocketReaction>(_onIncomingSocketReaction);
  }

  Future<void> _onReactToComment(ReactToCommentEvent event, Emitter<CueState> emit) async {
    final updatedComments = state.comments.map((c) {
      if (c.id == event.commentId) {
        final List<ReactionEntity> newReactions = List.from(c.reactions);
        final existingIndex = newReactions.indexWhere((r) => r.userId == event.userId);

        if (existingIndex != -1) {
          if (newReactions[existingIndex].type == event.type) {
            newReactions.removeAt(existingIndex);
          } else {
            newReactions[existingIndex] = ReactionEntity(userId: event.userId, type: event.type);
          }
        } else {
          newReactions.add(ReactionEntity(userId: event.userId, type: event.type));
        }
        return c.copyWith(reactions: newReactions);
      }
      return c;
    }).toList();

    emit(state.copyWith(comments: updatedComments));

    final result = await listeningRepository.reactToComment(
      commentId: event.commentId,
      type: event.type.name,
    );

    result.fold(
            (l) => print("❌ React failed: ${l.message}"),
            (r) => null
    );
  }

  void _onIncomingSocketReaction(IncomingSocketReaction event, Emitter<CueState> emit) {
    if (state.currentCue == null || event.cueId != state.currentCue!.id) {
      return;
    }

    final updatedComments = state.comments.map((c) {
      if (c.id == event.commentId) {
        return c.copyWith(reactions: event.reactions);
      }
      return c;
    }).toList();

    emit(state.copyWith(comments: updatedComments));
  }

  void _onIncomingSocketComment(IncomingSocketComment event, Emitter<CueState> emit) {
    if (state.currentCue == null || event.cueId != state.currentCue!.id) {
      return;
    }

    final currentList = List<CommentEntity>.from(state.comments);
    if (!currentList.any((c) => c.id == event.comment.id)) {
      currentList.insert(0, event.comment);
      emit(state.copyWith(comments: currentList));
    }
  }

  Future<void> _onLoad(LoadCuesAndAttempts e, Emitter<CueState> emit) async {
    // 🔥 CÚ CHỐT: Xóa sạch trí nhớ cũ, trả về state trắng tinh
    emit(CueState.initial().copyWith(status: CueStatus.loading));

    try {
      // 1. Lấy dữ liệu bài học (Không dùng Future.wait nữa)
      final listeningResult = await listeningRepository.getListeningById(e.listeningId);

      List<CueEntity> cues = [];
      String? errorMsg;

      listeningResult.fold((l) => errorMsg = l.message, (r) => cues = r.cues);

      if (errorMsg != null) {
        emit(state.copyWith(status: CueStatus.error, errorMessage: errorMsg));
        return;
      }

      cues.sort((a, b) => (a.startMs ?? 0).compareTo(b.startMs ?? 0));

      final latest = <int, DictationAttemptEntity>{};
      final completedSet = <int>{};

      // 🔥 LOGIC RETAKE: Nếu KHÔNG PHẢI retake thì mới gọi API lấy lịch sử
      if (!e.isRetake) {
        final attemptsResult = await listeningRepository.getDictationAttempts(e.listeningId);

        final attempts = attemptsResult.fold(
              (l) => <DictationAttemptEntity>[],
              (r) => r as List<DictationAttemptEntity>,
        );

        for (final a in attempts) {
          if (a.cueIdx != null) {
            int idx = a.cueIdx!;
            if (idx >= 0 && idx < cues.length) {
              latest[idx] = a;
              final isPassed = (a.score?.passed == true) || ((a.score?.wer ?? 1.0) <= 0.25);
              if (isPassed) completedSet.add(idx);
            }
          }
        }
      } // Nếu isRetake == true -> latest và completedSet sẽ hoàn toàn trống rỗng!

      // 🔥 LOGIC CHỌN CUE BAN ĐẦU
      int selectedIndex = 0;

      if (e.initialCueId != null && e.initialCueId!.isNotEmpty) {
        final foundIndex = cues.indexWhere((c) => c.id == e.initialCueId);
        if (foundIndex != -1) {
          selectedIndex = foundIndex;
        }
      } else {
        for (int i = 0; i < cues.length; i++) {
          if (!completedSet.contains(i)) {
            selectedIndex = i;
            break;
          }
        }
        if (completedSet.length == cues.length && cues.isNotEmpty) {
          selectedIndex = cues.length - 1;
        }
      }

      final initialText = latest[selectedIndex]?.userText ?? '';

      emit(state.copyWith(
        status: CueStatus.success,
        listeningId: e.listeningId,
        cues: cues,
        selectedIndex: selectedIndex,
        userAnswer: initialText,
        latestAttempts: latest,
        completedIdx: completedSet,
        justCompletedAll: completedSet.length >= cues.length,
      ));

      if (cues.isNotEmpty) {
        add(LoadCommentsEvent(cues[selectedIndex].id));
      }
    } catch (err) {
      emit(state.copyWith(status: CueStatus.error, errorMessage: '$err'));
    }
  }

  Future<void> _onLoadComments(LoadCommentsEvent event, Emitter<CueState> emit) async {
    if (state.listeningId.isEmpty) return;

    final int pageToLoad = event.isLoadMore ? state.commentPage + 1 : 1;

    if (event.isLoadMore && state.hasReachedMaxComments) return;

    if (!event.isLoadMore) {
      emit(state.copyWith(isCommentsLoading: true, comments: [], commentPage: 1, hasReachedMaxComments: false));
    }

    final result = await listeningRepository.getCueComments(state.listeningId, event.cueId, pageToLoad);

    result.fold(
          (failure) => emit(state.copyWith(isCommentsLoading: false)),
          (newComments) {
        List<CommentEntity> combinedList;
        if (event.isLoadMore) {
          combinedList = List.from(state.comments)..addAll(newComments);
        } else {
          combinedList = newComments;
        }

        emit(state.copyWith(
          isCommentsLoading: false,
          comments: combinedList,
          commentPage: pageToLoad,
          hasReachedMaxComments: newComments.isEmpty || newComments.length < 20,
        ));
      },
    );
  }

  Future<void> _onPostComment(PostCommentEvent event, Emitter<CueState> emit) async {
    final cue = state.currentCue;
    if (cue == null || state.listeningId.isEmpty) {
      return;
    }

    final result = await listeningRepository.postComment(
      listeningId: state.listeningId,
      cueId: cue.id,
      content: event.content,
      parentId: event.parentId,
    );

    result.fold((failure) => print("❌ Post comment failed: ${failure.message}"),
            (newComment) {
          final currentList = state.comments;
          final exists = currentList.any((c) => c.id == newComment.id);

          if (!exists) {
            final updatedList = List<CommentEntity>.from(currentList);
            updatedList.add(newComment);
            emit(state.copyWith(comments: updatedList));
          }
        });
  }

  Future<SubmitResult> submitCue({
    required String listeningId,
    required int cueIdx,
    required String userText,
    int? playedMs,
    required int durationInSeconds,
  }) async {
    if (cueIdx < 0 || cueIdx >= state.cues.length) {
      return SubmitResult(passed: false, wer: 0, cer: 0);
    }

    final currentCueId = state.cues[cueIdx].id;

    final result = await listeningRepository.submitAttempt(
      listeningId: listeningId,
      answers: [
        {'cueId': currentCueId, 'value': userText}
      ],
      durationInSeconds: durationInSeconds,
    );

    return result.fold(
          (l) => SubmitResult(passed: false, wer: 0, cer: 0),
          (data) {
        final details = data['details'] as List? ?? [];
        final myResult = details.firstWhere(
              (e) => e['cueIdx'] == cueIdx,
          orElse: () => {},
        );

        final isCorrect = myResult['isCorrect'] == true;

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

  void _updateIndex(Emitter<CueState> emit, int rawIdx) {
    final idx = rawIdx.clamp(0, state.cues.length - 1);
    final savedText = state.latestAttempts[idx]?.userText ?? '';
    final newCue = state.cues[idx];

    emit(state.copyWith(
      selectedIndex: idx,
      userAnswer: savedText,
      comments: [],
    ));

    add(LoadCommentsEvent(newCue.id));
  }

  void _onUpdateAnswer(UpdateUserAnswer event, Emitter<CueState> emit) {
    emit(state.copyWith(userAnswer: event.text));
  }
}