import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Colors based on Shadcn theme
  static const Color textMain = Color(0xFF09090B);
  static const Color textMuted = Color(0xFF71717A);
  static const Color borderCol = Color(0xFFE4E4E7);
  static const Color primaryCol = Color(0xFF18181B);

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final current = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showToast(context, 'Please fill in all fields', isError: true);
      return;
    }
    if (newPass != confirm) {
      _showToast(context, 'New passwords do not match', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showToast(context, 'Password must be at least 6 characters', isError: true);
      return;
    }

    context.read<UserBloc>().add(ChangePasswordEvent(
      currentPassword: current,
      newPassword: newPass,
    ));
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (!state.isFormLoading) {
          if (state.errorMessage == "Password changed successfully!") {
            Navigator.pop(context); // Đóng dialog
            _showToast(context, state.errorMessage!);
            // Reset error message để tránh hiện lại
            // (Optional: trigger clear error event)
          } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            _showToast(context, state.errorMessage!, isError: true);
          }
        }
      },
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: const [
                  Icon(Icons.lock_reset_rounded, color: textMain),
                  SizedBox(width: 12),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Update your password to keep your account secure.',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
              const SizedBox(height: 24),

              // INPUTS
              _Label('Current Password'),
              const SizedBox(height: 6),
              _ShadcnInput(
                controller: _currentPassController,
                hintText: 'Enter current password',
                obscureText: _obscureCurrent,
                onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),

              const SizedBox(height: 16),

              _Label('New Password'),
              const SizedBox(height: 6),
              _ShadcnInput(
                controller: _newPassController,
                hintText: 'Enter new password',
                obscureText: _obscureNew,
                onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              ),

              const SizedBox(height: 16),

              _Label('Confirm New Password'),
              const SizedBox(height: 6),
              _ShadcnInput(
                controller: _confirmPassController,
                hintText: 'Re-enter new password',
                obscureText: _obscureConfirm,
                onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 32),

              // ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: borderCol),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        foregroundColor: textMain,
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BlocBuilder<UserBloc, UserState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state.isFormLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryCol,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: state.isFormLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                        );
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- REUSABLE COMPONENTS (Mini version for Dialog) ---

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF09090B)));
  }
}

class _ShadcnInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback onToggleObscure;

  const _ShadcnInput({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 14, color: Color(0xFF09090B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.2)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF71717A),
            ),
            onPressed: onToggleObscure,
          ),
        ),
      ),
    );
  }
}