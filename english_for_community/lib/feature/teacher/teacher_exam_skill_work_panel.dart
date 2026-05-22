import 'package:english_for_community/core/entity/reading/reading_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/reading_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/exams/exam_answer_review_widgets.dart';
import 'package:english_for_community/feature/student/exams/integrated_exam_score_widgets.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';

/// Shows CMS skill submissions linked to an exam attempt (from API `skillWork`).
class TeacherExamSkillWorkPanel extends StatefulWidget {
  const TeacherExamSkillWorkPanel({
    super.key,
    required this.skill,
    required this.resources,
    this.markedComplete = false,
    this.integratedScoreScale = false,
  });

  final String skill;
  final List<Map<String, dynamic>> resources;
  final bool markedComplete;
  /// When true, show embedded skill stats on 0–10 scale (integrated exams), not legacy pts.
  final bool integratedScoreScale;

  @override
  State<TeacherExamSkillWorkPanel> createState() => _TeacherExamSkillWorkPanelState();
}

class _TeacherExamSkillWorkPanelState extends State<TeacherExamSkillWorkPanel> {
  final Map<String, ReadingEntity?> _readingCache = {};
  final Map<String, bool> _readingLoading = {};

  @override
  void initState() {
    super.initState();
    if (widget.skill == 'reading') {
      for (final r in widget.resources) {
        final id = '${r['resourceId'] ?? ''}';
        if (id.isNotEmpty) _loadReading(id);
      }
    }
  }

  Future<void> _loadReading(String id) async {
    if (_readingLoading[id] == true || _readingCache.containsKey(id)) return;
    setState(() => _readingLoading[id] = true);
    final res = await getIt<ReadingRepository>().getReadingDetail(id);
    if (!mounted) return;
    res.fold(
      (_) => setState(() {
        _readingCache[id] = null;
        _readingLoading[id] = false;
      }),
      (entity) => setState(() {
        _readingCache[id] = entity;
        _readingLoading[id] = false;
      }),
    );
  }

  bool _hasRecords(Map<String, dynamic> res) {
    final records = res['records'];
    if (records == null) return false;
    if (records is List) return records.isNotEmpty;
    if (records is Map) return records.isNotEmpty;
    return false;
  }

  bool get _anyWork => widget.resources.any(_hasRecords);

