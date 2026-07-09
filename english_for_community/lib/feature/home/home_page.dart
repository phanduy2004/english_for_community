import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

// --- Import Core & Shared ---
import '../../core/notification/local_notification_service.dart';
import '../../core/repository/user_repository.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/animation/animated_status_container.dart';
import '../../core/ui/motion/celebrate_burst.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';
import '../../core/ui/widget/app_navigation_bar.dart';
import '../../core/ui/widget/app_skeleton.dart';
import '../../core/locale/l10n_context.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/ui/motion/app_count_up.dart';
import '../../core/ui/motion/app_entrance.dart';
import '../../core/ui/motion/streak_flame.dart';
import 'notification_dialog.dart';
import '../classroom_chat/dock/classroom_chat_dock_controller.dart';
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
import '../student/messages/student_classroom_chat_hub_page.dart';
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
  static const int _tabHome = 0;
  static const int _tabMessages = 1;
  static const int _tabProgress = 2;
  static const int _tabProfile = 3;

  int _tab = _tabHome;
  late final NotificationBloc _notificationBloc;

  Widget? _homeTab;
  Widget? _messagesTab;
  Widget? _progressTab;
  Widget? _profileTab;

  static const int _tabCount = 4;

  List<Widget> get _pages => [
        _homeTab ??= _HomeContentView(
          onOpenNotifications: _openNotifications,
          onOpenAiAssistant: _openAiAssistant,
          onOpenProfile: _openProfile,
        ),
        _messagesTab ??= const StudentClassroomChatHubPage(),
        _progressTab ??= const ProgressReportPage(),
        _profileTab ??= BlocProvider.value(
          value: GetIt.I<UserBloc>(),
          child: const ProfilePage(),
        ),
      ];

  int get _tabIndex => _tab.clamp(0, _tabCount - 1);

  void _selectTab(int index) {
    final next = index.clamp(0, _tabCount - 1);
    if (_tab == next) return;
    setState(() => _tab = next);
  }

  @override
  void initState() {
    super.initState();
    _notificationBloc = GetIt.I<NotificationBloc>();
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
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
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
      _selectTab(_tabProgress);
    } else if (type == 'STREAK_RESCUE') {
      Future.delayed(AppMotion.enter, () {
        if (mounted) showSpeakingModeDialog(context);
      });
    }
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
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
        print(
            '📩 [FCM Foreground] Data received but suppressed (Let Socket handle it)');
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
    await LocalNotificationService().cancelAll();
  }

  void _openAiAssistant() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.barrierDismiss,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: AppMotion.page,
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
    _selectTab(_tabProfile);
  }

  @override
  Widget build(BuildContext context) {
    registerClassroomChatDockController();
    final chatController = GetIt.I<ClassroomChatDockController>();

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _notificationBloc),
      ],
      child: ListenableBuilder(
        listenable: chatController,
        builder: (context, _) {
          final unread = chatController.unreadConversations;
          final messagesBadge =
              unread > 0 ? Text(unread > 99 ? '99+' : '$unread') : null;
          final tab = _tabIndex;

          return Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: IndexedStack(index: tab, children: _pages),
            ),
            bottomNavigationBar: AppNavigationBar.studentMain(
              currentIndex: tab,
              onIndexSelected: (i) {
                _selectTab(i);
                if (i == _tabHome)
                  context.read<UserBloc>().add(GetProfileEvent());
                if (i == _tabMessages) chatController.loadRooms(force: true);
              },
              homeLabel: context.l10n.navHome,
              messagesLabel: context.l10n.navMessages,
              progressLabel: context.l10n.navProgress,
              profileLabel: context.l10n.navProfile,
              messagesBadge: messagesBadge,
            ),
          );
        },
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
          context: context,
          icon: Icons.notifications_outlined,
          onPressed: onPressed,
          tooltip: AppLocalizations.of(context)!.notificationsTitle,
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
    final t = AppLocalizations.of(context)!;
    return StudentMobileUi.headerIconButton(
      context: context,
      icon: Icons.auto_awesome,
      iconColor: AppColors.onPrimary,
      backgroundColor: AppColors.primary,
      borderColor: AppColors.primary,
      tooltip: t.aiAssistantTitle,
      semanticsLabel: t.aiAssistantTitle,
      onPressed: onPressed,
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
        // Có data rồi → key ổn định: refresh nền không nháy skeleton / không chạy lại entrance.
        final statusKey = state.userEntity != null
            ? 'ready_${state.userEntity!.id}'
            : '${state.status.name}_${state.errorMessage ?? ''}';

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
    // Chỉ hiện skeleton/lỗi toàn trang khi CHƯA có data. Có data rồi thì refresh
    // nền giữ nguyên nội dung (không nháy) — silent refresh.
    if ((state.status == UserStatus.initial ||
            state.status == UserStatus.loading) &&
        state.userEntity == null) {
      return const HomeContentSkeleton();
    }
    if (state.status == UserStatus.error && state.userEntity == null) {
      return Center(
        child: Padding(
          padding: StudentMobileUi.pagePadding,
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

    if (state.userEntity != null) {
      final user = state.userEntity!;

      final int dailyProgress = user.dailyActivityProgress ?? 0;
      final int dailyGoal = user.dailyLessonGoal ?? 5;
      final bool dailyGoalReached = dailyGoal > 0 && dailyProgress >= dailyGoal;
      final int streak = user.currentStreak ?? 0;
      final bool streakAtRisk =
          streak > 0 && dailyGoal > 0 && dailyProgress < dailyGoal;
      final int streakRemaining = dailyGoal - dailyProgress;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<UserBloc>().add(GetProfileEvent());
          await context.read<UserBloc>().stream.firstWhere(
                (s) => s.status != UserStatus.loading,
              );
        },
        child: GamificationCelebrateHost(
          streak: user.currentStreak ?? 0,
          level: user.level ?? 1,
          dailyGoalReached: dailyGoalReached,
          child: SingleChildScrollView(
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: StudentMobileUi.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppEntrance.item(
                  context,
                  _buildHeader(
                    context,
                    user.fullName,
                    user.avatarUrl,
                    t,
                    onOpenNotifications: onOpenNotifications,
                    onOpenAiAssistant: onOpenAiAssistant,
                    onOpenProfile: onOpenProfile,
                  ),
                  index: 0,
                ),
                const SizedBox(height: AppSpacing.s4),
                AppEntrance.item(
                  context,
                  _buildDailyGoalCard(context, dailyProgress, dailyGoal, t),
                  index: 1,
                ),
                if (streakAtRisk) ...[
                  const SizedBox(height: AppSpacing.s3),
                  AppEntrance.item(
                    context,
                    _buildStreakNudge(context, streakRemaining, streak, t),
                    index: 2,
                  ),
                ],
                const SizedBox(height: AppSpacing.s5),
                AppEntrance.item(
                  context,
                  _buildStatsRow(context, user, t),
                  index: 3,
                ),
                const SizedBox(height: StudentMobileUi.sectionGap),
                AppEntrance.item(
                  context,
                  _buildLessonsSection(context, showAllLessons, t),
                  index: 4,
                ),
                const SizedBox(height: StudentMobileUi.sectionGap),
                AppEntrance.item(
                  context,
                  _buildQuickActionsSection(context, t),
                  index: 5,
                ),
              ],
            ),
          ),
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
              const SizedBox(height: AppSpacing.s3),
              Text(
                t.homeReadySubtitle,
                style: StudentMobileUi.body(context)
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        _HomeHeaderNotificationButton(onPressed: onOpenNotifications),
        const SizedBox(width: AppSpacing.s3),
        _HomeHeaderAiButton(onPressed: onOpenAiAssistant),
        const SizedBox(width: AppSpacing.s3),
        StudentMobileUi.tappable(
          context: context,
          onTap: onOpenProfile,
          minSize: 48,
          tooltip: t.profileAndSettings,
          semanticsLabel: t.profileAndSettings,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            width: 36,
            height: 36,
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
      ],
    );
  }

  Widget _buildDailyGoalCard(
    BuildContext context,
    int progress,
    int goal,
    AppLocalizations t,
  ) {
    final bool complete = goal > 0 && progress >= goal;
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.homeDailyGoal,
                    style: StudentMobileUi.cardTitle(context)),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  t.homeDailyLessonsLine(progress, goal),
                  style: StudentMobileUi.body(context).copyWith(
                    color:
                        complete ? AppColors.success : AppColors.textSecondary,
                    fontWeight: complete ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          _DailyGoalRing(progress: progress, goal: goal),
        ],
      ),
    );
  }

  /// Nudge amber "sắp mất chuỗi" — chỉ hiện khi còn streak nhưng chưa xong goal hôm nay.
  Widget _buildStreakNudge(
    BuildContext context,
    int remaining,
    int streak,
    AppLocalizations t,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          StreakFlame(streak: streak, size: 20),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              t.homeStreakAtRisk(remaining, streak),
              style: StudentMobileUi.body(context).copyWith(
                color: AppColors.accentDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, dynamic user, AppLocalizations t) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StudentMobileUi.statCard(
              context: context,
              icon: Icons.local_fire_department_rounded,
              value: '${user.currentStreak ?? 0}',
              valueContent: AppCountUpText(
                value: user.currentStreak ?? 0,
                style: StudentMobileUi.kpi(context),
              ),
              iconContent: StreakFlame(streak: user.currentStreak ?? 0, size: 15),
              label: t.statStreak,
              iconColor: AppColors.accent,
              iconBg: AppColors.accentTint,
              compact: true,
            ),
          ),
          const SizedBox(width: StudentMobileUi.cardGap),
          Expanded(
            child: StudentMobileUi.statCard(
              context: context,
              icon: Icons.star_rounded,
              value: '${user.totalPoints ?? 0}',
              valueContent: AppCountUpText(
                value: user.totalPoints ?? 0,
                style: StudentMobileUi.kpi(context),
              ),
              label: t.statPoints,
              iconColor: AppColors.accent,
              iconBg: AppColors.accentTint,
              compact: true,
            ),
          ),
          const SizedBox(width: StudentMobileUi.cardGap),
          Expanded(
            child: StudentMobileUi.statCard(
              context: context,
              icon: Icons.workspace_premium_rounded,
              value: 'Lv.${user.level ?? 1}',
              valueContent: AppCountUpText(
                value: user.level ?? 1,
                prefix: 'Lv.',
                style: StudentMobileUi.kpi(context),
              ),
              label: t.statLevelLabel,
              iconColor: AppColors.primary,
              iconBg: AppColors.primaryTint,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsSection(BuildContext context,
      ValueNotifier<bool> showAllNotifier, AppLocalizations t) {
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
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 3;
            const itemHeight = 96.0;
            final itemWidth =
                (constraints.maxWidth - AppSpacing.s4 * (columns - 1)) /
                    columns;
            final childAspectRatio =
                (itemWidth / itemHeight).clamp(0.9, 2.8).toDouble();

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: AppSpacing.s4,
              crossAxisSpacing: AppSpacing.s4,
              childAspectRatio: childAspectRatio,
              children: [
                StudentMobileUi.quickActionButton(
                  context: context,
                  icon: Icons.favorite_rounded,
                  label: t.homeQuickFavorites,
                  skill: SkillType.vocabulary,
                  onTap: () => context.pushNamed(
                    'VocabularyPage',
                    extra: const {'initialTabIndex': 0},
                  ),
                ),
                StudentMobileUi.quickActionButton(
                  context: context,
                  icon: Icons.style_rounded,
                  label: t.homeQuickFlashcards,
                  skill: SkillType.listening,
                  onTap: () => context.pushNamed(
                    'VocabularyPage',
                    extra: const {'initialTabIndex': 1},
                  ),
                ),
                StudentMobileUi.quickActionButton(
                  context: context,
                  icon: Icons.bar_chart_rounded,
                  label: t.homeQuickStats,
                  skill: SkillType.speaking,
                  onTap: () => context.pushNamed(ProgressReportPage.routeName),
                ),
                StudentMobileUi.quickActionButton(
                  context: context,
                  icon: Icons.history_rounded,
                  label: t.exerciseHistory,
                  skill: SkillType.writing,
                  onTap: () =>
                      context.pushNamed(MyExerciseHistoryPage.routeName),
                ),
                StudentMobileUi.quickActionButton(
                  context: context,
                  icon: Icons.class_rounded,
                  label: t.homeQuickMyClasses,
                  iconColor: AppColors.accent,
                  iconBg: AppColors.accentTint,
                  onTap: () => context.push(MyClassesHubPage.routePath),
                ),
                StudentMobileUi.quickActionButton(
                  context: context,
                  icon: Icons.public_rounded,
                  label: t.homeQuickPublicExam,
                  skill: SkillType.reading,
                  onTap: () => context.push(MyClassesHubPage.routePath),
                ),
              ],
            );
          },
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
    final skill = _skillType;
    return StudentMobileUi.skillAccentCard(
      skill: skill,
      emphasized: false,
      scaleOnPress: true,
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
          StudentMobileUi.skillIconBox(icon, skill: skill),
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
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// Vòng tròn tiến độ mục tiêu ngày — fill động, chuyển xanh + tick khi hoàn thành.
class _DailyGoalRing extends StatelessWidget {
  const _DailyGoalRing({
    required this.progress,
    required this.goal,
  });

  final int progress;
  final int goal;

  @override
  Widget build(BuildContext context) {
    const double size = 60;
    final double fraction = goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 0.0;
    final bool complete = goal > 0 && progress >= goal;
    final Color color = complete ? AppColors.success : AppColors.accent;
    final bool reduce = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: reduce ? fraction : 0, end: fraction),
        duration:
            AppMotion.effective(context, const Duration(milliseconds: 650)),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  backgroundColor: AppColors.outlineMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              if (complete)
                Icon(Icons.check_rounded, color: color, size: size * 0.44)
              else
                Text(
                  '$progress/$goal',
                  style: StudentMobileUi.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
