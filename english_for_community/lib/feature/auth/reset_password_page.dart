import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/l10n_context.dart';
import '../../core/ui/widget/app_corner_toast.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import 'bloc/user_bloc.dart';
import 'bloc/user_event.dart';
import 'bloc/user_state.dart';
import 'login_page.dart';
import 'widgets/auth_form_widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({super.key, required this.email, required this.otp});

  static String routeName = 'ResetPasswordPage';
  static String routePath = '/reset-password';

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _onReset({required bool isLoading}) {
    if (isLoading) return;

    final pass = _passController.text;
    final confirm = _confirmPassController.text;

    final t = context.l10n;
    if (pass.isEmpty || confirm.isEmpty) {
      showAuthFeedbackDialog(
        context,
        title: t.errorTitle,
        message: t.enterBothPasswords,
        isError: true,
      );
      return;
    }
    if (pass != confirm) {
      showAuthFeedbackDialog(
        context,
        title: t.passwordErrorTitle,
        message: t.passwordsDoNotMatchShort,
        isError: true,
      );
      return;
    }
    if (pass.length < 6) {
      showAuthFeedbackDialog(
        context,
        title: t.passwordErrorTitle,
        message: t.passwordMinSixChars,
        isError: true,
      );
      return;
    }

    context.read<UserBloc>().add(ResetPasswordEvent(
          email: widget.email,
          otp: widget.otp,
          newPassword: pass,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.error && state.errorMessage != null) {
          showAuthFeedbackDialog(
            context,
            title: context.l10n.resetFailedTitle,
            message: state.errorMessage!,
            isError: true,
          );
        }

        if (state.status == UserStatus.unauthenticated &&
            state.errorMessage != null) {
          AppCornerToast.show(context, state.errorMessage!);
          context.goNamed(LoginPage.routeName);
        }
      },
      builder: (context, state) {
        final isLoading = state.isFormLoading;
        final t = context.l10n;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            toolbarHeight: StudentMobileUi.appBarHeight,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: StudentMobileUi.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: StudentMobileUi.skillIconBox(
                      Icons.key_outlined,
                      size: 64,
                      colors: SkillColorSet(
                        color: AppColors.accent,
                        tint: AppColors.accentTint,
                        dark: AppColors.accentDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s7),
                  Text(
                    t.setNewPasswordTitle,
                    textAlign: TextAlign.center,
                    style: context.h1Style,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    t.setNewPasswordSubtitle,
                    textAlign: TextAlign.center,
                    style: StudentMobileUi.body(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  AuthFieldLabel(t.labelNewPassword),
                  const SizedBox(height: AppSpacing.s3),
                  AuthTextField(
                    controller: _passController,
                    hintText: t.hintEnterNewPassword,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePass,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  AuthFieldLabel(t.labelConfirmNewPassword),
                  const SizedBox(height: AppSpacing.s3),
                  AuthTextField(
                    controller: _confirmPassController,
                    hintText: t.hintConfirmNewPassword,
                    prefixIcon: Icons.verified_user_outlined,
                    obscureText: _obscureConfirm,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  FilledButton(
                    onPressed: () => _onReset(isLoading: isLoading),
                    style: AuthFormUi.primaryButtonStyle(),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(t.resetPasswordButton),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
