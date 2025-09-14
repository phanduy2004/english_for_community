import 'package:flutter/material.dart';

class ListeningSkillsPage extends StatefulWidget {
  const ListeningSkillsPage({super.key});

  static String routeName = 'ListeningSkillsPage';
  static String routePath = '/listening-skills';

  @override
  State<ListeningSkillsPage> createState() => _ListeningSkillsPageState();
}

class _ListeningSkillsPageState extends State<ListeningSkillsPage> {
  final _dictationCtrl = TextEditingController();

  // Trạng thái mô phỏng audio
  bool _isPlaying = false;
  bool _showTranscript = false;
  Duration _position = const Duration(minutes: 1, seconds: 32);
  final Duration _duration = const Duration(minutes: 4);

  @override
  void dispose() {
    _dictationCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _togglePlay() => setState(() => _isPlaying = !_isPlaying);
  void _toggleTranscript() => setState(() => _showTranscript = !_showTranscript);

  void _checkAnswer() {
    // TODO: chấm chính tả thực tế bằng backend/AI.
    // Ở đây chỉ demo feedback đơn giản.
    final text = _dictationCtrl.text.trim();
    final snack = SnackBar(
      content: Text(text.isEmpty ? 'Please type your answer first.' : 'Submitted! Score: 85% • 4/5 words correct'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  void _replay() {
    // TODO: nối với audio.seek(Duration.zero)
    setState(() => _position = Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final progress = (_duration.inMilliseconds == 0)
        ? 0.0
        : _position.inMilliseconds / _duration.inMilliseconds;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text('Listening Skills', style: text.headlineMedium),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () {}, // mở dialog cài đặt nếu cần
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Hero card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _Card(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Conversation', style: text.headlineSmall),
                            const SizedBox(height: 4),
                            Text('Intermediate Level • 4 min',
                                style: text.bodyMedium?.copyWith(color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 8),
                            Row(children: const [
                              _Tag(label: 'Listening', filled: true),
                              SizedBox(width: 8),
                              _Tag(label: 'Dictation'),
                            ]),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _togglePlay,
                        borderRadius: BorderRadius.circular(30),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: scheme.primary,
                          child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: scheme.onPrimary),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Nội dung chính cuộn
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Audio controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Audio Controls', style: text.titleMedium),
                            Row(children: [
                              _IconPill(
                                icon: Icons.volume_up_rounded,
                                onTap: () {}, // TODO: volume
                              ),
                              const SizedBox(width: 12),
                              _IconPill(
                                icon: _showTranscript ? Icons.subtitles_off_rounded : Icons.subtitles_rounded,
                                onTap: _toggleTranscript,
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: scheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(_position), style: text.bodySmall?.copyWith(color: Colors.black54)),
                            Text(_fmt(_duration), style: text.bodySmall?.copyWith(color: Colors.black54)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1),
                        ),

                        // Transcript (optional)
                        if (_showTranscript) ...[
                          Text('Transcript', style: text.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Good morning, how are you today? I\'m planning to grab a coffee before the meeting.',
                            style: text.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Dictation
                        Text('Dictation Mode', style: text.titleMedium),
                        const SizedBox(height: 8),
                        Text('Type what you hear:', style: text.bodyMedium?.copyWith(color: Colors.black54)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _dictationCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Start typing the sentence...',
                            filled: true,
                            fillColor: scheme.surfaceVariant.withOpacity(.3),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _checkAnswer,
                                child: const Text('Check Answer'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _replay,
                              icon: const Icon(Icons.replay_rounded, size: 20),
                              label: const Text('Replay'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Feedback demo
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: scheme.surfaceVariant.withOpacity(.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Feedback:', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  style: text.bodyMedium,
                                  children: [
                                    const TextSpan(text: 'Good morning, '),
                                    TextSpan(text: 'how', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                                    const TextSpan(text: ' are '),
                                    TextSpan(
                                      text: 'you',
                                      style: TextStyle(
                                        color: scheme.error,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const TextSpan(text: ' today?'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Score: 85% • 4/5 words correct',
                                  style: text.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ======= UI helpers =======

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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.filled = false});
  final String label;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? scheme.primary : scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? scheme.onPrimary : Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: scheme.surfaceVariant, borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}
