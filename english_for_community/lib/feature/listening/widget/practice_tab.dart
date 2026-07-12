import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_skill_scope.dart';
import 'package:english_for_community/feature/student/exams/exam_integrity_tracker.dart';
import 'package:flutter/material.dart';
import '../listening_skill/bloc/cue_state.dart';
import '../../../core/locale/l10n_context.dart';

class PracticeTab extends StatelessWidget {
  final CueState state;
  final TextEditingController controller;
  final Function(String) onTextChange;
  final VoidCallback onSubmit;
  final VoidCallback? onReplay;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool showHint;
  final String? lastHint;
  final bool autoPlay;
  final Function(bool) onToggleAutoPlay;
  final VoidCallback? onAllFinished;
  final bool examPracticeMode;
  final bool readOnlyReview;

  const PracticeTab({
    super.key,
    required this.state,
    required this.controller,
    required this.onTextChange,
    required this.onSubmit,
    required this.onReplay,
    required this.onNext,
    required this.onPrev,
    required this.showHint,
    this.lastHint,
    required this.autoPlay,
    required this.onToggleAutoPlay,
    this.onAllFinished,
    this.examPracticeMode = false,
    this.readOnlyReview = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final compact = ExamEmbeddedSkillScope.compactOf(context);
    final isDone = state.completedIdx.contains(state.selectedIndex);
    final cue = state.currentCue;
    final isLast = state.selectedIndex == state.cues.length - 1;

    String btnText = examPracticeMode ? t.dictationSaveContinue : t.dictationCheckButton;
    Color btnColor = Theme.of(context).primaryColor;
    VoidCallback onBtn = onSubmit;
    IconData btnIcon = examPracticeMode ? Icons.arrow_forward : Icons.check;

    if (isDone) {
      if (!isLast) {
        btnText = t.dictationNextButton;
        btnColor = AppColors.success;
        btnIcon = Icons.arrow_forward;
        onBtn = onNext;
      } else {
        btnText = t.dictationFinishButton;
        btnColor = Colors.green;
        onBtn = onAllFinished ?? () => Navigator.pop(context, true);
      }
    }

    final sentenceStyle = compact
        ? ExamSystemUi.embeddedSectionLabelStyle
        : const TextStyle(fontWeight: FontWeight.bold);
    final fieldPadding = compact ? const EdgeInsets.all(12) : const EdgeInsets.all(20);

    return SingleChildScrollView(
      padding: fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.listeningSentenceNumber(state.selectedIndex + 1), style: sentenceStyle),
              Row(children: [
                IconButton(onPressed: state.selectedIndex > 0 ? onPrev : null, icon: const Icon(Icons.chevron_left)),
                IconButton(onPressed: !isLast ? onNext : null, icon: const Icon(Icons.chevron_right)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            contextMenuBuilder: examContextMenuBuilder,
            maxLines: 3,
            readOnly: readOnlyReview,
            style: compact ? ExamSystemUi.embeddedBodyStyle : null,
            decoration: InputDecoration(
              hintText: t.dictationTypeWhatYouHearHint,
              filled: true,
              fillColor: compact ? AppColors.surface : AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(compact ? 10 : 12),
                borderSide: BorderSide(color: compact ? AppColors.outlineMuted : AppColors.outline),
              ),
            ),
            onChanged: readOnlyReview ? null : onTextChange,
          ),
          if (!examPracticeMode && showHint && lastHint != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(AppRadius.input)),
              child: Text(lastHint!, style: const TextStyle(color: AppColors.danger)),
            ),
          if (!examPracticeMode && isDone && cue?.meaning != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.info),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.meaningLabel,
                    style: compact
                        ? ExamSystemUi.embeddedCaptionStyle.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)
                        : const TextStyle(fontSize: AppTypography.mobileCaption, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cue!.meaning!,
                    style: compact
                        ? ExamSystemUi.embeddedBodyStyle.copyWith(fontStyle: FontStyle.italic)
                        : const TextStyle(color: AppColors.info, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          if (!readOnlyReview) ...[
            const SizedBox(height: 20),
            if (examPracticeMode)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onBtn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                  ),
                  icon: Icon(btnIcon, size: 18),
                  label: Text(btnText),
                ),
              )
            else ...[
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: onBtn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                  ),
                  icon: Icon(btnIcon, size: 18),
                  label: Text(btnText),
                )),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onReplay,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                    foregroundColor: onReplay == null ? AppColors.textMuted : null,
                  ),
                  child: Icon(onReplay == null ? Icons.play_disabled : Icons.replay),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Text(
                  t.listeningAutoPlayNext,
                  style: compact ? ExamSystemUi.embeddedCaptionStyle : const TextStyle(fontSize: AppTypography.mobileBody, color: Colors.grey),
                ),
                const Spacer(),
                Switch(
                  value: autoPlay,
                  onChanged: onToggleAutoPlay,
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
              ]),
            ],
          ],
        ],
      ),
    );
  }
}