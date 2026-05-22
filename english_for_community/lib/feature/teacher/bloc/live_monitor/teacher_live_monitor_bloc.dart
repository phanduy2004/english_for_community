import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Merges socket/API live payloads without resetting UI focus from progress-only events.
Map<String, dynamic> mergeTeacherLivePayload(
  Map<String, dynamic> prev,
  Map<String, dynamic> patch,
) {
  final merged = Map<String, dynamic>.from({...prev, ...patch});
  final hasLiveView = patch['liveView'] is Map;
  if (hasLiveView) {
    final pLv = Map<String, dynamic>.from(patch['liveView'] as Map);
    final oLv = prev['liveView'] is Map ? Map<String, dynamic>.from(prev['liveView'] as Map) : <String, dynamic>{};
    merged['liveView'] = {...oLv, ...pLv};
  } else {
    if (prev['liveView'] is Map) merged['liveView'] = prev['liveView'];
    for (final k in ['currentItemId', 'currentItemKind', 'currentItemLabel']) {
      if (prev[k] != null) merged[k] = prev[k];
    }
  }
  if (patch['answers'] is Map) {
    final pA = Map<String, dynamic>.from(patch['answers'] as Map);
    final oA = prev['answers'] is Map ? Map<String, dynamic>.from(prev['answers'] as Map) : <String, dynamic>{};
    final nextA = Map<String, dynamic>.from(oA);
    for (final entry in pA.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is Map && nextA[key] is Map) {
        nextA[key] = {
          ...Map<String, dynamic>.from(nextA[key] as Map),
          ...Map<String, dynamic>.from(val),
        };
      } else {
        nextA[key] = val;
      }
    }
    merged['answers'] = nextA;
  }
  if (patch['examSnapshot'] is Map) {
    merged['examSnapshot'] = patch['examSnapshot'];
  }
  if (patch['skillStrips'] is List) {
    merged['skillStrips'] = patch['skillStrips'];
  }
  return merged;
}

class TeacherLiveMonitorBloc extends Bloc<TeacherLiveMonitorEvent, TeacherLiveMonitorState> {
  TeacherLiveMonitorBloc({
    required this.repository,
    required this.socketService,
    required this.sessionId,
  }) : super(TeacherLiveMonitorState.initial()) {
    on<TeacherLiveMonitorStarted>(_onStarted);
    on<TeacherLiveMonitorProgressUpdated>(_onProgress);
    on<TeacherLiveMonitorRefreshRequested>(_onRefresh);
    on<TeacherLiveMonitorFilterChanged>(_onFilter);
    on<TeacherLiveMonitorStopped>(_onStopped);
  }

  final TeacherExamRepository repository;
  final SocketService socketService;
  final String sessionId;
  void Function(Map<String, dynamic>)? _onLiveProgress;
  void Function(Map<String, dynamic>)? _onLiveScreen;

  void _ingestSnapshot(Map<String, dynamic> data, Emitter<TeacherLiveMonitorState> emit) {
    final raw = data['students'];
    final students = raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};
    emit(state.copyWith(
      status: TeacherLiveMonitorStatus.success,
      students: students,
      summary: summary,
      clearError: true,
    ));
  }

  Map<String, dynamic> _summaryFromStudents(List<Map<String, dynamic>> students) {
    final total = students.length;
    final inProgress = students.where((s) => s['status'] == 'in_progress').length;
    final submitted = students
        .where((s) => ['submitted', 'expired', 'void'].contains(s['status']))
        .length;
    final flagged = students
        .where((s) => s['integrityRiskLevel'] == 'high' || s['integrityRiskLevel'] == 'medium')
        .length;
    final avg = total == 0
        ? 0.0
        : students.fold<double>(0, (sum, s) => sum + ((s['progressPercent'] as num?)?.toDouble() ?? 0)) /
            total;
    return {
      'total': total,
      'inProgress': inProgress,
      'submitted': submitted,
      'flagged': flagged,
      'avgProgressPercent': (avg * 10).round() / 10,
    };
  }

  Map<String, dynamic> _mergeStudentLiveRow(
    Map<String, dynamic> prev,
    Map<String, dynamic> patch,
  ) =>
      mergeTeacherLivePayload(prev, patch);

  Future<void> _onStarted(
    TeacherLiveMonitorStarted event,
    Emitter<TeacherLiveMonitorState> emit,
  ) async {
    emit(state.copyWith(status: TeacherLiveMonitorStatus.loading, clearError: true));

    _onLiveProgress = (payload) {
      if (payload['sessionId']?.toString() != sessionId) return;
      add(TeacherLiveMonitorProgressUpdated(payload));
    };
    _onLiveScreen = (payload) {
      if (payload['sessionId']?.toString() != sessionId) return;
      add(TeacherLiveMonitorProgressUpdated(payload));
    };
    socketService.listenExamSessionLiveProgress(_onLiveProgress!);
    socketService.listenExamSessionLiveScreen(_onLiveScreen!);

    final initial = event.initialSnapshot;
    if (initial != null && initial.isNotEmpty) {
      _ingestSnapshot(initial, emit);
    } else {
      await _fetchSnapshot(emit);
    }
  }

  Future<void> _fetchSnapshot(Emitter<TeacherLiveMonitorState> emit) async {
    final r = await repository.getSessionLiveMonitor(sessionId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherLiveMonitorStatus.error,
        errorMessage: f.message,
      )),
      (data) {
        if (data is Map) _ingestSnapshot(Map<String, dynamic>.from(data), emit);
      },
    );
  }

  void _onProgress(
    TeacherLiveMonitorProgressUpdated event,
    Emitter<TeacherLiveMonitorState> emit,
  ) {
    final userId = event.payload['userId']?.toString();
    if (userId == null || userId.isEmpty) return;

    final list = List<Map<String, dynamic>>.from(state.students);
    final idx = list.indexWhere((s) => s['userId']?.toString() == userId);
    if (idx >= 0) {
      list[idx] = _mergeStudentLiveRow(list[idx], event.payload);
    } else {
      list.add(Map<String, dynamic>.from(event.payload));
    }
    emit(state.copyWith(
      students: list,
      summary: _summaryFromStudents(list),
    ));
  }

  Future<void> _onRefresh(
    TeacherLiveMonitorRefreshRequested event,
    Emitter<TeacherLiveMonitorState> emit,
  ) async {
    emit(state.copyWith(status: TeacherLiveMonitorStatus.loading, clearError: true));
    await _fetchSnapshot(emit);
  }

  void _onFilter(
    TeacherLiveMonitorFilterChanged event,
    Emitter<TeacherLiveMonitorState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onStopped(
    TeacherLiveMonitorStopped event,
    Emitter<TeacherLiveMonitorState> emit,
  ) {
    _detachLiveListeners();
  }

  void _detachLiveListeners() {
    if (_onLiveProgress != null) {
      socketService.offExamSessionLiveProgress(_onLiveProgress);
      _onLiveProgress = null;
    }
    if (_onLiveScreen != null) {
      socketService.offExamSessionLiveScreen(_onLiveScreen);
      _onLiveScreen = null;
    }
  }

  @override
  Future<void> close() {
    _detachLiveListeners();
    return super.close();
  }
}
