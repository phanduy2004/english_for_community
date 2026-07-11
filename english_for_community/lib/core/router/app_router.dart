// lib/core/router/app_router.dart

import 'dart:async';
import 'package:english_for_community/feature/admin/content_management/listening_comp/admin_listening_comp_list_page.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- CORE & UTILS ---
import '../../feature/admin/content_management/listening/admin_listening_list_view.dart';
import '../../feature/admin/content_management/listening/listening_editor_page.dart';
import '../../feature/admin/content_management/listening_comp/listening_comp_editor_page.dart';
import '../../feature/admin/content_management/reading/admin_reading_list_view.dart';
import '../../feature/admin/content_management/reading/reading_editor_page.dart';
import '../../feature/admin/content_management/speaking/admin_speaking_list_view.dart';
import '../../feature/admin/content_management/speaking/speaking_editor_page.dart';
import '../../feature/admin/content_management/writing/admin_writing_list_view.dart';
import '../../feature/admin/content_management/writing/writing_topic_editor_page.dart';
import '../../feature/admin/report_management/report_management_page.dart';
import '../../feature/admin/submission_managerment/activity_history_page.dart';
import '../../feature/auth/forgot_password_page.dart';
import '../../feature/auth/otp_verification_page.dart';
import '../../feature/auth/register_page.dart';
import '../../feature/auth/reset_password_page.dart';
import '../../feature/listening/listening_skill/bloc/cue_bloc.dart';
import '../../feature/listening/listening_skill/bloc/cue_event.dart';
import '../../feature/listening_comp/bloc/listening_comp_bloc.dart';
import '../../feature/listening_comp/listening_comp_list_page.dart';
import '../../feature/listening_comp/listening_comp_page.dart';
import '../get_it/get_it.dart';
import '../router/app_page_transitions.dart';
import '../utils/global_keys.dart';
import '../sqflite/dict_db.dart';

// --- AUTH & BLOCS ---
import '../../feature/auth/login_page.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_state.dart';
import '../../feature/onboarding_page.dart';

// --- ADMIN PAGES ---
import '../../feature/admin/layout/admin_shell.dart';
import '../../feature/admin/analytics/admin_analytics_page.dart';
import '../../feature/admin/dashboard_home/admin_dashboard.dart';
import '../../feature/admin/user_management/user_management_page.dart';
import '../../feature/admin/ops_center/admin_ops_center_page.dart';
import '../../feature/admin/release_management/release_management_page.dart';
// 👇 IMPORT CÁC PAGE QUẢN LÝ NỘI DUNG MỚI
import '../../feature/admin/content_management/content_dashboard_page.dart';
import '../../feature/home/home_page.dart';
import '../../feature/home/notifications_page.dart';
import '../../feature/profile/my_exercise_history/my_exercise_history_page.dart';
import '../../feature/profile/profile_page.dart';
import '../../feature/profile/edit_profile_page.dart';
import '../../feature/progress/progress_report_page.dart';

// Reading
import '../../feature/reading/reading_list_page.dart';
import '../../feature/reading/reading_detail_page.dart';
import '../entity/reading/reading_entity.dart';

// Listening
import '../../feature/listening/list_listening/listening_list_page.dart';
import '../../feature/listening/listening_skill/listening_skills_page.dart';

// Speaking
import '../../feature/speaking/speaking_hub_page.dart';
import '../../feature/speaking/speaking_skills_page.dart';
import '../../feature/speaking/free_speaking_page.dart';
import '../../feature/speaking/speaking_feedback_page.dart';
import '../../feature/speaking/speaking_progress_dashboard_page.dart';
import '../../feature/speaking/speaking_notebook_page.dart';
import '../entity/speaking_phase2_entity.dart';

// Writing
import '../../feature/writing/writing_topics_page.dart';
import '../../feature/writing/bloc/writing_bloc.dart';
import '../../feature/writing/bloc/writing_event.dart';

// Vocabulary
import '../../feature/vocabulary/vocabulary_home_page.dart';
import '../../feature/vocabulary/dict_demo_page.dart';
import '../../feature/vocabulary/dict_detail_page.dart';
import '../../feature/vocabulary/review_session_page.dart';

