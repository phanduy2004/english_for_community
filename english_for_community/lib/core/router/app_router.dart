// lib/core/router/app_router.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- CORE & UTILS ---
import '../../feature/admin/content_management/listening/admin_listening_list_view.dart';
import '../../feature/admin/content_management/listening/listening_editor_page.dart';
import '../../feature/admin/content_management/reading/admin_reading_list_view.dart';
import '../../feature/admin/content_management/reading/reading_editor_page.dart';
import '../../feature/admin/content_management/speaking/admin_speaking_list_view.dart';
import '../../feature/admin/content_management/speaking/speaking_editor_page.dart';
import '../../feature/admin/content_management/writing/admin_writing_list_view.dart';
import '../../feature/admin/content_management/writing/writing_topic_editor_page.dart';
import '../../feature/admin/report_management/report_management_page.dart';
import '../../feature/auth/forgot_password_page.dart';
import '../../feature/auth/otp_verification_page.dart';
import '../../feature/auth/register_page.dart';
import '../../feature/auth/reset_password_page.dart';
import '../get_it/get_it.dart';
import '../utils/global_keys.dart';
import '../sqflite/dict_db.dart';

// --- AUTH & BLOCS ---
import '../../feature/auth/login_page.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_state.dart';
import '../../feature/onboarding_page.dart';

// --- ADMIN PAGES ---
import '../../feature/admin/dashboard_home/admin_dashboard.dart';
import '../../feature/admin/user_management/user_management_page.dart';
// 👇 IMPORT CÁC PAGE QUẢN LÝ NỘI DUNG MỚI
import '../../feature/admin/content_management/content_dashboard_page.dart';
import '../../feature/home/home_page.dart';
import '../../feature/profile/profile_page.dart';
import '../../feature/profile/edit_profile_page.dart';
import '../../feature/progress/progress_report_page.dart' hide AdminDashboardPage;

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

// Writing
import '../../feature/writing/writing_topics_page.dart';
import '../../feature/writing/bloc/writing_bloc.dart';
import '../../feature/writing/bloc/writing_event.dart';

