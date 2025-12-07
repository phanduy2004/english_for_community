import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/cue_entity.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';
import 'package:english_for_community/core/entity/comment_entity.dart';

enum CueStatus { initial, loading, success, error }

class CueState extends Equatable {
  final CueStatus status;
  final String? errorMessage;
  final String listeningId;
  final List<CueEntity> cues;
  final int selectedIndex;
  final String userAnswer;
  final Set<int> completedIdx;
  final Map<int, DictationAttemptEntity> latestAttempts;
  final bool justCompletedAll;
  final List<CommentEntity> comments;
  final bool isCommentsLoading;
  final int commentPage;
  final bool hasReachedMaxComments;

  const CueState({
    required this.status,
    this.errorMessage,
    required this.listeningId,
    required this.cues,
    required this.selectedIndex,
    required this.userAnswer,
    required this.completedIdx,
    required this.latestAttempts,
    required this.justCompletedAll,
    required this.comments,
    required this.isCommentsLoading,
    this.commentPage = 1,
    this.hasReachedMaxComments = false,
  });

  factory CueState.initial() => const CueState(
    status: CueStatus.initial,
    listeningId: '',
    cues: [],
    selectedIndex: 0,
    userAnswer: '',
    errorMessage: null,
    completedIdx: {},
    latestAttempts: {},
    justCompletedAll: false,
    comments: [],
    isCommentsLoading: false,
    commentPage: 1,
    hasReachedMaxComments: false,
  );

  CueState copyWith({
    CueStatus? status,
    String? errorMessage,
    String? listeningId,
    List<CueEntity>? cues,
    int? selectedIndex,
    String? userAnswer,
    Set<int>? completedIdx,
    Map<int, DictationAttemptEntity>? latestAttempts,
    bool? justCompletedAll,
    List<CommentEntity>? comments,
    bool? isCommentsLoading,
    int? commentPage,
    bool? hasReachedMaxComments,
  }) {
    return CueState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      listeningId: listeningId ?? this.listeningId,
      cues: cues ?? this.cues,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      userAnswer: userAnswer ?? this.userAnswer,
      completedIdx: completedIdx ?? this.completedIdx,
      latestAttempts: latestAttempts ?? this.latestAttempts,
      justCompletedAll: justCompletedAll ?? this.justCompletedAll,
      comments: comments ?? this.comments,
      isCommentsLoading: isCommentsLoading ?? this.isCommentsLoading,
      commentPage: commentPage ?? this.commentPage,
      hasReachedMaxComments: hasReachedMaxComments ?? this.hasReachedMaxComments,
    );
  }

  CueEntity? get currentCue =>
      cues.isEmpty ? null : cues[selectedIndex.clamp(0, cues.length - 1)];

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    listeningId,
    cues,
    selectedIndex,
    userAnswer,
    completedIdx,
    latestAttempts,
    justCompletedAll,
    comments,
    isCommentsLoading,
    commentPage,
    hasReachedMaxComments,
  ];
}