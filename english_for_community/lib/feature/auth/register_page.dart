import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';
import 'bloc/user_bloc.dart';
import 'bloc/user_state.dart';
import 'bloc/user_event.dart';
import 'otp_verification_page.dart';
import 'widgets/auth_form_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  static String routeName = 'RegisterPage';
  static String routePath = '/register';
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  DateTime? _selectedDate;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _onSignUp({required bool isLoading}) {
    if (isLoading) return;

    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passController.text;
    final confirm = _confirmPassController.text;

    final t = context.l10n;
    if (name.isEmpty || username.isEmpty || email.isEmpty || pass.isEmpty) {
      showAuthFeedbackDialog(
        context,
        title: t.errorTitle,
        message: t.fillRequiredFields,
        isError: true,
      );
      return;
    }
    if (pass != confirm) {
      showAuthFeedbackDialog(
        context,
        title: t.passwordErrorTitle,
        message: t.passwordMismatch,
        isError: true,
      );
      return;
    }

    context.read<UserBloc>().add(SignUpEvent(
          email: email,
          password: pass,
          fullName: name,
          username: username,
          phone: phone.isNotEmpty ? phone : null,
          dateOfBirth: _selectedDate,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.error && state.errorMessage != null) {
          showAuthFeedbackDialog(
            context,
            title: context.l10n.registrationFailedTitle,
            message: state.errorMessage!,
            isError: true,
          );
        }

        if (state.status == UserStatus.otpRequired) {
          context.goNamed(OtpVerificationPage.routeName, extra: state.errorMessage);
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
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: StudentMobileUi.skillIconBox(
                      Icons.person_add_alt_1_rounded,
                      size: 64,
                      skill: SkillType.speaking,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s7),
                  Text(
                    t.registerHeroTitle,
                    textAlign: TextAlign.center,
                    style: context.h1Style,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    t.registerHeroSubtitle,
                    textAlign: TextAlign.center,
                    style: StudentMobileUi.body(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  AppCard(
                    variant: AppCardVariant.outline,
                    radius: AppRadius.card,
                    padding: const EdgeInsets.all(AppSpacing.s7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthFieldLabel(t.labelFullName),
                        const SizedBox(height: AppSpacing.s3),
                        AuthTextField(
                          controller: _nameController,
                          hintText: t.hintFullName,
                          prefixIcon: Icons.badge_outlined,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        AuthFieldLabel(t.labelUsername),
                        const SizedBox(height: AppSpacing.s3),
                        AuthTextField(
                          controller: _usernameController,
                          hintText: t.hintUsername,
                          prefixIcon: Icons.alternate_email,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AuthFieldLabel(t.labelPhone),
                                  const SizedBox(height: AppSpacing.s3),
                                  AuthTextField(
                                    controller: _phoneController,
                                    hintText: t.hintPhoneShort,
                                    prefixIcon: Icons.phone_outlined,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AuthFieldLabel(t.labelDateOfBirth),
                                  const SizedBox(height: AppSpacing.s3),
                                  AuthTextField(
                                    controller: _dobController,
                                    hintText: t.hintDatePlaceholder,
                                    prefixIcon: Icons.calendar_today_outlined,
                                    enabled: !isLoading,
                                    readOnly: true,
                                    onTap: () => _selectDate(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        AuthFieldLabel('${t.labelEmail} *'),
                        const SizedBox(height: AppSpacing.s3),
                        AuthTextField(
                          controller: _emailController,
                          hintText: t.hintEmail,
                          prefixIcon: Icons.email_outlined,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        AuthFieldLabel('${t.labelPassword} *'),
                        const SizedBox(height: AppSpacing.s3),
                        AuthTextField(
                          controller: _passController,
                          hintText: t.hintPasswordMask,
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
                        AuthFieldLabel(t.labelConfirmPassword),
                        const SizedBox(height: AppSpacing.s3),
                        AuthTextField(
                          controller: _confirmPassController,
                          hintText: t.hintPasswordMask,
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
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s7),
                        FilledButton(
                          onPressed: isLoading
                              ? null
                              : () => _onSignUp(isLoading: isLoading),
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
                              : Text(t.registerButton),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.alreadyHaveAccount,
                        style: StudentMobileUi.body(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.goNamed('LoginPage'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3,
                          ),
                          minimumSize: const Size(44, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(t.signIn, style: AppTypography.label()),
                      ),
                    ],
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