import '../../feature/teacher/teacher_dashboard_page.dart';
import '../../feature/teacher/teacher_classroom_detail_page.dart';
import '../../feature/teacher/teacher_exam_session_console_page.dart';
import '../../feature/teacher/teacher_exam_grading_page.dart';
import '../../feature/teacher/teacher_exams_list_page.dart';
import '../../feature/teacher/teacher_exam_editor_page.dart';
import '../../feature/teacher/teacher_integrated_exam_editor_page.dart';
import '../../feature/teacher/teacher_assignment_wizard_page.dart';
import '../../feature/teacher/teacher_exam_attempt_grade_page.dart';
import '../../feature/teacher/teacher_gradebook_page.dart';
import '../../feature/teacher/teacher_analytics_page.dart';
import '../../feature/teacher/teacher_calendar_page.dart';
import '../../feature/teacher/teacher_dashboard_inbox_builder.dart';
import '../../feature/teacher/teacher_inbox_page.dart';
import '../../feature/teacher/layout/teacher_shell.dart';
import '../../feature/student/classes/my_classes_hub_page.dart';
import '../../feature/student/classes/student_classroom_detail_page.dart';
import '../../feature/student/exams/exam_assignments_page.dart';
import '../../feature/student/exams/exam_runner_page.dart';
import '../../feature/student/exams/public_exam_join_page.dart';
import '../../feature/student/exams/exam_session_lobby_page.dart';
import '../../feature/classroom_chat/classroom_chat_page.dart';

