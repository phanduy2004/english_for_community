import 'dart:ui' show ImageFilter;

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/feature/auth/bloc/user_event.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static String routeName = 'LoginPage';
  static String routePath = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _email = TextEditingController(text: 'testuser@example.com');
  final _pass  = TextEditingController(text: 'Test@1234');
  final _emailNode = FocusNode();
  final _passNode  = FocusNode();
  bool _obscure = true;
  bool _remember = true;

  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _slide = Tween(begin: const Offset(0, .08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ac.forward());
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _emailNode.dispose();
    _passNode.dispose();
    _ac.dispose();
    super.dispose();
  }

  void _onSignIn({required bool isLoading}) {
    if (isLoading) return;
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    context.read<UserBloc>().add(LoginEvent(email: email, password: pass));
  }

  void _onForgot() => context.pushNamed('ForgotPasswordPage');
  void _onSignUp()   => context.pushNamed('RegisterPage');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final tt    = theme.textTheme;

    final insets = MediaQuery.of(context).viewInsets;
    final isKeyboard = insets.bottom > 0;

    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.status == UserStatus.success) {
          context.goNamed('HomePage');
        }
      },
      builder: (context, state) {
        final isLoading = state.status == UserStatus.loading;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: _scaffoldKey,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient nền “luxury”
                DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ Color(0xFF101820), Color(0xFF1D976C), Color(0xFFA5D6A7) ],
                      stops:  [ 0.0, 0.55, 1.0 ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Họa tiết tròn + blur nhẹ
                Positioned(
                  right: -60, top: -60,
                  child: _Bubble(size: 180, color: Colors.white.withOpacity(.08)),
                ),
                Positioned(
                  left: -40, top: 120,
                  child: _Bubble(size: 140, color: Colors.white.withOpacity(.07)),
                ),
                Positioned(
                  right: 30, bottom: 80,
                  child: _Bubble(size: 90, color: Colors.white.withOpacity(.06)),
                ),

                // Nội dung
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      // Responsive maxWidth cho card
                      final maxW = c.maxWidth >= 900 ? 520.0 : (c.maxWidth >= 600 ? 480.0 : double.infinity);
                      final topPad = isKeyboard ? 80.0 : (c.maxHeight * .18).clamp(140.0, 220.0);

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, topPad, 16, 16 + insets.bottom),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxW),
                            child: FadeTransition(
                              opacity: _fade,
                              child: SlideTransition(
                                position: _slide,
                                child: _GlassCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Logo + tiêu đề
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: cs.primary.withOpacity(.12),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(Icons.school_rounded, size: 30),
                                          ),
                                          const SizedBox(width: 12),
                                          Text('Welcome back', style: tt.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          )),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Sign in to continue your learning path',
                                        style: tt.bodyMedium?.copyWith(color: Colors.white70),
                                      ),

                                      const SizedBox(height: 24),

                                      // Email
                                      _buildTextField(
                                        controller: _email,
                                        focusNode: _emailNode,
                                        hintText: 'Email address',
                                        prefixIcon: Icons.email_outlined,
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.emailAddress,
                                        enabled: !isLoading,
                                      ),
                                      const SizedBox(height: 16),

                                      // Password
                                      _buildTextField(
                                        controller: _pass,
                                        focusNode: _passNode,
                                        hintText: 'Password',
                                        prefixIcon: Icons.lock_outline,
                                        obscureText: _obscure,
                                        onFieldSubmitted: (_) => _onSignIn(isLoading: isLoading),
                                        suffixIcon: IconButton(
                                          onPressed: isLoading ? null : () => setState(() => _obscure = !_obscure),
                                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                                        ),
                                        enabled: !isLoading,
                                      ),

                                      const SizedBox(height: 12),

                                      // ✅ SỬA LỖI OVERFLOW: dùng Wrap thay vì Row + co giãn linh hoạt
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        runSpacing: 8,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 22, height: 22,
                                                child: Checkbox(
                                                  value: _remember,
                                                  onChanged: isLoading ? null : (v) => setState(() => _remember = v ?? true),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text('Remember me', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: isLoading ? null : _onForgot,
                                            child: const Text('Forgot password?'),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Nút Sign in
                                      SizedBox(
                                        width: double.infinity, height: 56,
                                        child: FilledButton(
                                          onPressed: () => _onSignIn(isLoading: isLoading),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 220),
                                            child: isLoading
                                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                                                : Text('Sign In', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 18),

                                      // Divider “or”
                                      Row(
                                        children: [
                                          Expanded(child: Divider(color: Colors.white24)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text('or continue with', style: tt.bodyMedium?.copyWith(color: Colors.white70)),
                                          ),
                                          Expanded(child: Divider(color: Colors.white24)),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Google button
                                      SizedBox(
                                        width: double.infinity, height: 56,
                                        child: OutlinedButton.icon(
                                          onPressed: isLoading
                                              ? null
                                              : () => ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Google sign-in coming soon')),
                                          ),
                                          icon: SvgPicture.asset('assets/images/google.svg', height: 22, width: 22),
                                          label: Text('Continue with Google', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                        ),
                                      ),

                                      const SizedBox(height: 18),

                                      // Sign up
                                      Center(
                                        child: Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text("Don't have an account?  ", style: tt.bodyLarge?.copyWith(color: Colors.white70)),
                                            TextButton(
                                              onPressed: isLoading ? null : _onSignUp,
                                              child: const Text('Sign Up'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Overlay khi loading
                if (isLoading)
                  IgnorePointer(
                    child: Container(color: Colors.black.withOpacity(.04)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Input
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    Function(String)? onFieldSubmitted,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(prefixIcon, color: Colors.white70, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(.10),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(.20), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primaryContainer, width: 1.2),
        ),
      ),
    );
  }
}

/// Bong bóng + blur
class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});
  final double size; final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }
}

/// Thẻ “glassmorphism”
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.18)),
            boxShadow: const [BoxShadow(blurRadius: 30, spreadRadius: -4, color: Color(0x33000000))],
          ),
          child: child,
        ),
      ),
    );
  }
}
