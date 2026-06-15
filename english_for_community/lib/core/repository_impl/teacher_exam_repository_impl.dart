import 'package:dio/dio.dart';
import '../datasource/teacher_exam_remote_datasource.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../repository/teacher_exam_repository.dart';

class TeacherExamRepositoryImpl implements TeacherExamRepository {
  TeacherExamRepositoryImpl({required this.remote});

  final TeacherExamRemoteDatasource remote;

  String _dioMsg(DioException e) {
    if (e.response?.data is Map && (e.response!.data as Map)['message'] != null) {
      return (e.response!.data as Map)['message'].toString();
    }
    return e.message ?? 'Request failed';
  }

  @override
  Future<Either<Failure, dynamic>> getMyTeacherApplication() async {
    try {
      return Right(await remote.getMyTeacherApplication());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitTeacherApplication({String bio = '', String organization = ''}) async {
    try {
      await remote.submitTeacherApplication({
        'bio': bio,
        'organization': organization,
        'subjects': <String>[],
        'proofUrls': <String>[],
      });
      return Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> withdrawTeacherApplication() async {
    try {
      await remote.withdrawTeacherApplication();
      return Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listMyClassroomsAsTeacher() async {
    try {
      return Right(await remote.listMyClassroomsAsTeacher());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listEnrolledClassrooms() async {
    try {
      return Right(await remote.listEnrolledClassrooms());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> createClassroom({required String name}) async {
    try {
      return Right(await remote.createClassroom({'name': name, 'joinPolicy': 'open'}));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getClassroom(String id) async {
    try {
      return Right(await remote.getClassroom(id));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> joinClassByCode(String inviteCode) async {
    try {
      return Right(await remote.joinClassByCode(inviteCode.trim().toUpperCase()));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> joinClassByToken(String token) async {
    try {
      return Right(await remote.joinClassByToken(token));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> patchClassroom(String id, Map<String, dynamic> body) async {
    try {
      return Right(await remote.patchClassroom(id, body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> archiveClassroom(String id) async {
    try {
      return Right(await remote.archiveClassroom(id));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> rotateClassroomInvite(String id) async {
    try {
      return Right(await remote.rotateClassroomInvite(id));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listClassroomMembers(String classroomId) async {
    try {
      return Right(await remote.listClassroomMembers(classroomId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> removeClassroomMember(String classroomId, String userId) async {
    try {
      return Right(await remote.removeClassroomMember(classroomId, userId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listMyExams() async {
    try {
      return Right(await remote.listMyExams());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getExam(String examId) async {
    try {
      return Right(await remote.getExam(examId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> updateExamDraft(String examId, Map<String, dynamic> body) async {
    try {
      return Right(await remote.updateExamDraft(examId, body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> createExamDraft(Map<String, dynamic> body) async {
    try {
      return Right(await remote.createExamDraft(body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> publishExam(String examId) async {
    try {
      return Right(await remote.publishExam(examId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> archiveExam(String examId) async {
    try {
      return Right(await remote.archiveExam(examId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> restoreExam(String examId) async {
    try {
      return Right(await remote.restoreExam(examId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExam(String examId) async {
    try {
      await remote.deleteExam(examId);
      return Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExamAssignment(String assignmentId) async {
    try {
      await remote.deleteExamAssignment(assignmentId);
      return Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> closeExamAssignment(String assignmentId) async {
    try {
      return Right(await remote.closeExamAssignment(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> rotateExamAssignmentPublicJoin(String assignmentId) async {
    try {
      return Right(await remote.rotateExamAssignmentPublicJoin(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> createAssignmentBody(Map<String, dynamic> body) async {
    try {
      return Right(await remote.createAssignment(body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getGradingAttempt(String attemptId) async {
    try {
      return Right(await remote.getGradingAttempt(attemptId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> createAssignmentSelfPaced({
    required String examId,
    required String classroomId,
    DateTime? dueAt,
  }) async {
    try {
      final config = <String, dynamic>{};
      if (dueAt != null) config['dueAt'] = dueAt.toUtc().toIso8601String();
      return Right(await remote.createAssignment({
        'examId': examId,
        'audience': 'classroom',
        'classroomId': classroomId,
        'mode': 'self_paced',
        'config': config,
      }));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listAvailableExamAssignments() async {
    try {
      return Right(await remote.listAvailableExamAssignments());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listAvailableExamAssignmentsForClassroom(String classroomId) async {
    try {
      return Right(await remote.listAvailableExamAssignmentsForClassroom(classroomId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listClassroomAssignments(String classroomId) async {
    try {
      return Right(await remote.listClassroomAssignments(classroomId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> startExamAttempt(String assignmentId) async {
    try {
      return Right(await remote.startExamAttempt(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> patchExamAttempt(String attemptId, Map<String, dynamic> answers) async {
    try {
      return Right(await remote.patchExamAttempt(attemptId, answers));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncExamAttemptLiveView(String attemptId, Map<String, dynamic> liveView) async {
    try {
      await remote.syncExamAttemptLiveView(attemptId, liveView);
      return Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> submitExamAttempt(String attemptId, {bool force = false}) async {
    try {
      return Right(await remote.submitExamAttempt(attemptId, force: force));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getExamAttempt(String attemptId) async {
    try {
      return Right(await remote.getExamAttempt(attemptId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> startPublicExamAttempt(String publicToken) async {
    try {
      return Right(await remote.startPublicExamAttempt(publicToken.trim()));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> joinPublicExamSession(String publicToken) async {
    try {
      return Right(await remote.joinPublicExamSession(publicToken.trim()));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> previewPublicExam(String publicToken) async {
    try {
      return Right(await remote.previewPublicExam(publicToken.trim()));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listMyAssignments() async {
    try {
      return Right(await remote.listMyAssignments());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAssignmentGradingHub(String assignmentId) async {
    try {
      return Right(await remote.getAssignmentGradingHub(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listAssignmentAttempts(String assignmentId) async {
    final hub = await getAssignmentGradingHub(assignmentId);
    return hub.fold(
      Left.new,
      (h) => Right((h['attempts'] as List<dynamic>?) ?? []),
    );
  }

  @override
  Future<Either<Failure, dynamic>> getSessionConsole(String assignmentId) async {
    try {
      return Right(await remote.getSessionConsole(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> createExamSession(String assignmentId) async {
    try {
      return Right(await remote.createExamSession(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getExamSessionLobby(String sessionId) async {
    try {
      return Right(await remote.getExamSessionLobby(sessionId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getSessionLiveMonitor(String sessionId) async {
    try {
      return Right(await remote.getSessionLiveMonitor(sessionId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getAttemptLiveScreen(String attemptId) async {
    try {
      return Right(await remote.getAttemptLiveScreen(attemptId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> startExamSession(String sessionId) async {
    try {
      return Right(await remote.startExamSession(sessionId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> endExamSession(String sessionId) async {
    try {
      return Right(await remote.endExamSession(sessionId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> kickExamSessionParticipant(String sessionId, String userId) async {
    try {
      return Right(await remote.kickExamSessionParticipant(sessionId, userId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> joinExamSession(String sessionId) async {
    try {
      return Right(await remote.joinExamSession(sessionId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getSessionMyAttempt(String sessionId) async {
    try {
      return Right(await remote.getSessionMyAttempt(sessionId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> abandonExamAttempt(String attemptId) async {
    try {
      return Right(await remote.abandonExamAttempt(attemptId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> runAiGradingDraft(String attemptId) async {
    try {
      return Right(await remote.runAiGradingDraft(attemptId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> patchManualGrade(String attemptId, Map<String, dynamic> body) async {
    try {
      return Right(await remote.patchManualGrade(attemptId, body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> releaseExamResults(
    String attemptId, {
    String? resultsDetailLevel,
  }) async {
    try {
      return Right(await remote.releaseExamResults(
        attemptId,
        resultsDetailLevel: resultsDetailLevel,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> finalizeExamAttempt(String attemptId) async {
    try {
      return Right(await remote.finalizeExamAttempt(attemptId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> runAiGradingBatch(String assignmentId) async {
    try {
      return Right(await remote.runAiGradingBatch(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> duplicateExam(String examId) async {
    try {
      return Right(await remote.duplicateExam(examId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> duplicateAssignment(String assignmentId, [Map<String, dynamic>? body]) async {
    try {
      return Right(await remote.duplicateAssignment(assignmentId, body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> patchAssignment(String assignmentId, Map<String, dynamic> body) async {
    try {
      return Right(await remote.patchAssignment(assignmentId, body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> approveClassroomMember(String classroomId, String userId) async {
    try {
      return Right(await remote.approveClassroomMember(classroomId, userId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> rejectClassroomMember(String classroomId, String userId) async {
    try {
      return Right(await remote.rejectClassroomMember(classroomId, userId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getClassroomGradebook(String classroomId) async {
    try {
      return Right(await remote.getClassroomGradebook(classroomId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadClassroomGradebookCsv(String classroomId) async {
    try {
      return Right(await remote.downloadClassroomGradebookCsv(classroomId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ({List<int> bytes, String filename})>> downloadAssignmentScoresXlsx(
    String assignmentId,
  ) async {
    try {
      return Right(await remote.downloadAssignmentScoresXlsx(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTeacherDashboardActionItems() async {
    try {
      return Right(await remote.getTeacherDashboardActionItems());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTeacherAnalyticsSummary() async {
    try {
      return Right(await remote.getTeacherAnalyticsSummary());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTeacherCalendarEvents({String? from, String? to}) async {
    try {
      return Right(await remote.getTeacherCalendarEvents(from: from, to: to));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listAssignmentPresets() async {
    try {
      return Right(await remote.listAssignmentPresets());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> createAssignmentPreset(Map<String, dynamic> body) async {
    try {
      return Right(await remote.createAssignmentPreset(body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> deleteAssignmentPreset(String presetId) async {
    try {
      return Right(await remote.deleteAssignmentPreset(presetId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> batchReleaseExamResults(String assignmentId) async {
    try {
      return Right(await remote.batchReleaseExamResults(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> batchFinalizeExamAttempts(String assignmentId) async {
    try {
      return Right(await remote.batchFinalizeExamAttempts(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reportExamAttemptIntegrity(
    String attemptId, {
    int? tabSwitchDelta,
    int? focusLossDelta,
    int? copyPasteDelta,
  }) async {
    try {
      await remote.reportExamAttemptIntegrity(
        attemptId,
        tabSwitchDelta: tabSwitchDelta,
        focusLossDelta: focusLossDelta,
        copyPasteDelta: copyPasteDelta,
      );
      return Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> listClassroomActivity(String classroomId) async {
    try {
      return Right(await remote.listClassroomActivity(classroomId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> addCoTeacher(String classroomId, String username) async {
    try {
      return Right(await remote.addCoTeacher(classroomId, username));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> searchTeachersForCoTeacher(String query) async {
    try {
      return Right(await remote.searchTeachersForCoTeacher(query));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> removeCoTeacher(String classroomId, String userId) async {
    try {
      return Right(await remote.removeCoTeacher(classroomId, userId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getIntegrationsStatus() async {
    try {
      return Right(await remote.getIntegrationsStatus());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> linkGoogleClassroom(String classroomId, Map<String, dynamic> body) async {
    try {
      return Right(await remote.linkGoogleClassroom(classroomId, body));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> unlinkGoogleClassroom(String classroomId) async {
    try {
      return Right(await remote.unlinkGoogleClassroom(classroomId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTeacherAnalyticsFull({int days = 14}) async {
    try {
      return Right(await remote.getTeacherAnalyticsFull(days: days));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAssignmentIntegritySummary(String assignmentId) async {
    try {
      return Right(await remote.getAssignmentIntegritySummary(assignmentId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> generateWritingPromptOptions({
    String? topicId,
    String? topicName,
    String? taskType,
  }) async {
    try {
      return Right(await remote.generateWritingPromptOptions(
        topicId: topicId,
        topicName: topicName,
        taskType: taskType,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
