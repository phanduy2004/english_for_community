import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/locale/app_locale_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/entity/user_entity.dart';
import '../../core/socket/socket_service.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../auth/bloc/user_bloc.dart';
import '../auth/bloc/user_event.dart';
import '../auth/bloc/user_state.dart';
import '../auth/login_page.dart';
import 'change_password_dialog.dart';
import 'my_exercise_history/my_exercise_history_page.dart';
import '../../feature/student/classes/my_classes_hub_page.dart';
import '../../feature/teacher/teacher_apply_page.dart';
import '../../feature/teacher/teacher_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _appVersionLabel = '-';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersionLabel = '${info.version} (+${info.buildNumber})';
    });
  }

  void _goEditProfile() {
    context.pushNamed('EditProfilePage').then((_) {
      if (mounted) context.read<UserBloc>().add(GetProfileEvent());
    });
  }

  void _goChangePassword() {
    showDialog(context: context, builder: (context) => const ChangePasswordDialog());
  }

  void _goExportData() {}

  void _handleLogout() {
    GetIt.I<SocketService>().disconnect();
    context.read<UserBloc>().add(SignOutEvent());
  }

  void _handleDeleteAccount() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(t.deleteAccountTitle, style: AppTypography.titleMd()),
        content: Text(t.deleteAccountBody, style: AppTypography.body()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              GetIt.I<SocketService>().disconnect();
              context.read<UserBloc>().add(DeleteAccountEvent());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(t.deletePermanently),
          ),
        ],
      ),
    );
  }

  void _quickUpdateProfile({
    int? dailyMinutes,
    int? dailyLessonGoal,
    TimeOfDay? reminder,
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
      gender: currentUser.gender,
      strictCorrection: currentUser.strictCorrection,
      dailyMinutes: dailyMinutes ?? currentUser.dailyMinutes,
      dailyLessonGoal: dailyLessonGoal ?? currentUser.dailyLessonGoal,
      reminder: reminderMap,
    ));
  }

  void _showDailyTimePicker(BuildContext context, int currentMinutes) {
    final t = AppLocalizations.of(context)!;
    StudentBottomSheet.show(
      context,
      StudentBottomSheet(
        title: t.setDailyTimeGoal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [15, 30, 45, 60]
              .map(
                (mins) => StudentMobileUi.listTile(
                  context: context,
                  title: t.minutesPerDayOption(mins),
                  leading: StudentMobileUi.skillIconBox(Icons.timer_outlined, size: 40),
                  trailing: currentMinutes == mins
                      ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (currentMinutes != mins) _quickUpdateProfile(dailyMinutes: mins);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showLessonGoalPicker(BuildContext context, int currentGoal) {
    final t = AppLocalizations.of(context)!;
    StudentBottomSheet.show(
      context,
      StudentBottomSheet(
        title: t.setDailyLessonGoal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [3, 5, 7, 10]
              .map(
                (count) => StudentMobileUi.listTile(
                  context: context,
                  title: t.lessonsPerDayOption(count),
                  leading: StudentMobileUi.skillIconBox(Icons.flag_outlined, size: 40),
                  trailing: currentGoal == count
                      ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (currentGoal != count) _quickUpdateProfile(dailyLessonGoal: count);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showAppLanguagePicker(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ctrl = GetIt.I<AppLocaleController>();
    StudentBottomSheet.show(
      context,
      StudentBottomSheet(
        title: t.selectAppLanguage,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
              child: Text(
                t.appLanguageFootnote,
                textAlign: TextAlign.center,
                style: StudentMobileUi.caption(context),
              ),
            ),
            StudentMobileUi.listTile(
              context: context,
              title: t.languageEnglish,
              leading: StudentMobileUi.skillIconBox(Icons.language, size: 40),
              trailing: ctrl.locale.languageCode == 'en'
                  ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                  : null,
              onTap: () {
                ctrl.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            StudentMobileUi.listTile(
              context: context,
              title: t.languageVietnamese,
              leading: StudentMobileUi.skillIconBox(Icons.language, size: 40),
              trailing: ctrl.locale.languageCode == 'vi'
                  ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                  : null,
              onTap: () {
                ctrl.setLocale(const Locale('vi'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context, TimeOfDay current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            surface: AppColors.surfaceCard,
          ),
          timePickerTheme: const TimePickerThemeData(backgroundColor: AppColors.surfaceCard),
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
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.unauthenticated) context.goNamed(LoginPage.routeName);
        if (state.status == UserStatus.error && state.errorMessage != null) {
          AppFeedback.error(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        if (state.status == UserStatus.loading && state.userEntity == null) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: StudentMobileUi.runnerLoading(),
          );
        }

        final user = state.userEntity;
        if (user == null) return const SizedBox();

        final t = AppLocalizations.of(context)!;
        final localeCtrl = GetIt.I<AppLocaleController>();

        final int dailyMinutes = user.dailyMinutes ?? 15;
        final int dailyLessonGoal = user.dailyLessonGoal ?? 5;
        final bool isReminderOn = user.reminder != null;

        String reminderTimeStr = '19:00';
        TimeOfDay reminderTimeVal = const TimeOfDay(hour: 19, minute: 0);
        if (user.reminder != null) {
          reminderTimeVal = user.reminder!;
          reminderTimeStr =
              '${reminderTimeVal.hour.toString().padLeft(2, '0')}:${reminderTimeVal.minute.toString().padLeft(2, '0')}';
        }

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: StudentMobileUi.appBar(context, title: t.profileAndSettings, showBack: false),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => context.read<UserBloc>().add(GetProfileEvent()),
            child: SingleChildScrollView(
              primary: false,
              padding: StudentMobileUi.pagePadding,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, user, t),
                  const SizedBox(height: StudentMobileUi.sectionGap),

                  StudentMobileUi.sectionHeader(context, title: t.learningPreferences),
                  const SizedBox(height: AppSpacing.s3),
                  _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.timer_outlined,
                        title: t.dailyTimeGoal,
                        value: t.minutesShort(dailyMinutes),
                        iconColors: SkillColorSet(
                          color: AppColors.accent,
                          tint: AppColors.accentTint,
                          dark: AppColors.accentDark,
                        ),
                        onTap: () => _showDailyTimePicker(context, dailyMinutes),
                      ),
                      const _GroupDivider(),
                      _SettingsTile(
                        icon: Icons.flag_outlined,
                        title: t.dailyLessonGoal,
                        value: t.lessonsShort(dailyLessonGoal),
                        iconColors: SkillColorSet(
                          color: AppColors.accent,
                          tint: AppColors.accentTint,
                          dark: AppColors.accentDark,
                        ),
                        onTap: () => _showLessonGoalPicker(context, dailyLessonGoal),
                      ),
                      const _GroupDivider(),
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: t.dailyReminder,
                        iconColors: SkillColorSet(
                          color: AppColors.accent,
                          tint: AppColors.accentTint,
                          dark: AppColors.accentDark,
                        ),
                        trailing: Switch.adaptive(
                          value: isReminderOn,
                          activeTrackColor: AppColors.primary,
                          onChanged: (_) => _quickUpdateProfile(isToggleReminder: true),
                        ),
                      ),
                      if (isReminderOn) ...[
                        const _GroupDivider(),
                        _SettingsTile(
                          icon: Icons.access_time,
                          title: t.reminderTime,
                          value: reminderTimeStr,
                          iconColors: SkillColorSet(
                            color: AppColors.accent,
                            tint: AppColors.accentTint,
                            dark: AppColors.accentDark,
                          ),
                          onTap: () => _showTimePicker(context, reminderTimeVal),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: StudentMobileUi.sectionGap),

                  StudentMobileUi.sectionHeader(context, title: t.progress),
                  const SizedBox(height: AppSpacing.s3),
                  _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.history_rounded,
                        title: t.exerciseHistory,
                        subtitle: t.exerciseHistorySubtitle,
                        skill: SkillType.reading,
                        onTap: () => context.pushNamed(MyExerciseHistoryPage.routeName),
                      ),
                    ],
                  ),

                  const SizedBox(height: StudentMobileUi.sectionGap),

                  StudentMobileUi.sectionHeader(context, title: t.profileTeacherSectionTitle),
                  const SizedBox(height: AppSpacing.s3),
                  _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.class_outlined,
                        title: t.profileStudentClassesTitle,
                        subtitle: t.profileStudentClassesSubtitle,
                        skill: SkillType.speaking,
                        onTap: () => context.push(MyClassesHubPage.routePath),
                      ),
                      if (user.role == 'teacher' || user.role == 'admin') ...[
                        const _GroupDivider(),
                        _SettingsTile(
                          icon: Icons.school_outlined,
                          title: t.profileTeacherHubTitle,
                          subtitle: t.profileTeacherHubSubtitle,
                          skill: SkillType.writing,
                          onTap: () => context.push(TeacherDashboardPage.routePath),
                        ),
                      ],
                      if (user.role == 'user') ...[
                        const _GroupDivider(),
                        _SettingsTile(
                          icon: Icons.person_add_alt_1_outlined,
                          title: t.profileApplyTeacherTitle,
                          subtitle: t.profileApplyTeacherSubtitle,
                          skill: SkillType.writing,
                          onTap: () => context.push(TeacherApplyPage.routePath),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: StudentMobileUi.sectionGap),

                  StudentMobileUi.sectionHeader(context, title: t.generalSettings),
                  const SizedBox(height: AppSpacing.s3),
                  _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.language,
                        title: t.appLanguage,
                        value: localeCtrl.locale.languageCode == 'vi' ? t.languageVietnamese : t.languageEnglish,
                        skill: SkillType.vocabulary,
                        onTap: () => _showAppLanguagePicker(context),
                      ),
                      const _GroupDivider(),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        title: t.appVersionLabel,
                        value: _appVersionLabel,
                      ),
                      const _GroupDivider(),
                      _SettingsTile(
                        icon: Icons.public,
                        title: t.timezone,
                        value: user.timezone ?? 'GMT+7',
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: StudentMobileUi.sectionGap),

                  StudentMobileUi.sectionHeader(context, title: t.accountAndSecurity),
                  const SizedBox(height: AppSpacing.s3),
                  _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        title: t.changePassword,
                        iconColors: SkillColorSet(
                          color: AppColors.accent,
                          tint: AppColors.accentTint,
                          dark: AppColors.accentDark,
                        ),
                        onTap: _goChangePassword,
                      ),
                      const _GroupDivider(),
                      _SettingsTile(
                        icon: Icons.file_download_outlined,
                        title: t.exportData,
                        subtitle: t.exportDataSubtitle,
                        onTap: _goExportData,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.s8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _handleLogout,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: AppColors.surfaceCard,
                        side: const BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                      ),
                      child: Text(t.signOut, style: AppTypography.label()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleDeleteAccount,
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      child: Text(t.deleteAccount, style: AppTypography.label()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s9),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserEntity user, AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
        color: AppColors.surfaceCard,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border(
          left: BorderSide(color: AppColors.accent, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline),
              image: DecorationImage(
                image: (user.avatarUrl != null)
                    ? NetworkImage(user.avatarUrl!)
                    : const AssetImage('assets/avatar.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: StudentMobileUi.sectionTitle(context)),
                const SizedBox(height: AppSpacing.s2),
                Text(user.email, style: StudentMobileUi.caption(context)),
                const SizedBox(height: AppSpacing.s3),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ProfileBadge(label: user.role == 'admin' ? t.admin : t.member),
                      const SizedBox(width: AppSpacing.s3),
                      _ProfileBadge(
                        label: 'Lv.${user.level ?? 1}',
                        color: AppSkillColors.writing.color,
                        bg: AppSkillColors.writing.tint,
                        icon: Icons.workspace_premium_rounded,
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      _ProfileBadge(
                        label: '${user.totalPoints ?? 0} XP',
                        color: AppColors.accentDark,
                        bg: AppColors.accentTint,
                        icon: Icons.star_rounded,
                      ),
                      if ((user.currentStreak ?? 0) > 0) ...[
                        const SizedBox(width: AppSpacing.s3),
                        _ProfileBadge(
                          label: '${user.currentStreak ?? 0} 🔥',
                          color: AppColors.accentDark,
                          bg: AppColors.accentTint,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: InkWell(
              onTap: _goEditProfile,
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.edit_outlined, size: 20, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      radius: 12,
      padding: EdgeInsets.zero,
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
  final SkillType? skill;
  final SkillColorSet? iconColors;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.skill,
    this.iconColors,
  });

  @override
  Widget build(BuildContext context) {
    final showChevron = onTap != null && trailing == null && value == null;
    final skillSet = skill != null ? AppSkillColors.of(skill!) : iconColors;
    final chevronColor = skillSet?.color ?? AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
            child: Row(
              children: [
                StudentMobileUi.skillIconBox(
                  icon,
                  size: 36,
                  skill: skill,
                  colors: iconColors,
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: StudentMobileUi.cardTitle(context)),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.s2),
                        Text(subtitle!, style: StudentMobileUi.caption(context)),
                      ],
                    ],
                  ),
                ),
                if (value != null)
                  Text(value!, style: AppTypography.body(color: AppColors.textPrimary)),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.s3),
                  trailing!,
                ]                 else if (showChevron)
                  Icon(Icons.chevron_right_rounded, size: 18, color: chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.outlineMuted, indent: 16, endIndent: 16);
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bg;
  final IconData? icon;

  const _ProfileBadge({
    required this.label,
    this.color,
    this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textPrimary;
    final bgColor = bg ?? AppColors.primaryTint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: fg.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTypography.label(color: fg)),
        ],
      ),
    );
  }
}
