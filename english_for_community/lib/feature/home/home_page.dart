import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Import Core & Shared ---
import '../../core/notification/local_notification_service.dart';
import '../../core/repository/user_repository.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/animation/animated_status_container.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';
import '../../core/ui/widget/app_navigation_bar.dart';
import '../../core/ui/widget/app_skeleton.dart';
import '../../core/locale/l10n_context.dart';
import '../../l10n/generated/app_localizations.dart';
import '../progress/bloc/progress_bloc.dart';
import '../progress/bloc/progress_event.dart';
import '../progress/bloc/progress_state.dart';
import 'widgets/home_study_dashboard.dart';
import '../../core/notification/app_notification_listener.dart';
import '../../core/notification/notification_navigation.dart';

// --- Feature Imports ---
import 'bloc_noti/notification_bloc.dart';
import 'bloc_noti/notification_event.dart';
import 'bloc_noti/notification_state.dart';
import 'listening_mode_dialog.dart';
import '../auth/bloc/user_bloc.dart';
import '../auth/bloc/user_event.dart';
import '../auth/bloc/user_state.dart';
import '../profile/my_exercise_history/my_exercise_history_page.dart';
import '../profile/profile_page.dart';
import '../student/classes/my_classes_hub_page.dart';
import '../student/exams/public_exam_join_page.dart';
import '../progress/progress_report_page.dart';
import '../reading/reading_list_page.dart';
import '../writing/writing_topics_page.dart';
import 'ai_assistant_dialog.dart';
import 'speaking_mode_dialog.dart';

// ============================================================================
// 1. MAIN PAGE: Controller Logic & Scaffold
// ============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  late final NotificationBloc _notificationBloc;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _notificationBloc = GetIt.I<NotificationBloc>();
    _pages = [
      _HomeContentView(
        onOpenNotifications: _openNotifications,
        onOpenAiAssistant: _openAiAssistant,
        onOpenProfile: _openProfile,
      ),
      const ProgressReportPage(),
      BlocProvider.value(
        value: GetIt.I<UserBloc>(),
        child: const ProfilePage(),
      ),
    ];
    _notificationBloc.add(const NotificationLoadStarted());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserBloc>().add(GetProfileEvent());
      _initializeLocalNotifications();

      _setupPushNotifications();
      _setupInteractedMessage();
    });
  }

  Future<void> _setupInteractedMessage() async {
    // 1. App đang tắt (Terminated)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print("🚀 App launched from Terminated via Notification");
      _handleMessageNavigation(initialMessage.data);
    }

    // 2. App đang chạy ngầm (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 App opened from Background via Notification");
      _handleMessageNavigation(message.data);
    });
  }

  void _handleMessageNavigation(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    final router = GoRouter.of(context);
    if (navigateFromNotification(router, data: data)) return;

    final type = data['type']?.toString();
    if (type == 'PROGRESS_NUDGE') {
      setState(() => _tab = 1);
    } else if (type == 'STREAK_RESCUE') {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) showSpeakingModeDialog(context);
      });
    }
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null) {
        GetIt.I<UserRepository>().updateFcmToken(token);
      }

      messaging.onTokenRefresh.listen((newToken) {
        GetIt.I<UserRepository>().updateFcmToken(newToken);
      });

      // 🔥 SỬA LẠI ĐOẠN NÀY:
      // Khi App đang mở (Foreground), chỉ in log chơi thôi.
      // TUYỆT ĐỐI KHÔNG gọi LocalNotificationService ở đây nữa.
      // Vì SocketService đã lo việc hiển thị thông báo rồi.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 [FCM Foreground] Data received but suppressed (Let Socket handle it)');
        print('   - Type: ${message.data['type']}');

        // Nếu bạn muốn chắc chắn cập nhật badge kể cả khi socket lỡ miss (hiếm khi),
        // thì chỉ gọi load lại badge thôi, KHÔNG hiện popup.
        _notificationBloc.add(const NotificationLoadStarted(isRefresh: true));
      });
    }
  }

  Future<void> _initializeLocalNotifications() async {
    await LocalNotificationService().requestPermissions();
    await _syncDailyReminders();
  }

  Future<void> _syncDailyReminders() async {
    final userState = context.read<UserBloc>().state;
    if (userState.status != UserStatus.success || userState.userEntity == null) return;

    final user = userState.userEntity!;
    final prefs = await SharedPreferences.getInstance();

    if (user.reminder == null) {
      await LocalNotificationService().cancelAll();
      await prefs.remove('CACHED_DAILY_WORDS');
      return;
    }

    final vocabRepo = GetIt.I<UserVocabRepository>();
    final result = await vocabRepo.getDailyReminders();

    result.fold(
          (failure) async {
        final String? cachedJson = prefs.getString('CACHED_DAILY_WORDS');
        if (cachedJson != null) {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          await LocalNotificationService().scheduleDailyWordSequence(
            words: decoded, time: user.reminder!,
          );
        }
      },
          (words) async {
        if (words.isNotEmpty) {
          final wordsMapList = words.map((e) => {
            'headword': e.headword,
            'shortDefinition': e.shortDefinition,
          }).toList();
          await prefs.setString('CACHED_DAILY_WORDS', jsonEncode(wordsMapList));
          await LocalNotificationService().scheduleDailyWordSequence(
            words: wordsMapList, time: user.reminder!,
          );
        }
      },
    );
  }

  void _openAiAssistant() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.barrierDismiss,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => FadeTransition(
        opacity: anim1,
        child: const AiAssistantDialog(),
      ),
    );
  }

  void _openNotifications() {
    showAppNotificationsDialog(context);
  }

  void _openProfile() {
    context.read<UserBloc>().add(GetProfileEvent());
    setState(() => _tab = 2);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _notificationBloc),
      ],
      child: Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: IndexedStack(index: _tab, children: _pages),
          ),
          bottomNavigationBar: AppNavigationBar.main(
            currentIndex: _tab,
            onIndexSelected: (i) {
              if (i == 0) context.read<UserBloc>().add(GetProfileEvent());
              setState(() => _tab = i);
            },
            homeLabel: context.l10n.navHome,
            progressLabel: context.l10n.navProgress,
            profileLabel: context.l10n.navProfile,
            vocabularyBadge: null,
          ),
        ),
    );
  }
}

