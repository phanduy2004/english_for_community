import 'package:flutter/material.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';
import '../../core/entity/writing_submission_entity.dart';

class WritingFeedbackPage extends StatelessWidget {
  final WritingSubmissionEntity submission;

  const WritingFeedbackPage({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    final fb = submission.feedback;
    if (fb == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feedback Error')),
        body: const Center(child: Text('No feedback data found.')),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Writing Feedback'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overall',  icon: Icon(Icons.assessment_rounded)),
              Tab(text: 'Details',  icon: Icon(Icons.grading_rounded)),
              Tab(text: 'Rewrites', icon: Icon(Icons.edit_rounded)),
              Tab(text: 'Samples',  icon: Icon(Icons.article_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ===== Tab 1: Overall =====
            _PaddedList(children: [
              _FCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(context, 'Est. Overall Band Score'),
                  const SizedBox(height: 8),
                  Text(
                    (fb.overall ?? 0).toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              )),
              _FCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(context, 'Subscores'),
                  const SizedBox(height: 8),
                  _keyVal(context, 'Task Response (TR)', fb.tr?.toStringAsFixed(1)),
                  _keyVal(context, 'Coherence & Cohesion (CC)', fb.cc?.toStringAsFixed(1)),
                  _keyVal(context, 'Lexical Resource (LR)', fb.lr?.toStringAsFixed(1)),
                  _keyVal(context, 'Grammar (GRA)', fb.gra?.toStringAsFixed(1)),
                ],
              )),
              if (fb.keyTips != null && fb.keyTips!.isNotEmpty)
                _FCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context, 'Key Tips for Improvement'),
                    const SizedBox(height: 6),
                    _bullets(context, fb.keyTips!),
                  ],
                )),
            ]),

            // ===== Tab 2: Criteria Details =====
            _PaddedList(children: [
              _FCard(child: _criteriaBlock(
                context,
                label: 'Task Response (TR)',
                score: fb.tr?.toStringAsFixed(1),
                bullets: fb.trBullets,
                note: fb.trNote,
              )),
              _FCard(child: _criteriaBlock(
                context,
                label: 'Coherence & Cohesion (CC)',
                score: fb.cc?.toStringAsFixed(1),
                bullets: fb.ccBullets,
                note: fb.ccNote,
              )),
              _FCard(child: _criteriaBlock(
                context,
                label: 'Lexical Resource (LR)',
                score: fb.lr?.toStringAsFixed(1),
                bullets: fb.lrBullets,
                note: fb.lrNote,
              )),
              _FCard(child: _criteriaBlock(
                context,
                label: 'Grammar (GRA)',
                score: fb.gra?.toStringAsFixed(1),
                bullets: fb.graBullets,
                note: fb.graNote,
              )),
            ]),

            // ===== Tab 3: Rewrites (Diff) =====
            _PaddedList(children: [
              _FCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(context, 'Rewrites (Diff View)'),
                  const SizedBox(height: 8),
                  _FDiffBlockOneShot(
                    oldText: submission.content,
                    // -------------------------------------------------
                    // SỬA LỖI: Đã sửa logic để lấy 'paragraphs.rewrite'
                    // -------------------------------------------------
                    newText: (() {
                      final fb = submission.feedback!;
                      if (fb.paragraphs != null && fb.paragraphs!.isNotEmpty) {
                        // Ghép các đoạn rewrite (sửa lỗi) lại
                        final combinedRewrite = fb.paragraphs!
                            .map((p) => p.rewrite ?? '')
                            .join('\n\n')
                            .trim();

                        // Chỉ trả về nếu nó thực sự có nội dung
                        if (combinedRewrite.isNotEmpty) {
                          return combinedRewrite;
                        }
                      }
                      // Nếu không có, trả về "không có"
                      // TUYỆT ĐỐI KHÔNG DÙNG fb.sampleMid ở đây
                      return 'No rewrite available.';
                    })(),
                    // -------------------------------------------------
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lưu ý: Rewrite chỉ sửa lỗi ngữ pháp/chính tả/từ vựng – không nâng cấp văn phong.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w300),
                  ),
                ],
              )),
            ]),

            // ===== Tab 4: Samples =====
            _PaddedList(children: [
              if (fb.sampleMid != null)
                _FCard(child: _sample(context, 'Revised Essay (Band 5.5–6.5)', fb.sampleMid!)),
              if (fb.sampleHigh != null)
                _FCard(child: _sample(context, 'Sample Essay (Band 8.0–9.0)', fb.sampleHigh!)),
            ]),
          ],
        ),
      ),
    );
  }
}
class _FDiffBlockOneShot extends StatelessWidget {
  const _FDiffBlockOneShot({required this.oldText, required this.newText});
  final String oldText;
  final String newText;

