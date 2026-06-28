import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/student/join/student_join_coordinator.dart';
import 'package:flutter/material.dart';

class StudentUnifiedJoinCard extends StatefulWidget {
  const StudentUnifiedJoinCard({
    super.key,
    this.onClassJoined,
    this.compact = false,
  });

  final VoidCallback? onClassJoined;

  /// Gọn hơn khi đã có lớp — nhường chỗ cho danh sách.
  final bool compact;

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
    final accent = AppSkillColors.speaking;
    final compact = widget.compact;

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.s3 : AppSpacing.s4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.tint,
            AppColors.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        border: Border.all(color: accent.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentMobileUi.skillIconBox(
                Icons.qr_code_scanner_rounded,
                size: compact ? 32 : 36,
                skill: SkillType.speaking,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.studentUnifiedJoinTitle, style: StudentMobileUi.cardTitle(context)),
                    if (!compact) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        l10n.studentUnifiedJoinSubtitle,
                        style: StudentMobileUi.caption(context).copyWith(height: 1.4),
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.studentUnifiedJoinCompactHint,
                        style: StudentMobileUi.caption(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.s3 : AppSpacing.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: StudentMobileUi.body(context).copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: l10n.studentUnifiedJoinHint,
                    hintStyle: StudentMobileUi.caption(context).copyWith(
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceCard.withValues(alpha: 0.9),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.content_paste_go_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: accent.color, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: AppColors.outlineStrong,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
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
        ],
      ),
    );
  }
}
