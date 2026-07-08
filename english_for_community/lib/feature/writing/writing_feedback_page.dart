import 'package:english_for_community/feature/writing/widgets/interactive_diff_text.dart';
import 'package:flutter/material.dart';
import '../../core/entity/writing_submission_entity.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';

class WritingFeedbackPage extends StatelessWidget {
  final WritingSubmissionEntity submission;

  const WritingFeedbackPage({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    final fb = submission.feedback;
    // 👇 Lấy thông tin đề bài từ submission
    final prompt = submission.generatedPrompt;

    if (fb == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: StudentMobileUi.appBar(context, title: t.writingFbErrorTitle),
        body: Center(
          child: Text(t.writingFbNoData, style: StudentMobileUi.body(context)),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          toolbarHeight: StudentMobileUi.appBarHeight,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(t.writingFbResultTitle, style: StudentMobileUi.sectionTitle(context)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.outline)),
              ),
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: StudentMobileUi.cardTitle(context),
                tabs: [
                  Tab(text: t.writingFbTabOverview),
                  Tab(text: t.writingFbTabDetails),
                  Tab(text: t.writingFbTabRewrites),
                  Tab(text: t.writingFbTabSamples),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // 1. OVERVIEW TAB
            SingleChildScrollView(
              padding: StudentMobileUi.pagePadding,
              child: Column(
                children: [
                  // 👇 [MỚI] HIỂN THỊ ĐỀ BÀI & TASK TYPE
                  if (prompt != null) ...[
                    _ShadcnCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t.writingFbTopicRequirement,
                                style: StudentMobileUi.cardTitle(context),
                              ),
                              // Badge hiển thị Task Type
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.outlineMuted,
                                  borderRadius: BorderRadius.circular(AppRadius.chip),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: Text(
                                  prompt.taskType?.toUpperCase() ?? 'WRITING',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Tiêu đề đề bài
                          if (prompt.title != null && prompt.title!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                prompt.title!,
                                style: StudentMobileUi.sectionTitle(context),
                              ),
                            ),
                          // Nội dung câu hỏi
                          Text(
                            prompt.text ?? t.writingFbNoPromptContent,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- (PHẦN HIỂN THỊ ĐIỂM SỐ CŨ) ---
                  _ShadcnCard(
                    child: Column(
                      children: [
                        Text(t.writingFbOverallBand, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text(
                          (fb.overall ?? 0).toStringAsFixed(1),
                          style: StudentMobileUi.greeting(context).copyWith(fontSize: 48, height: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ShadcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.writingFbSubscores, style: StudentMobileUi.cardTitle(context)),
                        const SizedBox(height: 16),
                        _ScoreRow(label: t.writingFbCriterionTR, score: fb.tr),
                        const Divider(height: 24, color: AppColors.outlineMuted),
                        _ScoreRow(label: t.writingFbCriterionCC, score: fb.cc),
                        const Divider(height: 24, color: AppColors.outlineMuted),
                        _ScoreRow(label: t.writingFbCriterionLR, score: fb.lr),
                        const Divider(height: 24, color: AppColors.outlineMuted),
                        _ScoreRow(label: t.writingFbCriterionGRA, score: fb.gra),
                      ],
                    ),
                  ),
                  if (fb.keyTips != null && fb.keyTips!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ShadcnCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Text(t.writingFbKeyTips, style: StudentMobileUi.cardTitle(context)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _BulletedList(items: fb.keyTips!),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. DETAILS TAB
            ListView(
              padding: StudentMobileUi.pagePadding,
              children: [
                _CriteriaCard(label: t.writingFbCriterionTR, score: fb.tr, bullets: fb.trBullets, note: fb.trNote),
                const SizedBox(height: 16),
                _CriteriaCard(label: t.writingFbCriterionCC, score: fb.cc, bullets: fb.ccBullets, note: fb.ccNote),
                const SizedBox(height: 16),
                _CriteriaCard(label: t.writingFbCriterionLR, score: fb.lr, bullets: fb.lrBullets, note: fb.lrNote),
                const SizedBox(height: 16),
                _CriteriaCard(label: t.writingFbCriterionGrammar, score: fb.gra, bullets: fb.graBullets, note: fb.graNote),
              ],
            ),

            // 3. REWRITES TAB (Đã sửa fix xuống dòng)
            SingleChildScrollView(
              padding: StudentMobileUi.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.writingFbDetailedCorrection,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.writingFbTapHighlighted,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (fb.paragraphs != null && fb.paragraphs!.isNotEmpty)
                    ...fb.paragraphs!
                        .where((p) => (p.rewrite ?? '').trim().isNotEmpty)
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RewriteParagraphCard(
                                title: (p.title ?? '').trim(),
                                comment: (p.comment ?? '').trim(),
                                rewrite: (p.rewrite ?? '').trim(),
                                originalEssay: submission.content,
                              ),
                            ))
                        .toList()
                  else
                    _ShadcnCard(
                      child: InteractiveDiffText(
                        text: t.writingFbNoCorrections,
                        originalText: submission.content,
                      ),
                    ),
                ],
              ),
            ),

            // 4. SAMPLES TAB
            ListView(
              padding: StudentMobileUi.pagePadding,
              children: [
                if ((fb.sampleMid ?? '').trim().isNotEmpty)
                  _SampleCard(title: t.writingFbSampleMidTitle, content: fb.sampleMid!.trim()),
                if ((fb.sampleHigh ?? '').trim().isNotEmpty) ...[
                  if ((fb.sampleMid ?? '').trim().isNotEmpty) const SizedBox(height: 16),
                  _SampleCard(title: t.writingFbSampleHighTitle, content: fb.sampleHigh!.trim()),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ... (Các widget phụ _ShadcnCard, _ScoreRow, _CriteriaCard, _BulletedList, _SampleCard giữ nguyên) ...
class _ShadcnCard extends StatelessWidget {
  final Widget child;
  const _ShadcnCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: child,
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final num? score;

  const _ScoreRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.outlineMuted,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            score?.toStringAsFixed(1) ?? '-',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _CriteriaCard extends StatelessWidget {
  final String label;
  final num? score;
  final List<String>? bullets;
  final String? note;

  const _CriteriaCard({required this.label, this.score, this.bullets, this.note});

  @override
  Widget build(BuildContext context) {
    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(score?.toStringAsFixed(1) ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          if (bullets != null && bullets!.isNotEmpty) _BulletedList(items: bullets!),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(note!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }
}

class _BulletedList extends StatelessWidget {
  final List<String> items;
  const _BulletedList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•', style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(width: 8),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4))),
          ],
        ),
      )).toList(),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final String title;
  final String content;

  const _SampleCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    // Regex tách đoạn văn (xử lý cả \n và \\n)
    final RegExp splitRegex = RegExp(r'(\s*\\n\s*)+|(\s*\n\s*)+');

    final paragraphs = content.split(splitRegex);

    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề (Header)
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600, // Shadcn thường dùng w600 cho tiêu đề
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Nội dung (Body)
          ...paragraphs.map((paragraph) {
            if (paragraph.trim().isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                paragraph.trim(),
                // 👇 CẬP NHẬT STYLE GIỐNG HỆT INTERACTIVE DIFF TEXT
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary, // Màu đen chuẩn
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _RewriteParagraphCard extends StatelessWidget {
  final String title;
  final String comment;
  final String rewrite;
  final String originalEssay;

  const _RewriteParagraphCard({
    required this.title,
    required this.comment,
    required this.rewrite,
    required this.originalEssay,
  });

  List<String> _extractParagraphs(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\\n', '\n').trim();
    if (normalized.isEmpty) return const <String>[];
    final byBlankLines = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (byBlankLines.length > 1) return byBlankLines;
    return normalized
        .split(RegExp(r'(?<=[\.\!\?])\s+(?=[A-Z])'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Set<String> _tokenize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3)
        .toSet();
  }

  double _similarity(String a, String b) {
    final sa = _tokenize(a);
    final sb = _tokenize(b);
    if (sa.isEmpty || sb.isEmpty) return 0;
    final inter = sa.intersection(sb).length.toDouble();
    final union = sa.union(sb).length.toDouble();
    return union == 0 ? 0 : inter / union;
  }

  String _findBestMatch(String rewriteParagraph, String sourceEssay) {
    final candidates = _extractParagraphs(sourceEssay);
    if (candidates.isEmpty) return sourceEssay;
    String best = candidates.first;
    double bestScore = -1;
    for (final c in candidates) {
      final s = _similarity(rewriteParagraph, c);
      if (s > bestScore) {
        bestScore = s;
        best = c;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final matchedOriginal = _findBestMatch(rewrite, originalEssay);
    final hasToken = RegExp(r'\{\{.*?\|\|.*?\|\|.*?\}\}').hasMatch(rewrite);
    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (title.isNotEmpty)
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasToken ? AppColors.successBg : AppColors.infoBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: hasToken ? AppColors.success : AppColors.info,
                  ),
                ),
                child: Text(
                  hasToken ? 'Smart Tokens' : 'Auto Diff',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hasToken ? AppColors.success : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.outline),
            ),
            child: InteractiveDiffText(
              text: rewrite,
              originalText: matchedOriginal,
            ),
          ),
        ],
      ),
    );
  }
}