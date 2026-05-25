import 'package:flutter/material.dart';

import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import 'data_mock/task_type_instructions.dart';

class WritingTaskInstructionDialog extends StatelessWidget {
  const WritingTaskInstructionDialog({super.key, required this.taskType});

  final String taskType;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final instruction = taskInstructions[taskType] ?? taskInstructions['Opinion']!;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.s5),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s7,
                AppSpacing.s7,
                AppSpacing.s7,
                AppSpacing.s5,
              ),
              child: Row(
                children: [
                  StudentMobileUi.skillIconBox(Icons.lightbulb_outline, size: 44),
                  const SizedBox(width: AppSpacing.s5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.writingInstructionHowTo(instruction.title),
                          style: StudentMobileUi.sectionTitle(context),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          t.writingInstructionSubtitle,
                          style: StudentMobileUi.caption(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    tooltip: t.commonClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineMuted),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(t.writingInstructionWhatIsIt),
                    Text(
                      instruction.description,
                      style: StudentMobileUi.bodyLg(context),
                    ),
                    const SizedBox(height: AppSpacing.s7),
                    _buildSectionTitle(t.writingInstructionSuggestedStructure),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.card + 2),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Text(
                        instruction.structure.trim(),
                        style: AppTypography.body(large: true).copyWith(
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s7),
                    _buildSectionTitle(t.writingInstructionKeyTipsSection),
                    ...instruction.keyTips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.s4),
                            Expanded(
                              child: Text(tip, style: StudentMobileUi.body(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineMuted),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(t.writingInstructionGotIt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Text(
        title,
        style: AppTypography.label(color: AppColors.textSecondary).copyWith(
          letterSpacing: 1,
        ),
      ),
    );
  }
}
