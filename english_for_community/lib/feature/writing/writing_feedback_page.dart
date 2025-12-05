import 'package:flutter/material.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';
import '../../core/entity/writing_submission_entity.dart';

class WritingFeedbackPage extends StatelessWidget {
  final WritingSubmissionEntity submission;

  const WritingFeedbackPage({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final fb = submission.feedback;
    // 👇 Lấy thông tin đề bài từ submission
    final prompt = submission.generatedPrompt;

    if (fb == null) {
      return Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: textMain),
          title: const Text('Error', style: TextStyle(color: textMain)),
        ),
        body: const Center(
          child: Text(
            'No feedback data found.',
            style: TextStyle(color: Color(0xFF71717A)),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: textMain),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Feedback Result',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: borderCol)),
              ),
              child: TabBar(
                labelColor: primaryColor,
                unselectedLabelColor: const Color(0xFF71717A),
                indicatorColor: primaryColor,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Details'),
                  Tab(text: 'Rewrites'),
                  Tab(text: 'Samples'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // 1. OVERVIEW TAB
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                              const Text(
                                'Topic & Requirement',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textMain),
                              ),
                              // Badge hiển thị Task Type
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: borderCol),
                                ),
                                child: Text(
                                  prompt.taskType?.toUpperCase() ?? 'WRITING',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF71717A),
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
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMain),
                              ),
                            ),
                          // Nội dung câu hỏi
                          Text(
                            prompt.text ?? 'No prompt content available.',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF52525B), height: 1.5),
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
                        const Text('Overall Band Score', style: TextStyle(fontSize: 13, color: Color(0xFF71717A), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text(
                          (fb.overall ?? 0).toStringAsFixed(1),
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: primaryColor, height: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ShadcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Subscores', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textMain)),
                        const SizedBox(height: 16),
                        _ScoreRow(label: 'Task Response', score: fb.tr),
                        const Divider(height: 24, color: Color(0xFFF4F4F5)),
                        _ScoreRow(label: 'Coherence & Cohesion', score: fb.cc),
                        const Divider(height: 24, color: Color(0xFFF4F4F5)),
                        _ScoreRow(label: 'Lexical Resource', score: fb.lr),
                        const Divider(height: 24, color: Color(0xFFF4F4F5)),
                        _ScoreRow(label: 'Grammar Range', score: fb.gra),
                      ],
                    ),
                  ),
                  if (fb.keyTips != null && fb.keyTips!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ShadcnCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFF59E0B)),
                              SizedBox(width: 8),
                              Text('Key Improvement Tips', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textMain)),
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
              padding: const EdgeInsets.all(20),
              children: [
                _CriteriaCard(label: 'Task Response', score: fb.tr, bullets: fb.trBullets, note: fb.trNote),
                const SizedBox(height: 16),
                _CriteriaCard(label: 'Coherence & Cohesion', score: fb.cc, bullets: fb.ccBullets, note: fb.ccNote),
                const SizedBox(height: 16),
                _CriteriaCard(label: 'Lexical Resource', score: fb.lr, bullets: fb.lrBullets, note: fb.lrNote),
                const SizedBox(height: 16),
                _CriteriaCard(label: 'Grammar', score: fb.gra, bullets: fb.graBullets, note: fb.graNote),
              ],
            ),

            // 3. REWRITES TAB (Đã sửa fix xuống dòng)
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Diff View Correction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
                  const SizedBox(height: 12),
                  _ShadcnCard(
                    child: _DiffViewer(
                      oldText: submission.content,
                      newText: (() {
                        final fb = submission.feedback!;
                        if (fb.paragraphs != null && fb.paragraphs!.isNotEmpty) {
                          final combinedRewrite = fb.paragraphs!.map((p) => p.rewrite ?? '').join('\n\n').trim();
                          if (combinedRewrite.isNotEmpty) return combinedRewrite;
                        }
                        return 'No corrections available.';
                      })(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '* Red highlights indicate removed/changed text. Green highlights indicate additions/corrections.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF71717A), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            // 4. SAMPLES TAB
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (fb.sampleMid != null)
                  _SampleCard(title: 'Revised Version (Band 6.0-7.0)', content: fb.sampleMid!),
                if (fb.sampleHigh != null) ...[
                  const SizedBox(height: 16),
                  _SampleCard(title: 'Ideal Response (Band 8.0+)', content: fb.sampleHigh!),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ... (Các widget phụ _ShadcnCard, _ScoreRow, _CriteriaCard, _BulletedList, _SampleCard giữ nguyên) ...

// Widget _DiffViewer đã được sửa ở câu trước để fix lỗi xuống dòng
class _DiffViewer extends StatelessWidget {
  final String oldText;
  final String newText;

  const _DiffViewer({required this.oldText, required this.newText});

  String _norm(String s) {
    // Chỉ thay thế nhiều dấu cách/tab liên tiếp thành 1 dấu cách, KHÔNG thay thế \n
    return s.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final oldN = _norm(oldText);
    final newN = _norm(newText);

    if (oldN == newN) {
      return Text(oldText, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF52525B)));
    }

    return PrettyDiffText(
      oldText: oldN,
      newText: newN,
      defaultTextStyle: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF09090B)),
      addedTextStyle: const TextStyle(backgroundColor: Color(0xFFDCFCE7), color: Color(0xFF14532D), fontWeight: FontWeight.w500),
      deletedTextStyle: const TextStyle(backgroundColor: Color(0xFFFEE2E2), color: Color(0xFF991B1B), decoration: TextDecoration.lineThrough),
    );
  }
}

// ... (Các widget phụ khác copy lại từ code cũ của bạn nếu cần: _ShadcnCard, _ScoreRow, etc.) ...
class _ShadcnCard extends StatelessWidget {
  final Widget child;
  const _ShadcnCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
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
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF09090B))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            score?.toStringAsFixed(1) ?? '-',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF09090B)),
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
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF09090B))),
              Text(score?.toStringAsFixed(1) ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF71717A))),
            ],
          ),
          const SizedBox(height: 12),
          if (bullets != null && bullets!.isNotEmpty) _BulletedList(items: bullets!),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Text(note!, style: const TextStyle(fontSize: 13, color: Color(0xFF52525B), fontStyle: FontStyle.italic)),
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
            const Text('•', style: TextStyle(color: Color(0xFF71717A), height: 1.4)),
            const SizedBox(width: 8),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF52525B), height: 1.4))),
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
    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF09090B))),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF52525B), height: 1.6)),
        ],
      ),
    );
  }
}