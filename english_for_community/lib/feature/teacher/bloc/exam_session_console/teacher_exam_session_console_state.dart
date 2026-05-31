import 'package:equatable/equatable.dart';

enum TeacherExamSessionConsoleStatus { initial, loading, success, error }

class TeacherExamSessionConsoleState extends Equatable {
  const TeacherExamSessionConsoleState({
    required this.status,
    this.errorMessage,
    this.assignmentContext,
    this.session,
    this.participants = const [],
    this.joinedCount = 0,
    this.readyCount = 0,
    this.liveMonitor,
    this.busy = false,
    this.boundSessionId,
  });

  final TeacherExamSessionConsoleStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? assignmentContext;
  final Map<String, dynamic>? session;
  final List<Map<String, dynamic>> participants;
  final int joinedCount;
  final int readyCount;
  final Map<String, dynamic>? liveMonitor;
  final bool busy;
  final String? boundSessionId;

  String? get sessionId => session?['id'] as String? ?? session?['_id']?.toString();
  String get sessionStatus => (session?['status'] as String?) ?? 'lobby';
  bool get isLobby => sessionStatus == 'lobby';
  bool get isLive => sessionStatus == 'live';

  factory TeacherExamSessionConsoleState.initial() =>
      const TeacherExamSessionConsoleState(status: TeacherExamSessionConsoleStatus.initial);

  TeacherExamSessionConsoleState copyWith({
    TeacherExamSessionConsoleStatus? status,
    String? errorMessage,
    Map<String, dynamic>? assignmentContext,
    Map<String, dynamic>? session,
    List<Map<String, dynamic>>? participants,
    int? joinedCount,
    int? readyCount,
    Map<String, dynamic>? liveMonitor,
    bool? busy,
    String? boundSessionId,
    bool clearError = false,
    bool clearLiveMonitor = false,
  }) {
    return TeacherExamSessionConsoleState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      assignmentContext: assignmentContext ?? this.assignmentContext,
      session: session ?? this.session,
      participants: participants ?? this.participants,
      joinedCount: joinedCount ?? this.joinedCount,
      readyCount: readyCount ?? this.readyCount,
      liveMonitor: clearLiveMonitor ? null : (liveMonitor ?? this.liveMonitor),
      busy: busy ?? this.busy,
      boundSessionId: boundSessionId ?? this.boundSessionId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        assignmentContext,
        session,
        participants,
        joinedCount,
        readyCount,
        liveMonitor,
        busy,
        boundSessionId,
      ];
}
