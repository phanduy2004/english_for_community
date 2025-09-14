import 'package:flutter/material.dart';

class SpeakingSkillsPage extends StatefulWidget {
  const SpeakingSkillsPage({super.key});

  static const routeName = 'SpeakingSkillsPage';
  static const routePath = '/speaking-skills';

  @override
  State<SpeakingSkillsPage> createState() => _SpeakingSkillsPageState();
}

class _SpeakingSkillsPageState extends State<SpeakingSkillsPage> {
  bool _isPlaying = false;
  bool _isRecording = false;

  void _togglePlay() => setState(() => _isPlaying = !_isPlaying);

  void _toggleRecord() {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording == false) {
      // Demo: khi dừng ghi thì báo điểm
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted! Score: 85/100')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Speaking Practice', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            // Hero gradient
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                  begin: const Alignment(1, -1),
                  end: const Alignment(-1, 1),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.record_voice_over, color: scheme.onPrimary, size: 48),
                    const SizedBox(height: 12),
                    Text('Speaking Practice',
                        style: text.headlineSmall?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Practice pronunciation with AI feedback',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: scheme.onPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lesson card
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text('Daily Conversation',
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          _LevelPill(label: 'Level 2', color: scheme.primary, onPrimary: scheme.onPrimary.withOpacity(.9)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    "Hello, how are you today? I'm doing well, thank you for asking.",
                    style: text.bodyLarge?.copyWith(height: 1.4, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                        bg: scheme.secondary,
                        fg: scheme.onSecondary,
                        onTap: _togglePlay,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _toggleRecord,
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 20),
                            label: Text(_isRecording ? 'Stop' : 'Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? scheme.error : scheme.primary,
                              foregroundColor: _isRecording ? scheme.onError : scheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Analysis card
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text('Pronunciation Analysis',
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    _ScorePill(scoreText: '85/100', bg: Colors.green, fg: Colors.white),
                  ]),
                  const SizedBox(height: 12),
                  Text('Word Analysis:', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _WordChip(label: 'Hello', bg: Colors.green, fg: Colors.white),
                      _WordChip(label: 'how', bg: Colors.orange, fg: Colors.black87),
                      _WordChip(label: 'are', bg: Colors.green, fg: Colors.white),
                      _WordChip(label: 'you', bg: Colors.green, fg: Colors.white),
                      _WordChip(label: 'today', bg: Colors.redAccent, fg: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.lightbulb, color: scheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Improvement Tips:',
                              style: text.bodyMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 8),
                        Text("• Focus on the 'ay' sound in 'today' → /təˈdeɪ/",
                            style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                        Text('• Put stress on the second syllable: to-DAY',
                            style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _toggleRecord,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          side: BorderSide(color: scheme.primary, width: 2),
                        ),
                        child: Text('Try Again', style: TextStyle(color: scheme.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {}, // TODO: next lesson
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          child: const Text('Next Lesson'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Other lessons
            _LessonRow(
              title: 'Business English',
              subtitle: 'Professional conversations and presentations',
              levelText: 'Level 3',
              levelColor: Colors.blue.shade100,
              levelFg: Colors.black87,
            ),
            _LessonRow(
              title: 'Travel Phrases',
              subtitle: 'Essential phrases for traveling abroad',
              levelText: 'Level 1',
              levelColor: Colors.green.shade100,
              levelFg: Colors.black87,
            ),
            _LessonRow(
              title: 'Pronunciation Drills',
              subtitle: 'Focus on difficult sounds and phonemes',
              levelText: 'Level 4',
              levelColor: Colors.orange.shade200,
              levelFg: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}

/// ==== Small reusable widgets ====

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x1A000000), offset: Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.bg, required this.fg, required this.onTap});
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: fg, size: 24),
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label, required this.color, required this.onPrimary});
  final String label;
  final Color color;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.scoreText, required this.bg, required this.fg});
  final String scoreText;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: Text(scoreText, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 12)),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.title,
    required this.subtitle,
    required this.levelText,
    required this.levelColor,
    required this.levelFg,
  });

  final String title;
  final String subtitle;
  final String levelText;
  final Color levelColor;
  final Color levelFg;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: text.bodySmall?.copyWith(color: Colors.black54)),
            ]),
          ),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: levelColor, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(levelText, style: TextStyle(color: levelFg, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
