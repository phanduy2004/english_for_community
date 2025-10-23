// lib/feature/listening/bloc/cue_state.dart
import 'package:english_for_community/core/entity/cue_entity.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';
import 'package:equatable/equatable.dart';


enum CueStatus { initial, loading, success, error }

class CueState extends Equatable {
  final CueStatus status;
  final String? errorMessage;
  final List<CueEntity> cues;
  final int selectedIndex;
  final String userAnswer;

  /// Cue đã pass để tô chip xanh ✓
  final Set<int> completedIdx;

  /// Attempt mới nhất theo cueIdx (để autofill)
  final Map<int, DictationAttemptEntity> latestAttempts;

  final bool justCompletedAll;

  const CueState({
    required this.status,
    this.errorMessage,
    required this.cues,
    required this.selectedIndex,
    required this.userAnswer,
    required this.completedIdx,
    required this.latestAttempts,
    required this.justCompletedAll,
  });

  factory CueState.initial() => const CueState(
    status: CueStatus.initial,
    cues: [],
    selectedIndex: 0,
    userAnswer: '',
    errorMessage: null,
    completedIdx: {},
    latestAttempts: {},
    justCompletedAll: false,
  );

  CueState copyWith({
    CueStatus? status,
    String? errorMessage,
    List<CueEntity>? cues,
    int? selectedIndex,
    String? userAnswer,
    Set<int>? completedIdx,
    Map<int, DictationAttemptEntity>? latestAttempts,
    bool? justCompletedAll,
  }) {
    return CueState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      cues: cues ?? this.cues,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      userAnswer: userAnswer ?? this.userAnswer,
      completedIdx: completedIdx ?? this.completedIdx,
      latestAttempts: latestAttempts ?? this.latestAttempts,
      justCompletedAll: justCompletedAll ?? this.justCompletedAll,
    );
  }

  CueEntity? get currentCue =>
      cues.isEmpty ? null : cues[selectedIndex.clamp(0, cues.length - 1)];

  @override
  List<Object?> get props =>
      [status, errorMessage, cues, selectedIndex, userAnswer, completedIdx, latestAttempts, justCompletedAll];
}
