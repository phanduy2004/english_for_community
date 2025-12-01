import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/notification/local_notification_service.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/ui/widget/app_navigation_bar.dart';
import '../auth/bloc/user_bloc.dart';
import '../auth/bloc/user_event.dart';
import '../auth/bloc/user_state.dart';
import '../listening/list_listening/listening_list_page.dart';
import '../profile/profile_page.dart';
import '../progress/progress_report_page.dart';
import '../reading/reading_list_page.dart';
import '../writing/writing_topics_page.dart';
import 'ai_assistant_dialog.dart';
import 'speaking_mode_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  final List<Widget> _pages = [
    const _HomeTab(),
    const ProgressReportPage(),
    BlocProvider.value(
      value: GetIt.I<UserBloc>(),
      child: const ProfilePage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
    // Logic Socket đã được chuyển sang SocketLifecycleManager ở main.dart
  }
  Future<void> _initializeNotifications() async {
    // 1. Xin quyền thông báo (Android 13+)
    await LocalNotificationService().requestPermissions();

    // 2. Đồng bộ lịch nhắc
    await _syncDailyReminders();
  }
  Future<void> _syncDailyReminders() async {
    final userState = context.read<UserBloc>().state;
    if (userState.status != UserStatus.success || userState.userEntity == null) return;

    final user = userState.userEntity!;
    final prefs = await SharedPreferences.getInstance();

    // 1. Nếu tắt nhắc nhở -> Xóa hết
    if (user.reminder == null) {
      await LocalNotificationService().cancelAll();
      await prefs.remove('CACHED_DAILY_WORDS');
      return;
    }

    // 2. Lấy Repository từ GetIt (Đã được đăng ký ở main)
    final vocabRepo = GetIt.I<UserVocabRepository>();

    // 3. Gọi hàm lấy từ vựng (Repository sẽ lo việc gọi API)
    final result = await vocabRepo.getDailyReminders();

    result.fold(
          (failure) async {
        // ❌ THẤT BẠI (Mất mạng/Lỗi server): Dùng Cache
        print("⚠️ Lỗi API: ${failure.message}. Thử lấy từ Cache...");
        final String? cachedJson = prefs.getString('CACHED_DAILY_WORDS');

        if (cachedJson != null) {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          await LocalNotificationService().scheduleDailyWordSequence(
            words: decoded, // List Map
            time: user.reminder!,
          );
          print("♻️ Đã đặt lịch bằng Cache.");
        }
      },
          (words) async {
        // ✅ THÀNH CÔNG: Có danh sách UserWordEntity
        if (words.isNotEmpty) {
          // Convert Entity sang Map để lưu Cache và dùng cho Notification
          final wordsMapList = words.map((e) => {
            'headword': e.headword,
            'shortDefinition': e.shortDefinition,
            // Thêm các trường khác nếu cần
          }).toList();

          // Lưu Cache
          await prefs.setString('CACHED_DAILY_WORDS', jsonEncode(wordsMapList));

          // Đặt lịch
          await LocalNotificationService().scheduleDailyWordSequence(
            words: wordsMapList,
            time: user.reminder!,
          );
          print("✅ Đã đồng bộ ${words.length} từ mới từ Server.");
        }
      },
    );
  }
  void _openAiAssistant() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: const AiAssistantDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        // Sử dụng IndexedStack để giữ trạng thái của các trang khi chuyển tab
        child: IndexedStack(
          index: _tab,
          children: _pages,
        ),
      ),
      // Chỉ hiện nút AI Assistant ở Tab Home (Index 0)
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
        onPressed: _openAiAssistant,
        backgroundColor: const Color(0xFF09090B),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      )
          : null,
      bottomNavigationBar: AppNavigationBar.main(
        currentIndex: _tab,
        onIndexSelected: (i) {
          // Khi nhấn về Home, reload lại profile để cập nhật Streak/Points mới nhất
          if (i == 0) {
            context.read<UserBloc>().add(GetProfileEvent());
          }
          setState(() => _tab = i);
        },
        // Badge ví dụ, bạn có thể custom logic để hiện số thông báo thật
        vocabularyBadge: const Text('3'),
      ),
    );
  }
}

