import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:flutter/material.dart';

/// Writing part when the exam has [fixedWritingPrompt] but no CMS topic id (exam-only draft).
class ExamEmbeddedFixedWritingPanel extends StatefulWidget {
  const ExamEmbeddedFixedWritingPanel({
    super.key,
    required this.fixedWritingPrompt,
    required this.locked,
    this.initialDraft,
    this.onDraftChanged,
    this.onPartComplete,
  });

  final Map<String, dynamic> fixedWritingPrompt;
  final bool locked;
  final String? initialDraft;
  final void Function(String text)? onDraftChanged;
  final VoidCallback? onPartComplete;

  @override
  State<ExamEmbeddedFixedWritingPanel> createState() => _ExamEmbeddedFixedWritingPanelState();
}

class _ExamEmbeddedFixedWritingPanelState extends State<ExamEmbeddedFixedWritingPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDraft ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onDraftChanged?.call(_controller.text);
  }

  int get _wordCount {
    final t = _controller.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = (widget.fixedWritingPrompt['title'] as String?)?.trim() ?? '';
    final text = (widget.fixedWritingPrompt['text'] as String?)?.trim() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight;
        final editor = AppCard(
          variant: AppCardVariant.outline,
          child: TextField(
            controller: _controller,
            readOnly: widget.locked,
            maxLines: boundedHeight ? null : 14,
            expands: boundedHeight,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: l10n.studentExamEssayPlaceholder,
              border: InputBorder.none,
              filled: true,
              fillColor: AppColors.surfaceCard,
            ),
            style: ExamSystemUi.captionSecondary.copyWith(fontSize: AppTypography.mobileBodyLg, height: 1.5),
          ),
        );

        return Column(
          mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              variant: AppCardVariant.outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(title, style: ExamSystemUi.sectionTitle(context)),
                  if (title.isNotEmpty) const SizedBox(height: 8),
                  Text(text, style: ExamSystemUi.captionSecondary.copyWith(height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: ExamSystemUi.cardGap),
            if (boundedHeight)
              Expanded(child: editor)
            else
              SizedBox(
                height: (MediaQuery.sizeOf(context).height * 0.4).clamp(240.0, 480.0),
                child: editor,
              ),
            const SizedBox(height: 8),
            Text(
              l10n.wordCountN(_wordCount),
              style: ExamSystemUi.captionMuted,
            ),
          ],
        );
      },
    );
  }
}
