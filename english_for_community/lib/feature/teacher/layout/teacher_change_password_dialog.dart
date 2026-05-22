import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_corner_toast.dart';
import 'package:english_for_community/feature/auth/bloc/user_event.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Teacher-styled change password — `docs/ui-ux-system/07` §4 + §7.
class TeacherChangePasswordDialog extends StatefulWidget {
  const TeacherChangePasswordDialog({super.key});

  @override
  State<TeacherChangePasswordDialog> createState() => _TeacherChangePasswordDialogState();
}

class _TeacherChangePasswordDialogState extends State<TeacherChangePasswordDialog> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = false}) {
    TeacherCornerToast.show(context, message, error: error);
  }

  void _submit() {
    final t = context.l10n;
    final cur = _current.text;
    final neu = _newPass.text;
    final conf = _confirm.text;
    if (cur.isEmpty || neu.isEmpty || conf.isEmpty) {
      _toast(t.fillAllFields, error: true);
      return;
    }
    if (neu != conf) {
      _toast(t.newPasswordMismatchToast, error: true);
      return;
    }
    if (neu.length < 6) {
      _toast(t.passwordMinSixChars, error: true);
      return;
    }
    context.read<UserBloc>().add(ChangePasswordEvent(currentPassword: cur, newPassword: neu));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state.isFormLoading) return;
        if (state.errorMessage == 'Password changed successfully!') {
          _toast(state.errorMessage!);
          Navigator.pop(context);
        } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          _toast(state.errorMessage!, error: true);
        }
      },
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          return TeacherDialogShell(
            title: t.changePasswordTitle,
            subtitle: t.changePasswordSubtitle,
            icon: Icons.lock_reset_rounded,
            width: 480,
            maxBodyHeight: 360,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TeacherWebUi.formFieldLabel(context, t.labelCurrentPassword),
                const SizedBox(height: 6),
                _PasswordField(
                  controller: _current,
                  hint: t.hintCurrentPassword,
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 16),
                TeacherWebUi.formFieldLabel(context, t.labelNewPassword),
                const SizedBox(height: 6),
                _PasswordField(
                  controller: _newPass,
                  hint: t.hintEnterNewPassword,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 16),
                TeacherWebUi.formFieldLabel(context, t.labelConfirmNewPassword),
                const SizedBox(height: 6),
                _PasswordField(
                  controller: _confirm,
                  hint: t.hintReenterNewPassword,
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ],
            ),
            footer: TeacherDialogFooterActions(
              cancelLabel: t.cancel,
              primaryLabel: t.saveChanges,
              primaryLoading: state.isFormLoading,
              onPrimary: _submit,
            ),
          );
        },
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TeacherWebUi.webBody(context),
      decoration: TeacherWebUi.formInputDecoration(context, hintText: hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
