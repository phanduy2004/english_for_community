import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import để lưu trạng thái

import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_state.dart';
import '../../feature/auth/bloc/user_event.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static String routeName = 'LoginPage';
  static String routePath = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Xóa text mặc định
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false; // Mặc định là false

  // --- SHADCN/FOURI COLOR PALETTE ---
  static const Color bgPage = Color(0xFFF9FAFB);
  static const Color textMain = Color(0xFF09090B);
  static const Color textMuted = Color(0xFF71717A);
  static const Color borderCol = Color(0xFFE4E4E7);
  static const Color primaryCol = Color(0xFF18181B);
  static const Color accentCol = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    // 2. Load thông tin đã lưu khi mở màn hình
    _loadUserCredentials();
  }

  // Hàm load thông tin từ bộ nhớ máy
  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  // Hàm lưu thông tin
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
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _onSignIn({required bool isLoading}) {
    if (isLoading) return;
    final email = _emailController.text.trim();
    final pass = _passController.text;

    if (email.isEmpty || pass.isEmpty) {
      _showShadcnDialog(
        context,
        title: 'Missing Information',
        message: 'Please enter your full email and password.',
        isError: true,
      );
      return;
    }

    // 3. Gọi hàm lưu trước khi Login
    _saveUserCredentials();

    context.read<UserBloc>().add(LoginEvent(email: email, password: pass));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.error && state.errorMessage != null) {
          _showShadcnDialog(context, title: 'Login Failed', message: state.errorMessage!, isError: true);
        }
      },
      builder: (context, state) {
        final isLoading = state.isFormLoading;

        return Scaffold(
          backgroundColor: bgPage,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HEADER ---
                    Center(
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.auto_stories_rounded, size: 32, color: accentCol),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textMain, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your details to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 32),

                    // --- FORM CARD ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Email'),
                          const SizedBox(height: 8),
                          _ShadcnInput(
                            controller: _emailController,
                            hintText: 'name@example.com',
                            icon: Icons.email_outlined,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),

                          _Label('Password'),
                          const SizedBox(height: 8),
                          _ShadcnInput(
                            controller: _passController,
                            hintText: 'Enter password...',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            enabled: !isLoading,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18, color: textMuted,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            onSubmitted: (_) => _onSignIn(isLoading: isLoading),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20, height: 20,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: primaryCol,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        side: const BorderSide(color: borderCol, width: 1.5),
                                        onChanged: (v) => setState(() => _rememberMe = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Remember me', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMain)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.pushNamed('ForgotPasswordPage'),
                                child: const Text('Forgot password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMain)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => _onSignIn(isLoading: isLoading),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryCol,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- DIVIDER ---
                    Row(
                      children: [
                        const Expanded(child: Divider(color: borderCol)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600)),
                        ),
                        const Expanded(child: Divider(color: borderCol)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- 4. NEW GOOGLE BUTTON (Modern Style) ---
                    _buildGoogleButton(context, isLoading),

                    const SizedBox(height: 32),

                    // --- SIGN UP LINK ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(fontSize: 14, color: textMuted)),
                        GestureDetector(
                          onTap: () => context.pushNamed('RegisterPage'),
                          child: const Text('Sign Up', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textMain)),
                        ),
                      ],
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

  // 🔥 4. Widget Button Google Đẹp hơn
  Widget _buildGoogleButton(BuildContext context, bool isLoading) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isLoading ? null : () => context.read<UserBloc>().add(LoginWithGoogleEvent()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Google
                SvgPicture.asset(
                    'assets/images/google.svg',
                    width: 22,
                    height: 22
                ),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textMain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- GIỮ NGUYÊN CÁC WIDGET CON (REUSABLE) ---

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