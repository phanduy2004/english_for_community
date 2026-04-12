import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../core/locale/app_locale_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/entity/user_entity.dart';
import '../../core/socket/socket_service.dart';
import '../auth/bloc/user_bloc.dart';
import '../auth/bloc/user_event.dart';
import '../auth/bloc/user_state.dart';
import '../auth/login_page.dart';
import 'change_password_dialog.dart';
import 'my_exercise_history/my_exercise_history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- NAVIGATION ---
  void _goEditProfile() {
    context.pushNamed('EditProfilePage').then((_) {
      if (mounted) context.read<UserBloc>().add(GetProfileEvent());
    });
  }

  void _goChangePassword() {
    showDialog(context: context, builder: (context) => const ChangePasswordDialog());
  }

  void _goOfflineManager() {} // Placeholder
  void _goExportData() {} // Placeholder

  // --- ACTIONS ---
  void _handleLogout() {
    GetIt.I<SocketService>().disconnect();
    context.read<UserBloc>().add(SignOutEvent());
  }

  void _handleDeleteAccount() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteAccountTitle),
        content: Text(t.deleteAccountBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              GetIt.I<SocketService>().disconnect();
              context.read<UserBloc>().add(DeleteAccountEvent());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.deletePermanently),
          ),
        ],
      ),
    );
  }

  // 🔥 1. HÀM UPDATE NHANH (Bao gồm cả Lesson Goal)
  void _quickUpdateProfile({
    int? dailyMinutes,
    int? dailyLessonGoal, // Tham số mới
    TimeOfDay? reminder,
    bool? isToggleReminder,
  }) {
    final currentUser = context.read<UserBloc>().state.userEntity;
    if (currentUser == null) return;

    Map<String, int>? reminderMap;

    // Logic xử lý Reminder
    if (isToggleReminder == true) {
      if (currentUser.reminder != null) {
        reminderMap = null; // Tắt reminder
      } else {
        reminderMap = {"hour": 19, "minute": 0}; // Mặc định bật lúc 19:00
      }
    } else if (reminder != null) {
      reminderMap = {"hour": reminder.hour, "minute": reminder.minute};
    } else if (currentUser.reminder != null) {
      // Giữ nguyên reminder cũ nếu không đổi
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
      gender: currentUser.gender,
      strictCorrection: currentUser.strictCorrection,

      // Update các trường Learning
      dailyMinutes: dailyMinutes ?? currentUser.dailyMinutes,
      dailyLessonGoal: dailyLessonGoal ?? currentUser.dailyLessonGoal,
      reminder: reminderMap,
    ));
  }

  // 🔥 2. PICKER: Chọn Thời Gian Học (Phút)
  void _showDailyTimePicker(BuildContext context, int currentMinutes) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(t.setDailyTimeGoal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...[15, 30, 45, 60].map((mins) => ListTile(
                title: Text(t.minutesPerDayOption(mins)),
                leading: const Icon(Icons.timer_outlined, color: Colors.grey),
                trailing: currentMinutes == mins ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (currentMinutes != mins) _quickUpdateProfile(dailyMinutes: mins);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // 🔥 3. PICKER: Chọn Số Bài Học (Bài)
  void _showLessonGoalPicker(BuildContext context, int currentGoal) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(t.setDailyLessonGoal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...[3, 5, 7, 10].map((count) => ListTile(
                title: Text(t.lessonsPerDayOption(count)),
                leading: const Icon(Icons.flag_outlined, color: Colors.grey),
                trailing: currentGoal == count ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (currentGoal != count) _quickUpdateProfile(dailyLessonGoal: count);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAppLanguagePicker(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ctrl = GetIt.I<AppLocaleController>();
    const textMuted = Color(0xFF71717A);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(t.selectAppLanguage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(t.appLanguageFootnote, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: textMuted)),
              ),
              ListTile(
                title: Text(t.languageEnglish),
                leading: const Icon(Icons.language, color: Colors.grey),
                trailing: ctrl.locale.languageCode == 'en' ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                onTap: () {
                  ctrl.setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(t.languageVietnamese),
                leading: const Icon(Icons.language, color: Colors.grey),
                trailing: ctrl.locale.languageCode == 'vi' ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                onTap: () {
                  ctrl.setLocale(const Locale('vi'));
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // 🔥 4. PICKER: Chọn Giờ Nhắc Nhở
  Future<void> _showTimePicker(BuildContext context, TimeOfDay current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
          timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
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
        if (state.status == UserStatus.unauthenticated) context.goNamed(LoginPage.routeName);
        if (state.status == UserStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == UserStatus.loading && state.userEntity == null) {
          return const Scaffold(backgroundColor: bgPage, body: Center(child: CircularProgressIndicator()));
        }

        final user = state.userEntity;
        if (user == null) return const SizedBox();

        final t = AppLocalizations.of(context)!;
        final localeCtrl = GetIt.I<AppLocaleController>();

        // Data Prep
        final int dailyMinutes = user.dailyMinutes ?? 15;
        final int dailyLessonGoal = user.dailyLessonGoal ?? 5; // Lấy từ Entity
        final bool isReminderOn = user.reminder != null;

        String reminderTimeStr = '19:00';
        TimeOfDay reminderTimeVal = const TimeOfDay(hour: 19, minute: 0);
        if (user.reminder != null) {
          reminderTimeVal = user.reminder!;
          reminderTimeStr = '${reminderTimeVal.hour.toString().padLeft(2, '0')}:${reminderTimeVal.minute.toString().padLeft(2, '0')}';
        }

        return Scaffold(
          backgroundColor: bgPage,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderCol, height: 1)),
            title: Text(t.profileAndSettings, style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          body: RefreshIndicator(
            onRefresh: () async => context.read<UserBloc>().add(GetProfileEvent()),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROFILE HEADER ---
                  _buildProfileHeader(context, user, textMain, textMuted, borderCol),
                  const SizedBox(height: 32),

                  // --- LEARNING SETTINGS ---
                  _SectionTitle(t.learningPreferences),
                  _ShadcnGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.timer_outlined,
                        title: t.dailyTimeGoal,
                        value: t.minutesShort(dailyMinutes),
                        onTap: () => _showDailyTimePicker(context, dailyMinutes),
                      ),
                      const _Divider(),
                      // 🔥 MỤC TIÊU SỐ BÀI HỌC
                      _SettingsTile(
                        icon: Icons.flag_outlined,
                        title: t.dailyLessonGoal,
                        value: t.lessonsShort(dailyLessonGoal),
                        onTap: () => _showLessonGoalPicker(context, dailyLessonGoal),
                      ),
                      const _Divider(),
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: t.dailyReminder,
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
                          title: t.reminderTime,
                          value: reminderTimeStr,
                          onTap: () => _showTimePicker(context, reminderTimeVal),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- EXERCISE HISTORY ---
                  _SectionTitle(t.progress),
                  _ShadcnGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.history_rounded,
                        title: t.exerciseHistory,
                        subtitle: t.exerciseHistorySubtitle,
                        onTap: () => context.pushNamed(MyExerciseHistoryPage.routeName),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- GENERAL SETTINGS ---
                  _SectionTitle(t.generalSettings),
                  _ShadcnGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.language,
                        title: t.appLanguage,
                        value: localeCtrl.locale.languageCode == 'vi' ? t.languageVietnamese : t.languageEnglish,
                        onTap: () => _showAppLanguagePicker(context),
                      ),
                      const _Divider(),
                      _SettingsTile(icon: Icons.public, title: t.timezone, value: user.timezone ?? 'GMT+7', onTap: () {}),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- ACCOUNT ---
                  _SectionTitle(t.accountAndSecurity),
                  _ShadcnGroup(
                    children: [
                      _SettingsTile(icon: Icons.lock_outline, title: t.changePassword, onTap: _goChangePassword),
                      const _Divider(),
                      _SettingsTile(icon: Icons.file_download_outlined, title: t.exportData, subtitle: t.exportDataSubtitle, onTap: _goExportData),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- LOGOUT ---
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleLogout,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: textMain,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: borderCol)),
                      ),
                      child: Text(t.signOut, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleDeleteAccount,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(t.deleteAccount, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserEntity user, Color textMain, Color textMuted, Color borderCol) {
    final t = AppLocalizations.of(context)!;
    final roleColor = (user.role == 'admin') ? Colors.red : Colors.indigo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // ... (Phần Avatar giữ nguyên)
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderCol),
              image: DecorationImage(
                image: (user.avatarUrl != null) ? NetworkImage(user.avatarUrl!) : const AssetImage('assets/avatar.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain)),
                const SizedBox(height: 2),
                Text(user.email, style: TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 8),

                // 🔥 SỬA LỖI OVERFLOW TẠI ĐÂY
                // Bọc Row bằng SingleChildScrollView
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ShadcnBadge(label: user.role == 'admin' ? t.admin : t.member, color: roleColor),
                      const SizedBox(width: 8),
                      _ShadcnBadge(label: 'Lv.${user.level ?? 1}', color: Colors.teal),
                      const SizedBox(width: 8),
                      _ShadcnBadge(label: '${user.totalPoints ?? 0} XP', color: Colors.amber[700]!),
                    ],
                  ),
                )
              ],
            ),
          ),
          IconButton(
            onPressed: _goEditProfile,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF4F4F5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: Icon(Icons.edit_outlined, size: 20, color: textMain),
          )
        ],
      ),
    );
  }
}

// ... (Các Widget phụ trợ: _SectionTitle, _ShadcnGroup, _SettingsTile, _ShadcnBadge giữ nguyên như code cũ)
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF71717A), letterSpacing: 0.8)),
    );
  }
}

class _ShadcnGroup extends StatelessWidget {
  final List<Widget> children;
  const _ShadcnGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4E4E7))),
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
  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.value, this.trailing, this.onTap});

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
              Icon(icon, size: 20, color: const Color(0xFF09090B)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
                  ],
                ),
              ),
              if (value != null) Text(value!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF52525B))),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!]
              else if (onTap != null && value == null) const Icon(Icons.chevron_right, size: 18, color: Color(0xFFA1A1AA)),
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
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5), indent: 16, endIndent: 16);
}

class _ShadcnBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ShadcnBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}