// --- CÁC WIDGET CON (PRIVATE) GIỮ NGUYÊN ---

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final showAllLessons = ValueNotifier<bool>(false);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state.status == UserStatus.initial || state.status == UserStatus.loading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (state.status == UserStatus.error) {
          return const Center(child: Text('Không thể tải dữ liệu', style: TextStyle(color: textMuted)));
        }

        if (state.status == UserStatus.unauthenticated) {
          return const Center(child: Text('Vui lòng đăng nhập'));
        }

        if (state.status == UserStatus.success && state.userEntity != null) {
          final user = state.userEntity!;
          final String avatarUrl = user.avatarUrl ?? '';
          final int dailyProgress = user.dailyActivityProgress ?? 0;
          final int dailyGoal = user.dailyActivityGoal ?? 5;
          final double progressValue = (dailyGoal > 0)
              ? (dailyProgress / dailyGoal).clamp(0.0, 1.0)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Chào & Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào, ${user.fullName} 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textMain,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sẵn sàng học tiếp chưa?',
                          style: TextStyle(fontSize: 14, color: textMuted),
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE4E4E7), width: 2),
                        image: DecorationImage(
                          image: (avatarUrl.isNotEmpty && avatarUrl.startsWith('http'))
                              ? NetworkImage(avatarUrl)
                              : const AssetImage('assets/avatar.png') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Card Mục tiêu ngày
                _ShadcnCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mục tiêu ngày',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textMain)),
                              const SizedBox(height: 4),
                              Text(
                                '$dailyProgress / $dailyGoal bài học hoàn thành',
                                style: const TextStyle(fontSize: 13, color: textMuted),
                              ),
                            ],
                          ),
                          const Text('🏆', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressValue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    Expanded(child: _StatItem(emoji: '🔥', value: '${user.currentStreak ?? 0}', label: 'Streak')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatItem(emoji: '⭐', value: '${user.totalPoints ?? 0}', label: 'Points')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatItem(emoji: '📚', value: 'Lv.${user.level ?? 1}', label: 'Level')),
                  ],
                ),

                const SizedBox(height: 32),

                // Danh sách bài học
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bài học hôm nay',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
                    ValueListenableBuilder<bool>(
                      valueListenable: showAllLessons,
                      builder: (context, showAll, child) {
                        return GestureDetector(
                          onTap: () => showAllLessons.value = !showAll,
                          child: Text(
                            showAll ? 'Thu gọn' : 'Xem tất cả',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ValueListenableBuilder<bool>(
                  valueListenable: showAllLessons,
                  builder: (context, showAll, child) {
                    return Column(
                      children: [
                        const _LessonCard(
                          icon: Icons.headphones,
                          iconBg: Color(0xFFE8F5E9),
                          iconColor: Color(0xFF2E7D32),
                          title: 'Listening Practice',
                          subtitle: 'Daily conversations • 15 min',
                        ),
                        const SizedBox(height: 12),
                        const _LessonCard(
                          icon: Icons.menu_book,
                          iconBg: Color(0xFFFFF8E1),
                          iconColor: Color(0xFFF9A825),
                          title: 'Reading Comprehension',
                          subtitle: 'Short stories • 20 min',
                        ),
                        const SizedBox(height: 12),
                        const _LessonCard(
                          icon: Icons.quiz,
                          iconBg: Color(0xFFE3F2FD),
                          iconColor: Color(0xFF1976D2),
                          title: 'Vocabulary Builder',
                          subtitle: 'New words • 10 min',
                        ),
                        if (showAll) ...[
                          const SizedBox(height: 12),
                          const _LessonCard(
                            icon: Icons.record_voice_over,
                            iconBg: Color(0xFFFCE4EC),
                            iconColor: Color(0xFFD81B60),
                            title: 'Speaking Practice',
                            subtitle: 'Pronunciation • 25 min',
                          ),
                          const SizedBox(height: 12),
                          const _LessonCard(
                            icon: Icons.edit_note_rounded,
                            iconBg: Color(0xFFE0F7FA),
                            iconColor: Color(0xFF00838F),
                            title: 'Writing Practice',
                            subtitle: 'Select a topic • 15 min',
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Truy cập nhanh
                const Text('Truy cập nhanh',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _QuickAction(
                      colorBg: Color(0xFFF3E8FF),
                      icon: Icons.favorite,
                      iconColor: Color(0xFFA855F7),
                      label: 'Yêu thích',
                    ),
                    _QuickAction(
                      colorBg: Color(0xFFF0FDF4),
                      icon: Icons.style,
                      iconColor: Color(0xFF22C55E),
                      label: 'Flashcards',
                    ),
                    _QuickAction(
                      colorBg: Color(0xFFFEF2F2),
                      icon: Icons.trending_up,
                      iconColor: Color(0xFFEF4444),
                      label: 'Thống kê',
                    ),
                    _QuickAction(
                      colorBg: Color(0xFFEFF6FF),
                      icon: Icons.history,
                      iconColor: Color(0xFF3B82F6),
                      label: 'Lịch sử',
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('Không có dữ liệu'));
      },
    );
  }
}

// ... (Giữ nguyên các class _ShadcnCard, _StatItem, _LessonCard, _QuickAction như cũ)
// Tôi đã kiểm tra _LessonCard, logic điều hướng context.pushNamed đã chính xác.

class _ShadcnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const _ShadcnCard({required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
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
    return _ShadcnCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF09090B))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _LessonCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _ShadcnCard(
      onTap: () {
        if (title.contains('Listening')) {
          context.pushNamed(ListeningListPage.routeName);
        } else if (title.contains('Reading')) {
          context.pushNamed(ReadingListPage.routeName);
        } else if (title.contains('Vocabulary')) {
          // Lưu ý: Đảm bảo routeName 'VocabularyPage' đã được định nghĩa trong AppRouter
          context.pushNamed('VocabularyPage');
        } else if (title.contains('Speaking')) {
          showSpeakingModeDialog(context);
        } else if (title.contains('Writing')) {
          context.pushNamed(WritingTopicsPage.routeName);
        }
      },
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF09090B))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF71717A))),
              ],
            ),
          ),
          const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFD4D4D8), size: 28),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final Color colorBg, iconColor;
  final IconData icon;
  final String label;

  const _QuickAction({
    required this.colorBg,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF52525B)),
        ),
      ],
    );
  }
}