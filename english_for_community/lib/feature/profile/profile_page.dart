import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../core/entity/user_entity.dart';
import '../../core/notification/local_notification_service.dart';
import '../../core/repository/user_vocab_repository.dart'; // 🔥 Import Repository
import '../../core/socket/socket_service.dart';
import '../auth/bloc/user_bloc.dart';
import '../auth/bloc/user_event.dart';
import '../auth/bloc/user_state.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Navigation Handlers
  void _goEditProfile() {
    context.pushNamed('EditProfilePage').then((_) {
      if (mounted) {
        context.read<UserBloc>().add(GetProfileEvent());
      }
    });
  }

  void _goChangePassword() => context.pushNamed('ChangePasswordPage');

  // Placeholders
  void _goOfflineManager() {}
  void _goExportData() {}

  // --- ACTIONS ---

  void _handleLogout() {
    GetIt.I<SocketService>().disconnect();
    context.read<UserBloc>().add(SignOutEvent());
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
            'This action cannot be undone. All your learning data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              GetIt.I<SocketService>().disconnect();
              context.read<UserBloc>().add(DeleteAccountEvent());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  // 🔥 1. QUICK UPDATE FUNCTION
  void _quickUpdateProfile({
    int? dailyMinutes,
    TimeOfDay? reminder,
    bool? strictCorrection,
    bool? isToggleReminder,
  }) {
    final currentUser = context.read<UserBloc>().state.userEntity;
    if (currentUser == null) return;

    Map<String, int>? reminderMap;

    if (isToggleReminder == true) {
      if (currentUser.reminder != null) {
        reminderMap = null;
      } else {
        reminderMap = {"hour": 19, "minute": 0};
      }
    } else if (reminder != null) {
      reminderMap = {"hour": reminder.hour, "minute": reminder.minute};
    } else if (currentUser.reminder != null) {
      reminderMap = {"hour": currentUser.reminder!.hour, "minute": currentUser.reminder!.minute};
    }

    context.read<UserBloc>().add(UpdateProfileEvent(
      fullName: currentUser.fullName,
      username: currentUser.username,
      phone: currentUser.phone,
      dateOfBirth: currentUser.dateOfBirth,
      bio: currentUser.bio,
      goal: currentUser.goal,
      cefr: currentUser.cefr,
      avatarFile: null,
      language: currentUser.language,
      timezone: currentUser.timezone,
      dailyMinutes: dailyMinutes ?? currentUser.dailyMinutes,
      reminder: reminderMap,
      strictCorrection: strictCorrection ?? currentUser.strictCorrection,
    ));
  }

  // 🔥 2. SHOW BOTTOM SHEET
  void _showDailyGoalPicker(BuildContext context, int currentGoal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Select Learning Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...[15, 30, 45, 60].map((mins) => ListTile(
                title: Text('$mins mins / day'),
                leading: const Icon(Icons.timer_outlined, color: Colors.grey),
                trailing: currentGoal == mins ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (currentGoal != mins) {
                    _quickUpdateProfile(dailyMinutes: mins);
                  }
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // 🔥 3. SHOW TIME PICKER
  Future<void> _showTimePicker(BuildContext context, TimeOfDay current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
            timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != current) {
      _quickUpdateProfile(reminder: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.unauthenticated) {
          context.goNamed(LoginPage.routeName);
        }
        if (state.status == UserStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == UserStatus.loading && state.userEntity == null) {
          return const Scaffold(backgroundColor: bgPage, body: Center(child: CircularProgressIndicator()));
        }

        final user = state.userEntity;

        final String fullName = user?.fullName ?? 'User';
        final String email = user?.email ?? '';
        final String avatarUrl = user?.avatarUrl ?? '';
        final String language = user?.language ?? 'English';
        final String timezone = user?.timezone ?? 'GMT+7';

        // Data logic
        final int dailyMinutes = user?.dailyMinutes ?? 15;
        final bool isReminderOn = user?.reminder != null;

        // Info Display
        final String role = (user?.role == 'admin') ? 'Admin' : 'Member';
        final Color roleColor = (user?.role == 'admin') ? Colors.red : Colors.indigo;
        final String level = 'Level ${user?.level ?? 1}';

        // 🔥 LẤY ĐIỂM (TOTAL POINTS)
        final int points = user?.totalPoints ?? 0;

        String reminderTimeStr = '19:00';
        TimeOfDay reminderTimeVal = const TimeOfDay(hour: 19, minute: 0);

        if (user?.reminder != null) {
          reminderTimeVal = user!.reminder!;
          final h = reminderTimeVal.hour.toString().padLeft(2, '0');
          final m = reminderTimeVal.minute.toString().padLeft(2, '0');
          reminderTimeStr = '$h:$m';
        }

        return Scaffold(
          backgroundColor: bgPage,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: borderCol, height: 1),
            ),
            leading: Navigator.canPop(context)
                ? IconButton(icon: const Icon(Icons.arrow_back, color: textMain), onPressed: () => context.pop())
                : null,
            title: const Text('Profile & Settings', style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<UserBloc>().add(GetProfileEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROFILE CARD ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderCol, width: 1),
                            image: DecorationImage(
                              image: (avatarUrl.isNotEmpty)
                                  ? NetworkImage(avatarUrl)
                                  : const AssetImage('assets/avatar.png') as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain)),
                              const SizedBox(height: 2),
                              Text(email, style: const TextStyle(fontSize: 13, color: textMuted)),
                              const SizedBox(height: 8),

                              // 🔥 DÒNG HIỂN THỊ BADGE (ROLE - LEVEL - POINTS)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _ShadcnBadge(label: role, color: roleColor),
                                    const SizedBox(width: 8),
                                    _ShadcnBadge(label: level, color: Colors.teal),
                                    const SizedBox(width: 8),
                                    _ShadcnBadge(
                                        label: '$points XP',
                                        color: Colors.amber[700]!
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _goEditProfile,
                          tooltip: 'Edit Profile',
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFFF4F4F5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          icon: const Icon(Icons.edit_outlined, size: 20, color: textMain),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- LEARNING SETTINGS ---
                  const _SectionTitle('LEARNING PREFERENCES'),
                  _ShadcnGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.timer_outlined,
                        title: 'Daily Goal',
                        value: '$dailyMinutes mins',
                        onTap: () => _showDailyGoalPicker(context, dailyMinutes),
                      ),
                      const _Divider(),

                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Daily Reminder',
                        trailing: Switch.adaptive(
                          value: isReminderOn,
                          activeColor: textMain,
                          onChanged: (v) => _quickUpdateProfile(isToggleReminder: true),
                        ),
                      ),

                      if (isReminderOn) ...[
                        const _Divider(),
                        _SettingsTile(
                          icon: Icons.access_time,
                          title: 'Reminder Time',
                          value: reminderTimeStr,
                          onTap: () => _showTimePicker(context, reminderTimeVal),
                        ),
                      ],
                      const _Divider(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- GENERAL ---
                  const _SectionTitle('GENERAL SETTINGS'),
                  _ShadcnGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.language,
                        title: 'App Language',
                        value: language,
                        onTap: (){},
                      ),
                      const _Divider(),
                      _SettingsTile(
                        icon: Icons.public,
                        title: 'Timezone',
                        value: timezone,
                        onTap: (){},
                      ),
                      const _Divider(),
                      _SettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'Theme',
                        value: 'System',
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- STORAGE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _SectionTitle('OFFLINE DATA', paddingBottom: 0),
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('0 MB used', style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ShadcnGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.cloud_download_outlined,
                        title: 'Basic Vocabulary Pack',
                        value: 'Not downloaded',
                        onTap: _goOfflineManager,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- ACCOUNT ---
                  const _SectionTitle('ACCOUNT & SECURITY'),
                  _ShadcnGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: _goChangePassword,
                      ),
                      const _Divider(),
                      _SettingsTile(
                        icon: Icons.file_download_outlined,
                        title: 'Export Data',
                        subtitle: 'Download your learning history',
                        onTap: _goExportData,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- ACTIONS ---
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleLogout,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: textMain,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: borderCol),
                        ),
                      ),
                      child: state.status == UserStatus.loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleDeleteAccount,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                      child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 👇 BUTTON TEST THẦN THÁNH (NOTIFICATION - DATA THẬT) 👇
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // 1. Báo hiệu đang tải
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang lấy từ vựng từ Server...')),
                        );

                        // 2. Gọi Repository lấy 3 từ mới (Dữ liệu thật)
                        final vocabRepo = GetIt.I<UserVocabRepository>();
                        final result = await vocabRepo.getDailyReminders();

                        result.fold(
                              (failure) {
                            // Lỗi
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: ${failure.message}')),
                            );
                          },
                              (words) async {
                            if (words.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Server không trả về từ nào (Hãy chắc chắn bạn có từ vựng đang học)')),
                              );
                              return;
                            }

                            // 3. Convert Entity sang Map để ném vào hàm Test
                            final wordsData = words.map((e) => {
                              'id': e.id, // 🔥 Rất quan trọng để payload không bị null
                              'headword': e.headword,
                              'shortDefinition': e.shortDefinition ?? 'Chạm để học',
                            }).toList();

                            // 4. Gọi hàm Test Dữ liệu thật (Có logic hiện ngay lập tức)
                            await LocalNotificationService().requestPermissions();
                            await LocalNotificationService().testWithRealData(wordsData);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xong! Thông báo đầu tiên sẽ hiện NGAY LẬP TỨC!')),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.science), // Icon ống nghiệm test
                      label: const Text("TEST VỚI TỪ VỰNG THẬT"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple, // Đổi màu tím cho khác biệt
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: Column(
                      children: const [
                        Text('Version 1.0.0', style: TextStyle(color: textMuted, fontSize: 12)),
                        SizedBox(height: 4),
                        Text('© 2025 English For Community', style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ... (Phần Widget con _SectionTitle, _SettingsTile... giữ nguyên như cũ) ...
class _SectionTitle extends StatelessWidget {
  final String title;
  final double paddingBottom;
  const _SectionTitle(this.title, {this.paddingBottom = 8});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF71717A), // Zinc-500
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ShadcnGroup extends StatelessWidget {
  final List<Widget> children;
  const _ShadcnGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)), // Zinc-200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool isWarning;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? const Color(0xFF09090B)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF09090B)),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                      ),
                  ],
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isWarning ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null && value == null)
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFFA1A1AA)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5), indent: 16, endIndent: 16);
  }
}

class _ShadcnBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ShadcnBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final bgCol = color.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}