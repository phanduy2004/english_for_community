import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/join/student_join_coordinator.dart';
import 'package:flutter/material.dart';

class StudentUnifiedJoinCard extends StatefulWidget {
  const StudentUnifiedJoinCard({
    super.key,
    this.onClassJoined,
  });

  final VoidCallback? onClassJoined;

  @override
  State<StudentUnifiedJoinCard> createState() => _StudentUnifiedJoinCardState();
}

class _StudentUnifiedJoinCardState extends State<StudentUnifiedJoinCard> {
  final _inputCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _inputCtrl.text.trim();
    if (raw.isEmpty || _busy) return;
    setState(() => _busy = true);
    final ok = await StudentJoinCoordinator.submit(
      context,
      raw,
      onClassJoined: widget.onClassJoined,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      variant: AppCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentMobileUi.skillIconBox(Icons.qr_code_scanner_rounded, size: 36, skill: SkillType.speaking),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.studentUnifiedJoinTitle, style: StudentMobileUi.cardTitle(context)),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      l10n.studentUnifiedJoinSubtitle,
                      style: StudentMobileUi.caption(context).copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          TextField(
            controller: _inputCtrl,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.studentUnifiedJoinHint,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              filled: true,
              fillColor: AppColors.surfaceSubtle,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: const Icon(Icons.content_paste_go_rounded, size: 18, color: AppColors.textMuted),
              prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.outlineStrong,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: AppLoadingIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.studentUnifiedJoinButton),
            ),
          ),
        ],
      ),
    );
  }
}
