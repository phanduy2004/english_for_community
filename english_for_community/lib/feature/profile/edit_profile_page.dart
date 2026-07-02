import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import '../../core/entity/user_entity.dart';
import '../../core/locale/l10n_context.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';

class EditProfilePage extends StatefulWidget {
  static String routeName = 'EditProfilePage';
  static String routePath = '/profile/edit';
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  UserEntity? _profile;
  XFile? _pickedAvatar;
  Uint8List? _pickedAvatarBytes;

  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGender;
  bool _isDirty = false;

  static final _accentIconColors = SkillColorSet(
    color: AppColors.accent,
    tint: AppColors.accentTint,
    dark: AppColors.accentDark,
  );

  @override
  void initState() {
    super.initState();
    final user = context.read<UserBloc>().state.userEntity;
    if (user != null) {
      _profile = user;
      _fullNameController.text = user.fullName;
      _usernameController.text = user.username;
      _bioController.text = user.bio ?? '';
      _phoneController.text = user.phone ?? '';
      _selectedGender = user.gender;

      if (user.dateOfBirth != null) {
        _dobController.text =
            DateFormat('dd/MM/yyyy').format(user.dateOfBirth!);
      }
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _handleBackPressed() async {
    if (!_isDirty) {
      Navigator.maybePop(context);
      return;
    }
    await _handleUnsavedChanges();
  }

  Future<void> _handlePopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    await _handleUnsavedChanges();
  }

  Future<void> _handleUnsavedChanges() async {
    if (!mounted) return;
    final isLoading =
        context.read<UserBloc>().state.status == UserStatus.loading;
    if (isLoading) return;
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = ctx.l10n;
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          surfaceTintColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: Text(t.saveChanges, style: AppTypography.titleMd()),
          content: Text(
            t.writingSaveDraftMessage,
            style: AppTypography.body(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                t.writingDiscardButton,
                style: AppTypography.label(color: AppColors.danger),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text(
                t.saveChanges,
                style: AppTypography.label(color: AppColors.onPrimary),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldSave == null) return;
    if (shouldSave) {
      _save();
      return;
    }
    setState(() => _isDirty = false);
    Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedAvatar = file;
        _pickedAvatarBytes = bytes;
        _isDirty = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _profile?.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            surface: AppColors.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _profile = _profile!.copyWith(dateOfBirth: picked);
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
        _isDirty = true;
      });
    }
  }