// ============================================================================
// 2. HOME HEADER ACTIONS (thông báo + AI — cùng hàng avatar, đối xứng nội dung)
// ============================================================================

class _HomeHeaderNotificationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HomeHeaderNotificationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return StudentMobileUi.headerIconButton(
          icon: Icons.notifications_outlined,
          onPressed: onPressed,
          badge: StudentMobileUi.notificationBadge(state.unreadCount),
        );
      },
    );
  }
}

class _HomeHeaderAiButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HomeHeaderAiButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        splashColor: AppColors.onPrimary.withValues(alpha: 0.12),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.auto_awesome, color: AppColors.onPrimary, size: 17),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. HOME CONTENT VIEW
// ============================================================================

class _HomeContentView extends StatelessWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenAiAssistant;
  final VoidCallback onOpenProfile;

  const _HomeContentView({
    required this.onOpenNotifications,
    required this.onOpenAiAssistant,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final showAllLessons = ValueNotifier<bool>(false);

    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        final statusKey =
            '${state.status.name}_${state.userEntity?.id ?? 'x'}_${state.errorMessage ?? ''}';

        return AnimatedStatusContainer(
          statusKey: statusKey,
          child: _homeBodyForState(
            context,
            state,
            showAllLessons,
            onOpenNotifications,
            onOpenAiAssistant,
            onOpenProfile,
            t,
          ),
        );
      },
    );
  }

  Widget _homeBodyForState(
    BuildContext context,
    UserState state,
    ValueNotifier<bool> showAllLessons,
    VoidCallback onOpenNotifications,
    VoidCallback onOpenAiAssistant,
    VoidCallback onOpenProfile,
    AppLocalizations t,
  ) {
    if (state.status == UserStatus.initial || state.status == UserStatus.loading) {
      return const HomeContentSkeleton();
    }
    if (state.status == UserStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SoftErrorBanner(
            message: state.errorMessage ?? t.homeLoadFailed,
            onRetry: () => context.read<UserBloc>().add(GetProfileEvent()),
          ),
        ),
      );
    }
    if (state.status == UserStatus.unauthenticated) {
      return Center(
        child: Text(
          t.homePleaseSignIn,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    if (state.status == UserStatus.success && state.userEntity != null) {
      final user = state.userEntity!;

      final int dailyProgress = user.dailyActivityProgress ?? 0;
      final int dailyGoal = user.dailyLessonGoal ?? 5;
      final double progressValue =
          (dailyGoal > 0) ? (dailyProgress / dailyGoal).clamp(0.0, 1.0) : 0.0;

      return BlocProvider(
        create: (_) => GetIt.I<ProgressBloc>()..add(const FetchProgressData(range: 'week')),
        child: Builder(
          builder: (scrollContext) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                scrollContext.read<UserBloc>().add(GetProfileEvent());
                scrollContext.read<ProgressBloc>().add(const FetchProgressData(range: 'week'));
                await scrollContext.read<UserBloc>().stream.firstWhere(
                      (s) => s.status != UserStatus.loading,
                    );
                await scrollContext.read<ProgressBloc>().stream.firstWhere(
                      (s) => s.status != ProgressStatus.loading,
                    );
              },
              child: SingleChildScrollView(
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: StudentMobileUi.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      scrollContext,
                      user.fullName,
                      user.avatarUrl,
                      t,
                      onOpenNotifications: onOpenNotifications,
                      onOpenAiAssistant: onOpenAiAssistant,
                      onOpenProfile: onOpenProfile,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    _buildDailyGoalCard(scrollContext, dailyProgress, dailyGoal, progressValue, t),
                    const SizedBox(height: AppSpacing.s5),
                    HomeStudyDashboard(
                      streak: user.currentStreak ?? 0,
                      dailyProgress: dailyProgress,
                      dailyGoal: dailyGoal,
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _buildStatsRow(scrollContext, user, t),
                    const SizedBox(height: StudentMobileUi.sectionGap),
                    _buildLessonsSection(scrollContext, showAllLessons, t),
                    const SizedBox(height: StudentMobileUi.sectionGap),
                    _buildQuickActionsSection(scrollContext, t),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return Center(
      child: Text(t.homeNoData, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String? avatarUrl,
    AppLocalizations t, {
    required VoidCallback onOpenNotifications,
    required VoidCallback onOpenAiAssistant,
    required VoidCallback onOpenProfile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.homeGreeting(name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StudentMobileUi.greeting(context),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(t.homeReadySubtitle, style: StudentMobileUi.body(context)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        _HomeHeaderNotificationButton(onPressed: onOpenNotifications),
        const SizedBox(width: AppSpacing.s3),
        _HomeHeaderAiButton(onPressed: onOpenAiAssistant),
        const SizedBox(width: AppSpacing.s3),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onOpenProfile,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline, width: 1),
                image: DecorationImage(
                  image: (avatarUrl != null && avatarUrl.startsWith('http'))
                      ? NetworkImage(avatarUrl)
                      : const AssetImage('assets/avatar.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalCard(
    BuildContext context,
    int progress,
    int goal,
    double progressValue,
    AppLocalizations t,
  ) {
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.homeDailyGoal, style: StudentMobileUi.cardTitle(context)),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      t.homeDailyLessonsLine(progress, goal),
                      style: StudentMobileUi.body(context),
                    ),
                  ],
                ),
              ),
              Icon(Icons.emoji_events_outlined, color: AppColors.accent, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          StudentMobileUi.skillProgressBar(value: progressValue, height: 6),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, dynamic user, AppLocalizations t) {
    return Row(
      children: [
        Expanded(
          child: StudentMobileUi.statCard(
            context: context,
            icon: Icons.local_fire_department_rounded,
            value: '${user.currentStreak ?? 0}',
            label: t.statStreak,
            iconColor: AppColors.accent,
            iconBg: AppColors.accentTint,
          ),
        ),
        const SizedBox(width: StudentMobileUi.cardGap),
        Expanded(
          child: StudentMobileUi.statCard(
            context: context,
            icon: Icons.star_rounded,
            value: '${user.totalPoints ?? 0}',
            label: t.statPoints,
            skill: SkillType.reading,
          ),
        ),
        const SizedBox(width: StudentMobileUi.cardGap),
        Expanded(
          child: StudentMobileUi.statCard(
            context: context,
            icon: Icons.workspace_premium_rounded,
            value: 'Lv.${user.level ?? 1}',
            label: t.statLevelLabel,
            skill: SkillType.writing,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsSection(BuildContext context, ValueNotifier<bool> showAllNotifier, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: showAllNotifier,
          builder: (context, showAll, _) {
            return StudentMobileUi.sectionHeader(
              context,
              title: t.homeTodaysLessons,
              actionLabel: showAll ? t.homeShowLess : t.homeSeeAll,
              onAction: () => showAllNotifier.value = !showAll,
            );
          },
        ),
        const SizedBox(height: AppSpacing.s4),
        ValueListenableBuilder<bool>(
          valueListenable: showAllNotifier,
          builder: (context, showAll, _) {
            return Column(
              children: [
                _LessonCard(
                  slot: _HomeLessonSlot.listening,
                  icon: Icons.headphones_outlined,
                  title: t.homeLessonListeningTitle,
                  subtitle: t.homeLessonListeningSubtitle,
                ),
                const SizedBox(height: StudentMobileUi.cardGap),
                _LessonCard(
                  slot: _HomeLessonSlot.reading,
                  icon: Icons.menu_book_outlined,
                  title: t.homeLessonReadingTitle,
                  subtitle: t.homeLessonReadingSubtitle,
                ),
                const SizedBox(height: StudentMobileUi.cardGap),
                _LessonCard(
                  slot: _HomeLessonSlot.vocabulary,
                  icon: Icons.style_outlined,
                  title: t.homeLessonVocabTitle,
                  subtitle: t.homeLessonVocabSubtitle,
                ),
                if (showAll) ...[
                  const SizedBox(height: StudentMobileUi.cardGap),
                  _LessonCard(
                    slot: _HomeLessonSlot.speaking,
                    icon: Icons.record_voice_over_outlined,
                    title: t.homeLessonSpeakingTitle,
                    subtitle: t.homeLessonSpeakingSubtitle,
                  ),
                  const SizedBox(height: StudentMobileUi.cardGap),
                  _LessonCard(
                    slot: _HomeLessonSlot.writing,
                    icon: Icons.edit_note_outlined,
                    title: t.homeLessonWritingTitle,
                    subtitle: t.homeLessonWritingSubtitle,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.homeQuickAccess, style: StudentMobileUi.sectionTitle(context)),
        const SizedBox(height: AppSpacing.s5),
        Row(
          children: [
            Expanded(
              child: StudentMobileUi.quickActionButton(
                context: context,
                icon: Icons.favorite_rounded,
                label: t.homeQuickFavorites,
                skill: SkillType.vocabulary,
                onTap: () => context.pushNamed('VocabularyPage', extra: const {'initialTabIndex': 0}),
              ),
            ),
            Expanded(
              child: StudentMobileUi.quickActionButton(
                context: context,
                icon: Icons.style_rounded,
                label: t.homeQuickFlashcards,
                skill: SkillType.listening,
                onTap: () => context.pushNamed('VocabularyPage', extra: const {'initialTabIndex': 1}),
              ),
            ),
            Expanded(
              child: StudentMobileUi.quickActionButton(
                context: context,
                icon: Icons.bar_chart_rounded,
                label: t.homeQuickStats,
                skill: SkillType.speaking,
                onTap: () => context.pushNamed(ProgressReportPage.routeName),
              ),
            ),
            Expanded(
              child: StudentMobileUi.quickActionButton(
                context: context,
                icon: Icons.history_rounded,
                label: t.exerciseHistory,
                skill: SkillType.writing,
                onTap: () => context.pushNamed(MyExerciseHistoryPage.routeName),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Row(
          children: [
            Expanded(
              child: StudentMobileUi.quickActionButton(
                context: context,
                icon: Icons.class_rounded,
                label: t.homeQuickMyClasses,
                iconColor: AppColors.accent,
                iconBg: AppColors.accentTint,
                onTap: () => context.push(MyClassesHubPage.routePath),
              ),
            ),
            Expanded(
              child: StudentMobileUi.quickActionButton(
                context: context,
                icon: Icons.public_rounded,
                label: t.homeQuickPublicExam,
                skill: SkillType.reading,
                onTap: () => context.push(PublicExamJoinPage.routePath),
              ),
            ),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

enum _HomeLessonSlot { listening, reading, vocabulary, speaking, writing }

class _LessonCard extends StatelessWidget {
  final _HomeLessonSlot slot;
  final IconData icon;
  final String title;
  final String subtitle;

  const _LessonCard({
    required this.slot,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  SkillType get _skillType {
    switch (slot) {
      case _HomeLessonSlot.listening:
        return SkillType.listening;
      case _HomeLessonSlot.reading:
        return SkillType.reading;
      case _HomeLessonSlot.vocabulary:
        return SkillType.vocabulary;
      case _HomeLessonSlot.speaking:
        return SkillType.speaking;
      case _HomeLessonSlot.writing:
        return SkillType.writing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentMobileUi.skillAccentCard(
      skill: _skillType,
      onTap: () {
        switch (slot) {
          case _HomeLessonSlot.listening:
            showListeningModeDialog(context);
            break;
          case _HomeLessonSlot.reading:
            context.pushNamed(ReadingListPage.routeName);
            break;
          case _HomeLessonSlot.vocabulary:
            context.pushNamed('VocabularyPage');
            break;
          case _HomeLessonSlot.speaking:
            showSpeakingModeDialog(context);
            break;
          case _HomeLessonSlot.writing:
            context.pushNamed(WritingTopicsPage.routeName);
            break;
        }
      },
      child: Row(
        children: [
          StudentMobileUi.skillIconBox(icon, skill: _skillType),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: StudentMobileUi.cardTitle(context)),
                const SizedBox(height: AppSpacing.s2),
                Text(subtitle, style: StudentMobileUi.body(context)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppSkillColors.of(_skillType).color, size: 18),
        ],
      ),
    );
  }
}