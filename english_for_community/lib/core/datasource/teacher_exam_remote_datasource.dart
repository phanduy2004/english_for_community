import 'package:dio/dio.dart';

/// Teacher applications, classrooms, teacher exams, and student exam runtime (same authorized Dio).
class TeacherExamRemoteDatasource {
  TeacherExamRemoteDatasource({required this.dio});

  final Dio dio;

  Future<dynamic> getMyTeacherApplication() async {
    final r = await dio.get('teacher/applications/me');
    return r.data;
  }

  Future<dynamic> submitTeacherApplication(Map<String, dynamic> body) async {
    final r = await dio.post('teacher/applications', data: body);
    return r.data;
  }

  Future<dynamic> withdrawTeacherApplication() async {
    final r = await dio.post('teacher/applications/withdraw');
    return r.data;
  }

  Future<List<dynamic>> listMyClassroomsAsTeacher() async {
    final r = await dio.get('classrooms/mine');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> listEnrolledClassrooms() async {
    final r = await dio.get('classrooms/enrolled');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<dynamic> createClassroom(Map<String, dynamic> body) async {
    final r = await dio.post('classrooms', data: body);
    return r.data;
  }

  Future<dynamic> getClassroom(String id) async {
    final r = await dio.get('classrooms/$id');
    return r.data;
  }

  Future<dynamic> joinClassByCode(String inviteCode) async {
    final r = await dio.post('classrooms/join-by-code', data: {'inviteCode': inviteCode});
    return r.data;
  }

  Future<dynamic> joinClassByToken(String token) async {
    final r = await dio.post('classrooms/join-by-token', data: {'token': token.trim()});
    return r.data;
  }

  Future<dynamic> patchClassroom(String id, Map<String, dynamic> body) async {
    final r = await dio.patch('classrooms/$id', data: body);
    return r.data;
  }

  Future<dynamic> archiveClassroom(String id) async {
    final r = await dio.post('classrooms/$id/archive');
    return r.data;
  }

  Future<dynamic> rotateClassroomInvite(String id) async {
    final r = await dio.post('classrooms/$id/rotate-invite');
    return r.data;
  }

  Future<List<dynamic>> listClassroomMembers(String classroomId) async {
    final r = await dio.get('classrooms/$classroomId/members');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<dynamic> removeClassroomMember(String classroomId, String userId) async {
    final r = await dio.post('classrooms/$classroomId/members/$userId/remove');
    return r.data;
  }

  Future<dynamic> getExam(String examId) async {
    final r = await dio.get('teacher/exams/$examId');
    return r.data;
  }

  Future<dynamic> updateExamDraft(String examId, Map<String, dynamic> body) async {
    final r = await dio.patch('teacher/exams/$examId', data: body);
    return r.data;
  }

  Future<dynamic> getGradingAttempt(String attemptId) async {
    final r = await dio.get('teacher/exams/grading-attempts/$attemptId');
    return r.data;
  }

  Future<List<dynamic>> listMyExams() async {
    final r = await dio.get('teacher/exams');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<dynamic> createExamDraft(Map<String, dynamic> body) async {
    final r = await dio.post('teacher/exams', data: body);
    return r.data;
  }

  Future<dynamic> archiveExam(String examId) async {
    final r = await dio.post('teacher/exams/$examId/archive');
    return r.data;
  }

  Future<dynamic> restoreExam(String examId) async {
    final r = await dio.post('teacher/exams/$examId/restore');
    return r.data;
  }

  Future<void> deleteExam(String examId) async {
    await dio.delete('teacher/exams/$examId');
  }

  Future<dynamic> publishExam(String examId) async {
    final r = await dio.post('teacher/exams/$examId/publish');
    return r.data;
  }

  Future<dynamic> closeExamAssignment(String assignmentId) async {
    final r = await dio.post('teacher/exams/assignments/$assignmentId/close');
    return r.data;
  }

  Future<void> deleteExamAssignment(String assignmentId) async {
    await dio.delete('teacher/exams/assignments/$assignmentId');
  }

  Future<dynamic> rotateExamAssignmentPublicJoin(String assignmentId) async {
    final r = await dio.post('teacher/exams/assignments/$assignmentId/public-join/rotate');
    return r.data;
  }

  Future<dynamic> createAssignment(Map<String, dynamic> body) async {
    final r = await dio.post('teacher/exams/assignments', data: body);
    return r.data;
  }

  Future<List<dynamic>> listMyAssignments() async {
    final r = await dio.get('teacher/exams/assignments');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> listClassroomAssignments(String classroomId) async {
    final r = await dio.get('teacher/exams/classrooms/$classroomId/assignments');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> getAssignmentGradingHub(String assignmentId) async {
    final r = await dio.get('teacher/exams/assignments/$assignmentId/attempts');
    final data = r.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'assignment': <String, dynamic>{}, 'attempts': data is List ? data : [], 'stats': <String, dynamic>{}};
  }

  Future<dynamic> getExamSessionLobby(String sessionId) async {
    final r = await dio.get('teacher/exams/sessions/$sessionId/lobby');
    return r.data;
  }

  Future<dynamic> getSessionLiveMonitor(String sessionId) async {
    final r = await dio.get('teacher/exams/sessions/$sessionId/live-monitor');
    return r.data;
  }

  Future<dynamic> getAttemptLiveScreen(String attemptId) async {
    final r = await dio.get('teacher/exams/attempts/$attemptId/live-screen');
    return r.data;
  }

  Future<dynamic> getSessionConsole(String assignmentId) async {
    final r = await dio.get('teacher/exams/assignments/$assignmentId/session-console');
    return r.data;
  }

  Future<dynamic> createExamSession(String assignmentId) async {
    final r = await dio.post('teacher/exams/assignments/$assignmentId/sessions');
    return r.data;
  }

  Future<dynamic> startExamSession(String sessionId) async {
    final r = await dio.post('teacher/exams/sessions/$sessionId/start');
    return r.data;
  }

  Future<dynamic> endExamSession(String sessionId) async {
    final r = await dio.post('teacher/exams/sessions/$sessionId/end');
    return r.data;
  }

  Future<dynamic> kickExamSessionParticipant(String sessionId, String userId) async {
    final r = await dio.post('teacher/exams/sessions/$sessionId/kick', data: {'userId': userId});
    return r.data;
  }

  Future<dynamic> runAiGradingDraft(String attemptId) async {
    final r = await dio.post('teacher/exams/attempts/$attemptId/ai-suggestions');
    return r.data;
  }

  Future<dynamic> patchManualGrade(String attemptId, Map<String, dynamic> body) async {
    final r = await dio.patch('teacher/exams/attempts/$attemptId/manual-grade', data: body);
    return r.data;
  }

  Future<dynamic> releaseExamResults(String attemptId, {String? resultsDetailLevel}) async {
    final r = await dio.post(
      'teacher/exams/attempts/$attemptId/release-results',
      data: resultsDetailLevel != null ? {'resultsDetailLevel': resultsDetailLevel} : null,
    );
    return r.data;
  }

  Future<dynamic> finalizeExamAttempt(String attemptId) async {
    final r = await dio.post('teacher/exams/attempts/$attemptId/finalize');
    return r.data;
  }

  Future<dynamic> runAiGradingBatch(String assignmentId) async {
    final r = await dio.post('teacher/exams/assignments/$assignmentId/grading/ai-batch');
    return r.data;
  }

  Future<dynamic> previewPublicExam(String token) async {
    final r = await dio.get('exams/public/$token/preview');
    return r.data;
  }

  Future<dynamic> startPublicExamAttempt(String token) async {
    final r = await dio.post('exams/public/$token/start');
    return r.data;
  }

  Future<dynamic> joinExamSession(String sessionId) async {
    final r = await dio.post('exams/sessions/$sessionId/join');
    return r.data;
  }

  Future<dynamic> getSessionMyAttempt(String sessionId) async {
    final r = await dio.get('exams/sessions/$sessionId/my-attempt');
    return r.data;
  }

  Future<dynamic> abandonExamAttempt(String attemptId) async {
    final r = await dio.post('exams/attempts/$attemptId/abandon');
    return r.data;
  }

  Future<List<dynamic>> listAvailableExamAssignments() async {
    final r = await dio.get('exams/assignments/available');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> listAvailableExamAssignmentsForClassroom(String classroomId) async {
    final r = await dio.get('exams/classrooms/$classroomId/assignments/available');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<dynamic> startExamAttempt(String assignmentId) async {
    final r = await dio.post('exams/assignments/$assignmentId/start');
    return r.data;
  }

  Future<dynamic> patchExamAttempt(String attemptId, Map<String, dynamic> answers) async {
    final r = await dio.patch('exams/attempts/$attemptId', data: {'answers': answers});
    return r.data;
  }

  Future<void> syncExamAttemptLiveView(String attemptId, Map<String, dynamic> liveView) async {
    await dio.patch(
      'exams/attempts/$attemptId/live-view',
      data: {'liveView': liveView},
    );
  }

  Future<dynamic> submitExamAttempt(String attemptId, {bool force = false}) async {
    final r = await dio.post(
      'exams/attempts/$attemptId/submit',
      data: force ? {'force': true} : null,
    );
    return r.data;
  }

  Future<dynamic> getExamAttempt(String attemptId) async {
    final r = await dio.get('exams/attempts/$attemptId');
    return r.data;
  }

  Future<dynamic> duplicateExam(String examId) async {
    final r = await dio.post('teacher/exams/$examId/duplicate');
    return r.data;
  }

  Future<dynamic> duplicateAssignment(String assignmentId, [Map<String, dynamic>? body]) async {
    final r = await dio.post('teacher/exams/assignments/$assignmentId/duplicate', data: body ?? {});
    return r.data;
  }

  Future<dynamic> patchAssignment(String assignmentId, Map<String, dynamic> body) async {
    final r = await dio.patch('teacher/exams/assignments/$assignmentId', data: body);
    return r.data;
  }

  Future<dynamic> approveClassroomMember(String classroomId, String userId) async {
    final r = await dio.post('classrooms/$classroomId/members/$userId/approve');
    return r.data;
  }

  Future<dynamic> rejectClassroomMember(String classroomId, String userId) async {
    final r = await dio.post('classrooms/$classroomId/members/$userId/reject');
    return r.data;
  }

  Future<Map<String, dynamic>> getClassroomGradebook(String classroomId) async {
    final r = await dio.get('teacher/exams/classrooms/$classroomId/gradebook');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<String> downloadClassroomGradebookCsv(String classroomId) async {
    final r = await dio.get<String>(
      'teacher/exams/classrooms/$classroomId/gradebook/export.csv',
      options: Options(responseType: ResponseType.plain),
    );
    return r.data ?? '';
  }

  Future<({List<int> bytes, String filename})> downloadAssignmentScoresXlsx(
    String assignmentId,
  ) async {
    final r = await dio.get<List<int>>(
      'teacher/exams/assignments/$assignmentId/attempts/export.xlsx',
      options: Options(responseType: ResponseType.bytes),
    );
    var filename = 'scores.xlsx';
    final disposition = r.headers.value('content-disposition');
    if (disposition != null) {
      final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
      if (match != null) filename = match.group(1)!;
    }
    return (bytes: r.data ?? <int>[], filename: filename);
  }

  Future<Map<String, dynamic>> getTeacherDashboardActionItems() async {
    final r = await dio.get('teacher/dashboard/action-items');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> getTeacherAnalyticsSummary() async {
    final r = await dio.get('teacher/dashboard/analytics');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> getTeacherCalendarEvents({String? from, String? to}) async {
    final r = await dio.get(
      'teacher/dashboard/calendar',
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<List<dynamic>> listAssignmentPresets() async {
    final r = await dio.get('teacher/assignment-presets');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<dynamic> createAssignmentPreset(Map<String, dynamic> body) async {
    final r = await dio.post('teacher/assignment-presets', data: body);
    return r.data;
  }

  Future<dynamic> deleteAssignmentPreset(String presetId) async {
    final r = await dio.delete('teacher/assignment-presets/$presetId');
    return r.data;
  }

  Future<dynamic> batchReleaseExamResults(String assignmentId) async {
    final r = await dio.post('teacher/exams/assignments/$assignmentId/grading/batch-release');
    return r.data;
  }

  Future<dynamic> batchFinalizeExamAttempts(String assignmentId) async {
    final r = await dio.post('teacher/exams/assignments/$assignmentId/grading/batch-finalize');
    return r.data;
  }

  Future<dynamic> reportExamAttemptIntegrity(
    String attemptId, {
    int? tabSwitchDelta,
    int? focusLossDelta,
    int? copyPasteDelta,
  }) async {
    final r = await dio.post('exams/attempts/$attemptId/integrity', data: {
      if (tabSwitchDelta != null) 'tabSwitchDelta': tabSwitchDelta,
      if (focusLossDelta != null) 'focusLossDelta': focusLossDelta,
      if (copyPasteDelta != null) 'copyPasteDelta': copyPasteDelta,
    });
    return r.data;
  }

  Future<List<dynamic>> listClassroomActivity(String classroomId) async {
    final r = await dio.get('classrooms/$classroomId/activity');
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<dynamic> addCoTeacher(String classroomId, String username) async {
    final r = await dio.post('classrooms/$classroomId/co-teachers', data: {'username': username.trim()});
    return r.data;
  }

  Future<List<dynamic>> searchTeachersForCoTeacher(String query, {int limit = 10}) async {
    final r = await dio.get(
      'classrooms/teachers/search',
      queryParameters: {'q': query.trim(), 'limit': limit},
    );
    return (r.data as List<dynamic>?) ?? [];
  }

  Future<dynamic> removeCoTeacher(String classroomId, String userId) async {
    final r = await dio.post('classrooms/$classroomId/co-teachers/$userId/remove');
    return r.data;
  }

  Future<Map<String, dynamic>> getIntegrationsStatus() async {
    final r = await dio.get('classrooms/integrations/status');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<dynamic> linkGoogleClassroom(String classroomId, Map<String, dynamic> body) async {
    final r = await dio.post('classrooms/$classroomId/integrations/google-classroom/link', data: body);
    return r.data;
  }

  Future<dynamic> unlinkGoogleClassroom(String classroomId) async {
    final r = await dio.post('classrooms/$classroomId/integrations/google-classroom/unlink');
    return r.data;
  }

  Future<Map<String, dynamic>> getTeacherAnalyticsFull({int days = 14}) async {
    final r = await dio.get('teacher/dashboard/analytics', queryParameters: {'days': days});
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> getAssignmentIntegritySummary(String assignmentId) async {
    final r = await dio.get('teacher/exams/assignments/$assignmentId/integrity-summary');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<List<Map<String, dynamic>>> generateWritingPromptOptions({
    String? topicId,
    String? topicName,
    String? taskType,
  }) async {
    final body = <String, dynamic>{};
    if (topicId != null && topicId.isNotEmpty) body['topicId'] = topicId;
    if (topicName != null && topicName.isNotEmpty) body['topicName'] = topicName;
    if (taskType != null && taskType.isNotEmpty) body['taskType'] = taskType;
    final r = await dio.post('teacher/exams/writing/generate-prompt-options', data: body);
    final data = r.data as Map<String, dynamic>;
    final options = data['options'] as List<dynamic>;
    return options.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