// Route Constants
const String kReadingDetailRouteName = 'reading-detail';
const String kDictDetailRouteName = 'dict-detail';
const String kDictDemoRouteName = 'dict-demo';
const String kReviewSessionRouteName = 'review-session';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  static const String routePath = '/';
  static const String routeName = 'SplashPage';
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: AppLoadingIndicator.center()),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static var router = GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: GoRouterRefreshStream(getIt<UserBloc>().stream),

    // --- LOGIC ĐIỀU HƯỚNG & PHÂN QUYỀN (REDIRECT) ---
    redirect: (BuildContext context, GoRouterState state) {
      final userState = getIt<UserBloc>().state;
      final location = state.matchedLocation;

      final publicRoutes = [
        LoginPage.routePath,
        RegisterPage.routePath,
        OtpVerificationPage.routePath,
        OnboardingPage.routePath,
        ForgotPasswordPage
            .routePath, // 🔥 NEW: Add Forgot Password to public routes
        ResetPasswordPage.routePath,
        '/dictionary-search',
        '/dictionary-detail',
      ];

      // 1. Đang load thông tin user -> Splash
      if (userState.status == UserStatus.initial ||
          (userState.status == UserStatus.loading &&
              userState.userEntity == null)) {
        return location == SplashPage.routePath ? null : SplashPage.routePath;
      }

      // 2. Chưa đăng nhập -> Login
      if (userState.status == UserStatus.unauthenticated) {
        return publicRoutes.contains(location) ? null : LoginPage.routePath;
      }

      // 3. Đã đăng nhập
      if (userState.status == UserStatus.success) {
        final user = userState.userEntity;
        final role = user?.role ?? 'user';
        final isAdminConsoleRole = role == 'admin';

        // 🔥 ADMIN CHECK 🔥
        if (isAdminConsoleRole) {
          // Nếu Admin đang ở trang Login/Splash -> Vào Dashboard
          if (publicRoutes.contains(location) ||
              location == SplashPage.routePath) {
            return AdminDashboardPage.routePath;
          }
          // Chặn Admin vào Home của User thường (nếu muốn)
          if (location == HomePage.routePath) {
            return AdminDashboardPage.routePath;
          }
        }
        // 🟢 TEACHER — vào workspace giáo viên, không qua Home học sinh
        else if (role == 'teacher') {
          final isDictionaryRoute = location.startsWith('/dictionary');
          final isAccountRoute = location.startsWith('/profile');

          if (publicRoutes.contains(location) && !isDictionaryRoute ||
              location == SplashPage.routePath) {
            return TeacherDashboardPage.routePath;
          }

          if (!location.startsWith('/teacher') &&
              !isAccountRoute &&
              !isDictionaryRoute) {
            return TeacherDashboardPage.routePath;
          }

          if (location.contains('/admin')) {
            return TeacherDashboardPage.routePath;
          }
        }
        // 🟢 USER THƯỜNG
        else {
          final isDictionaryRoute = location.startsWith('/dictionary');

          if (location.startsWith('/teacher')) {
            return HomePage.routePath;
          }

          if ((publicRoutes.contains(location) && !isDictionaryRoute) ||
              location == SplashPage.routePath ||
              location.contains('/admin')) {
            return HomePage.routePath;
          }
        }
      }

      return null;
    },

    // --- DANH SÁCH ROUTES ---
    routes: [
      GoRoute(
        path: SplashPage.routePath,
        name: SplashPage.routeName,
        builder: (context, state) => const SplashPage(),
      ),

      // ==========================================
      // 👑 ADMIN ROUTES (web shell)
      // ==========================================
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin-dashboard',
            name: AdminDashboardPage.routeName,
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: AdminAnalyticsPage.routePath,
            name: AdminAnalyticsPage.routeName,
            builder: (context, state) => const AdminAnalyticsPage(),
          ),
          GoRoute(
            path: AdminOpsCenterPage.routePath,
            name: AdminOpsCenterPage.routeName,
            builder: (context, state) => const AdminOpsCenterPage(),
          ),
          GoRoute(
            path: ReleaseManagementPage.routePath,
            name: ReleaseManagementPage.routeName,
            builder: (context, state) => const ReleaseManagementPage(),
          ),
          GoRoute(
            path: '/admin/users',
            name: UserManagementPage.routeName,
            builder: (context, state) {
              final filterParam = state.uri.queryParameters['filter'];
              UserFilter initialFilter = UserFilter.all;
              if (filterParam == 'today') initialFilter = UserFilter.today;
              if (filterParam == 'online') initialFilter = UserFilter.online;
              return UserManagementPage(initialFilter: initialFilter);
            },
          ),
          GoRoute(
            path: ActivityHistoryPage.routePath,
            name: ActivityHistoryPage.routeName,
            builder: (context, state) => const ActivityHistoryPage(),
          ),
          GoRoute(
            path: '/admin/reports',
            name: ReportManagementPage.routeName,
            builder: (context, state) => const ReportManagementPage(),
          ),
          GoRoute(
            path: '/admin/content',
            name: ContentDashboardPage.routeName,
            builder: (context, state) => const ContentDashboardPage(),
            routes: [
              GoRoute(
                path: ':type',
                name: 'ContentListViewRoute',
                builder: (context, state) {
                  final type = state.pathParameters['type'];
                  if (type == 'reading') {
                    return const AdminReadingListView(skillType: 'reading');
                  } else if (type == 'listening') {
                    return const AdminListeningListView();
                  } else if (type == 'listening-comp') {
                    return const AdminListeningCompListPage();
                  } else if (type == 'speaking') {
                    return const AdminSpeakingListView();
                  } else if (type == 'writing') {
                    return const AdminWritingListView();
                  }
                  return Scaffold(
                      body: Center(child: Text('Unknown type: $type')));
                },
                routes: [
                  GoRoute(
                    path: 'editor',
                    name: 'ContentEditorRoute',
                    builder: (context, state) {
                      final type = state.pathParameters['type'];
                      final id = state.extra as String?;
                      if (type == 'reading') {
                        return ReadingEditorPage(id: id);
                      } else if (type == 'listening') {
                        return ListeningEditorPage(id: id);
                      } else if (type == 'listening-comp') {
                        return ListeningCompEditorPage(id: id);
                      } else if (type == 'speaking') {
                        return SpeakingEditorPage(id: id);
                      } else if (type == 'writing') {
                        return WritingTopicEditorPage(id: id);
                      }
                      return Scaffold(
                          body: Center(child: Text('Error: $type')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // --- Authentication ---
      GoRoute(
        path: '/onboarding',
        name: 'OnboardingPage',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RegisterPage.routePath,
        name: RegisterPage.routeName,
        builder: (context, state) => const RegisterPage(),
      ),

      // 🔥 NEW: OTP Verification Route
      GoRoute(
        path: OtpVerificationPage.routePath,
        name: OtpVerificationPage.routeName,
        builder: (context, state) {
          // Retrieve 'email' passed via extra
          final email = state.extra as String? ?? '';
          return OtpVerificationPage(email: email);
        },
      ),
      GoRoute(
        path: ForgotPasswordPage.routePath,
        name: ForgotPasswordPage.routeName,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      // 🔥 NEW: Reset Password Route
      GoRoute(
        path: ResetPasswordPage.routePath,
        name: ResetPasswordPage.routeName,
        builder: (context, state) {
          final extra =
              state.extra as Map<String, dynamic>? ?? {}; // Safer cast
          final email = extra['email'] as String? ?? '';
          final otp = extra['otp'] as String? ?? '';
          return ResetPasswordPage(email: email, otp: otp);
        },
      ),
      GoRoute(
        path: LoginPage.routePath,
        name: LoginPage.routeName,
        builder: (context, state) => LoginPage(),
      ),

      // --- Main Features ---
      GoRoute(
        path: HomePage.routePath,
        name: HomePage.routeName,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: NotificationsPage.routePath,
        name: NotificationsPage.routeName,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'ProfilePage',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: EditProfilePage.routePath,
        name: EditProfilePage.routeName,
        builder: (context, state) => EditProfilePage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TeacherShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TeacherDashboardPage.routePath,
                name: TeacherDashboardPage.routeName,
                pageBuilder: (context, state) => AppPageTransitions.build(
                  state: state,
                  child: const TeacherDashboardPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'classroom/:classroomId',
                    name: TeacherClassroomDetailPage.routeName,
                    pageBuilder: (context, state) => AppPageTransitions.build(
                      state: state,
                      transition: AppRouteTransition.push,
                      child: TeacherClassroomDetailPage(
                        classroomId: state.pathParameters['classroomId'] ?? '',
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'gradebook',
                        name: TeacherGradebookPage.routeName,
                        pageBuilder: (context, state) =>
                            AppPageTransitions.build(
                          state: state,
                          transition: AppRouteTransition.push,
                          child: TeacherGradebookPage(
                            classroomId:
                                state.pathParameters['classroomId'] ?? '',
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'chat',
                        name: ClassroomChatPage.routeName,
                        pageBuilder: (context, state) {
                          final classroomId =
                              state.pathParameters['classroomId'] ?? '';
                          final extra = state.extra as Map<String, dynamic>?;
                          final name = extra?['classroomName'] as String? ??
                              'Nhóm lớp học';
                          final userId =
                              extra?['currentUserId'] as String? ?? '';
                          return AppPageTransitions.build(
                            state: state,
                            transition: AppRouteTransition.push,
                            child: ClassroomChatPage(
                              classroomId: classroomId,
                              classroomName: name,
                              currentUserId: userId,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: TeacherInboxPage.routePath,
                    name: TeacherInboxPage.routeName,
                    pageBuilder: (context, state) {
                      final raw = state.uri.queryParameters['filter'];
                      final filter =
                          TeacherInboxFilter.values.asNameMap()[raw] ??
                              TeacherInboxFilter.all;
                      return AppPageTransitions.build(
                        state: state,
                        transition: AppRouteTransition.push,
                        child: TeacherInboxPage(initialFilter: filter),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'exam-grading/:assignmentId/attempt/:attemptId',
                    name: TeacherExamAttemptGradePage.routeName,
                    pageBuilder: (context, state) => AppPageTransitions.build(
                      state: state,
                      transition: AppRouteTransition.push,
                      child: TeacherExamAttemptGradePage(
                        assignmentId:
                            state.pathParameters['assignmentId'] ?? '',
                        attemptId: state.pathParameters['attemptId'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'exam-console/:assignmentId',
                    name: TeacherExamSessionConsolePage.routeName,
                    pageBuilder: (context, state) => AppPageTransitions.build(
                      state: state,
                      transition: AppRouteTransition.push,
                      child: TeacherExamSessionConsolePage(
                        assignmentId:
                            state.pathParameters['assignmentId'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'exam-grading/:assignmentId',
                    name: TeacherExamGradingPage.routeName,
                    pageBuilder: (context, state) => AppPageTransitions.build(
                      state: state,
                      transition: AppRouteTransition.push,
                      child: TeacherExamGradingPage(
                        assignmentId:
                            state.pathParameters['assignmentId'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'content/:type/new',
                    name: 'TeacherContentNewRoute',
                    pageBuilder: (context, state) {
                      final type = state.pathParameters['type'];
                      final Widget page;
                      if (type == 'reading') {
                        page = ReadingEditorPage();
                      } else if (type == 'listening') {
                        page = ListeningEditorPage();
                      } else if (type == 'speaking') {
                        page = SpeakingEditorPage();
                      } else if (type == 'writing') {
                        page = WritingTopicEditorPage();
                      } else {
                        page = Scaffold(
                            body: Center(
                                child: Text('Unknown content type: $type')));
                      }
                      return AppPageTransitions.build(
                        state: state,
                        transition: AppRouteTransition.push,
                        child: page,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TeacherExamsListPage.routePath,
                name: TeacherExamsListPage.routeName,
                pageBuilder: (context, state) => AppPageTransitions.build(
                  state: state,
                  child: const TeacherExamsListPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':examId/edit',
                    name: TeacherExamEditorPage.routeName,
                    pageBuilder: (context, state) => AppPageTransitions.build(
                      state: state,
                      transition: AppRouteTransition.push,
                      child: TeacherExamEditorPage(
                        examId: state.pathParameters['examId'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':examId/integrated-edit',
                    name: 'TeacherIntegratedExamEditorPage',
                    pageBuilder: (context, state) => AppPageTransitions.build(
                      state: state,
                      transition: AppRouteTransition.push,
                      child: TeacherIntegratedExamEditorPage(
                        examId: state.pathParameters['examId'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':examId/assign',
                    name: 'TeacherAssignmentWizardPage',
                    pageBuilder: (context, state) {
                      final extra = state.extra;
                      String? initialClassroomId;
                      if (extra is Map<String, dynamic>) {
                        initialClassroomId =
                            extra['initialClassroomId'] as String?;
                      }
                      return AppPageTransitions.build(
                        state: state,
                        transition: AppRouteTransition.push,
                        child: TeacherAssignmentWizardPage(
                          examId: state.pathParameters['examId'] ?? '',
                          initialClassroomId: initialClassroomId,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TeacherCalendarPage.routePath,
                name: TeacherCalendarPage.routeName,
                pageBuilder: (context, state) => AppPageTransitions.build(
                  state: state,
                  child: const TeacherCalendarPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TeacherAnalyticsPage.routePath,
                name: TeacherAnalyticsPage.routeName,
                pageBuilder: (context, state) => AppPageTransitions.build(
                  state: state,
                  child: const TeacherAnalyticsPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: MyClassesHubPage.routePath,
        name: MyClassesHubPage.routeName,
        builder: (context, state) => const MyClassesHubPage(),
      ),
      GoRoute(
        path: '/student/classroom/:classroomId/chat',
        name: ClassroomChatPage.studentRouteName,
        pageBuilder: (context, state) {
          final classroomId = state.pathParameters['classroomId'] ?? '';
          final extra = state.extra;
          var classroomName = 'Nhóm lớp học';
          var currentUserId = getIt<UserBloc>().state.userEntity?.id ?? '';
          String? coverImageUrl;
          if (extra is Map<String, dynamic>) {
            classroomName = extra['classroomName'] as String? ?? classroomName;
            final fromExtra = extra['currentUserId'] as String?;
            if (fromExtra != null && fromExtra.isNotEmpty) {
              currentUserId = fromExtra;
            }
            coverImageUrl = extra['coverImageUrl'] as String?;
          }
          return AppPageTransitions.build(
            state: state,
            transition: AppRouteTransition.push,
            child: ClassroomChatPage(
              classroomId: classroomId,
              classroomName: classroomName,
              currentUserId: currentUserId,
              coverImageUrl: coverImageUrl,
            ),
          );
        },
      ),
      GoRoute(
        path: '${StudentClassroomDetailPage.routePath}/:classroomId',
        name: StudentClassroomDetailPage.routeName,
        builder: (context, state) => StudentClassroomDetailPage(
          classroomId: state.pathParameters['classroomId'] ?? '',
        ),
      ),
      GoRoute(
        path: PublicExamJoinPage.routePath,
        name: PublicExamJoinPage.routeName,
        builder: (context, state) => const PublicExamJoinPage(),
      ),
      GoRoute(
        path: ExamAssignmentsPage.routePath,
        name: ExamAssignmentsPage.routeName,
        builder: (context, state) => const ExamAssignmentsPage(),
      ),
      GoRoute(
        path: '/student/exam-session/:sessionId',
        name: ExamSessionLobbyPage.routeName,
        builder: (context, state) => ExamSessionLobbyPage(
          sessionId: state.pathParameters['sessionId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/student/exam-run/:attemptId',
        name: ExamRunnerPage.routeName,
        builder: (context, state) => ExamRunnerPage(
          attemptId: state.pathParameters['attemptId'] ?? '',
        ),
      ),
      GoRoute(
        path: ProgressReportPage.routePath,
        name: ProgressReportPage.routeName,
        builder: (context, state) => const ProgressReportPage(),
      ),
      GoRoute(
        path: MyExerciseHistoryPage.routePath,
        name: MyExerciseHistoryPage.routeName,
        builder: (context, state) => const MyExerciseHistoryPage(),
      ),
      // --- Listening ---
      // --- Listening Dictation ---
      GoRoute(
        path: ListeningListPage.routePath, // '/listening-list'
        name: ListeningListPage.routeName,
        builder: (context, state) => const ListeningListPage(),
      ),

      // --- Listening Comprehension ---
      GoRoute(
        name: 'ListeningCompPage',
        path: '/listening-comp/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return const Scaffold(
                body: Center(child: Text('Error: Missing ID')));
          }

          // 🔥 LẤY CỜ TỪ URL (QUERY PARAMETERS)
          final isRetakeStr = state.uri.queryParameters['isRetake'];
          final isRetake = isRetakeStr == 'true';

          return BlocProvider(
            create: (_) => getIt<ListeningCompBloc>(),
            // Truyền cờ vào Constructor
            child: ListeningCompPage(id: id, isRetake: isRetake),
          );
        },
      ),
      GoRoute(
        path: ListeningCompListPage.routePath, // '/listening-comp-list'
        name: ListeningCompListPage.routeName,
        builder: (context, state) => const ListeningCompListPage(),
      ),
      GoRoute(
        path: '/listening-skills/:listeningId',
        name: 'ListeningSkillsPage',
        builder: (context, state) {
          // 1. Lấy ID từ URL (bắt buộc)
          final listeningId = state.pathParameters['listeningId'] ?? '';

          // 2. Lấy Object 'extra' (Dùng cho Notification hoặc điều hướng nội bộ phức tạp)
          final extra = state.extra as Map<String, dynamic>?;

          // 3. Lấy Query Params (Dùng cho điều hướng web/link chia sẻ)
          final queryParams = state.uri.queryParameters;

          // 4. Ưu tiên lấy dữ liệu từ 'extra' trước, nếu không có thì lấy từ 'queryParams'
          // (NotificationService sẽ gửi data qua 'extra')
          final audioUrl = extra?['audioUrl'] ?? queryParams['audioUrl'] ?? '';
          final title = extra?['title'] ?? queryParams['title'];
          final levelText = extra?['levelText'] ?? queryParams['levelText'];

          // 5. Các tham số xử lý Deep Link (Mở tab Discussion & Scroll)
          final targetCommentId = extra?['targetCommentId'];
          final openDiscussion = extra?['openDiscussion'] == true;
          final targetCueId = extra?['cueId'];
          return BlocProvider<CueBloc>(
            create: (context) => getIt<CueBloc>()
              ..add(LoadCuesAndAttempts(
                  listeningId: listeningId,
                  initialCueId:
                      targetCueId)), // Load dữ liệu ngay khi vào trang
            child: ListeningSkillsPage(
              listeningId: listeningId,
              audioUrl: audioUrl,
              title: title,
              levelText: levelText,
              initialTab: openDiscussion ? 1 : 0,
              targetCommentId: targetCommentId,
            ),
          );
        },
      ),

      // --- Reading ---
      GoRoute(
          path: ReadingListPage.routePath,
          name: ReadingListPage.routeName,
          builder: (context, state) => const ReadingListPage(),
          routes: [
            GoRoute(
              name: kReadingDetailRouteName,
              path: 'detail',
              builder: (context, state) {
                final reading = state.extra as ReadingEntity?;
                if (reading == null) return const ReadingListPage();
                return ReadingDetailPage(reading: reading);
              },
            ),
          ]),

      // --- Vocabulary ---
      GoRoute(
        path: '/vocabulary',
        name: 'VocabularyPage',
        builder: (context, state) {
          // Lấy extra data
          int? initialIndex;
          if (state.extra != null && state.extra is Map) {
            final map = state.extra as Map;
            if (map.containsKey('initialTabIndex')) {
              initialIndex = map['initialTabIndex'] as int;
            }
          }

          return VocabularyHomePage(initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/dictionary-search',
        name: kDictDemoRouteName, // Giá trị là 'dict-demo'
        builder: (context, state) {
          // Lấy tham số isGuest từ extra map
          final extra = state.extra as Map<String, dynamic>?;
          final isGuest = extra?['isGuest'] as bool? ?? false;

          return DictDemoPage(isGuest: isGuest);
        },
      ),
      GoRoute(
        path: '/dictionary-detail',
        name: kDictDetailRouteName,
        builder: (context, state) {
          Entry? entry;
          bool isGuest = false;

          final extra = state.extra;

          // 🛡️ CÁCH FIX AN TOÀN: Kiểm tra kiểu dữ liệu trước khi dùng

          // Trường hợp 1: Code mới (Truyền Map để kèm biến isGuest)
          if (extra is Map<String, dynamic>) {
            // Hoặc kiểm tra 'is Map'
            entry = extra['entry'] as Entry?;
            isGuest = extra['isGuest'] as bool? ?? false;
          }
          // Trường hợp 2: Code cũ (Chỉ truyền trực tiếp object Entry)
          // Đoạn này giúp app không bị crash nếu bạn quên sửa chỗ pushNamed nào đó
          else if (extra is Entry) {
            entry = extra;
            isGuest = false; // Mặc định
          }

          // Nếu không có dữ liệu entry thì quay về trang tìm kiếm
          if (entry == null) return const DictDemoPage();

          return DictDetailPage(entry: entry, isGuest: isGuest);
        },
      ),
      GoRoute(
        path: '/review-session',
        name: kReviewSessionRouteName,
        builder: (context, state) => const ReviewSessionPage(),
      ),

      // --- Speaking ---
      GoRoute(
        path: SpeakingHubPage.routePath,
        name: SpeakingHubPage.routeName,
        builder: (context, state) {
          final modeName = state.pathParameters['modeName'];
          final mode = SpeakingMode.values.firstWhere(
            (e) => e.name == modeName,
            orElse: () => SpeakingMode.readAloud,
          );
          return SpeakingHubPage(mode: mode);
        },
      ),
      GoRoute(
        name: SpeakingSkillsPage.routeName,
        path: '/speaking-skills/:setId',
        builder: (context, state) {
          final setId = state.pathParameters['setId'];
          if (setId == null) {
            return const Scaffold(
                body: Center(child: Text('Error: Missing ID')));
          }

          // 🔥 BẮT CỜ isRetake TỪ URL
          final isRetakeStr = state.uri.queryParameters['isRetake'];
          final isRetake = isRetakeStr == 'true';

          // Truyền vào Constructor
          return SpeakingSkillsPage(setId: setId, isRetake: isRetake);
        },
      ),
      GoRoute(
        path: FreeSpeakingPage.routePath,
        name: FreeSpeakingPage.routeName,
        builder: (context, state) => FreeSpeakingPage(
          scenario: state.extra is SpeakingScenarioEntity
              ? state.extra as SpeakingScenarioEntity
              : null,
        ),
      ),
      GoRoute(
        path: SpeakingProgressDashboardPage.routePath,
        name: SpeakingProgressDashboardPage.routeName,
        builder: (context, state) => const SpeakingProgressDashboardPage(),
      ),
      GoRoute(
        path: SpeakingNotebookPage.routePath,
        name: SpeakingNotebookPage.routeName,
        builder: (context, state) => const SpeakingNotebookPage(),
      ),
      GoRoute(
        path: SpeakingFeedbackPage.routePath,
        name: SpeakingFeedbackPage.routeName,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is SpeakingFeedbackPageArgs) {
            return SpeakingFeedbackPage(args: extra);
          }
          return const SpeakingFeedbackHistoryPage();
        },
      ),
      GoRoute(
        path: SpeakingFeedbackHistoryPage.routePath,
        name: SpeakingFeedbackHistoryPage.routeName,
        builder: (context, state) => const SpeakingFeedbackHistoryPage(),
      ),

      // --- Writing ---
      GoRoute(
        path: '/writing-topics',
        name: WritingTopicsPage.routeName,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<WritingBloc>()..add(GetWritingTopicsEvent()),
            child: const WritingTopicsPage(),
          );
        },
      ),
    ],
  );
}
