// forgot_password_page.dart
import 'dart:async';
import 'package:english_for_community/feature/auth/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';
import 'login_page.dart'; // Để sử dụng _showShadcnDialog nếu không share

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static String routeName = 'ForgotPasswordPage';
  static String routePath = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _textController = TextEditingController(); // For OTP
  final _focusNode = FocusNode(); // For OTP

  bool _showOtpInput = false;
  String? _email;
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  // --- SHADCN COLORS ---
  static const Color bgPage = Color(0xFFF9FAFB);
  static const Color textMain = Color(0xFF09090B);
  static const Color textMuted = Color(0xFF71717A);
  static const Color borderCol = Color(0xFFE4E4E7);
  static const Color primaryCol = Color(0xFF18181B);
  static const Color accentCol = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
  }

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

    if (email.isEmpty) {
      _showShadcnDialog(context, title: 'Error', message: 'Please enter your email.', isError: true);
      return;
    }

    context.read<UserBloc>().add(RequestForgotPasswordEvent(email: email));
  }

  void _onNext(bool isLoading) {
    if (isLoading || !_showOtpInput) return;
    final otp = _textController.text;

    if (otp.length < 6) {
      _showShadcnDialog(context, title: 'Error', message: 'Please enter the 6-digit code.', isError: true);
      return;
    }

    // Chuyển sang ResetPasswordPage với email và otp
    context.pushNamed(ResetPasswordPage.routeName, extra: {'email': _email, 'otp': otp});
  }

  void _onResend() {
    if (!_canResend) return;

    context.read<UserBloc>().add(RequestForgotPasswordEvent(email: _email!));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resending code...')));
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.error && state.errorMessage != null) {
          _showShadcnDialog(context, title: 'Error', message: state.errorMessage!, isError: true);
        }

        if (state.status == UserStatus.otpRequired) {
          setState(() {
            _email = state.errorMessage; // Lưu email từ state
            _showOtpInput = true;
          });
          if (!(_timer?.isActive ?? false)) { startTimer(); }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusNode.requestFocus();
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email.')));
        }
      },
      builder: (context, state) {
        final isLoading = state.isFormLoading;

        return Scaffold(
          backgroundColor: bgPage,
          appBar: AppBar(
            backgroundColor: bgPage,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textMain),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. Icon & Title
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderCol),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                      ),
                      child: const Icon(Icons.lock_reset_outlined, size: 32, color: accentCol),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Reset Your Password',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textMain, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your email to receive a verification code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 32),

                    // 2. Email Input with Send Button
                    _Label('Email'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ShadcnInput(
                            controller: _emailController,
                            hintText: 'name@example.com',
                            icon: Icons.email_outlined,
                            enabled: !isLoading && !_showOtpInput, // Disable after send
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _showOtpInput ? null : () => _onSend(isLoading),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryCol,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isLoading && !_showOtpInput
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Send', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 3. OTP Input (Show after send)
                    if (_showOtpInput) ...[
                      const Text(
                        'Enter Verification Code',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textMain),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5),
                          children: [
                            const TextSpan(text: 'A 6-digit code has been sent to\n'),
                            TextSpan(
                              text: _email,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: textMain),
                            ),
                            const TextSpan(text: '. Please check your inbox.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _CustomOtpInput(
                        controller: _textController,
                        focusNode: _focusNode,
                        length: 6,
                        onCompleted: (_) => _onNext(isLoading),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _onNext(isLoading),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryCol,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Next', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Didn't receive the code? ", style: TextStyle(fontSize: 14, color: textMuted)),
                          _canResend
                              ? GestureDetector(
                            onTap: _onResend,
                            child: const Text('Resend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMain)),
                          )
                              : Text(
                            'Resend in $_start s',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🔥 WIDGET CUSTOM OTP: Copied from otp_verification_page.dart
class _CustomOtpInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final Function(String)? onCompleted;

  const _CustomOtpInput({
    required this.controller,
    required this.focusNode,
    this.length = 6,
    this.onCompleted,
  });

  @override
  State<_CustomOtpInput> createState() => _CustomOtpInputState();
}

class _CustomOtpInputState extends State<_CustomOtpInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
      if (widget.controller.text.length == widget.length) {
        widget.onCompleted?.call(widget.controller.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. HIDDEN TEXTFIELD: Captures input events
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            showCursor: false,
            enableInteractiveSelection: false,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
        ),

        // 2. DISPLAY LAYOUT: Renders the boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final text = widget.controller.text;
            final char = index < text.length ? text[index] : '';
            final isFocused = index == text.length && widget.focusNode.hasFocus;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 44,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFocused
                      ? const Color(0xFF18181B)
                      : (char.isNotEmpty ? const Color(0xFF52525B) : const Color(0xFFE4E4E7)),
                  width: isFocused ? 1.5 : 1.0,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1))
                ],
              ),
              child: Text(
                char,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF09090B),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// _Label and _ShadcnInput: Copied from login_page.dart or register_page.dart
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF09090B)));
  }
}

class _ShadcnInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final Function(String)? onSubmitted;

  const _ShadcnInput({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        style: const TextStyle(fontSize: 14, color: Color(0xFF09090B)),
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF71717A)),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.2)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

// Helper Dialog: Copied
void _showShadcnDialog(BuildContext context, {required String title, required String message, bool isError = false}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(24),
      title: Row(
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? Colors.red : Colors.green, size: 24),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF52525B))),
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: Color(0xFFE4E4E7)),
              foregroundColor: const Color(0xFF09090B),
            ),
            child: const Text('Close'),
          ),
        )
      ],
    ),
  );
}