  // Chuẩn hoá mạnh để tránh false-positive
  String _norm(String s) => s
      .replaceAll('\u00A0', ' ')                // NBSP -> space
      .replaceAll('\u2009', ' ')               // thin space -> space
      .replaceAll(RegExp(r'[“”]'), '"')        // smart quotes
      .replaceAll(RegExp(r"[‘’]"), "'")        // smart quotes
      .replaceAll('–', '-')                    // en dash
      .replaceAll('—', '-')                    // em dash
      .replaceAll(RegExp(r'[ \t]+'), ' ')      // collapse spaces
      .replaceAll(RegExp(r'\r\n?'), '\n')      // CRLF -> LF
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')   // collapse blank lines
      .trim();

  // Similarity Jaccard bigram
  double _similarity(String a, String b) {
    final s1 = _norm(a).toLowerCase();
    final s2 = _norm(b).toLowerCase();
    if (s1 == s2) return 1.0;
    Set<String> grams(String s) {
      if (s.length <= 1) return {s};
      final g = <String>{};
      for (var i = 0; i < s.length - 1; i++) g.add(s.substring(i, i + 2));
      return g;
    }
    final g1 = grams(s1), g2 = grams(s2);
    final inter = g1.intersection(g2).length;
    final union = g1.union(g2).length;
    return union == 0 ? 0 : inter / union;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final oldN = _norm(oldText);
    final newN = _norm(newText);
    final nearSame = oldN == newN || _similarity(oldN, newN) >= 0.995;

    final body = nearSame
    // Gần như giống hệt: hiển thị plain text, không highlight
        ? Text(
      oldN.isEmpty ? 'No rewrite available.' : oldN,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(height: 1.5, fontWeight: FontWeight.w300),
    )
    // Khác đáng kể: dùng PrettyDiffText
        : PrettyDiffText(
      oldText: oldN,
      newText: newN,
      defaultTextStyle: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(height: 1.5, fontWeight: FontWeight.w300)
          ?? const TextStyle(fontSize: 13.5, height: 1.5),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: body,
    );
  }
}

class _PaddedList extends StatelessWidget {
  const _PaddedList({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    itemBuilder: (_, i) => children[i],
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemCount: children.length,
  );
}

class _FCard extends StatelessWidget {
  const _FCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

Widget _title(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w500, // giữ đúng style bạn đang dùng
  ),
);

Widget _keyVal(BuildContext context, String k, String? v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      Expanded(child: Text(k, style: Theme.of(context).textTheme.bodySmall)),
      Text(v ?? 'N/A', style: Theme.of(context).textTheme.bodySmall),
    ],
  ),
);

Widget _bullets(BuildContext context, List<String> items) {
  final style = Theme.of(context)
      .textTheme
      .bodySmall
      ?.copyWith(fontWeight: FontWeight.w300); // bodySmall w300 như trang viết
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items.map((b) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(child: Text(b, style: style)),
          ],
        ),
      );
    }).toList(),
  );
}

Widget _criteriaBlock(
    BuildContext context, {
      required String label,
      String? score,
      List<String>? bullets,
      String? note,
    }) {
  final cs = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(score ?? 'N/A', style: Theme.of(context).textTheme.bodySmall),
      ]),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bullets != null && bullets.isNotEmpty) _bullets(context, bullets),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

Widget _sample(BuildContext context, String title, String content) {
  final cs = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(
          content,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w300),
        ),
      ),
    ],
  );
}