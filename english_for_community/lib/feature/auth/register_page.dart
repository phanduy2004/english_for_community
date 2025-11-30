import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../auth/bloc/user_bloc.dart';
import '../auth/bloc/user_state.dart';
import '../auth/bloc/user_event.dart';
import 'otp_verification_page.dart';

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

  static const Color bgPage = Color(0xFFF9FAFB);
  static const Color textMain = Color(0xFF09090B);
  static const Color textMuted = Color(0xFF71717A);
  static const Color borderCol = Color(0xFFE4E4E7);
  static const Color primaryCol = Color(0xFF18181B);
  static const Color accentCol = Color(0xFF16A34A);

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
              primary: primaryCol,
              onPrimary: Colors.white,
              onSurface: textMain,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryCol),
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

    if (name.isEmpty || username.isEmpty || email.isEmpty || pass.isEmpty) {
      _showShadcnDialog(context, title: 'Error', message: 'Please fill in all required fields (*).', isError: true);
      return;
    }
    if (pass != confirm) {
      _showShadcnDialog(context, title: 'Password Error', message: 'Confirmation password does not match.', isError: true);
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
          _showShadcnDialog(context, title: 'Registration Failed', message: state.errorMessage!, isError: true);
        }

        if (state.status == UserStatus.otpRequired) {
          context.goNamed(OtpVerificationPage.routeName, extra: state.errorMessage);
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
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- 1. HEADER ---
                    const Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textMain, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fill in the details to start your journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 32),

                    // --- 2. FORM CARD ---
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
                          // Full Name
                          _Label('Full Name *'),
                          const SizedBox(height: 8),
                          _ShadcnInput(
                            controller: _nameController, hintText: 'John Doe', icon: Icons.badge_outlined, enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),

                          // Username
                          _Label('Username *'),
                          const SizedBox(height: 8),
                          _ShadcnInput(
                            controller: _usernameController, hintText: 'username123', icon: Icons.alternate_email, enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),

                          // Phone & DOB (Row)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Label('Phone Number'),
                                    const SizedBox(height: 8),
                                    _ShadcnInput(
                                      controller: _phoneController, hintText: '0912...', icon: Icons.phone_outlined, enabled: !isLoading, keyboardType: TextInputType.phone,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Date of Birth
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Label('Date of Birth'),
                                    const SizedBox(height: 8),
                                    _ShadcnInput(
                                      controller: _dobController, hintText: 'DD/MM/YYYY', icon: Icons.calendar_today_outlined, enabled: !isLoading, readOnly: true, onTap: () => _selectDate(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _Label('Email *'),
                          const SizedBox(height: 8),
                          _ShadcnInput(
                            controller: _emailController, hintText: 'name@example.com', icon: Icons.email_outlined, enabled: !isLoading, keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _Label('Password *'),
                          const SizedBox(height: 8),
                          _ShadcnInput(
                            controller: _passController, hintText: '******', icon: Icons.lock_outline, obscureText: _obscurePass, enabled: !isLoading,
                            suffixIcon: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: textMuted), onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _Label('Confirm Password *'),
                          const SizedBox(height: 8),
                          _ShadcnInput(
                            controller: _confirmPassController, hintText: '******', icon: Icons.verified_user_outlined, obscureText: _obscureConfirm, enabled: !isLoading,
                            suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: textMuted), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity, height: 44,
                            child: ElevatedButton(
                              onPressed: () => _onSignUp(isLoading: isLoading),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryCol, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Register', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- 3. FOOTER ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(fontSize: 14, color: textMuted)),
                        GestureDetector(
                          onTap: () => context.goNamed('LoginPage'),
                          child: const Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMain)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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

// --- WIDGETS REUSABLE ---

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF09090B)));
}

class _ShadcnInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;

  const _ShadcnInput({
    required this.controller, required this.hintText, required this.icon,
    this.obscureText = false, this.suffixIcon, this.enabled = true,
    this.readOnly = false, this.onTap, this.keyboardType,
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
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF09090B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF71717A)),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.2)),
          filled: true, fillColor: Colors.white,
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
      title: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? Colors.red : Colors.green, size: 24),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
      content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF52525B))),
      actions: [
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => Navigator.pop(ctx),
          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: const BorderSide(color: Color(0xFFE4E4E7)), foregroundColor: const Color(0xFF09090B)),
          child: const Text('Close'),
        ))
      ],
    ),
  );
}