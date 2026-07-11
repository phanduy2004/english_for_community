import 'dart:math' as math;

import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/exams/exam_answer_review_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared accent palette for grammar interactive elements (matching, MCQ, blanks, reorder).
abstract final class GrammarAccentPalette {
  static const List<Color> colors = [
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.danger,
    AppColors.tertiary,
    AppColors.accent,
    AppColors.primary,
    AppColors.secondary,
  ];

  static Color of(int index) => colors[index.abs() % colors.length];

  static Color fillBg(Color color, {double alpha = 0.08}) => color.withValues(alpha: alpha);

  static int blankIndex(String blankId, {int fallback = 0}) =>
      int.tryParse(blankId) ?? fallback;
}

/// MCQ row with per-option accent color (grammar exam).
class _GrammarMcqOption extends StatelessWidget {
  const _GrammarMcqOption({
    required this.index,
    required this.text,
    required this.selected,
    this.multiSelect = false,
    this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final bool multiSelect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = GrammarAccentPalette.of(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? GrammarAccentPalette.fillBg(accent) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: selected ? accent : AppColors.outlineMuted,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: selected ? 0.18 : 0.1),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.input)),
                  ),
                  child: Text(
                    StudentMobileUi.mcqLetter(index),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: accent,
                      fontSize: AppTypography.mobileH3,
                      height: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(text, style: ExamSystemUi.captionSecondary.copyWith(height: 1.35)),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            multiSelect ? Icons.check_box_rounded : Icons.radio_button_checked,
                            size: 18,
                            color: accent,
                          ),
                        ],
                      ],
                    ),
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

/// Inline blank — cùng kiểu viền accent + cột id như MCQ grammar.
class _GrammarBlankField extends StatelessWidget {
  const _GrammarBlankField({
    required this.blankId,
    required this.accent,
    required this.controller,
    required this.enabled,
    this.onChanged,
    this.width = 120,
    this.fieldKey,
  });

  final String blankId;
  final Color accent;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final double width;
  final Key? fieldKey;

  static const double _blankHeight = 32;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.trim().isNotEmpty;
    return SizedBox(
      width: width,
      height: _blankHeight,
      // Fill + border drawn in one Material shape (single paint pass) so the two
      // rounded-rect edges coincide exactly — avoids the antialiased corner seam
      // (visible as a "missing corner" on the right, where no badge tint masks it).
      child: Material(
        color: GrammarAccentPalette.fillBg(accent, alpha: filled ? 0.08 : 0.05),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: accent, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.input)),
              ),
              child: Text(
                blankId,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: accent,
                  fontSize: AppTypography.mobileCaption,
                  height: 1,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                key: fieldKey,
                enabled: enabled,
                controller: controller,
                onChanged: onChanged,
                maxLines: 1,
                style: ExamSystemUi.captionSecondary,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only chip for review (gap / cloze inline).
Widget _grammarAccentAnswerChip({
  required String label,
  required String text,
  required Color accent,
}) {
  return Container(
    constraints: const BoxConstraints(minWidth: 72),
    decoration: BoxDecoration(
      color: GrammarAccentPalette.fillBg(accent),
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: accent, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.input)),
          ),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, color: accent, fontSize: AppTypography.mobileCaption, height: 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(text, style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

/// Localized label for a grammar / objective item [kind] string.
String grammarItemKindLabel(BuildContext context, String kind) {
  final t = context.l10n;
  switch (kind) {
    case 'mcq_single':
      return t.teacherExamGrammarKindMcqSingle;
    case 'mcq_multi':
      return t.teacherExamGrammarKindMcqMulti;
    case 'grammar_cloze':
      return t.teacherExamGrammarKindCloze;
    case 'grammar_gap':
      return t.teacherExamGrammarKindGap;
    case 'grammar_matching':
      return t.teacherExamGrammarKindMatching;
    case 'grammar_reorder':
      return t.teacherExamGrammarKindReorder;
    default:
      return kind;
  }
}

/// Teacher grading: shows the keyed correct answer (MCQ indexes, cloze keys, etc.).
class GrammarCorrectAnswerReviewPanel extends StatelessWidget {
  const GrammarCorrectAnswerReviewPanel({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final lines = _lines(context);
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.teacherAttemptGradeCorrectAnswer,
            style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 8),
          ...lines,
        ],
      ),
    );
  }

  List<Widget> _lines(BuildContext context) {
    final kind = '${item['kind'] ?? ''}';
    final style = ExamSystemUi.captionSecondary;

    if (kind == 'mcq_single' || kind == 'mcq_multi') {
      final options = (item['options'] as List?)?.map((e) => '$e').toList() ?? <String>[];
      final raw = item['correctOptionIndexes'];
      if (raw is! List || raw.isEmpty) return [];
      final idxs = raw.map((e) => int.tryParse('$e') ?? -1).where((i) => i >= 0).toList()..sort();
      final texts = idxs.map((i) => (i < options.length) ? options[i] : '#$i').toList();
      return [
        Text(texts.join(kind == 'mcq_multi' ? '; ' : ' — '), style: style),
      ];
    }

    if (kind == 'grammar_cloze' || kind == 'grammar_gap') {
      final defs = item['blanks'] as List? ?? [];
      final out = <Widget>[];
      for (var i = 0; i < defs.length; i++) {
        if (defs[i] is! Map) continue;
        final d = defs[i] as Map;
        final id = '${d['blankId'] ?? i}';
        final accepted = (d['acceptedAnswers'] as List?)?.map((e) => '$e').where((s) => s.isNotEmpty).toList() ?? [];
        if (accepted.isEmpty) continue;
        out.add(
          Padding(
            padding: EdgeInsets.only(bottom: i < defs.length - 1 ? 6 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$id: ', style: ExamSystemUi.captionMuted),
                Expanded(child: Text(accepted.join(' / '), style: style)),
              ],
            ),
          ),
        );
      }
      return out;
    }

    if (kind == 'grammar_matching') {
      final left = (item['leftItems'] ?? item['leftColumn']) as List? ?? [];
      final right = (item['rightItems'] ?? item['rightColumn']) as List? ?? [];
      final corr = item['correctPairs'];
      if (corr is! List || corr.isEmpty) return [];
      String? rightText(String id) {
        for (final r in right) {
          if (r is Map && '${r['id']}' == id) return '${r['text'] ?? ''}'.trim();
        }
        return id;
      }

      String? leftText(String id) {
        for (final r in left) {
          if (r is Map && '${r['id']}' == id) return '${r['text'] ?? ''}'.trim();
        }
        return id;
      }

      final out = <Widget>[];
      for (final p in corr) {
        if (p is! List || p.length < 2) continue;
        final lt = leftText('${p[0]}');
        final rt = rightText('${p[1]}');
        out.add(Text('• $lt → $rt', style: style));
      }
      return out;
    }

    if (kind == 'grammar_reorder') {
      final fr = (item['fragments'] as List?)?.map((e) => '$e').toList() ?? <String>[];
      final cor = (item['correctOrder'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toList() ?? <int>[];
      if (fr.isEmpty || cor.length != fr.length) return [];
      final ordered = cor.map((i) => (i >= 0 && i < fr.length) ? fr[i] : '').where((s) => s.isNotEmpty).toList();
      return [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < ordered.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${i + 1}. ${ordered[i]}', style: style),
              ),
          ],
        ),
      ];
    }

    return [];
  }
}

