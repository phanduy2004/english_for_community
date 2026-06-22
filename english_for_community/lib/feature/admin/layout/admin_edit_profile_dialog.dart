import 'dart:typed_data';

import 'package:english_for_community/core/entity/user_entity.dart';
import 'package:english_for_community/core/ui/avatar_url.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_event.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/admin/layout/admin_dialog_shell.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Edit profile in admin dialog shell.
class AdminEditProfileDialog extends StatefulWidget {
  const AdminEditProfileDialog({super.key});

  @override
  State<AdminEditProfileDialog> createState() => _AdminEditProfileDialogState();
}

class _AdminEditProfileDialogState extends State<AdminEditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  UserEntity? _profile;
  XFile? _pickedAvatar;
  Uint8List? _pickedAvatarBytes;
  bool _isDirty = false;
  bool _awaitingSaveResult = false;

  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  String? _gender;

  @override
  void initState() {
    super.initState();
    _loadUser(context.read<UserBloc>().state.userEntity);
  }

  void _loadUser(UserEntity? user) {
    if (user == null) return;
    _profile = user;
    _fullName.text = user.fullName;
    _username.text = user.username;
    _bio.text = user.bio ?? '';
    _phone.text = user.phone ?? '';
    _gender = user.gender;
    if (user.dateOfBirth != null) {
      _dob.text = DateFormat('dd/MM/yyyy').format(user.dateOfBirth!);
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _bio.dispose();
    _phone.dispose();
    _dob.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _toast(String message, {bool error = false}) {
    AppCornerToast.show(context, message, error: error);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedAvatar = picked;
      _pickedAvatarBytes = bytes;
      _isDirty = true;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _profile?.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || _profile == null || !mounted) return;
    setState(() {
      _profile = _profile!.copyWith(dateOfBirth: picked);
      _dob.text = DateFormat('dd/MM/yyyy').format(picked);
      _isDirty = true;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _profile == null) return;
    final old = context.read<UserBloc>().state.userEntity;
    if (old == null) return;
    setState(() => _awaitingSaveResult = true);
    context.read<UserBloc>().add(UpdateProfileEvent(
      fullName: _fullName.text.trim(),
      username: _username.text.trim(),
      phone: _phone.text.trim(),
      bio: _bio.text.trim(),
      dateOfBirth: _profile!.dateOfBirth,
      avatarFile: _pickedAvatar,
      gender: _gender,
      goal: old.goal,
      cefr: old.cefr,
      dailyMinutes: old.dailyMinutes,
      dailyLessonGoal: old.dailyLessonGoal,
      reminder: old.reminder == null
          ? null
          : {'hour': old.reminder!.hour, 'minute': old.reminder!.minute},
      strictCorrection: old.strictCorrection,
      language: old.language,
      timezone: old.timezone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (!_awaitingSaveResult) return;
        if (state.status == UserStatus.success && _isDirty) {
          AppCornerToast.show(context, t.profileUpdatedSuccess);
          Navigator.pop(context);
          setState(() {
            _awaitingSaveResult = false;
            _isDirty = false;
          });
        } else if (state.status == UserStatus.error && state.errorMessage != null) {
          _toast(state.errorMessage!, error: true);
          setState(() => _awaitingSaveResult = false);
        }
      },
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (_profile == null) {
            return AdminDialogShell(
              title: t.editProfileTitle,
              icon: Icons.person_outline,
              body: AdminSkeleton.page(AdminSkeleton.cardList()),
            );
          }

          final isLoading = state.status == UserStatus.loading && _awaitingSaveResult;

          return AdminDialogShell(
            title: t.editProfileTitle,
            subtitle: t.teacherAccountEditProfileSubtitle,
            icon: Icons.person_outline,
            width: 520,
            maxBodyHeight: 480,
            body: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _AvatarPicker(
                    profile: _profile!,
                    pickedBytes: _pickedAvatarBytes,
                    onPick: _pickImage,
                  )),
                  const SizedBox(height: AppSpacing.s6),
                  AdminDialogSectionLabel(t.sectionPublicInfo),
                  _Field(
                    label: t.labelFullName,
                    child: TextFormField(
                      controller: _fullName,
                      style: AdminWebUi.webBody(context),
                      decoration: AdminWebUi.formInputDecoration(context),
                      onChanged: (_) => _markDirty(),
                      validator: (v) => (v == null || v.trim().isEmpty) ? t.fieldRequired : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Field(
                    label: t.labelUsername,
                    child: TextFormField(
                      controller: _username,
                      style: AdminWebUi.webBody(context),
                      decoration: AdminWebUi.formInputDecoration(context, hintText: '@username'),
                      onChanged: (_) => _markDirty(),
                      validator: (v) => (v == null || v.trim().isEmpty) ? t.fieldRequired : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Field(
                    label: t.labelBio,
                    child: TextFormField(
                      controller: _bio,
                      maxLines: 3,
                      style: AdminWebUi.webBody(context),
                      decoration: AdminWebUi.formInputDecoration(context, hintText: t.hintBio),
                      onChanged: (_) => _markDirty(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  AdminDialogSectionLabel(t.sectionPrivateDetails),
                  _Field(
                    label: t.labelGender,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _GenderChip(
                          label: t.genderMale,
                          selected: _gender == 'Male',
                          onTap: () => setState(() {
                            _gender = 'Male';
                            _isDirty = true;
                          }),
                        ),
                        _GenderChip(
                          label: t.genderFemale,
                          selected: _gender == 'Female',
                          onTap: () => setState(() {
                            _gender = 'Female';
                            _isDirty = true;
                          }),
                        ),
                        _GenderChip(
                          label: t.genderOther,
                          selected: _gender == 'Other',
                          onTap: () => setState(() {
                            _gender = 'Other';
                            _isDirty = true;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Field(
                    label: t.labelBirthday,
                    child: TextFormField(
                      controller: _dob,
                      readOnly: true,
                      style: AdminWebUi.webBody(context),
                      decoration: AdminWebUi.formInputDecoration(context, hintText: t.hintSelectDate).copyWith(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                          onPressed: _pickDate,
                        ),
                      ),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Field(
                    label: t.labelPhone,
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      style: AdminWebUi.webBody(context),
                      decoration: AdminWebUi.formInputDecoration(context, hintText: t.hintPhoneShort),
                      onChanged: (_) => _markDirty(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  AdminDialogSectionLabel(t.sectionSystemInfo),
                  _Field(
                    label: t.labelEmail,
                    child: TextFormField(
                      initialValue: _profile!.email,
                      readOnly: true,
                      enabled: false,
                      style: AdminWebUi.webBody(context).copyWith(color: AppColors.textMuted),
                      decoration: AdminWebUi.formInputDecoration(context),
                    ),
                  ),
                ],
              ),
            ),
            footer: AdminDialogFooterActions(
              cancelLabel: t.cancel,
              primaryLabel: t.saveChanges,
              primaryLoading: isLoading,
              primaryEnabled: _isDirty,
              onPrimary: _save,
            ),
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminWebUi.formFieldLabel(context, label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryTint : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AdminWebUi.webBody(context).copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.profile,
    required this.pickedBytes,
    required this.onPick,
  });

  final UserEntity profile;
  final Uint8List? pickedBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (pickedBytes != null && pickedBytes!.isNotEmpty) {
      img = MemoryImage(pickedBytes!);
    } else {
      img = AdminWebUi.networkAvatar(profile.avatarUrl, logicalSize: 72);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primaryTint,
          backgroundImage: img,
          child: img == null
              ? Text(
                  avatarInitials(profile.fullName),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPick,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.onPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}



