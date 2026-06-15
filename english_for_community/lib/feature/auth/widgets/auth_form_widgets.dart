import 'package:flutter/material.dart';

import '../../../core/locale/l10n_context.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/student_mobile_ui.dart';

/// Shared form primitives for student auth screens — `docs/ui-ux-system/04`.
abstract final class AuthFormUi {
  static const double fieldHeight = 48;

  static ButtonStyle primaryButtonStyle() => FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, fieldHeight),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      );

  static InputDecoration fieldDecoration({
    required String hintText,
    String? helperText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.outlineStrong),
    );
    return InputDecoration(
      hintText: hintText,
      helperText: helperText,
      helperStyle: AppTypography.label(color: AppColors.textMuted),
      helperMaxLines: 3,
      hintStyle: AppTypography.body(color: AppColors.textMuted),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      isDense: true,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.outlineMuted),
      ),
      filled: true,
      fillColor: AppColors.surfaceCard,
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.label());
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.helperText,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.onSubmitted,
    this.focusNode,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: context.bodyStyle,
      decoration: AuthFormUi.fieldDecoration(
        hintText: hintText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
    if (helperText == null || helperText!.isEmpty) {
      return SizedBox(height: AuthFormUi.fieldHeight, child: field);
    }
    return field;
  }
}

class AuthOtpInput extends StatefulWidget {
  const AuthOtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.length = 6,
    this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final ValueChanged<String>? onCompleted;

  @override
  State<AuthOtpInput> createState() => _AuthOtpInputState();
}

class _AuthOtpInputState extends State<AuthOtpInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          height: AuthFormUi.fieldHeight,
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
              filled: false,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final text = widget.controller.text;
            final char = index < text.length ? text[index] : '';
            final isFocused =
                index == text.length && widget.focusNode.hasFocus;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
              width: 44,
              height: AuthFormUi.fieldHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(
                  color: isFocused
                      ? AppColors.primary
                      : (char.isNotEmpty
                          ? AppColors.textSecondary
                          : AppColors.outlineStrong),
                  width: isFocused ? 1.5 : 1,
                ),
              ),
              child: Text(
                char,
                style: context.h2Style.copyWith(fontWeight: FontWeight.w600),
              ),
            );
          }),
        ),
      ],
    );
  }
}

void showAuthFeedbackDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool isError = false,
}) {
  final t = context.l10n;
  showDialog(
    context: context,
    builder: (ctx) => StudentDialogShell(
      title: title,
      subtitle: message,
      child: const SizedBox.shrink(),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: AuthFormUi.primaryButtonStyle().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(88, 44)),
          ),
          child: Text(t.close),
        ),
      ],
    ),
  );
}