  String? _sourceHint(BuildContext context) {
    final l10n = context.l10n;
    for (final r in widget.resources) {
      final src = r['source'] as String?;
      if (src == 'exam_inline') return l10n.teacherAttemptGradeSkillWorkExamInline;
      if (src == 'near_session') return l10n.teacherAttemptGradeSkillWorkNearSession;
      if (src == 'latest_linked') return l10n.teacherAttemptGradeSkillWorkLatestLinked;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.resources.isEmpty) {
      return _emptyStateCard(
        context,
        widget.markedComplete ? l10n.teacherAttemptGradeOnlyMarkedComplete : l10n.teacherAttemptGradeNoSkillWork,
      );
    }

    if (!_anyWork) {
      return _emptyStateCard(
        context,
        widget.markedComplete ? l10n.teacherAttemptGradeOnlyMarkedComplete : l10n.teacherAttemptGradeNoSkillWork,
      );
    }

    final hint = _sourceHint(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(child: Text(hint, style: TeacherWebUi.webBody(context).copyWith(fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        for (var ri = 0; ri < widget.resources.length; ri++) ...[
          if (ri > 0) const SizedBox(height: AppSpacing.s4),
          _buildResourceBlock(context, widget.resources[ri]),
        ],
      ],
    );
  }

  Widget _emptyStateCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.article_outlined, size: 22, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TeacherWebUi.webBody(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceBlock(BuildContext context, Map<String, dynamic> res) {
    final title = (res['title'] as String?)?.trim() ?? '';
    final rid = '${res['resourceId'] ?? ''}';
    final records = res['records'];

    if (!_hasRecords(res)) {
      return const SizedBox.shrink();
    }

    return AppCard(
      variant: AppCardVariant.outline,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: Text(title, style: TeacherWebUi.listTitle(context)),
              ),
            switch (widget.skill) {
              'reading' => _buildReadingWork(context, rid, records),
              'listening' => _buildListeningWork(context, records),
              'speaking' => _buildSpeakingWork(context, records),
              'writing' => _buildWritingWork(context, records),
              _ => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildReadingWork(BuildContext context, String readingId, dynamic records) {
    final l10n = context.l10n;
    final attempt = Map<String, dynamic>.from(records as Map);
    final answersRaw = attempt['answers'] as List? ?? [];
    final chosenByQ = <String, int>{};
    for (final a in answersRaw) {
      if (a is! Map) continue;
      final qid = '${a['questionId']}';
      final idx = int.tryParse('${a['chosenIndex']}') ?? -1;
      if (qid.isNotEmpty && idx >= 0) chosenByQ[qid] = idx;
    }

    if (_readingLoading[readingId] == true) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final reading = _readingCache[readingId];
    if (reading == null) {
      return Text(l10n.teacherAttemptGradeNoSkillWork, style: TeacherWebUi.webBody(context));
    }

    final score = attempt['score'];
    final correct = attempt['correctCount'];
    final total = attempt['totalQuestions'];
    String? scoreLine;
    if (score != null) {
      if (widget.integratedScoreScale) {
        final raw = num.tryParse('$score');
        final onTen = raw != null ? (raw / 10).clamp(0.0, 10.0) : null;
        scoreLine = onTen != null
            ? l10n.integratedSkillScoreLabel(formatIntegratedScore(onTen))
            : null;
      } else {
        scoreLine = l10n.teacherAttemptGradePointsShort('$score', '100');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scoreLine != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '$scoreLine${correct != null && total != null ? ' · $correct/$total' : ''}',
              style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        for (var qi = 0; qi < reading.questions.length; qi++) ...[
          if (qi > 0) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineMuted),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.teacherAttemptGradeQuestionN(qi + 1),
                  style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(reading.questions[qi].questionText, style: ExamSystemUi.questionStem(context)),
                const SizedBox(height: 8),
                McqGradingReviewList(
                  options: reading.questions[qi].options,
                  correctIndexes: {reading.questions[qi].correctAnswerIndex},
                  selectedIndexes: chosenByQ.containsKey(reading.questions[qi].id)
                      ? {chosenByQ[reading.questions[qi].id]!}
                      : {},
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListeningWork(BuildContext context, dynamic records) {
    final l10n = context.l10n;
    if (records is! List || records.isEmpty) {
      return Text(l10n.teacherAttemptGradeNoSkillWork, style: TeacherWebUi.webBody(context));
    }
    return Column(
      children: [
        for (final row in records)
          if (row is Map) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineMuted),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.teacherAttemptGradeListeningCue} ${row['cueIdx'] ?? '—'}',
                    style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${row['userText'] ?? '—'}',
                    style: TeacherWebUi.webBody(context).copyWith(height: 1.5),
                  ),
                  if (row['score'] is Map) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.teacherAttemptGradeDictationScore(
                        '${(row['score'] as Map)['correctWords'] ?? 0}',
                        '${(row['score'] as Map)['totalWords'] ?? 0}',
                      ),
                      style: TeacherWebUi.webCaption(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildSpeakingWork(BuildContext context, dynamic records) {
    final l10n = context.l10n;
    if (records is! List || records.isEmpty) {
      return Text(l10n.teacherAttemptGradeNoSkillWork, style: TeacherWebUi.webBody(context));
    }
    return Column(
      children: [
        for (final row in records)
          if (row is Map) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineMuted),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teacherAttemptGradeSpeakingLine('${row['sentenceId'] ?? ''}'),
                    style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${row['userTranscript'] ?? '—'}',
                    style: TeacherWebUi.webBody(context).copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildWritingWork(BuildContext context, dynamic records) {
    final l10n = context.l10n;
    if (records == null || records is! Map) {
      return Text(l10n.teacherAttemptGradeNoSkillWork, style: TeacherWebUi.webBody(context));
    }
    final sub = Map<String, dynamic>.from(records);
    final content = '${sub['content'] ?? ''}'.trim();
    final score = sub['score'];
    final wordCount = sub['wordCount'];
    final status = sub['status'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (score != null)
              TeacherStatusChip(
                label: l10n.teacherAttemptGradeWritingScore('$score'),
                tone: _WritingChipTone.score,
              ),
            if (wordCount is num)
              TeacherStatusChip(
                label: l10n.teacherAttemptGradeWordCount(wordCount.toInt()),
                tone: _WritingChipTone.meta,
              ),
            if (status != null && status.isNotEmpty)
              TeacherStatusChip(label: status, tone: _WritingChipTone.meta),
          ],
        ),
        const SizedBox(height: 12),
        SelectableText(
          content.isNotEmpty ? content : '—',
          style: TeacherWebUi.webBody(context).copyWith(height: 1.55, fontSize: 14),
        ),
      ],
    );
  }
}

enum _WritingChipTone { score, meta }

class TeacherStatusChip extends StatelessWidget {
  const TeacherStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final _WritingChipTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = tone == _WritingChipTone.score ? AppColors.primaryTint : AppColors.outlineMuted;
    final fg = tone == _WritingChipTone.score ? AppColors.primaryDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
