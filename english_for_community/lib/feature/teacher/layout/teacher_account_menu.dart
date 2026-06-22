import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/core/locale/app_locale_controller.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_event.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_change_password_dialog.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_edit_profile_dialog.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Teacher account hub — centered dialog only (`docs/ui-ux-system/07` §4).
void showTeacherAccountMenu(BuildContext context) {
  TeacherDialogShell.show<void>(context, child: const TeacherAccountMenuDialog());
}

class TeacherAccountMenuDialog extends StatefulWidget {
  const TeacherAccountMenuDialog({super.key});

  @override
  State<TeacherAccountMenuDialog> createState() => _TeacherAccountMenuDialogState();
}

class _TeacherAccountMenuDialogState extends State<TeacherAccountMenuDialog> {
  String _appVersion = '—';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version} (${info.buildNumber})');
  }

  void _close() => Navigator.of(context).pop();

  void _closeThen(void Function(BuildContext ctx) action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final root = rootNavigatorKey.currentContext;
      if (root != null && root.mounted) action(root);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        final user = state.userEntity;
        if (user == null) return const SizedBox.shrink();

        final localeCtrl = getIt<AppLocaleController>();
        final langLabel = localeCtrl.locale.languageCode == 'vi'
            ? l10n.languageVietnamese
            : l10n.languageEnglish;
        final tz = user.timezone ?? 'Asia/Ho_Chi_Minh';

        return TeacherDialogShell(
          title: l10n.teacherAccountMenuTitle,
          subtitle: user.email,
          icon: Icons.manage_accounts_outlined,
          width: 440,
          maxBodyHeight: 480,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountIdentityCard(
                name: user.fullName,
                email: user.email,
                avatarUrl: user.avatarUrl,
                roleLabel: l10n.teacherAccountRoleTeacher,
              ),
              const SizedBox(height: AppSpacing.s5),
              TeacherDialogSectionLabel(l10n.accountAndSecurity),
              TeacherDialogOptionTile(
                icon: Icons.person_outline,
                title: l10n.editProfileTitle,
                onTap: () => _closeThen(
                  (ctx) => TeacherDialogShell.show(
                    ctx,
                    child: const TeacherEditProfileDialog(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              TeacherDialogOptionTile(
                icon: Icons.lock_outline,
                title: l10n.changePassword,
                subtitle: l10n.changePasswordSubtitle,
                onTap: () => _closeThen(
                  (ctx) => TeacherDialogShell.show(
                    ctx,
                    child: const TeacherChangePasswordDialog(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s5),
              TeacherDialogSectionLabel(l10n.generalSettings),
              TeacherDialogOptionTile(
                icon: Icons.language_outlined,
                title: l10n.appLanguage,
                trailing: langLabel,
                onTap: () => _closeThen(_showLanguageDialog),
              ),
              const SizedBox(height: AppSpacing.s3),
              TeacherDialogOptionTile(
                icon: Icons.public_outlined,
                title: l10n.timezone,
                trailing: tz,
                onTap: () => _closeThen((ctx) => _showTimezoneDialog(ctx, tz)),
              ),
              const SizedBox(height: AppSpacing.s5),
              TeacherDialogSectionLabel(l10n.teacherAccountSectionAbout),
              TeacherDialogOptionTile(
                icon: Icons.info_outline,
                title: l10n.appVersionLabel,
                trailing: _appVersion,
                showChevron: false,
                onTap: null,
              ),
            ],
          ),
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  style: TeacherWebUi.compactOutlinedStyle(context),
                  icon: const Icon(Icons.logout, size: 16),
                  label: Text(l10n.signOut),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Center(
                child: TextButton(
                  onPressed: () => _closeThen(_showDeleteAccountDialog),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: TeacherWebUi.webLabel(context).copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.deleteAccount),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _signOut() {
    _close();
    getIt<SocketService>().disconnect();
    context.read<UserBloc>().add(SignOutEvent());
  }

  static void _showDeleteAccountDialog(BuildContext context) {
    final l10n = context.l10n;
    TeacherDialogShell.show<void>(
      context,
      child: TeacherDialogShell(
        title: l10n.deleteAccountTitle,
        subtitle: l10n.deleteAccountBody,
        icon: Icons.warning_amber_rounded,
        width: 480,
        maxBodyHeight: 120,
        body: const SizedBox.shrink(),
        footer: TeacherDialogFooterActions(
          cancelLabel: l10n.cancel,
          primaryLabel: l10n.deletePermanently,
          destructive: true,
          onPrimary: () {
            Navigator.of(context).pop();
            getIt<SocketService>().disconnect();
            context.read<UserBloc>().add(DeleteAccountEvent());
          },
        ),
      ),
    );
  }

  static void _showLanguageDialog(BuildContext context) {
    final l10n = context.l10n;
    final ctrl = getIt<AppLocaleController>();
    TeacherDialogShell.show<void>(
      context,
      child: TeacherDialogShell(
        title: l10n.selectAppLanguage,
        icon: Icons.language_outlined,
        width: 400,
        maxBodyHeight: 200,
        body: Column(
          children: [
            _PickerChoiceTile(
              label: l10n.languageEnglish,
              selected: ctrl.locale.languageCode == 'en',
              onTap: () {
                ctrl.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.s3),
            _PickerChoiceTile(
              label: l10n.languageVietnamese,
              selected: ctrl.locale.languageCode == 'vi',
              onTap: () {
                ctrl.setLocale(const Locale('vi'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
        footer: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: TeacherWebUi.compactOutlinedStyle(context),
            child: Text(l10n.close),
          ),
        ),
      ),
    );
  }

  static void _showTimezoneDialog(BuildContext context, String current) {
    final l10n = context.l10n;
    const zones = [
      'Asia/Ho_Chi_Minh',
      'Asia/Bangkok',
      'Asia/Singapore',
      'Asia/Tokyo',
      'Asia/Seoul',
      'Europe/London',
      'America/New_York',
      'UTC',
    ];
    TeacherDialogShell.show<void>(
      context,
      child: TeacherDialogShell(
        title: l10n.timezone,
        icon: Icons.public_outlined,
        width: 420,
        maxBodyHeight: 320,
        body: Column(
          children: [
            for (var i = 0; i < zones.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.s3),
              _PickerChoiceTile(
                label: zones[i],
                selected: current == zones[i] || (current.isEmpty && zones[i] == 'Asia/Ho_Chi_Minh'),
                onTap: () {
                  Navigator.pop(context);
                  final root = rootNavigatorKey.currentContext;
                  if (root != null) _updateTimezone(root, zones[i]);
                },
              ),
            ],
          ],
        ),
        footer: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: TeacherWebUi.compactOutlinedStyle(context),
            child: Text(l10n.close),
          ),
        ),
      ),
    );
  }

  static void _updateTimezone(BuildContext context, String zone) {
    final user = context.read<UserBloc>().state.userEntity;
    if (user == null) return;
    context.read<UserBloc>().add(UpdateProfileEvent(
      fullName: user.fullName,
      username: user.username,
      phone: user.phone,
      dateOfBirth: user.dateOfBirth,
      bio: user.bio,
      goal: user.goal,
      cefr: user.cefr,
      avatarFile: null,
      language: user.language,
      timezone: zone,
      gender: user.gender,
      strictCorrection: user.strictCorrection,
      dailyMinutes: user.dailyMinutes,
      dailyLessonGoal: user.dailyLessonGoal,
      reminder: user.reminder != null
          ? {'hour': user.reminder!.hour, 'minute': user.reminder!.minute}
          : null,
    ));
  }
}

class _AccountIdentityCard extends StatelessWidget {
  const _AccountIdentityCard({
    required this.name,
    required this.email,
    required this.roleLabel,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String roleLabel;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Row(
        children: [
          TeacherWebUi.userAvatarCircle(
            avatarUrl: avatarUrl,
            displayName: name,
            radius: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(email, style: TeacherWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerChoiceTile extends StatelessWidget {
  const _PickerChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryTint : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TeacherWebUi.webBody(context).copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, size: 18, color: AppColors.primary)
              else
                const Icon(Icons.circle_outlined, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
