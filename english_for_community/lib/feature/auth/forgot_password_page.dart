import 'dart:async';

import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/l10n_context.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import 'bloc/user_bloc.dart';
import 'bloc/user_event.dart';
import 'bloc/user_state.dart';
import 'reset_password_page.dart';
import 'widgets/auth_form_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static String routeName = 'ForgotPasswordPage';
  static String routePath = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  bool _showOtpInput = false;
  String? _email;
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _emailController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  void _onSend(bool isLoading) {
    if (isLoading) return;
    final email = _emailController.text.trim();

    final t = context.l10n;
    if (email.isEmpty) {
      showAuthFeedbackDialog(
        context,
        title: t.errorTitle,
        message: t.enterEmailRequired,
        isError: true,
      );
      return;
    }

    context.read<UserBloc>().add(RequestForgotPasswordEvent(email: email));
  }

  void _onNext(bool isLoading) {
    if (isLoading || !_showOtpInput) return;
    final otp = _textController.text;

    if (otp.length < 6) {
      showAuthFeedbackDialog(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.otpSixDigitsRequired,
        isError: true,
      );
      return;
    }

    context.pushNamed(
      ResetPasswordPage.routeName,
      extra: {'email': _email, 'otp': otp},
    );
  }

  void _onResend() {
    if (!_canResend) return;

    context.read<UserBloc>().add(RequestForgotPasswordEvent(email: _email!));

    AppFeedback.info(context, context.l10n.resendingCodeSnack);
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.error && state.errorMessage != null) {
          showAuthFeedbackDialog(
            context,
            title: context.l10n.errorTitle,
            message: state.errorMessage!,
            isError: true,
          );
        }

        if (state.status == UserStatus.otpRequired) {
          setState(() {
            _email = state.errorMessage;
            _showOtpInput = true;
          });
          if (!(_timer?.isActive ?? false)) {
            startTimer();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusNode.requestFocus();
          });
          AppFeedback.success(context, context.l10n.otpSentEmailSnack);
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
                      Icons.lock_reset_outlined,
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
                    t.forgotHeroTitle,
                    textAlign: TextAlign.center,
                    style: context.h1Style,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    t.forgotHeroSubtitle,
                    textAlign: TextAlign.center,
                    style: StudentMobileUi.body(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  AuthFieldLabel(t.labelEmail),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          controller: _emailController,
                          hintText: t.hintEmail,
                          prefixIcon: Icons.email_outlined,
                          enabled: !isLoading && !_showOtpInput,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      SizedBox(
                        height: AuthFormUi.fieldHeight,
                        child: FilledButton(
                          onPressed: _showOtpInput
                              ? null
                              : () => _onSend(isLoading),
                          style: AuthFormUi.primaryButtonStyle().copyWith(
                            minimumSize: const WidgetStatePropertyAll(
                              Size(88, AuthFormUi.fieldHeight),
                            ),
                          ),
                          child: isLoading && !_showOtpInput
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: AppLoadingIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Text(t.sendButton),
                        ),
                      ),
                    ],
                  ),
                  if (_showOtpInput) ...[
                    const SizedBox(height: StudentMobileUi.sectionGap),
                    Text(
                      t.enterVerificationCode,
                      textAlign: TextAlign.center,
                      style: context.h2Style,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: StudentMobileUi.body(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(text: t.otpSentPrefix),
                          TextSpan(
                            text: _email,
                            style: AppTypography.label(),
                          ),
                          TextSpan(text: t.otpSentSuffix),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s7),
                    AuthOtpInput(
                      controller: _textController,
                      focusNode: _focusNode,
                      onCompleted: (_) => _onNext(isLoading),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    FilledButton(
                      onPressed: () => _onNext(isLoading),
                      style: AuthFormUi.primaryButtonStyle(),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: AppLoadingIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Text(t.next),
                    ),
                    const SizedBox(height: AppSpacing.s7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.didNotReceiveCode,
                          style: StudentMobileUi.body(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_canResend)
                          TextButton(
                            onPressed: _onResend,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s3,
                              ),
                              minimumSize: const Size(44, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(t.resendAction, style: AppTypography.label()),
                          )
                        else
                          Text(
                            t.resendCooldown(_start),
                            style: StudentMobileUi.caption(context),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
