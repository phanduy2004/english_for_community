import 'package:english_for_community/feature/ai_tutor_page.dart';
import 'package:english_for_community/feature/gamification_notifications_page.dart';
import 'package:english_for_community/feature/listening/list_listening/listening_list_page.dart';
import 'package:english_for_community/feature/profile/edit_profile_page.dart';
import 'package:english_for_community/feature/profile_page.dart';
import 'package:english_for_community/feature/progress_report_page.dart';
import 'package:go_router/go_router.dart';

import '../../feature/home/home_page.dart';
import '../../feature/listening/listening_skill/listening_skills_page.dart';
import '../../feature/auth/login_page.dart';
import '../../feature/onboarding_page.dart';
import '../../feature/reading_page.dart';
import '../../feature/speaking_skills_page.dart';
import '../../feature/vocabulary_page.dart';

class AppRouter{
  static var router = GoRouter(initialLocation: '/onboarding',routes: [
    GoRoute(
      path: '/listening',
      name: 'ListeningSkillsPage',
      builder: (context, state) => const ListeningSkillsPage(),
    ),
    GoRoute(
      path: '/reading',
      name: 'ReadingPage',
      builder: (context, state) => const ReadingPage(),
    ),
    GoRoute(
      path: '/vocabulary',
      name: 'VocabularyPage',
      builder: (context, state) => const VocabularyPage(),
    ),
    GoRoute(
      path: '/speaking',
      name: 'SpeakingSkillsPage',
      builder: (context, state) => const SpeakingSkillsPage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'OnboardingPage',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: LoginPage.routePath,
      name: LoginPage.routeName,
      builder: (context, state){return LoginPage();
        },
    ),
    GoRoute(
      path: HomePage.routePath,
      name: HomePage.routeName,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/ai-tutor',
      name: 'AITutorPage',
      builder: (context, state) => const AITutorPage(),
    ),
    GoRoute(
      path: '/gamification',
      name: 'GamificationNotificationPage',
      builder: (context, state) => const GamificationNotificationPage(),
    ),
    GoRoute(
      path: '/progress',
      name: 'ProgressReportPage',
      builder: (context, state) => const ProgressReportPage(),
    ),
    GoRoute(
      path: '/profile',
      name: 'ProfilePage',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: ListeningListPage.routePath,
      name: ListeningListPage.routeName,
      builder: (context, state) => const ListeningListPage(),
    ),
    GoRoute(
      path: EditProfilePage.routePath,
      name: EditProfilePage.routeName,
      builder: (context, state){return EditProfilePage();
      },
    ),
  ]);
}