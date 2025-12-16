import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/entity/writing_submission_entity.dart';

// Palette màu riêng cho Writing (Hồng/Đỏ)
const Color kPrimaryWriting = Color(0xFFE11D48); // Rose 600
const Color kBgWriting = Color(0xFFFFF1F2);      // Rose 50
const Color kBorderWriting = Color(0xFFFECDD3);  // Rose 200

class WritingDetailView extends StatelessWidget {
  final WritingSubmissionEntity data;

  const WritingDetailView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final feedback = data.feedback;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SCORE HEADER
          _buildScoreHeader(),
          const SizedBox(height: 24),

          // 2. PROMPT (Đề bài)
          if (data.generatedPrompt != null) ...[
            _buildSectionTitle("Topic"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.generatedPrompt?.title ?? "Writing Task",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(data.generatedPrompt?.text ?? "",
                      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54)),
                  const SizedBox(height: 12),
                  // Badge Task Type
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text(data.generatedPrompt?.taskType ?? "Essay",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 3. SCORE BREAKDOWN
          if (feedback != null) ...[
            _buildSectionTitle("Band Score Breakdown"),
            Row(
              children: [
                Expanded(child: _buildCriteriaBox("TR", feedback.tr, "Task Response")),
                const SizedBox(width: 10),
                Expanded(child: _buildCriteriaBox("CC", feedback.cc, "Coherence")),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildCriteriaBox("LR", feedback.lr, "Lexical Resource")),
                const SizedBox(width: 10),
                Expanded(child: _buildCriteriaBox("GRA", feedback.gra, "Grammar")),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // 4. USER SUBMISSION
          _buildSectionTitle("Your Submission"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              data.content,
              style: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF334155), fontFamily: 'Roboto'),
            ),
          ),
          const SizedBox(height: 24),

          // 5. DETAILED FEEDBACK (Paragraphs)
          if (feedback?.paragraphs != null && feedback!.paragraphs!.isNotEmpty) ...[
            _buildSectionTitle("AI Paragraph Feedback"),
            ...feedback.paragraphs!.map((p) => _buildParagraphFeedback(p)),
            const SizedBox(height: 24),
          ],

          // 6. SAMPLE ESSAY (High Band)
          if (feedback?.sampleHigh != null) ...[
            _buildSectionTitle("High Band Sample", color: Colors.green),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Green 50
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                feedback!.sampleHigh!,
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.green.shade900),
              ),
            ),
            const SizedBox(height: 40),
          ]
        ],
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildSectionTitle(String title, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kBgWriting,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorderWriting),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Overall Score", style: TextStyle(color: Color(0xFF9F1239), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${data.score ?? '--'}", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: kPrimaryWriting, height: 1)),
                  const Padding(padding: EdgeInsets.only(bottom: 6, left: 4), child: Text("Band", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryWriting))),
                ],
              ),
            ],
          ),
          Container(height: 40, width: 1, color: kBorderWriting),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMetaRow(Icons.short_text, "${data.wordCount ?? 0} words"),
              const SizedBox(height: 8),
              _buildMetaRow(Icons.timer_outlined, _formatDuration(data.durationInSeconds ?? 0)),
              const SizedBox(height: 8),
              _buildMetaRow(Icons.calendar_today, DateFormat('MMM dd').format(data.submittedAt ?? DateTime.now())),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9F1239)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF881337))),
      ],
    );
  }

  Widget _buildCriteriaBox(String code, int? score, String fullName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: kBgWriting, borderRadius: BorderRadius.circular(4)),
                child: Text("${score ?? '-'}", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryWriting)),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(fullName, style: const TextStyle(fontSize: 12, color: Colors.black87), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildParagraphFeedback(ParagraphImprove p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        title: Text(p.title ?? "Paragraph", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(p.comment ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          const Align(alignment: Alignment.centerLeft, child: Text("SUGGESTED REWRITE:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple))),
          const SizedBox(height: 8),
          Text(p.rewrite ?? "", style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    if (m == 0) return '${sec}s';
    return '${m}m';
  }
}