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
import 'login_page.dart';
import 'widgets/auth_form_widgets.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key, required this.email});

  final String email;

  static String routeName = 'OtpVerificationPage';
  static String routePath = '/verify-otp';

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  static const String otpPurpose = 'signup';

  @override
  void initState() {
    super.initState();
    startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
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

  void _onVerify(bool isLoading) {
    if (isLoading) return;
    final otp = _textController.text;

    final t = context.l10n;
    if (otp.length < 6) {
      showAuthFeedbackDialog(
        context,
        title: t.errorTitle,
        message: t.otpSixDigitsRequired,
        isError: true,
      );
      return;
    }

    context.read<UserBloc>().add(VerifyOtpEvent(
          email: widget.email,
          otp: otp,
          purpose: otpPurpose,
        ));
  }

  void _onResend() {
    if (!_canResend) return;

    context.read<UserBloc>().add(ResendOtpEvent(email: widget.email));

    AppFeedback.info(context, context.l10n.resendingCodeSnack);
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.error && state.errorMessage != null) {
          _textController.clear();
          _focusNode.requestFocus();
          showAuthFeedbackDialog(
            context,
            title: context.l10n.verificationFailedTitle,
            message: state.errorMessage!,
            isError: true,
          );
        }

        if (state.status == UserStatus.unauthenticated &&
            state.errorMessage != null) {
          AppFeedback.error(context, state.errorMessage!);
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
                      Icons.lock_person_outlined,
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
                    t.enterVerificationCode,
                    textAlign: TextAlign.center,
                    style: context.h1Style,
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
                          text: widget.email,
                          style: AppTypography.label(),
                        ),
                        TextSpan(text: t.otpSentSuffix),
                      ],
                    ),
                  ),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  AuthOtpInput(
                    controller: _textController,
                    focusNode: _focusNode,
                    onCompleted: (_) => _onVerify(isLoading),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  FilledButton(
                    onPressed: () => _onVerify(isLoading),
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
                        : Text(t.verifyButton),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
