import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Colors based on Shadcn theme
  static const Color textMain = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color borderCol = AppColors.outline;
  static const Color primaryCol = AppColors.primary;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final current = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    final t = context.l10n;
    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showToast(context, t.fillAllFields, isError: true);
      return;
    }
    if (newPass != confirm) {
      _showToast(context, t.newPasswordMismatchToast, isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showToast(context, t.passwordMinSixChars, isError: true);
      return;
    }

    context.read<UserBloc>().add(ChangePasswordEvent(
      currentPassword: current,
      newPassword: newPass,
    ));
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    AppCornerToast.show(context, message, error: isError);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (!state.isFormLoading) {
          if (state.errorMessage == "Password changed successfully!") {
            Navigator.pop(context); // Đóng dialog
            _showToast(context, state.errorMessage!);
            // Reset error message để tránh hiện lại
            // (Optional: trigger clear error event)
          } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            _showToast(context, state.errorMessage!, isError: true);
          }
        }
      },
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  const Icon(Icons.lock_reset_rounded, color: textMain),
                  const SizedBox(width: 12),
                  Text(
                    t.changePasswordTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.changePasswordSubtitle,
                style: const TextStyle(fontSize: 13, color: textMuted),
              ),
              const SizedBox(height: 24),

              // INPUTS
              _Label(t.labelCurrentPassword),
              const SizedBox(height: 6),
              _ShadcnInput(
                controller: _currentPassController,
                hintText: t.hintCurrentPassword,
                obscureText: _obscureCurrent,
                onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),

              const SizedBox(height: 16),

              _Label(t.labelNewPassword),
              const SizedBox(height: 6),
              _ShadcnInput(
                controller: _newPassController,
                hintText: t.hintEnterNewPassword,
                obscureText: _obscureNew,
                onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              ),

              const SizedBox(height: 16),

              _Label(t.labelConfirmNewPassword),
              const SizedBox(height: 6),
              _ShadcnInput(
                controller: _confirmPassController,
                hintText: t.hintReenterNewPassword,
                obscureText: _obscureConfirm,
                onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 32),

              // ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: borderCol),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        foregroundColor: textMain,
                      ),
                      child: Text(t.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BlocBuilder<UserBloc, UserState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state.isFormLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryCol,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: state.isFormLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(t.saveChanges,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                        );
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- REUSABLE COMPONENTS (Mini version for Dialog) ---

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary));
  }
}

class _ShadcnInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback onToggleObscure;

  const _ShadcnInput({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outline)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outline)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: onToggleObscure,
          ),
        ),
      ),
    );
  }
}