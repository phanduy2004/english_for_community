import '../model/either.dart';
import '../model/failure.dart';

abstract class TeacherExamRepository {
  Future<Either<Failure, dynamic>> getMyTeacherApplication();
  Future<Either<Failure, void>> submitTeacherApplication({String bio, String organization});
  Future<Either<Failure, void>> withdrawTeacherApplication();

  Future<Either<Failure, List<dynamic>>> listMyClassroomsAsTeacher();
  Future<Either<Failure, List<dynamic>>> listEnrolledClassrooms();
  Future<Either<Failure, dynamic>> createClassroom({required String name});
  Future<Either<Failure, dynamic>> getClassroom(String id);
  Future<Either<Failure, dynamic>> joinClassByCode(String inviteCode);
  Future<Either<Failure, dynamic>> joinClassByToken(String token);

  Future<Either<Failure, dynamic>> patchClassroom(String id, Map<String, dynamic> body);
  Future<Either<Failure, dynamic>> archiveClassroom(String id);
  Future<Either<Failure, dynamic>> rotateClassroomInvite(String id);
  Future<Either<Failure, List<dynamic>>> listClassroomMembers(String classroomId);
  Future<Either<Failure, dynamic>> removeClassroomMember(String classroomId, String userId);

  Future<Either<Failure, dynamic>> getExam(String examId);
  Future<Either<Failure, dynamic>> updateExamDraft(String examId, Map<String, dynamic> body);
  Future<Either<Failure, dynamic>> createAssignmentBody(Map<String, dynamic> body);
  Future<Either<Failure, dynamic>> getGradingAttempt(String attemptId);
  Future<Either<Failure, List<dynamic>>> listMyExams();
  Future<Either<Failure, dynamic>> createExamDraft(Map<String, dynamic> body);
  Future<Either<Failure, dynamic>> publishExam(String examId);
  Future<Either<Failure, dynamic>> archiveExam(String examId);
  Future<Either<Failure, dynamic>> restoreExam(String examId);
  Future<Either<Failure, void>> deleteExam(String examId);
  Future<Either<Failure, void>> deleteExamAssignment(String assignmentId);
  Future<Either<Failure, dynamic>> closeExamAssignment(String assignmentId);
  Future<Either<Failure, dynamic>> rotateExamAssignmentPublicJoin(String assignmentId);
  Future<Either<Failure, dynamic>> createAssignmentSelfPaced({
    required String examId,
    required String classroomId,
    DateTime? dueAt,
  });

  Future<Either<Failure, List<dynamic>>> listAvailableExamAssignments();
  Future<Either<Failure, List<dynamic>>> listAvailableExamAssignmentsForClassroom(String classroomId);
  Future<Either<Failure, List<dynamic>>> listClassroomAssignments(String classroomId);
  Future<Either<Failure, dynamic>> startExamAttempt(String assignmentId);
  Future<Either<Failure, dynamic>> startPublicExamAttempt(String publicToken);
  Future<Either<Failure, dynamic>> previewPublicExam(String publicToken);
  Future<Either<Failure, List<dynamic>>> listMyAssignments();
  Future<Either<Failure, Map<String, dynamic>>> getAssignmentGradingHub(String assignmentId);
  Future<Either<Failure, List<dynamic>>> listAssignmentAttempts(String assignmentId);
  Future<Either<Failure, dynamic>> getSessionConsole(String assignmentId);
  Future<Either<Failure, dynamic>> createExamSession(String assignmentId);
  Future<Either<Failure, dynamic>> getExamSessionLobby(String sessionId);
  Future<Either<Failure, dynamic>> getSessionLiveMonitor(String sessionId);
  Future<Either<Failure, dynamic>> getAttemptLiveScreen(String attemptId);
  Future<Either<Failure, dynamic>> startExamSession(String sessionId);
  Future<Either<Failure, dynamic>> endExamSession(String sessionId);
  Future<Either<Failure, dynamic>> kickExamSessionParticipant(String sessionId, String userId);
  Future<Either<Failure, dynamic>> joinExamSession(String sessionId);
  Future<Either<Failure, dynamic>> getSessionMyAttempt(String sessionId);
  Future<Either<Failure, dynamic>> abandonExamAttempt(String attemptId);
  Future<Either<Failure, dynamic>> runAiGradingDraft(String attemptId);
  Future<Either<Failure, dynamic>> patchManualGrade(String attemptId, Map<String, dynamic> body);
  Future<Either<Failure, dynamic>> releaseExamResults(String attemptId);
  Future<Either<Failure, dynamic>> finalizeExamAttempt(String attemptId);
  Future<Either<Failure, dynamic>> runAiGradingBatch(String assignmentId);
  Future<Either<Failure, dynamic>> patchExamAttempt(String attemptId, Map<String, dynamic> answers);
  Future<Either<Failure, void>> syncExamAttemptLiveView(String attemptId, Map<String, dynamic> liveView);
  Future<Either<Failure, dynamic>> submitExamAttempt(String attemptId);
  Future<Either<Failure, dynamic>> getExamAttempt(String attemptId);

