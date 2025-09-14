import 'package:flutter/material.dart';

class ReadingPage extends StatelessWidget {
  const ReadingPage({super.key});

  static const String routeName = 'ReadingPage';
  static const String routePath = '/reading';

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
        title: Text('Reading Skills', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            // Header gradient
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                  begin: const Alignment(1, -1),
                  end: const Alignment(-1, 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: text.bodyMedium!.copyWith(color: scheme.onPrimary),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reading Skills',
                              style: text.headlineMedium?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 4),
                          Text('Improve comprehension and vocabulary'),
                          const SizedBox(height: 8),
                          Row(children: [
                            _Pill(label: 'Level 3', color: scheme.onPrimary.withOpacity(.3), fg: scheme.onPrimary),
                            const SizedBox(width: 8),
                            Text('Reading Speed: 145 WPM'),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.menu_book_outlined, color: scheme.onPrimary, size: 48),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // BEGINNER
            _ReadingItem(
              levelText: 'BEGINNER LEVEL',
              levelColor: Colors.green,
              title: 'The Magic Garden',
              summary: "A young girl discovers a hidden garden behind her grandmother's house...",
              minutes: 3,
              questions: 5,
              trailingIcon: Icons.eco_rounded,
              actionText: 'Start',
              onAction: () {
                // TODO: Navigator.pushNamed(context, '/reading/detail', arguments: ...);
              },
            ),

            // INTERMEDIATE
            _ReadingItem(
              levelText: 'INTERMEDIATE LEVEL',
              levelColor: Colors.orange,
              title: 'Climate Change Solutions',
              summary:
              'Scientists around the world are working on innovative ways to combat climate change...',
              minutes: 5,
              questions: 8,
              trailingIcon: Icons.public_rounded,
              actionText: 'Start',
              onAction: () {},
            ),

            // ADVANCED (completed)
            _ReadingItem(
              levelText: 'ADVANCED LEVEL',
              levelColor: Colors.redAccent,
              title: 'Artificial Intelligence Ethics',
              summary:
              'As AI becomes more prevalent in society, ethical considerations become increasingly important...',
              minutes: 7,
              questions: null, // dùng score thay cho câu hỏi
              trailingIcon: Icons.memory_rounded,
              actionText: 'Review',
              actionFilled: false,
              badgeText: 'COMPLETED',
              scoreText: 'Score: 92%',
              onAction: () {},
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Reusable widgets =====

class _ReadingItem extends StatelessWidget {
  const _ReadingItem({
    required this.levelText,
    required this.levelColor,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.trailingIcon,
    required this.actionText,
    required this.onAction,
    this.questions,
    this.actionFilled = true,
    this.badgeText,
    this.scoreText,
  });

  final String levelText;
  final Color levelColor;
  final String title;
  final String summary;
  final int minutes;
  final int? questions;
  final IconData trailingIcon;
  final String actionText;
  final VoidCallback onAction;
  final bool actionFilled;
  final String? badgeText;
  final String? scoreText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x1A000000), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(levelText,
                        style: text.labelSmall?.copyWith(
                          color: levelColor,
                          fontWeight: FontWeight.w700,
                        )),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      _Pill(label: badgeText!, color: scheme.secondary.withOpacity(.2), fg: scheme.onSurface, small: true),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                ]),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(trailingIcon, color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // meta + action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(children: [
                    Icon(Icons.schedule_rounded, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('$minutes min read', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ]),
                  if (questions != null)
                    Row(children: [
                      Icon(Icons.quiz_rounded, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('$questions questions', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ]),
                  if (scoreText != null)
                    Row(children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(scoreText!, style: text.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
                    ]),
                ],
              ),
              SizedBox(
                height: 32,
                child: actionFilled
                    ? ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(actionText, style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                )
                    : OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(actionText, style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.fg, this.small = false});
  final String label;
  final Color color;
  final Color fg;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: small ? 20 : 24,
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: fg,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
