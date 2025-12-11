import 'package:flutter/material.dart';
import '../../core/get_it/get_it.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/sqflite/dict_db.dart';

class DictDetailPage extends StatelessWidget {
  final Entry entry;
  final UserVocabRepository _userVocabRepository = getIt<UserVocabRepository>();

  DictDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline, color: textMain),
            tooltip: 'Save word',
            onPressed: () => _saveWord(context),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12, left: 4),
            child: ElevatedButton.icon(
              onPressed: () => _startLearning(context),
              icon: const Icon(Icons.school, size: 16),
              label: const Text("Learn"),
              style: ElevatedButton.styleFrom(
                backgroundColor: textMain, // Black bg
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            Text(
              entry.headword,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textMain, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (entry.ipa != null && entry.ipa!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF4F4F5), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '/${entry.ipa}/',
                      style: const TextStyle(fontSize: 15, fontFamily: 'NotoSans', color: textMuted),
                    ),
                  ),
                const SizedBox(width: 12),
                // POS & Tags
                if (entry.pos != null) _buildTag(entry.pos!, Colors.blue),
                ...entry.tags.map((t) => Padding(padding: const EdgeInsets.only(left: 8), child: _buildTag(t, Colors.grey))),
              ],
            ),
            const SizedBox(height: 32),

            // 2. MEANINGS
            const Text("Definitions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain)),
            const SizedBox(height: 16),
            ...entry.senses.asMap().entries.map((e) => _buildSenseItem(e.key + 1, e.value)),

            // 3. SEE ALSO
            if (entry.seeAlso.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(color: borderCol),
              const SizedBox(height: 16),
              const Text("See also", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: entry.seeAlso.map((s) => Chip(
                  label: Text(s),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: borderCol),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF52525B))),
    );
  }

  Widget _buildSenseItem(int index, Sense sense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$index.", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFA1A1AA))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sense.def, style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF09090B))),
                if (sense.examples.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFE4E4E7), width: 2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sense.examples.map((ex) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(ex, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF71717A))),
                      )).toList(),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWord(BuildContext context) async {
    final result = await _userVocabRepository.saveWord(entry);
    if (context.mounted) {
      result.fold(
            (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
            (r) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved '${entry.headword}'"))),
      );
    }
  }

  Future<void> _startLearning(BuildContext context) async {
    final result = await _userVocabRepository.startLearningWord(entry);
    if (context.mounted) {
      result.fold(
            (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
            (r) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Learning '${entry.headword}'"))),
      );
    }
  }
}