  Future<Either<Failure, dynamic>> duplicateExam(String examId);
  Future<Either<Failure, dynamic>> duplicateAssignment(String assignmentId, [Map<String, dynamic>? body]);
  Future<Either<Failure, dynamic>> patchAssignment(String assignmentId, Map<String, dynamic> body);
  Future<Either<Failure, dynamic>> approveClassroomMember(String classroomId, String userId);
  Future<Either<Failure, dynamic>> rejectClassroomMember(String classroomId, String userId);
  Future<Either<Failure, Map<String, dynamic>>> getClassroomGradebook(String classroomId);
  Future<Either<Failure, String>> downloadClassroomGradebookCsv(String classroomId);
  Future<Either<Failure, Map<String, dynamic>>> getTeacherDashboardActionItems();
  Future<Either<Failure, Map<String, dynamic>>> getTeacherAnalyticsSummary();
  Future<Either<Failure, Map<String, dynamic>>> getTeacherCalendarEvents({String? from, String? to});
  Future<Either<Failure, List<dynamic>>> listAssignmentPresets();
  Future<Either<Failure, dynamic>> createAssignmentPreset(Map<String, dynamic> body);
  Future<Either<Failure, dynamic>> deleteAssignmentPreset(String presetId);
  Future<Either<Failure, dynamic>> batchReleaseExamResults(String assignmentId);
  Future<Either<Failure, dynamic>> batchFinalizeExamAttempts(String assignmentId);
  Future<Either<Failure, void>> reportExamAttemptIntegrity(
    String attemptId, {
    int? tabSwitchDelta,
    int? focusLossDelta,
    int? copyPasteDelta,
  });
  Future<Either<Failure, List<dynamic>>> listClassroomActivity(String classroomId);
  Future<Either<Failure, dynamic>> addCoTeacher(String classroomId, String email);
  Future<Either<Failure, dynamic>> removeCoTeacher(String classroomId, String userId);
  Future<Either<Failure, Map<String, dynamic>>> getIntegrationsStatus();
  Future<Either<Failure, dynamic>> linkGoogleClassroom(String classroomId, Map<String, dynamic> body);
  Future<Either<Failure, dynamic>> unlinkGoogleClassroom(String classroomId);
  Future<Either<Failure, Map<String, dynamic>>> getTeacherAnalyticsFull({int days = 14});
  Future<Either<Failure, Map<String, dynamic>>> getAssignmentIntegritySummary(String assignmentId);

  /// Generates AI writing prompt options for a topic (teacher picks one for exam).
  Future<Either<Failure, List<Map<String, dynamic>>>> generateWritingPromptOptions({
    required String topicId,
    String? taskType,
  });
}
