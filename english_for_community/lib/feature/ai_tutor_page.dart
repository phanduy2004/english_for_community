import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AITutorPage extends StatefulWidget {
  const AITutorPage({super.key});

  static String routeName = 'AITutorPage';
  static String routePath = '/ai-tutor';

  @override
  State<AITutorPage> createState() => _AITutorPageState();
}

class _AITutorPageState extends State<AITutorPage> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  bool _strictCorrection = true;

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // --- Mock data model ---
  final List<_ChatMessage> _messages = [
    _ChatMessage.ai(
      "Hello! I'm your interviewer today. Thank you for coming. Please tell me about yourself and why you're interested in this position.",
      timeLabel: 'AI Tutor • 2:34 PM',
    ),
    _ChatMessage.user(
      "Thank you for having me. I am very excited about this opportunity. I have 3 years experience in marketing and I think I can contribute a lot to your team.",
      timeLabel: 'You • 2:35 PM',
    ),
    _ChatMessage.correction(
      'Grammar Correction:\n'
      '• “I have 3 years **of** experience” (not “3 years experience”)\n'
      '• “I **believe** I can contribute” sounds more professional than “I think”.',
      timeLabel: 'Correction • 2:35 PM',
    ),
    _ChatMessage.ai(
      'Excellent! Can you give me a specific example of a successful marketing campaign you worked on?',
      timeLabel: 'AI Tutor • 2:36 PM',
    ),
  ];

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage.user(text, timeLabel: 'You • now'));
      _composer.clear();
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    // TODO: call your AI backend here and push AI response into _messages
  }

  void _insertHint(String hint) {
    if (_composer.text.isEmpty) {
      _composer.text = '$hint: ';
    } else {
      _composer.text = '${_composer.text} $hint: ';
    }
    _composer.selection = TextSelection.fromPosition(
      TextPosition(offset: _composer.text.length),
    );
    setState(() {});
  }

  void _openSettings() => context.pushNamed('TutorSettingsPage');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text('AI Tutor Chat',
            style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.settings_rounded, color: cs.onBackground),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header gradient + topic + strict correction
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.secondary],
                    begin: const Alignment(1, -1),
                    end: const Alignment(-1, 1),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: cs.onPrimary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('AI Tutor Chat',
                                  style: txt.headlineSmall?.copyWith(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.smart_toy_rounded,
                                  color: cs.onPrimary, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Role-play: Job Interview Practice',
                            style: txt.bodyMedium?.copyWith(
                              color: cs.onPrimary,
                              fontSize: 14,
                            )),
                        const SizedBox(height: 8),
                        FilterChip(
                          selected: _strictCorrection,
                          onSelected: (v) => setState(() {
                            _strictCorrection = v;
                          }),
                          label: Text(
                            _strictCorrection
                                ? 'Strict Correction ON'
                                : 'Strict Correction OFF',
                            style: txt.bodySmall?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          avatar: Icon(
                            _strictCorrection
                                ? Icons.check_circle_outline
                                : Icons.circle_outlined,
                            size: 16,
                            color: cs.onPrimary,
                          ),
                          backgroundColor: Colors.white.withOpacity(.2),
                          selectedColor: Colors.white.withOpacity(.3),
                          shape: StadiumBorder(
                            side: BorderSide(color: Colors.white.withOpacity(.4)),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  switch (m.type) {
                    case _MsgType.user:
                      return _UserBubble(message: m.text, timeLabel: m.timeLabel);
                    case _MsgType.ai:
                      return _AIBubble(message: m.text, timeLabel: m.timeLabel);
                    case _MsgType.correction:
                      return _CorrectionBubble(
                          message: m.text, timeLabel: m.timeLabel);
                  }
                },
              ),
            ),

            // Suggestions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SuggestChip(
                    icon: Icons.help_outline_rounded,
                    label: 'Explain',
                    onTap: () => _insertHint('Explain'),
                  ),
                  _SuggestChip(
                    icon: Icons.refresh_rounded,
                    label: 'Paraphrase',
                    onTap: () => _insertHint('Paraphrase'),
                  ),
                  _SuggestChip(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Give examples',
                    onTap: () => _insertHint('Give examples'),
                  ),
                ],
              ),
            ),

            // Composer
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16,
                  8 + MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Type your response...',
                        suffixIcon: IconButton(
                          tooltip: 'Voice input',
                          icon: const Icon(Icons.mic_rounded, size: 20),
                          onPressed: () {
                            // TODO: implement voice input
                          },
                        ),
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FloatingActionButton(
                      heroTag: 'send',
                      elevation: 0,
                      onPressed: _send,
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Models =====
enum _MsgType { ai, user, correction }

class _ChatMessage {
  final _MsgType type;
  final String text;
  final String timeLabel;

  const _ChatMessage(this.type, this.text, {required this.timeLabel});

  factory _ChatMessage.ai(String text, {required String timeLabel}) =>
      _ChatMessage(_MsgType.ai, text, timeLabel: timeLabel);

  factory _ChatMessage.user(String text, {required String timeLabel}) =>
      _ChatMessage(_MsgType.user, text, timeLabel: timeLabel);

  factory _ChatMessage.correction(String text, {required String timeLabel}) =>
      _ChatMessage(_MsgType.correction, text, timeLabel: timeLabel);
}

// ===== UI Pieces =====

class _AIBubble extends StatelessWidget {
  const _AIBubble({required this.message, required this.timeLabel});
  final String message;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.secondary,
              child: Icon(Icons.psychology_rounded, color: cs.onPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  message,
                  style: txt.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              timeLabel,
              style: txt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.timeLabel});
  final String message;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  message,
                  style: txt.bodyMedium?.copyWith(
                    height: 1.4,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.tertiary,
              child: Icon(Icons.person_rounded, color: cs.onPrimary, size: 20),
            ),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 52),
            child: Text(
              timeLabel,
              style: txt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionBubble extends StatelessWidget {
  const _CorrectionBubble({required this.message, required this.timeLabel});
  final String message;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.tertiary,
              child: Icon(Icons.edit_rounded, color: cs.onPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.tertiary, width: 1),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  message,
                  style: txt.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              timeLabel,
              style: txt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestChip extends StatelessWidget {
  const _SuggestChip({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Material(
      color: cs.primary.withOpacity(.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: txt.bodySmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
