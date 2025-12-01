// reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';
import 'login_page.dart'; // Để sử dụng _showShadcnDialog nếu không share

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

  // --- SHADCN COLORS ---
  static const Color bgPage = Color(0xFFF9FAFB);
  static const Color textMain = Color(0xFF09090B);
  static const Color textMuted = Color(0xFF71717A);
  static const Color borderCol = Color(0xFFE4E4E7);
  static const Color primaryCol = Color(0xFF18181B);
  static const Color accentCol = Color(0xFF16A34A);

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

    if (pass.isEmpty || confirm.isEmpty) {
      _showShadcnDialog(context, title: 'Error', message: 'Please enter both passwords.', isError: true);
      return;
    }
    if (pass != confirm) {
      _showShadcnDialog(context, title: 'Password Error', message: 'Passwords do not match.', isError: true);
      return;
    }
    if (pass.length < 6) {
      _showShadcnDialog(context, title: 'Password Error', message: 'Password must be at least 6 characters.', isError: true);
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
          _showShadcnDialog(context, title: 'Reset Failed', message: state.errorMessage!, isError: true);
        }

        if (state.status == UserStatus.unauthenticated && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          context.goNamed(LoginPage.routeName);
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
                      child: const Icon(Icons.key_outlined, size: 32, color: accentCol),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Set New Password',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textMain, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter a new password for your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 32),

                    // 2. Password Input
                    _Label('New Password'),
                    const SizedBox(height: 8),
                    _ShadcnInput(
                      controller: _passController,
                      hintText: 'Enter new password...',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePass,
                      enabled: !isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Input
                    _Label('Confirm New Password'),
                    const SizedBox(height: 8),
                    _ShadcnInput(
                      controller: _confirmPassController,
                      hintText: 'Confirm new password...',
                      icon: Icons.verified_user_outlined,
                      obscureText: _obscureConfirm,
                      enabled: !isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: textMuted,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 3. Reset Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _onReset(isLoading: isLoading),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCol,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
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

// _Label and _ShadcnInput: Copied
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