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
import '../../core/socket/socket_service.dart';
import '../../core/theme/app_color.dart';
import '../../core/ui/animation/animated_status_container.dart';
import '../../core/ui/interactive/scale_pressable.dart';
import '../../core/ui/widget/app_navigation_bar.dart';
import '../../core/ui/widget/app_skeleton.dart';
import '../progress/bloc/progress_bloc.dart';
import '../progress/bloc/progress_event.dart';
import 'widgets/home_study_dashboard.dart';
import '../../core/entity/notification_entity.dart';

// --- Feature Imports ---
import 'bloc_noti/notification_bloc.dart';
import 'bloc_noti/notification_event.dart';
import 'bloc_noti/notification_state.dart';
import 'listening_mode_dialog.dart';
import 'notification_dialog.dart';

import '../auth/bloc/user_bloc.dart';
import '../auth/bloc/user_event.dart';
import '../auth/bloc/user_state.dart';
import '../profile/my_exercise_history/my_exercise_history_page.dart';
import '../profile/profile_page.dart';
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
  bool _isSocketSetup = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _notificationBloc = GetIt.I<NotificationBloc>();
    _pages = [
      _HomeContentView(
        onOpenNotifications: _openNotifications,
        onOpenAiAssistant: _openAiAssistant,
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

      final userState = context.read<UserBloc>().state;
      if (userState.status == UserStatus.success && userState.userEntity != null) {
        _setupSocketConnection(userState.userEntity!.id);
      }
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

  // 🔥 HÀM XỬ LÝ ĐIỀU HƯỚNG QUAN TRỌNG
  void _handleMessageNavigation(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    try {
      final String? type = data['type'];

      // --- 1. LISTENING (Comment/Reply) ---
      if (data.containsKey('listeningId')) {
        final String listeningId = data['listeningId'].toString();
        final String? commentId = data['commentId']?.toString();
        final String audioUrl = data['audioUrl']?.toString() ?? '';
        final String? cueId = data['cueId']?.toString();
        final bool openDiscussion = data['openDiscussion'] == 'true' || data['openDiscussion'] == true;

        context.pushNamed(
          'ListeningSkillsPage',
          pathParameters: {'listeningId': listeningId},
          extra: {
            'listeningId': listeningId,
            'audioUrl': audioUrl,
            'targetCommentId': commentId,
            'cueId': cueId,
            'openDiscussion': openDiscussion,
          },
        );
      }

      // --- 2. DAILY VOCAB (Nhắc học từ) ---
      else if (data.containsKey('wordId') || type == 'DAILY_VOCAB') {
        print("🚀 Navigating to Vocabulary Recent Tab...");
        context.pushNamed(
            'VocabularyPage',
            extra: {'initialTabIndex': 0} // 🔥 Tab 0 = Recent
        );      }

      // --- 3. REVIEW REMINDER (Nhắc ôn tập) ---
      else if (type == 'REVIEW_REMINDER') {
        print("🚀 Navigating to Vocabulary Learning Tab...");
        context.pushNamed(
            'VocabularyPage',
            extra: {'initialTabIndex': 1} // 🔥 Tab 1 = Learning
        );
      }

      // --- 4. 🔥 PROGRESS NUDGE (Nhắc tiến độ) ---
      else if (type == 'PROGRESS_NUDGE') {
        print("🚀 Navigating to Progress Report...");
        // Chuyển sang Tab 1 (ProgressReportPage)
        setState(() {
          _tab = 1;
        });
      }

      // --- 5. 🔥 STREAK RESCUE (Cứu chuỗi) ---
      else if (type == 'STREAK_RESCUE') {
        print("🚀 Streak Rescue -> Open Speaking Mode");
        // Mở ngay dialog Speaking để học nhanh
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) showSpeakingModeDialog(context);
        });
      }

    } catch (e) {
      print("❌ Error navigating from push notification: $e");
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

  void _setupSocketConnection(String userId) {
    if (_isSocketSetup) return;
    final socketService = GetIt.I<SocketService>();
    socketService.userLogin(userId);

    socketService.listenToNotifications((data) {
      try {
        final noti = NotificationEntity.fromJson(data);
        _notificationBloc.add(NotificationIncomingReceived(noti));

        String senderName = '';
        if (data['senderId'] != null && data['senderId'] is Map) {
          senderName = data['senderId']['fullName'] ?? 'Unknown User';
        }
        String serverMessage = data['message'] ?? '';
        String displayBody = "$senderName $serverMessage".trim();
        String title = data['title'] ?? 'New Notification';

        String? payload;
        if (data['data'] != null) {
          payload = jsonEncode(data['data']);
        }

        LocalNotificationService().showInstantNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: displayBody,
          payload: payload,
        );
      } catch (e) {
        debugPrint("❌ Error processing notification: $e");
      }
    });
    _isSocketSetup = true;
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
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => FadeTransition(
        opacity: anim1,
        child: const AiAssistantDialog(),
      ),
    );
  }

  void _openNotifications() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => FadeTransition(
        opacity: anim1,
        child: BlocProvider.value(
          value: _notificationBloc,
          child: const NotificationDialog(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _notificationBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<UserBloc, UserState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              if (state.status == UserStatus.success && state.userEntity != null) {
                _setupSocketConnection(state.userEntity!.id);
              }
            },
          ),
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
            vocabularyBadge: null,
          ),
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
    const double size = 44;
    const double iconSize = 20;
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Material(
                color: Colors.white,
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size / 2),
                  side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: const SizedBox(
                    width: size,
                    height: size,
                    child: Icon(Icons.notifications_outlined, color: Color(0xFF09090B), size: iconSize),
                  ),
                ),
              ),
              if (state.unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    const double size = 44;
    const double iconSize = 20;
    return Material(
      color: const Color(0xFF09090B),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.auto_awesome, color: Colors.white, size: iconSize),
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

  const _HomeContentView({
    required this.onOpenNotifications,
    required this.onOpenAiAssistant,
  });

  @override
  Widget build(BuildContext context) {
    final showAllLessons = ValueNotifier<bool>(false);
    final scheme = Theme.of(context).colorScheme;
    final textMain = scheme.onSurface;
    final textMuted = scheme.onSurfaceVariant;
    final primaryColor = scheme.primary;

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
            textMain,
            textMuted,
            primaryColor,
            onOpenNotifications,
            onOpenAiAssistant,
          ),
        );
      },
    );
  }

  Widget _homeBodyForState(
    BuildContext context,
    UserState state,
    ValueNotifier<bool> showAllLessons,
    Color textMain,
    Color textMuted,
    Color primaryColor,
    VoidCallback onOpenNotifications,
    VoidCallback onOpenAiAssistant,
  ) {
    if (state.status == UserStatus.initial || state.status == UserStatus.loading) {
      return const HomeContentSkeleton();
    }
    if (state.status == UserStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SoftErrorBanner(
            message: state.errorMessage ?? 'Unable to load data',
            onRetry: () => context.read<UserBloc>().add(GetProfileEvent()),
          ),
        ),
      );
    }
    if (state.status == UserStatus.unauthenticated) {
      return Center(
        child: Text(
          'Please sign in',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                user.fullName,
                user.avatarUrl,
                onOpenNotifications: onOpenNotifications,
                onOpenAiAssistant: onOpenAiAssistant,
              ),
              const SizedBox(height: 12),
              _buildDailyGoalCard(
                  dailyProgress, dailyGoal, progressValue, textMain, textMuted, primaryColor),
              const SizedBox(height: 16),
              HomeStudyDashboard(
                streak: user.currentStreak ?? 0,
                dailyProgress: dailyProgress,
                dailyGoal: dailyGoal,
                textMain: textMain,
                textMuted: textMuted,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),
              _buildStatsRow(user),
              const SizedBox(height: 32),
              _buildLessonsSection(context, showAllLessons, textMain, primaryColor),
              const SizedBox(height: 32),
              _buildQuickActionsSection(context, textMain),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Text('No data available', style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String? avatarUrl, {
    required VoidCallback onOpenNotifications,
    required VoidCallback onOpenAiAssistant,
  }) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $name 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleLarge?.copyWith(letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text('Ready to continue learning?', style: tt.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HomeHeaderNotificationButton(onPressed: onOpenNotifications),
        const SizedBox(width: 6),
        _HomeHeaderAiButton(onPressed: onOpenAiAssistant),
        const SizedBox(width: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline, width: 2),
            image: DecorationImage(
              image: (avatarUrl != null && avatarUrl.startsWith('http'))
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/avatar.png') as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalCard(int progress, int goal, double progressValue, Color textMain, Color textMuted, Color primary) {
    return _ShadcnCard(
      padding: const EdgeInsets.all(16),
      child: Builder(
        builder: (context) {
          final track = Theme.of(context).colorScheme.surfaceContainerHighest;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Goal', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: textMain)),
                      const SizedBox(height: 4),
                      Text(
                        '$progress / $goal lessons completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textMuted),
                      ),
                    ],
                  ),
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: track,
                  valueColor: AlwaysStoppedAnimation(primary),
                  minHeight: 8,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ... (Các phần _buildStatsRow, _buildLessonsSection, _ShadcnCard... giữ nguyên như cũ)
  Widget _buildStatsRow(dynamic user) {
    return Row(
      children: [
        Expanded(child: _StatItem(emoji: '🔥', value: '${user.currentStreak ?? 0}', label: 'Streak')),
        const SizedBox(width: 12),
        Expanded(child: _StatItem(emoji: '⭐', value: '${user.totalPoints ?? 0}', label: 'Points')),
        const SizedBox(width: 12),
        Expanded(child: _StatItem(emoji: '📚', value: 'Lv.${user.level ?? 1}', label: 'Level')),
      ],
    );
  }

  Widget _buildLessonsSection(BuildContext context, ValueNotifier<bool> showAllNotifier, Color textMain, Color primary) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today\'s Lessons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
            ValueListenableBuilder<bool>(
              valueListenable: showAllNotifier,
              builder: (context, showAll, child) {
                return GestureDetector(
                  onTap: () => showAllNotifier.value = !showAll,
                  child: Text(showAll ? 'Show less' : 'See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: showAllNotifier,
          builder: (context, showAll, child) {
            return Column(
              children: [
                const _LessonCard(icon: Icons.headphones, iconBg: Color(0xFFE8F5E9), iconColor: Color(0xFF2E7D32), title: 'Listening Practice', subtitle: 'Daily conversations • 15 min'),
                const SizedBox(height: 12),
                const _LessonCard(icon: Icons.menu_book, iconBg: Color(0xFFFFF8E1), iconColor: Color(0xFFF9A825), title: 'Reading Comprehension', subtitle: 'Short stories • 20 min'),
                const SizedBox(height: 12),
                const _LessonCard(icon: Icons.quiz, iconBg: Color(0xFFE3F2FD), iconColor: Color(0xFF1976D2), title: 'Vocabulary Builder', subtitle: 'New words • 10 min'),
                if (showAll) ...[
                  const SizedBox(height: 12),
                  const _LessonCard(icon: Icons.record_voice_over, iconBg: Color(0xFFFCE4EC), iconColor: Color(0xFFD81B60), title: 'Speaking Practice', subtitle: 'Pronunciation • 25 min'),
                  const SizedBox(height: 12),
                  const _LessonCard(icon: Icons.edit_note_rounded, iconBg: Color(0xFFE0F7FA), iconColor: Color(0xFF00838F), title: 'Writing Practice', subtitle: 'Select a topic • 15 min'),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, Color textMain) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access', style: tt.titleMedium?.copyWith(color: textMain)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: _QuickAction(
                  colorBg: const Color(0xFFF3E8FF),
                  icon: Icons.favorite,
                  iconColor: const Color(0xFFA855F7),
                  label: 'Favorites',
                  onTap: () => context.pushNamed('VocabularyPage', extra: const {'initialTabIndex': 0}),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _QuickAction(
                  colorBg: const Color(0xFFF0FDF4),
                  icon: Icons.style,
                  iconColor: const Color(0xFF22C55E),
                  label: 'Flashcards',
                  onTap: () => context.pushNamed('VocabularyPage', extra: const {'initialTabIndex': 1}),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _QuickAction(
                  colorBg: const Color(0xFFFEF2F2),
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFFEF4444),
                  label: 'Stats',
                  onTap: () => context.pushNamed(ProgressReportPage.routeName),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _QuickAction(
                  colorBg: const Color(0xFFEFF6FF),
                  icon: Icons.history,
                  iconColor: const Color(0xFF3B82F6),
                  label: 'History',
                  onTap: () => context.pushNamed(MyExerciseHistoryPage.routeName),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShadcnCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const _ShadcnCard({required this.child, this.padding, this.onTap});

  @override
  State<_ShadcnCard> createState() => _ShadcnCardState();
}

class _ShadcnCardState extends State<_ShadcnCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(14);
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: radius,
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            splashColor: scheme.primary.withValues(alpha: 0.12),
            highlightColor: scheme.primary.withValues(alpha: 0.06),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji, value, label;
  const _StatItem({required this.emoji, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return _ShadcnCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  const _LessonCard({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return _ShadcnCard(
      onTap: () {
        if (title.contains('Listening')) showListeningModeDialog(context);
        else if (title.contains('Reading')) context.pushNamed(ReadingListPage.routeName);
        else if (title.contains('Vocabulary')) context.pushNamed('VocabularyPage');
        else if (title.contains('Speaking')) showSpeakingModeDialog(context);
        else if (title.contains('Writing')) context.pushNamed(WritingTopicsPage.routeName);
      },
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: tt.bodySmall?.copyWith(color: muted)),
          ])),
          Icon(Icons.play_circle_outline_rounded, color: AppColors.outline, size: 28),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final Color colorBg, iconColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.colorBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const double iconDiameter = 52;
    // Chỉ bo / clip vùng tròn của icon — chữ nằm ngoài Material để không bị cắt.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScalePressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(iconDiameter / 2),
          minScale: 0.94,
          splashColor: scheme.primary.withValues(alpha: 0.12),
          highlightColor: scheme.primary.withValues(alpha: 0.06),
          child: SizedBox(
            width: iconDiameter,
            height: iconDiameter,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colorBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}