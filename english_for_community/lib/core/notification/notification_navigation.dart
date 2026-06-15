import 'package:english_for_community/core/entity/notification_entity.dart';
import 'package:english_for_community/feature/student/classes/my_classes_hub_page.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_detail_page.dart';
import 'package:english_for_community/feature/student/exams/exam_runner_page.dart';
import 'package:english_for_community/feature/student/exams/exam_session_lobby_page.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
import 'package:go_router/go_router.dart';

/// Deep-link navigation for notification taps (in-app list, FCM, local push).
bool navigateFromNotification(GoRouter router, {NotificationEntity? item, Map<String, dynamic>? data}) {
  final Map<String, dynamic> payload = data ?? item?.data ?? {};
  final String type = (payload['type'] as String?) ?? item?.type ?? '';

  try {
    if (payload.containsKey('listeningId')) {
      final listeningId = '${payload['listeningId']}';
      router.pushNamed(
        'ListeningSkillsPage',
        pathParameters: {'listeningId': listeningId},
        extra: {
          'listeningId': listeningId,
          'audioUrl': payload['audioUrl']?.toString() ?? '',
          'targetCommentId': payload['commentId']?.toString(),
          'cueId': payload['cueId']?.toString(),
          'openDiscussion': true,
        },
      );
      return true;
    }

    switch (type) {
      case 'CLASSROOM_JOIN_REQUEST':
      case 'CO_TEACHER_INVITE':
      case 'CO_TEACHER_INVITE_ACCEPTED':
      case 'CO_TEACHER_INVITE_DECLINED':
        final cid = payload['classroomId']?.toString();
        if (cid != null && cid.isNotEmpty) {
          router.push('${TeacherClassroomDetailPage.routePath}/$cid');
          return true;
        }
        break;

      case 'EXAM_SUBMISSION_RECEIVED':
        final assignmentId = payload['assignmentId']?.toString();
        if (assignmentId != null && assignmentId.isNotEmpty) {
          router.push('${TeacherExamGradingPage.routePath}/$assignmentId');
          return true;
        }
        break;

      case 'EXAM_ASSIGNED':
      case 'EXAM_ASSIGNMENT_UPDATED':
      case 'EXAM_ASSIGNMENT_CLOSED':
      case 'CLASSROOM_JOIN_APPROVED':
        final classroomId = payload['classroomId']?.toString();
        if (classroomId != null && classroomId.isNotEmpty) {
          router.pushNamed(
            StudentClassroomDetailPage.routeName,
            pathParameters: {'classroomId': classroomId},
          );
          return true;
        }
        if (type == 'CLASSROOM_JOIN_APPROVED') {
          router.push(MyClassesHubPage.routePath);
          return true;
        }
        break;

      case 'EXAM_RESULTS_RELEASED':
        final attemptId = payload['attemptId']?.toString();
        if (attemptId != null && attemptId.isNotEmpty) {
          router.push('${ExamRunnerPage.routePath}/$attemptId');
          return true;
        }
        break;

      case 'EXAM_SESSION_LIVE':
        final sessionId = payload['sessionId']?.toString();
        if (sessionId != null && sessionId.isNotEmpty) {
          router.pushNamed(
            ExamSessionLobbyPage.routeName,
            pathParameters: {'sessionId': sessionId},
          );
          return true;
        }
        break;

      case 'REVIEW_REMINDER':
        router.pushNamed('VocabularyPage', extra: const {'initialTabIndex': 1});
        return true;

      case 'DAILY_VOCAB':
      case 'DAILY_REMINDER':
        if (payload.containsKey('wordId') || type.startsWith('DAILY')) {
          router.pushNamed('VocabularyPage', extra: const {'initialTabIndex': 0});
          return true;
        }
        break;
    }

    if (payload.containsKey('wordId')) {
      router.pushNamed('VocabularyPage', extra: const {'initialTabIndex': 0});
      return true;
    }
  } catch (_) {
    return false;
  }
  return false;
}
