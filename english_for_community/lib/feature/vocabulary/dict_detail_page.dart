import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/get_it/get_it.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/sqflite/dict_db.dart';

class DictDetailPage extends StatefulWidget {
  final Entry entry;
  final bool isGuest; // 🔥 Thêm tham số isGuest

  const DictDetailPage({
    super.key,
    required this.entry,
    this.isGuest = false, // Mặc định là false
  });

  @override
  State<DictDetailPage> createState() => _DictDetailPageState();
}

class _DictDetailPageState extends State<DictDetailPage> {
  // Repo có thể null hoặc không dùng đến nếu là Guest
  UserVocabRepository? _userVocabRepository;
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    _initTts();
    // Chỉ init repo nếu không phải guest
    if (!widget.isGuest) {
      _userVocabRepository = getIt<UserVocabRepository>();
    }
  }

  void _initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);
  }

  Future<void> _speak() async {
    await flutterTts.stop();
    await flutterTts.speak(widget.entry.headword);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Colors.white;
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

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
        // 🔥 Nếu là Guest thì không hiện actions (Nút Save/Learn)
        actions: widget.isGuest ? [] : [
          IconButton(
            icon: const Icon(Icons.school_rounded, color: Color(0xFF10B981)),
            tooltip: 'Start Learning',
            onPressed: () => _startLearning(context),
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border_rounded, color: Colors.amber[700]),
            tooltip: 'Save word',
            onPressed: () => _saveWord(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.blue.withOpacity(0.05)],
                ),
                border: const Border(bottom: BorderSide(color: Color(0xFFF4F4F5))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.headword,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: textMain, letterSpacing: -1),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      InkWell(
                        onTap: _speak,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.volume_up_rounded, color: Color(0xFF3B82F6), size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.entry.ipa != null && widget.entry.ipa!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE4E4E7))),
                          child: Text('/${widget.entry.ipa}/', style: const TextStyle(fontSize: 16, fontFamily: 'NotoSans', color: textMuted)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      if (widget.entry.pos != null) _buildTag(widget.entry.pos!, Colors.blue),
                      ...widget.entry.tags.map((t) => _buildTag(t, Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            // MEANINGS
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Definitions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain)),
                  const SizedBox(height: 16),
                  ...widget.entry.senses.asMap().entries.map((e) => _buildSenseItem(e.key + 1, e.value)),

                  if (widget.entry.seeAlso.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Divider(color: Color(0xFFE4E4E7)),
                    const SizedBox(height: 16),
                    Text("See also", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber[800])),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.entry.seeAlso.map((s) => Chip(
                        label: Text(s),
                        backgroundColor: Colors.amber.withOpacity(0.05),
                        side: BorderSide(color: Colors.amber.withOpacity(0.2)),
                        labelStyle: TextStyle(color: Colors.amber[900]),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color[700])),
    );
  }

  Widget _buildSenseItem(int index, Sense sense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24, alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFF4F4F5), shape: BoxShape.circle),
            child: Text("$index", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF71717A))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sense.def, style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF09090B))),
                if (sense.examples.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
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
    if (_userVocabRepository == null) return;
    final result = await _userVocabRepository!.saveWord(widget.entry);
    if (context.mounted) {
      result.fold(
            (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
            (r) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved '${widget.entry.headword}'"))),
      );
    }
  }

  Future<void> _startLearning(BuildContext context) async {
    if (_userVocabRepository == null) return;
    final result = await _userVocabRepository!.startLearningWord(widget.entry);
    if (context.mounted) {
      result.fold(
            (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
            (r) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added '${widget.entry.headword}' to learning queue!"))),
      );
    }
  }
}