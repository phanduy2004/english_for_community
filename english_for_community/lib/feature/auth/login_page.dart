import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';
import 'bloc/user_bloc.dart';
import 'bloc/user_state.dart';
import 'bloc/user_event.dart';
import 'widgets/auth_form_widgets.dart';
import 'widgets/login_rive_mascot.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static String routeName = 'LoginPage';
  static String routePath = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  LoginRiveInputs? _riveInputs;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
    _emailFocus.addListener(_syncRiveFromFocus);
    _passFocus.addListener(_syncRiveFromFocus);
    _emailController.addListener(_syncRiveFromText);
  }

  void _syncRiveFromFocus() {
    final rive = _riveInputs;
    if (rive == null) return;
    if (_passFocus.hasFocus) {
      rive.passwordActive(focused: true, obscure: _obscurePassword);
    } else if (_emailFocus.hasFocus) {
      rive.emailActive(
        focused: true,
        textLength: _emailController.text.length,
      );
    } else {
      rive.idle();
    }
  }

  void _syncRiveFromText() {
    if (_riveInputs == null || !_emailFocus.hasFocus) return;
    _riveInputs!.emailActive(
      focused: true,
      textLength: _emailController.text.length,
    );
  }

  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  Future<void> _saveUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
    } else {
      await prefs.remove('saved_email');
    }
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_syncRiveFromFocus);
    _passFocus.removeListener(_syncRiveFromFocus);
    _emailController.removeListener(_syncRiveFromText);
    _emailFocus.dispose();
    _passFocus.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _onSignIn({required bool isLoading}) {
    if (isLoading) return;
    final email = _emailController.text.trim();
    final pass = _passController.text;

    if (email.isEmpty || pass.isEmpty) {
      showAuthFeedbackDialog(
        context,
        title: context.l10n.missingInfo,
        message: context.l10n.enterEmailPassword,
        isError: true,
      );
      return;
    }
    _saveUserCredentials();
    context.read<UserBloc>().add(LoginEvent(email: email, password: pass));
  }

  void _openGuestDictionary() {
    context.pushNamed(kDictDemoRouteName, extra: {'isGuest': true});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.success && state.userEntity != null) {
          _riveInputs?.loginSuccess();
        } else if (state.status == UserStatus.error &&
            state.errorMessage != null) {
          _riveInputs?.loginFailed();
          showAuthFeedbackDialog(
            context,
            title: context.l10n.loginFailed,
            message: state.errorMessage!,
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.isFormLoading;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Stack(
            children: [
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: StudentMobileUi.pagePadding,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.s6),
                          AuthLoginRiveMascot(
                            onReady: (inputs) {
                              _riveInputs = inputs;
                              _syncRiveFromFocus();
                            },
                          ),
                          const SizedBox(height: AppSpacing.s5),
                          Text(
                            context.l10n.loginWelcomeBack,
                            textAlign: TextAlign.center,
                            style: context.h1Style,
                          ),
                          const SizedBox(height: AppSpacing.s3),
                          Text(
                            context.l10n.loginSubtitle,
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
                                AuthFieldLabel(context.l10n.loginEmailOrUsername),
                                const SizedBox(height: AppSpacing.s3),
                                AuthTextField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  hintText: context.l10n.hintLoginEmailOrUsername,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  enabled: !isLoading,
                                  onChanged: (_) => _syncRiveFromText(),
                                ),
                                const SizedBox(height: AppSpacing.s5),
                                AuthFieldLabel(context.l10n.labelPassword),
                                const SizedBox(height: AppSpacing.s3),
                                AuthTextField(
                                  controller: _passController,
                                  focusNode: _passFocus,
                                  hintText: context.l10n.hintPassword,
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  enabled: !isLoading,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      );
                                      if (_passFocus.hasFocus) {
                                        _riveInputs?.passwordActive(
                                          focused: true,
                                          obscure: _obscurePassword,
                                        );
                                      }
                                    },
                                  ),
                                  onSubmitted: (_) =>
                                      _onSignIn(isLoading: isLoading),
                                ),
                                const SizedBox(height: AppSpacing.s6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _rememberMe = !_rememberMe,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              onChanged: (v) => setState(
                                                () => _rememberMe = v ?? false,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.s3),
                                          Text(
                                            context.l10n.rememberMe,
                                            style: AppTypography.label(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.pushNamed(
                                        'ForgotPasswordPage',
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(44, 36),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        context.l10n.forgotPasswordLink,
                                        style: AppTypography.label(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s7),
                                FilledButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => _onSignIn(isLoading: isLoading),
                                  style: AuthFormUi.primaryButtonStyle(),
                                  child: isLoading
                                      ? const AppLoadingIndicator.button(
                                          color: AppColors.onPrimary,
                                        )
                                      : Text(context.l10n.signIn),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s7),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppColors.outline),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s4,
                                ),
                                child: Text(
                                  context.l10n.orDivider,
                                  style: context.captionStyle.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: AppColors.outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s7),
                          _buildGoogleButton(context, isLoading),
                          const SizedBox(height: AppSpacing.s8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.l10n.noAccountPrompt,
                                style: StudentMobileUi.body(context).copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.pushNamed('RegisterPage'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.s3,
                                  ),
                                  minimumSize: const Size(44, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  context.l10n.signUp,
                                  style: AppTypography.label(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(StudentMobileUi.pageHPadding),
                    child: _buildGuestDictButton(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestDictButton(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: _openGuestDictionary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.s3),
              Text(
                context.l10n.dictionary,
                style: AppTypography.label(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context, bool isLoading) {
    return SizedBox(
      height: AuthFormUi.fieldHeight,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () => context.read<UserBloc>().add(LoginWithGoogleEvent()),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceCard,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.outlineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/google.svg', width: 22, height: 22),
            const SizedBox(width: AppSpacing.s4),
            Text(context.l10n.continueWithGoogle, style: AppTypography.label()),
          ],
        ),
      ),
    );
  }
}