// Vocabulary
import '../../feature/vocabulary/vocabulary_home_page.dart';
import '../../feature/vocabulary/dict_demo_page.dart';
import '../../feature/vocabulary/dict_detail_page.dart';
import '../../feature/vocabulary/review_session_page.dart';

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
      body: Center(child: CircularProgressIndicator()),
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
        ForgotPasswordPage.routePath, // 🔥 NEW: Add Forgot Password to public routes
        ResetPasswordPage.routePath,

      ];

      // 1. Đang load thông tin user -> Splash
      if (userState.status == UserStatus.initial ||
          (userState.status == UserStatus.loading && userState.userEntity == null)) {
        return location == SplashPage.routePath ? null : SplashPage.routePath;
      }

      // 2. Chưa đăng nhập -> Login
      if (userState.status == UserStatus.unauthenticated) {
        return publicRoutes.contains(location) ? null : LoginPage.routePath;
      }

      // 3. Đã đăng nhập
      if (userState.status == UserStatus.success) {
        final user = userState.userEntity;

        // 🔥 ADMIN CHECK 🔥
        if (user?.role == 'admin') {
          // Nếu Admin đang ở trang Login/Splash -> Vào Dashboard
          if (publicRoutes.contains(location) || location == SplashPage.routePath) {
            return AdminDashboardPage.routePath;
          }
          // Chặn Admin vào Home của User thường (nếu muốn)
          if (location == HomePage.routePath) {
            return AdminDashboardPage.routePath;
          }
        }
        // 🟢 USER THƯỜNG
        else {
          // Chặn User thường truy cập các route bắt đầu bằng '/admin'
          if (publicRoutes.contains(location) || location == SplashPage.routePath || location.contains('/admin')) {
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
      // 👑 ADMIN ROUTES
      // ==========================================
      GoRoute(
        path: '/admin-dashboard',
        name: AdminDashboardPage.routeName,
        builder: (context, state) => const AdminDashboardPage(),
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
        path: '/admin/reports', // Khớp với routePath bạn đã đặt trong file Page
        name: ReportManagementPage.routeName,
        builder: (context, state) => const ReportManagementPage(),
      ),
      // 👇 QUẢN LÝ NỘI DUNG (NESTED ROUTES) 👇
      GoRoute(
        path: '/admin/content',
        name: ContentDashboardPage.routeName,
        builder: (context, state) => const ContentDashboardPage(),
        routes: [
          // 1. Route Danh sách
          GoRoute(
            path: ':type', // URL: /admin/content/reading
            name: 'ContentListViewRoute',
            builder: (context, state) {
              final type = state.pathParameters['type'];

              // 👇 KIỂM TRA & TRẢ VỀ MÀN HÌNH TƯƠNG ỨNG
              if (type == 'reading') {
                return const AdminReadingListView(skillType: 'reading');
              }
              else if (type == 'listening') { // 🟢 Thêm case Listening
                return const AdminListeningListView();
              }
              // 👇 THÊM CASE SPEAKING
              else if (type == 'speaking') {
                return const AdminSpeakingListView();
              }
              else if (type == 'writing') {
                return const AdminWritingListView();
              }
              return Scaffold(body: Center(child: Text("Unknown type: $type")));
            },
            routes: [
              // 2. Route Editor
              GoRoute(
                path: 'editor',
                name: 'ContentEditorRoute',
                builder: (context, state) {
                  final type = state.pathParameters['type'];

                  // 🔥 KIỂM TRA DÒNG NÀY: Lấy ID từ extra
                  final id = state.extra as String?;

                  // In ra log để kiểm tra xem có ID không
                  print("DEBUG ROUTER - Type: $type, ID: $id");

                  if (type == 'reading') {
                    return ReadingEditorPage(id: id);
                  }
                  else if (type == 'listening') {
                    // 👇 Truyền ID vào đây
                    return ListeningEditorPage(id: id);
                  }
                  // 👇 THÊM CASE SPEAKING
                  else if (type == 'speaking') {
                    return SpeakingEditorPage(id: id);
                  }
                  else if (type == 'writing') {
                    return WritingTopicEditorPage(id: id);
                  }
                  return Scaffold(body: Center(child: Text("Error: $type")));
                },
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
          final extra = state.extra as Map<String, dynamic>? ?? {};  // Safer cast
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
        path: '/profile',
        name: 'ProfilePage',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: EditProfilePage.routePath,
        name: EditProfilePage.routeName,
        builder: (context, state) => EditProfilePage(),
      ),
      GoRoute(
        path: ProgressReportPage.routePath,
        name: ProgressReportPage.routeName,
        builder: (context, state) => const ProgressReportPage(),
      ),
      // --- Listening ---
      GoRoute(
        path: ListeningListPage.routePath,
        name: ListeningListPage.routeName,
        builder: (context, state) => const ListeningListPage(),
      ),
      GoRoute(
        path: '/listening-skills/:listeningId',
        name: 'ListeningSkillsPage',
        builder: (context, state) {
          final listeningId = state.pathParameters['listeningId'] ?? '';
          final audioUrl = state.uri.queryParameters['audioUrl'] ?? '';
          final title = state.uri.queryParameters['title'];
          final levelText = state.uri.queryParameters['levelText'];
          return ListeningSkillsPage(
            listeningId: listeningId,
            audioUrl: audioUrl,
            title: title,
            levelText: levelText,
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
        builder: (context, state) => const VocabularyHomePage(),
      ),
      GoRoute(
        path: '/dictionary-search',
        name: kDictDemoRouteName,
        builder: (context, state) => const DictDemoPage(),
      ),
      GoRoute(
        path: '/dictionary-detail',
        name: kDictDetailRouteName,
        builder: (context, state) {
          final entry = state.extra as Entry?;
          if (entry == null) return const DictDemoPage();
          return DictDetailPage(entry: entry);
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
          if (setId == null) return const Scaffold(body: Center(child: Text('Error: Missing ID')));
          return SpeakingSkillsPage(setId: setId);
        },
      ),
      GoRoute(
        path: FreeSpeakingPage.routePath,
        name: FreeSpeakingPage.routeName,
        builder: (context, state) => const FreeSpeakingPage(),
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