  void _showGenderPicker(BuildContext context) {
    final t = context.l10n;
    final items = [
      ('Male', t.genderMale),
      ('Female', t.genderFemale),
      ('Other', t.genderOther),
    ];
    StudentBottomSheet.show(
      context,
      StudentBottomSheet(
        title: t.labelGender,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map(
                (e) => StudentMobileUi.listTile(
                  context: context,
                  title: e.$2,
                  leading: StudentMobileUi.skillIconBox(
                    Icons.wc_rounded,
                    size: 40,
                    colors: _accentIconColors,
                  ),
                  trailing: _selectedGender == e.$1
                      ? Icon(Icons.check_circle_rounded,
                          size: 20, color: AppColors.accent)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedGender = e.$1;
                      _isDirty = true;
                    });
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String? _genderLabel(BuildContext context) {
    final t = context.l10n;
    return switch (_selectedGender) {
      'Male' => t.genderMale,
      'Female' => t.genderFemale,
      'Other' => t.genderOther,
      _ => null,
    };
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _profile == null) return;
    final old = context.read<UserBloc>().state.userEntity!;

    context.read<UserBloc>().add(UpdateProfileEvent(
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
          dateOfBirth: _profile!.dateOfBirth,
          avatarFile: _pickedAvatar,
          gender: _selectedGender,
          goal: old.goal,
          cefr: old.cefr,
          dailyMinutes: old.dailyMinutes,
          reminder: old.reminder == null
              ? null
              : {"hour": old.reminder!.hour, "minute": old.reminder!.minute},
          strictCorrection: old.strictCorrection,
          language: old.language,
          timezone: old.timezone,
        ));
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppLocalizations t, bool canSave, bool isLoading) {
    return AppBar(
      toolbarHeight: StudentMobileUi.appBarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
        onPressed: _handleBackPressed,
      ),
      title: Text(t.editProfileTitle,
          style: StudentMobileUi.sectionTitle(context)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.s4),
          child: FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(72, 36),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: isLoading && _isDirty
                  ? AppColors.primary
                  : AppColors.surfaceSubtle,
              disabledForegroundColor: isLoading && _isDirty
                  ? AppColors.onPrimary
                  : AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
            ),
            child: isLoading && _isDirty
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: AppLoadingIndicator(
                        strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : Text(
                    t.saveChanges,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      color:
                          canSave ? AppColors.onPrimary : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
            height: 2, color: AppColors.accent.withValues(alpha: 0.55)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.success && _isDirty) {
          setState(() => _isDirty = false);
          AppFeedback.success(context, context.l10n.profileUpdatedSuccess);
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isLoading = state.status == UserStatus.loading;
        final t = context.l10n;
        final canSave = _isDirty && !isLoading;

        return PopScope<Object?>(
          canPop: !_isDirty,
          onPopInvokedWithResult: _handlePopInvoked,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _buildAppBar(context, t, canSave, isLoading),
            body: _profile == null
                ? StudentMobileUi.runnerLoading()
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: StudentMobileUi.pagePadding,
                      children: [
                        _AvatarHeader(
                          avatarBytes: _pickedAvatarBytes,
                          avatarUrl: _profile!.avatarUrl,
                          onPick: _pickImage,
                          hint: t.changePhotoHint,
                        ),
                        const SizedBox(height: StudentMobileUi.sectionGap),
                        StudentMobileUi.sectionHeader(
                          context,
                          title: t.sectionPublicInfo,
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _ProfileSectionCard(
                          skill: SkillType.speaking,
                          children: [
                            _ProfileFormField(
                              icon: Icons.person_rounded,
                              skill: SkillType.speaking,
                              label: t.labelFullName,
                              controller: _fullNameController,
                              onChanged: (_) => _markDirty(),
                              validator: (v) =>
                                  v!.isEmpty ? t.fieldRequired : null,
                            ),
                            const _FieldDivider(),
                            _ProfileFormField(
                              icon: Icons.alternate_email_rounded,
                              skill: SkillType.speaking,
                              label: t.labelUsername,
                              controller: _usernameController,
                              prefixText: '@',
                              onChanged: (_) => _markDirty(),
                              validator: (v) =>
                                  v!.isEmpty ? t.fieldRequired : null,
                            ),
                            const _FieldDivider(),
                            _ProfileFormField(
                              icon: Icons.edit_note_rounded,
                              skill: SkillType.speaking,
                              label: t.labelBio,
                              controller: _bioController,
                              hint: t.hintBio,
                              maxLines: 4,
                              onChanged: (_) => _markDirty(),
                            ),
                          ],
                        ),
                        const SizedBox(height: StudentMobileUi.sectionGap),
                        StudentMobileUi.sectionHeader(
                          context,
                          title: t.sectionPrivateDetails,
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _ProfileSectionCard(
                          skill: SkillType.reading,
                          children: [
                            _ProfilePickerField(
                              icon: Icons.wc_rounded,
                              skill: SkillType.reading,
                              label: t.labelGender,
                              value:
                                  _genderLabel(context) ?? t.selectPlaceholder,
                              isPlaceholder: _genderLabel(context) == null,
                              onTap: () => _showGenderPicker(context),
                            ),
                            const _FieldDivider(),
                            _ProfileFormField(
                              icon: Icons.cake_rounded,
                              skill: SkillType.reading,
                              label: t.labelBirthday,
                              controller: _dobController,
                              readOnly: true,
                              hint: t.hintSelectDate,
                              onTap: _pickDate,
                              suffixIcon: Icons.calendar_today_rounded,
                            ),
                            const _FieldDivider(),
                            _ProfileFormField(
                              icon: Icons.phone_rounded,
                              skill: SkillType.reading,
                              label: t.labelPhone,
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              hint: t.hintPhoneShort,
                              onChanged: (_) => _markDirty(),
                            ),
                          ],
                        ),
                        const SizedBox(height: StudentMobileUi.sectionGap),
                        StudentMobileUi.sectionHeader(
                          context,
                          title: t.sectionSystemInfo,
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _ProfileSectionCard(
                          muted: true,
                          children: [
                            _ProfileFormField(
                              icon: Icons.email_rounded,
                              label: t.labelEmail,
                              initialValue: _profile!.email,
                              readOnly: true,
                              enabled: false,
                              suffixIcon: _profile!.isVerified
                                  ? Icons.verified_rounded
                                  : Icons.info_outline,
                              suffixColor: _profile!.isVerified
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                            const _FieldDivider(),
                            _ProfileFormField(
                              icon: Icons.security_rounded,
                              label: t.labelRole,
                              initialValue: _profile!.role.toUpperCase(),
                              readOnly: true,
                              enabled: false,
                            ),
                            const _FieldDivider(),
                            _ProfileFormField(
                              icon: Icons.fingerprint_rounded,
                              label: t.labelUserId,
                              initialValue: _profile!.id,
                              readOnly: true,
                              enabled: false,
                              isCopyable: true,
                            ),
                          ],
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
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({
    required this.avatarBytes,
    required this.avatarUrl,
    required this.onPick,
    required this.hint,
  });

  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final VoidCallback onPick;
  final String hint;

  @override
  Widget build(BuildContext context) {
    ImageProvider image;
    if (avatarBytes != null) {
      image = MemoryImage(avatarBytes!);
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      image = NetworkImage(avatarUrl!);
    } else {
      image = const AssetImage('assets/avatar.png');
    }

    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 3),
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.surfaceSubtle,
              backgroundImage: image,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          hint,
          style: StudentMobileUi.caption(context)
              .copyWith(color: AppColors.accentDark),
        ),
      ],
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.children,
    this.skill,
    this.muted = false,
  });

  final List<Widget> children;
  final SkillType? skill;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (skill != null && !muted) {
      return StudentMobileUi.skillAccentCard(
        skill: skill!,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
        child: Column(children: children),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
      child: Column(children: children),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Divider(height: 1, thickness: 1, color: AppColors.outlineMuted),
    );
  }
}

// ─── Form fields ──────────────────────────────────────────────────────────────

class _ProfileFormField extends StatelessWidget {
  const _ProfileFormField({
    required this.icon,
    required this.label,
    this.skill,
    this.controller,
    this.initialValue,
    this.hint,
    this.prefixText,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
    this.suffixColor,
    this.onTap,
    this.onChanged,
    this.validator,
    this.isCopyable = false,
  });

  final IconData icon;
  final String label;
  final SkillType? skill;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? prefixText;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final Color? suffixColor;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool isCopyable;

  InputDecoration _decoration({required bool disabled}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(
          color: disabled ? AppColors.outlineMuted : AppColors.outlineStrong),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.body(color: AppColors.textMuted),
      prefixText: prefixText,
      prefixStyle: AppTypography.body(color: AppColors.textMuted),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon,
              size: 18, color: suffixColor ?? AppColors.textSecondary)
          : null,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: maxLines > 1 ? AppSpacing.s4 : AppSpacing.s3,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      disabledBorder: border,
      filled: true,
      fillColor: disabled ? AppColors.surfaceSubtle : AppColors.surfaceCard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StudentMobileUi.skillIconBox(icon, size: 36, skill: skill),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: Text(label, style: AppTypography.label())),
            if (isCopyable)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: AppColors.textSecondary),
                onPressed: () {
                  final text = controller?.text ?? initialValue ?? '';
                  if (text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: text));
                    AppFeedback.success(
                        context, context.l10n.copiedToClipboard);
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly || onTap != null,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.body(
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
          decoration: _decoration(disabled: disabled),
          onChanged: onChanged,
          validator: validator,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _ProfilePickerField extends StatelessWidget {
  const _ProfilePickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.skill,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final SkillType? skill;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final skillColor = skill != null
        ? AppSkillColors.of(skill!).color
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StudentMobileUi.skillIconBox(icon, size: 36, skill: skill),
            const SizedBox(width: AppSpacing.s3),
            Text(label, style: AppTypography.label()),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Material(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.outlineStrong),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.body(
                        color: isPlaceholder
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: skillColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
