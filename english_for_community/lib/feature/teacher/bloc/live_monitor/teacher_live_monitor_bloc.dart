import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Merges socket/API live payloads without resetting UI focus from progress-only events.
Map<String, dynamic> mergeTeacherLivePayload(
  Map<String, dynamic> prev,
  Map<String, dynamic> patch,
) {
  final merged = Map<String, dynamic>.from({...prev, ...patch});
  if (patch.containsKey('status') && patch['status'] != null) {
    merged['status'] = patch['status'];
  }
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

  void _emitStudents(
    List<Map<String, dynamic>> students,
    Emitter<TeacherLiveMonitorState> emit, {
    Map<String, dynamic>? summary,
    TeacherLiveMonitorStatus? status,
    bool clearError = false,
  }) {
    final enriched = students.map(enrichLiveMonitorStudentRow).toList();
    final nextSummary = summary ?? summaryFromLiveMonitorStudents(enriched);
    final nextVisible = filterLiveMonitorStudents(enriched, state.filter);

    if (status == null &&
        !clearError &&
        state.status == TeacherLiveMonitorStatus.success &&
        _sameEnrichedRoster(state.students, enriched) &&
        mapEquals(state.summary, nextSummary) &&
        _sameEnrichedRoster(state.visibleStudents, nextVisible)) {
      return;
    }

    emit(state.copyWith(
      status: status ?? state.status,
      students: enriched,
      summary: nextSummary,
      visibleStudents: nextVisible,
      studentsByUserId: indexLiveMonitorStudents(enriched),
      dataRevision: state.dataRevision + 1,
      clearError: clearError,
    ));
  }

  bool _sameEnrichedRoster(List<Map<String, dynamic>> before, List<Map<String, dynamic>> after) {
    if (before.length != after.length) return false;
    final afterById = indexLiveMonitorStudents(after);
    for (final s in before) {
      final id = s['userId']?.toString();
      if (id == null || id.isEmpty) return false;
      final other = afterById[id];
      if (other == null || liveMonitorRowVisualChanged(s, other)) return false;
    }
    return true;
  }

  void _ingestSnapshot(Map<String, dynamic> data, Emitter<TeacherLiveMonitorState> emit) {
    final raw = data['students'];
    final students = raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : null;
    _emitStudents(
      students,
      emit,
      summary: summary,
      status: TeacherLiveMonitorStatus.success,
      clearError: true,
    );
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

    // Gỡ listener cũ trước khi đăng ký lại — tránh rò nếu _onStarted chạy lại.
    _detachLiveListeners();
    _onLiveProgress = (payload) {
      if (payload['sessionId']?.toString() != sessionId) return;
      add(TeacherLiveMonitorProgressUpdated(payload));
    };
    // CHỈ nghe live_progress cho roster — backend phát cùng payload trên cả 2 event,
    // nghe thêm live_screen chỉ khiến mỗi cập nhật bị xử lý 2 lần (thừa).
    socketService.listenExamSessionLiveProgress(_onLiveProgress!);

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
    if (!liveMonitorPatchAffectsRosterUi(event.payload)) return;

    final userId = event.payload['userId']?.toString();
    if (userId == null || userId.isEmpty) return;

    final list = List<Map<String, dynamic>>.from(state.students);
    final idx = list.indexWhere((s) => s['userId']?.toString() == userId);
    final merged = idx >= 0
        ? _mergeStudentLiveRow(list[idx], event.payload)
        : Map<String, dynamic>.from(event.payload);

    if (idx >= 0 && !liveMonitorRowVisualChanged(list[idx], merged)) return;

    if (idx >= 0) {
      list[idx] = merged;
    } else {
      list.add(merged);
    }
    _emitStudents(list, emit);
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
    if (event.filter == state.filter) return;
    emit(state.copyWith(
      filter: event.filter,
      visibleStudents: filterLiveMonitorStudents(state.students, event.filter),
      dataRevision: state.dataRevision + 1,
    ));
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

/// Skips rebuild when only filter changes vs student data (use [TeacherLiveMonitorState.dataRevision]).
bool teacherLiveMonitorListBuildWhen(
  TeacherLiveMonitorState previous,
  TeacherLiveMonitorState current,
) {
  return previous.dataRevision != current.dataRevision;
}

bool teacherLiveMonitorSummaryBuildWhen(
  TeacherLiveMonitorState previous,
  TeacherLiveMonitorState current,
) {
  return previous.dataRevision != current.dataRevision ||
      previous.filter != current.filter;
}