/// Student / teacher review for non-MCQ grammar — shows user vs correct with pass/fail colors.
class GrammarObjectiveGradingReview extends StatelessWidget {
  const GrammarObjectiveGradingReview({
    super.key,
    required this.item,
    this.answer,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;

  static GrammarObjectiveGradingReview fromMaps({
    required Map<String, dynamic> item,
    Map<String, dynamic>? answer,
  }) {
    return GrammarObjectiveGradingReview(item: item, answer: answer);
  }

  @override
  Widget build(BuildContext context) {
    final kind = '${item['kind'] ?? ''}';
    switch (kind) {
      case 'grammar_cloze':
        return _buildCloze(context);
      case 'grammar_gap':
        return _buildGap(context);
      case 'grammar_matching':
        return _buildMatching(context);
      case 'grammar_reorder':
        return _buildReorder(context);
      default:
        return GrammarCorrectAnswerReviewPanel(item: item);
    }
  }

  Widget _buildCloze(BuildContext context) {
    final l10n = context.l10n;
    final passage = '${item['passage'] ?? ''}';
    final defs = (item['blanks'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    final userBlanks = (answer?['blanks'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {};

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (passage.isNotEmpty) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: _clozePassageReviewPieces(context, passage, defs, userBlanks, l10n.integratedExamReviewNotAnswered),
            ),
            const SizedBox(height: 10),
          ],
          for (var i = 0; i < defs.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _blankReviewRow(
              context,
              blankId: '${defs[i]['blankId'] ?? i}',
              userText: userBlanks['${defs[i]['blankId'] ?? i}'] ?? '',
              correctText: _acceptedLabel(defs[i]),
              ok: _grammarBlankOk(defs[i], userBlanks['${defs[i]['blankId'] ?? i}']),
              notAnsweredLabel: l10n.integratedExamReviewNotAnswered,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _clozePassageReviewPieces(
    BuildContext context,
    String passage,
    List<Map<String, dynamic>> defs,
    Map<String, String> userBlanks,
    String notAnsweredLabel,
  ) {
    final reg = RegExp(r'\{\{([0-9]+)\}\}');
    final pieces = <Widget>[];
    var start = 0;
    for (final m in reg.allMatches(passage)) {
      if (m.start > start) {
        pieces.add(Text(passage.substring(start, m.start), style: ExamSystemUi.captionSecondary.copyWith(height: 1.45)));
      }
      final id = m.group(1) ?? '0';
      final accent = GrammarAccentPalette.of(GrammarAccentPalette.blankIndex(id));
      final userText = (userBlanks[id] ?? '').trim();
      pieces.add(
        _grammarAccentAnswerChip(
          label: id,
          text: userText.isNotEmpty ? userText : notAnsweredLabel,
          accent: accent,
        ),
      );
      start = m.end;
    }
    if (start < passage.length) {
      pieces.add(Text(passage.substring(start), style: ExamSystemUi.captionSecondary.copyWith(height: 1.45)));
    }
    if (pieces.isEmpty && passage.isNotEmpty) {
      pieces.add(Text(passage, style: ExamSystemUi.captionSecondary.copyWith(height: 1.45)));
    }
    return pieces;
  }

  Widget _buildGap(BuildContext context) {
    final l10n = context.l10n;
    final before = '${item['textBefore'] ?? ''}';
    final after = '${item['textAfter'] ?? ''}';
    final defs = (item['blanks'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    final blankDef = defs.isNotEmpty ? defs.first : <String, dynamic>{'blankId': '0', 'acceptedAnswers': []};
    final blankId = '${blankDef['blankId'] ?? '0'}';
    final userBlanks = (answer?['blanks'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {};
    final userText = userBlanks[blankId] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 6,
            children: [
              if (before.isNotEmpty) Text(before, style: ExamSystemUi.captionSecondary),
              _grammarAccentAnswerChip(
                label: blankId,
                accent: GrammarAccentPalette.of(GrammarAccentPalette.blankIndex(blankId)),
                text: userText.isNotEmpty ? userText : l10n.integratedExamReviewNotAnswered,
              ),
              if (after.isNotEmpty) Text(after, style: ExamSystemUi.captionSecondary),
            ],
          ),
          const SizedBox(height: 10),
          _labeledAnswerBlock(
            context,
            label: l10n.integratedExamReviewCorrectAnswer,
            text: _acceptedLabel(blankDef),
            ok: true,
            showAsCorrect: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMatching(BuildContext context) {
    final l10n = context.l10n;
    final left = ((item['leftItems'] ?? item['leftColumn']) as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    final right = ((item['rightItems'] ?? item['rightColumn']) as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    final chosen = (answer?['matching'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {};
    final corr = item['correctPairs'] as List? ?? [];

    String rightLabel(String id) {
      for (final r in right) {
        if ('${r['id']}' == id) return '${r['text'] ?? ''}'.trim();
      }
      return id;
    }

    String correctRightFor(String leftId) {
      for (final p in corr) {
        if (p is List && p.length >= 2 && '${p[0]}' == leftId) {
          return rightLabel('${p[1]}');
        }
      }
      return '—';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < left.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Builder(builder: (context) {
              final leftId = '${left[i]['id']}';
              final leftText = '${left[i]['text'] ?? ''}'.trim();
              final userRightId = chosen[leftId];
              final userRight = userRightId != null ? rightLabel(userRightId) : '';
              final expectedRight = correctRightFor(leftId);
              final answered = userRight.isNotEmpty;
              final ok = answered && userRightId == _correctRightId(leftId, corr);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(leftText, style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _labeledAnswerBlock(
                    context,
                    label: l10n.integratedExamReviewYourAnswer,
                    text: answered ? userRight : l10n.integratedExamReviewNotAnswered,
                    ok: ok,
                  ),
                  const SizedBox(height: 6),
                  _labeledAnswerBlock(
                    context,
                    label: l10n.integratedExamReviewCorrectAnswer,
                    text: expectedRight,
                    ok: true,
                    showAsCorrect: true,
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildReorder(BuildContext context) {
    final l10n = context.l10n;
    final fr = (item['fragments'] as List?)?.map((e) => '$e').toList() ?? <String>[];
    final cor = (item['correctOrder'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toList() ?? <int>[];
    final userOrder = (answer?['order'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toList() ?? <int>[];

    String fragmentAt(int idx) => (idx >= 0 && idx < fr.length) ? fr[idx] : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.integratedExamReviewYourAnswer, style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (userOrder.isEmpty)
            _labeledAnswerBlock(
              context,
              label: '',
              text: l10n.integratedExamReviewNotAnswered,
              ok: false,
            )
          else
            ...List.generate(userOrder.length, (i) {
              final idx = userOrder[i];
              final text = fragmentAt(idx);
              final ok = i < cor.length && idx == cor[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i == userOrder.length - 1 ? 0 : 6),
                child: _orderLine(context, number: i + 1, text: text, ok: ok),
              );
            }),
          const SizedBox(height: 10),
          Text(l10n.integratedExamReviewCorrectAnswer, style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...List.generate(cor.length, (i) {
            final text = fragmentAt(cor[i]);
            return Padding(
              padding: EdgeInsets.only(bottom: i == cor.length - 1 ? 0 : 6),
              child: _orderLine(context, number: i + 1, text: text, ok: true, showAsCorrect: true),
            );
          }),
        ],
      ),
    );
  }

  String? _correctRightId(String leftId, List corr) {
    for (final p in corr) {
      if (p is List && p.length >= 2 && '${p[0]}' == leftId) return '${p[1]}';
    }
    return null;
  }

  String _acceptedLabel(Map<String, dynamic> blankDef) {
    final accepted = (blankDef['acceptedAnswers'] as List?)?.map((e) => '$e').where((s) => s.isNotEmpty).toList() ?? [];
    if (accepted.isEmpty) return '—';
    return accepted.join(' / ');
  }

  Widget _blankReviewRow(
    BuildContext context, {
    required String blankId,
    required String userText,
    required String correctText,
    required bool ok,
    required String notAnsweredLabel,
  }) {
    final answered = userText.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Blank $blankId', style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600, fontSize: AppTypography.mobileCaption)),
        const SizedBox(height: 4),
        _labeledAnswerBlock(
          context,
          label: context.l10n.integratedExamReviewYourAnswer,
          text: answered ? userText : notAnsweredLabel,
          ok: ok,
        ),
        const SizedBox(height: 6),
        _labeledAnswerBlock(
          context,
          label: context.l10n.integratedExamReviewCorrectAnswer,
          text: correctText,
          ok: true,
          showAsCorrect: true,
        ),
      ],
    );
  }

  Widget _labeledAnswerBlock(
    BuildContext context, {
    required String label,
    required String text,
    required bool ok,
    bool showAsCorrect = false,
  }) {
    final border = showAsCorrect || ok ? AppColors.success : AppColors.danger;
    final bg = showAsCorrect || ok ? AppColors.successBg : AppColors.dangerBg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: border.withValues(alpha: showAsCorrect ? 0.45 : 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(label, style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600, fontSize: AppTypography.mobileCaption)),
          if (label.isNotEmpty) const SizedBox(height: 4),
          Text(
            text,
            style: ExamSystemUi.captionSecondary.copyWith(
              height: 1.4,
              color: text == context.l10n.integratedExamReviewNotAnswered ? AppColors.textMuted : AppColors.textPrimary,
              fontStyle: text == context.l10n.integratedExamReviewNotAnswered ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderLine(BuildContext context, {required int number, required String text, required bool ok, bool showAsCorrect = false}) {
    final color = showAsCorrect || ok ? AppColors.success : AppColors.danger;
    final bg = showAsCorrect || ok ? AppColors.successBg : AppColors.dangerBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: color.withValues(alpha: showAsCorrect ? 0.45 : 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number.', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: AppTypography.mobileH3)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: ExamSystemUi.captionSecondary.copyWith(height: 1.4))),
          if (!showAsCorrect)
            Icon(ok ? Icons.check_rounded : Icons.close_rounded, size: 16, color: color),
        ],
      ),
    );
  }
}

String _grammarNorm(String s, {bool caseInsensitive = true}) {
  var v = s.trim();
  if (caseInsensitive) v = v.toLowerCase();
  return v;
}

bool _grammarBlankOk(Map<String, dynamic> blankDef, String? raw) {
  if (raw == null || raw.trim().isEmpty) return false;
  final ci = blankDef['caseInsensitive'] != false;
  final norm = _grammarNorm(raw, caseInsensitive: ci);
  final accepted = (blankDef['acceptedAnswers'] as List?)?.map((e) => '$e').toList() ?? [];
  return accepted.any((a) => _grammarNorm(a, caseInsensitive: ci) == norm);
}

/// Whether the stored answer object satisfies backend [grammarAnswerComplete].
bool grammarAnswerLooksComplete(Map<String, dynamic> item, Map<String, dynamic>? answer) {
  if (answer == null) return false;
  final k = '${item['kind'] ?? ''}';
  if (k == 'mcq_single' || k == 'mcq_multi') {
    final sel = answer['selectedIndexes'];
    if (sel is! List || sel.isEmpty) return false;
    if (k == 'mcq_single' && sel.length != 1) return false;
    return true;
  }
  if (k == 'grammar_cloze' || k == 'grammar_gap') {
    final bl = answer['blanks'];
    if (bl is! Map) return false;
    final defs = item['blanks'];
    if (defs is! List || defs.isEmpty) return false;
    for (final d in defs) {
      if (d is! Map) return false;
      final id = '${d['blankId']}';
      final v = bl[id];
      if (v == null || '$v'.trim().isEmpty) return false;
    }
    return true;
  }
  if (k == 'grammar_matching') {
    final m = answer['matching'];
    if (m is! Map) return false;
    final left = (item['leftItems'] ?? item['leftColumn']) as List?;
    if (left == null) return false;
    for (final row in left) {
      if (row is! Map) return false;
      final id = '${row['id']}';
      final v = m[id];
      if (v == null || '$v'.trim().isEmpty) return false;
    }
    return true;
  }
  if (k == 'grammar_reorder') {
    final ord = answer['order'];
    final fr = item['fragments'];
    if (ord is! List || fr is! List) return false;
    return ord.length == fr.length;
  }
  return false;
}

List<int> _initialReorderDisplay(List<dynamic> correctOrderRaw) {
  final cor = correctOrderRaw.map((e) => int.tryParse('$e') ?? 0).toList();
  final n = cor.length;
  if (n < 2) return List<int>.generate(n, (i) => i);
  var perm = List<int>.generate(n, (i) => i);
  var same = perm.length == cor.length;
  if (same) {
    for (var i = 0; i < n; i++) {
      if (perm[i] != cor[i]) {
        same = false;
        break;
      }
    }
  }
  if (same) {
    perm = perm.reversed.toList();
  }
  return perm;
}

/// One Grammar question — MCQ, cloze, gap, matching, or reorder.
class IntegratedExamGrammarQuestionCard extends StatelessWidget {
  const IntegratedExamGrammarQuestionCard({
    super.key,
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
    this.displayIndex = 1,
    this.wrapInCard = true,
    this.reviewFooter,
    this.gradingReviewMode = false,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;
  final int displayIndex;
  /// When false, only the inner column is returned (for embedding in a parent card).
  final bool wrapInCard;
  /// Optional block below the interactive body (e.g. correct-answer callout for teachers).
  final Widget? reviewFooter;
  /// Teacher grading: colored MCQ options (green correct / red wrong).
  final bool gradingReviewMode;

  @override
  Widget build(BuildContext context) {
    final kind = '${item['kind'] ?? ''}';
    final prompt = '${item['prompt'] ?? ''}'.trim();
    final idx = displayIndex;

    Widget inner;
    switch (kind) {
      case 'mcq_single':
      case 'mcq_multi':
        inner = gradingReviewMode
            ? McqGradingReviewList.fromMaps(item: item, answer: answer)
            : _McqBody(
                item: item,
                answer: answer,
                locked: locked,
                onPartialPatch: onPartialPatch,
              );
        break;
      case 'grammar_cloze':
        inner = gradingReviewMode
            ? GrammarObjectiveGradingReview.fromMaps(item: item, answer: answer)
            : _ClozeBody(
                item: item,
                answer: answer,
                locked: locked,
                onPartialPatch: onPartialPatch,
              );
        break;
      case 'grammar_gap':
        inner = gradingReviewMode
            ? GrammarObjectiveGradingReview.fromMaps(item: item, answer: answer)
            : _GapBody(
                item: item,
                answer: answer,
                locked: locked,
                onPartialPatch: onPartialPatch,
              );
        break;
      case 'grammar_matching':
        inner = gradingReviewMode
            ? GrammarObjectiveGradingReview.fromMaps(item: item, answer: answer)
            : _MatchingBody(
                item: item,
                answer: answer,
                locked: locked,
                onPartialPatch: onPartialPatch,
              );
        break;
      case 'grammar_reorder':
        inner = gradingReviewMode
            ? GrammarObjectiveGradingReview.fromMaps(item: item, answer: answer)
            : _ReorderBody(
                item: item,
                answer: answer,
                locked: locked,
                onPartialPatch: onPartialPatch,
              );
        break;
      default:
        inner = Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            context.l10n.integratedExamGrammarUnsupported,
            style: ExamSystemUi.captionSecondary,
          ),
        );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Text(
                    '$idx.',
                    style: const TextStyle(fontSize: AppTypography.mobileH3, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (prompt.isNotEmpty) Text(prompt, style: ExamSystemUi.questionStem(context)),
                        if (prompt.isNotEmpty) const SizedBox(height: 4),
                        Text(
                          grammarItemKindLabel(context, kind),
                          style: const TextStyle(fontSize: AppTypography.mobileCaption, color: AppColors.textSecondary),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        inner,
        if (reviewFooter != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: reviewFooter!,
          ),
        ],
      ],
    );

    if (!wrapInCard) {
      return column;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
      child: AppCard(
        variant: AppCardVariant.outline,
        child: column,
      ),
    );
  }
}

/// Optimistic MCQ: local selection updates instantly on tap, then syncs to server.
class _McqBody extends StatefulWidget {
  const _McqBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  State<_McqBody> createState() => _McqBodyState();
}

class _McqBodyState extends State<_McqBody> {
  late Set<int> _localSel;

  static Set<int> _parseSelection(Map<String, dynamic>? answer) =>
      (answer?['selectedIndexes'] as List?)
          ?.map((e) => int.tryParse('$e') ?? 0)
          .toSet() ??
      <int>{};

  static bool _setsEqual(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  void initState() {
    super.initState();
    _localSel = _parseSelection(widget.answer);
  }

  @override
  void didUpdateWidget(covariant _McqBody old) {
    super.didUpdateWidget(old);
    final serverSel = _parseSelection(widget.answer);
    // Sync from server only when it genuinely differs (avoids overwriting optimistic tap)
    if (!_setsEqual(_localSel, serverSel)) {
      setState(() => _localSel = serverSel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = (widget.item['options'] as List?)?.map((e) => '$e').toList() ?? <String>[];
    final kind = '${widget.item['kind'] ?? ''}';

    if (kind == 'mcq_single') {
      final group = _localSel.isEmpty ? null : _localSel.first;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            for (var i = 0; i < options.length; i++)
              _GrammarMcqOption(
                index: i,
                text: options[i],
                selected: group == i,
                onTap: widget.locked
                    ? null
                    : () {
                        setState(() => _localSel = {i});
                        widget.onPartialPatch({'selectedIndexes': [i]});
                      },
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++)
            _GrammarMcqOption(
              index: i,
              text: options[i],
              selected: _localSel.contains(i),
              multiSelect: true,
              onTap: widget.locked
                  ? null
                  : () {
                      final next = {..._localSel};
                      if (next.contains(i)) {
                        next.remove(i);
                      } else {
                        next.add(i);
                      }
                      final list = List<int>.from(next)..sort();
                      setState(() => _localSel = next);
                      widget.onPartialPatch({'selectedIndexes': list});
                    },
            ),
        ],
      ),
    );
  }
}

class _ClozeBody extends StatefulWidget {
  const _ClozeBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  State<_ClozeBody> createState() => _ClozeBodyState();
}

class _ClozeBodyState extends State<_ClozeBody> {
  final Map<String, TextEditingController> _controllers = {};
  bool _hydratedFromAnswer = false;

  @override
  void initState() {
    super.initState();
    _ensureControllersForPassage();
    _hydrateFromAnswerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _ClozeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['passage'] != widget.item['passage']) {
      _ensureControllersForPassage();
      _hydratedFromAnswer = false;
      _hydrateFromAnswerIfNeeded();
      return;
    }
    if (!_hydratedFromAnswer && widget.answer != null) {
      _hydrateFromAnswerIfNeeded();
    }
    if (!oldWidget.locked && widget.locked) {
      _hydrateFromAnswerIfNeeded(force: true);
    }
  }

  void _ensureControllersForPassage() {
    final passage = '${widget.item['passage'] ?? ''}';
    final reg = RegExp(r'\{\{([0-9]+)\}\}');
    final ids = reg.allMatches(passage).map((m) => m.group(1) ?? '0').toSet();
    for (final k in _controllers.keys.toList()) {
      if (!ids.contains(k)) {
        _controllers.remove(k)?.dispose();
      }
    }
    for (final id in ids) {
      _controllers.putIfAbsent(id, () => TextEditingController());
    }
  }

  void _hydrateFromAnswerIfNeeded({bool force = false}) {
    if (!force && _hydratedFromAnswer) return;
    final blanks = (widget.answer?['blanks'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {};
    if (!force && blanks.isEmpty) return;
    for (final e in _controllers.entries) {
      final t = blanks[e.key] ?? '';
      if (e.value.text != t) {
        e.value.text = t;
      }
    }
    _hydratedFromAnswer = true;
  }

  Map<String, String> _allBlanks() {
    return {for (final e in _controllers.entries) e.key: e.value.text};
  }

  void _emitBlanks() {
    widget.onPartialPatch({'blanks': _allBlanks()});
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passage = '${widget.item['passage'] ?? ''}';
    final reg = RegExp(r'\{\{([0-9]+)\}\}');
    final pieces = <Widget>[];
    var start = 0;
    for (final m in reg.allMatches(passage)) {
      if (m.start > start) {
        pieces.add(Text(passage.substring(start, m.start), style: ExamSystemUi.captionSecondary));
      }
      final id = m.group(1) ?? '0';
      final ctl = _controllers[id]!;
      final accent = GrammarAccentPalette.of(GrammarAccentPalette.blankIndex(id));
      pieces.add(
        _GrammarBlankField(
          fieldKey: ValueKey('cloze_${widget.item['itemId']}_$id'),
          blankId: id,
          accent: accent,
          enabled: !widget.locked,
          controller: ctl,
          onChanged: widget.locked
              ? null
              : (_) {
                  setState(() {});
                  _emitBlanks();
                },
        ),
      );
      start = m.end;
    }
    if (start < passage.length) {
      pieces.add(Text(passage.substring(start), style: ExamSystemUi.captionSecondary));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: pieces,
      ),
    );
  }
}

class _GapBody extends StatefulWidget {
  const _GapBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  State<_GapBody> createState() => _GapBodyState();
}

class _GapBodyState extends State<_GapBody> {
  late final TextEditingController _ctl = TextEditingController();

  String get _blankId {
    final defs = widget.item['blanks'] as List?;
    if (defs != null && defs.isNotEmpty && defs.first is Map) {
      return '${(defs.first as Map)['blankId']}';
    }
    return '0';
  }

  @override
  void initState() {
    super.initState();
    _applyAnswer(force: true);
  }

  bool _hydrated = false;

  @override
  void didUpdateWidget(covariant _GapBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hydrated && widget.answer != null) _applyAnswer();
    if (!oldWidget.locked && widget.locked) _applyAnswer(force: true);
  }

  void _applyAnswer({bool force = false}) {
    if (!force && _hydrated) return;
    final blanks = (widget.answer?['blanks'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {};
    final t = blanks[_blankId] ?? '';
    if (_ctl.text != t) _ctl.text = t;
    if (t.isNotEmpty || force) _hydrated = true;
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final before = '${widget.item['textBefore'] ?? ''}';
    final after = '${widget.item['textAfter'] ?? ''}';
    final accent = GrammarAccentPalette.of(0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(before, style: ExamSystemUi.captionSecondary),
          _GrammarBlankField(
            blankId: _blankId,
            accent: accent,
            enabled: !widget.locked,
            controller: _ctl,
            onChanged: widget.locked
                ? null
                : (v) {
                    setState(() {});
                    widget.onPartialPatch({'blanks': {_blankId: v}});
                  },
          ),
          Text(after, style: ExamSystemUi.captionSecondary),
        ],
      ),
    );
  }
}

class _MatchingBody extends StatefulWidget {
  const _MatchingBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  State<_MatchingBody> createState() => _MatchingBodyState();
}

class _MatchingBodyState extends State<_MatchingBody> {
  final GlobalKey _canvasKey = GlobalKey();
  final Map<String, GlobalKey> _leftKeys = {};
  final Map<String, GlobalKey> _rightKeys = {};
  late Map<String, String> _matching;
  String? _selectedLeftId;
  List<_MatchLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _matching = _readMatching();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLines());
  }

  @override
  void didUpdateWidget(covariant _MatchingBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer && widget.locked) {
      setState(() => _matching = _readMatching());
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLines());
    }
  }

  Map<String, String> _readMatching() {
    return (widget.answer?['matching'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {};
  }

  List<Map<String, dynamic>> get _leftRows =>
      ((widget.item['leftItems'] ?? widget.item['leftColumn']) as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      [];

  List<Map<String, dynamic>> get _rightRows =>
      ((widget.item['rightItems'] ?? widget.item['rightColumn']) as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      [];

  void _emitMatching() {
    widget.onPartialPatch({'matching': Map<String, String>.from(_matching)});
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLines());
  }

  void _setPair(String leftId, String rightId) {
    if (widget.locked) return;
    setState(() {
      _matching.removeWhere((_, r) => r == rightId);
      _matching[leftId] = rightId;
      _selectedLeftId = null;
    });
    _emitMatching();
  }

  void _clearLeft(String leftId) {
    if (widget.locked) return;
    setState(() {
      _matching.remove(leftId);
      if (_selectedLeftId == leftId) _selectedLeftId = null;
    });
    _emitMatching();
  }

  Color _pairColorForLeft(String leftId) {
    final idx = _leftRows.indexWhere((r) => '${r['id']}' == leftId);
    if (idx < 0) return AppColors.textSecondary;
    return GrammarAccentPalette.of(idx);
  }

  void _refreshLines() {
    if (!mounted) return;
    final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox == null) return;
    final origin = canvasBox.localToGlobal(Offset.zero);
    final next = <_MatchLine>[];
    for (final entry in _matching.entries) {
      final lBox = _leftKeys[entry.key]?.currentContext?.findRenderObject() as RenderBox?;
      final rBox = _rightKeys[entry.value]?.currentContext?.findRenderObject() as RenderBox?;
      if (lBox == null || rBox == null) continue;
      final lCenter = lBox.localToGlobal(Offset(lBox.size.width, lBox.size.height / 2));
      final rCenter = rBox.localToGlobal(Offset(0, rBox.size.height / 2));
      next.add(
        _MatchLine(
          start: lCenter - origin,
          end: rCenter - origin,
          color: _pairColorForLeft(entry.key),
        ),
      );
    }
    setState(() => _lines = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    for (final row in _leftRows) {
      final id = '${row['id']}';
      _leftKeys.putIfAbsent(id, () => GlobalKey());
    }
    for (final row in _rightRows) {
      final id = '${row['id']}';
      _rightKeys.putIfAbsent(id, () => GlobalKey());
    }

    final rowCount = math.max(_leftRows.length, _rightRows.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLines());

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.locked)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.integratedExamMatchHint,
                style: ExamSystemUi.captionMuted.copyWith(fontSize: AppTypography.mobileCaption),
              ),
            ),
          Stack(
            key: _canvasKey,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MatchingLinesPainter(lines: _lines),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rowCount; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: i < _leftRows.length
                                ? _buildLeftCard(_leftRows[i])
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            child: i < _rightRows.length
                                ? _buildRightCard(_rightRows[i])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftCard(Map<String, dynamic> row) {
    final id = '${row['id']}';
    final text = '${row['text'] ?? ''}'.trim();
    final matchedRight = _matching[id];
    final selected = _selectedLeftId == id;
    final paired = matchedRight != null;
    final pairColor = paired ? _pairColorForLeft(id) : null;

    Widget card = Material(
      key: _leftKeys[id],
      color: selected
          ? AppColors.primaryTint
          : (paired ? pairColor!.withValues(alpha: 0.08) : AppColors.surface),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: widget.locked ? null : () => setState(() => _selectedLeftId = selected ? null : id),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (paired ? pairColor! : AppColors.outlineMuted),
              width: selected || paired ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                paired ? Icons.link_outlined : Icons.drag_indicator,
                size: 16,
                color: paired ? pairColor : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: ExamSystemUi.captionSecondary.copyWith(height: 1.35),
                ),
              ),
              if (!widget.locked && paired)
                IconButton(
                  onPressed: () => _clearLeft(id),
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.locked) return card;

    return LongPressDraggable<String>(
      data: id,
      feedback: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(AppRadius.input),
        color: AppColors.surfaceCard,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(text, style: ExamSystemUi.captionSecondary),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }

  Widget _buildRightCard(Map<String, dynamic> row) {
    final id = '${row['id']}';
    final text = '${row['text'] ?? ''}'.trim();
    String? linkedLeftId;
    for (final e in _matching.entries) {
      if (e.value == id) {
        linkedLeftId = e.key;
        break;
      }
    }
    final isLinked = linkedLeftId != null;
    final pairColor = isLinked ? _pairColorForLeft(linkedLeftId) : null;
    final highlight = _selectedLeftId != null;

    Widget card = Material(
      key: _rightKeys[id],
      color: isLinked ? pairColor!.withValues(alpha: 0.08) : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isLinked
                ? pairColor!
                : (highlight ? AppColors.primary.withValues(alpha: 0.35) : AppColors.outlineMuted),
            width: isLinked ? 1.5 : 1,
          ),
        ),
        child: Text(
          text,
          style: ExamSystemUi.captionSecondary.copyWith(height: 1.35),
        ),
      ),
    );

    if (widget.locked) return card;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.locked,
      onAcceptWithDetails: (d) => _setPair(d.data, id),
      builder: (context, candidate, _) {
        final active = candidate.isNotEmpty;
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: _selectedLeftId == null ? null : () => _setPair(_selectedLeftId!, id),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: active
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.5)
                  : null,
            ),
            child: card,
          ),
        );
      },
    );
  }
}

class _MatchLine {
  const _MatchLine({required this.start, required this.end, required this.color});
  final Offset start;
  final Offset end;
  final Color color;
}

/// Curved connector between matched left/right cards — one color per left item.
class _MatchingLinesPainter extends CustomPainter {
  const _MatchingLinesPainter({required this.lines});
  final List<_MatchLine> lines;

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color.withValues(alpha: 0.88)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final dy = (line.end.dy - line.start.dy).abs();
      final flat = dy < 6;
      if (flat) {
        canvas.drawLine(line.start, line.end, paint);
        _drawArrowHead(canvas, line.end, line.start, paint);
        continue;
      }
      final dx = (line.end.dx - line.start.dx) * 0.38;
      final c1 = Offset(line.start.dx + dx, line.start.dy);
      final c2 = Offset(line.end.dx - dx, line.end.dy);
      final path = Path()
        ..moveTo(line.start.dx, line.start.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, line.end.dx, line.end.dy);
      canvas.drawPath(path, paint);
      _drawArrowHead(canvas, line.end, line.start, paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, Offset from, Paint paint) {
    final dir = tip - from;
    if (dir.distance < 1) return;
    final n = dir / dir.distance;
    const len = 5.0;
    const spread = 0.32;
    final ortho = Offset(-n.dy, n.dx) * spread;
    final base = tip - n * len;
    canvas.drawLine(tip, base + ortho, paint);
    canvas.drawLine(tip, base - ortho, paint);
  }

  @override
  bool shouldRepaint(covariant _MatchingLinesPainter old) => old.lines != lines;
}

class _ReorderBody extends StatefulWidget {
  const _ReorderBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  State<_ReorderBody> createState() => _ReorderBodyState();
}

class _ReorderBodyState extends State<_ReorderBody> {
  late List<int> _order;
  late List<String> _fragments;

  @override
  void initState() {
    super.initState();
    final fr = (widget.item['fragments'] as List?)?.map((e) => '$e').toList() ?? <String>[];
    _fragments = fr;
    final cor = (widget.item['correctOrder'] as List?) ?? [];
    final saved = widget.answer?['order'] as List?;
    if (saved != null && saved.length == fr.length) {
      _order = saved.map((e) => int.tryParse('$e') ?? 0).toList();
    } else {
      _order = _initialReorderDisplay(cor);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPartialPatch({'order': List<int>.from(_order)});
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ReorderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['fragments'] != widget.item['fragments']) {
      final fr = (widget.item['fragments'] as List?)?.map((e) => '$e').toList() ?? <String>[];
      _fragments = fr;
      final cor = (widget.item['correctOrder'] as List?) ?? [];
      final saved = widget.answer?['order'] as List?;
      if (saved != null && saved.length == fr.length) {
        _order = saved.map((e) => int.tryParse('$e') ?? 0).toList();
      } else {
        _order = _initialReorderDisplay(cor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _order.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _GrammarReorderTile(
                  displayIndex: i,
                  text: _fragments.isNotEmpty && _order[i] < _fragments.length ? _fragments[_order[i]] : '',
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _order.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final x = _order.removeAt(oldIndex);
                _order.insert(newIndex, x);
              });
              widget.onPartialPatch({'order': List<int>.from(_order)});
            },
            itemBuilder: (context, i) {
              final fi = _order[i];
              final text = fi < _fragments.length ? _fragments[fi] : '';
              return Padding(
                key: ValueKey('${widget.item['itemId']}_${_order[i]}_$i'),
                padding: const EdgeInsets.only(bottom: 6),
                child: _GrammarReorderTile(
                  displayIndex: i,
                  text: text,
                  draggable: true,
                  dragIndex: i,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GrammarReorderTile extends StatelessWidget {
  const _GrammarReorderTile({
    super.key,
    required this.displayIndex,
    required this.text,
    this.draggable = false,
    this.dragIndex,
  });

  final int displayIndex;
  final String text;
  final bool draggable;
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final accent = GrammarAccentPalette.of(displayIndex);
    final leading = draggable && dragIndex != null
        ? ReorderableDragStartListener(
            index: dragIndex!,
            child: Icon(Icons.drag_handle, size: 18, color: accent),
          )
        : Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '${displayIndex + 1}',
              style: TextStyle(fontSize: AppTypography.mobileCaption, fontWeight: FontWeight.w700, color: accent, height: 1),
            ),
          );

    return Material(
      color: GrammarAccentPalette.fillBg(accent),
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: ExamSystemUi.captionSecondary.copyWith(height: 1.35)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}