import 'package:english_for_community/feature/gamification_notifications_page.dart';
import 'package:english_for_community/feature/profile_page.dart';
import 'package:english_for_community/feature/progress_report_page.dart';
import 'package:english_for_community/feature/vocabulary_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final pages = [
      _HomeTab(),
      ProgressReportPage(),
      GamificationNotificationPage(),
      ProfilePage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: 'Vocabulary'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  _HomeTab();
  
  // Add state variable to track if "View all" is pressed
  final ValueNotifier<bool> _showAllLessons = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Good morning!', style: text.headlineMedium),
                const SizedBox(height: 4),
                Text('Ready to continue learning?', style: text.bodyMedium!.copyWith(color: Colors.black54)),
              ]),
              const CircleAvatar(radius: 25, backgroundImage: AssetImage('assets/avatar.png')),
            ],
          ),
          const SizedBox(height: 20),

          // Daily Goal card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Daily Goal', style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text('3 of 5 lessons completed', style: text.bodySmall!.copyWith(color: Colors.black54)),
                  ]),
                  const Text('🏆', style: TextStyle(fontSize: 28)),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: const [
              Expanded(child: _StatCard(emoji: '🔥', value: '12', label: 'Day streak')),
              SizedBox(width: 12),
              Expanded(child: _StatCard(emoji: '⭐', value: '2,450', label: 'Total points')),
              SizedBox(width: 12),
              Expanded(child: _StatCard(emoji: '📚', value: 'Level 8', label: 'Current')),
            ],
          ),
          const SizedBox(height: 16),

          // Today's Lessons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Text("Today's Lessons", style: text.titleLarge),
              GestureDetector(
                onTap: () {
                  _showAllLessons.value = !_showAllLessons.value;
                },
                child: Text(
                  'View all', 
                  style: text.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ]
          ),
          const SizedBox(height: 12),
          
          // Lessons list with ValueListenableBuilder to update when view all is pressed
          ValueListenableBuilder<bool>(
            valueListenable: _showAllLessons,
            builder: (context, showAll, child) {
              return Column(
                children: [
                  const _LessonTile(
                    icon: Icons.headphones, iconBg: Color(0xFFE8F5E9), iconColor: Color(0xFF2E7D32),
                    title: 'Listening Practice', subtitle: 'Daily conversations • 15 min', pillColor: Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 8),
                  const _LessonTile(
                    icon: Icons.menu_book, iconBg: Color(0xFFFFF8E1), iconColor: Color(0xFFF9A825),
                    title: 'Reading Comprehension', subtitle: 'Short stories • 20 min', pillColor: Color(0xFFF9A825),
                  ),
                  const SizedBox(height: 8),
                  const _LessonTile(
                    icon: Icons.quiz, iconBg: Color(0xFFE3F2FD), iconColor: Color(0xFF1976D2),
                    title: 'Vocabulary Builder', subtitle: 'New words • 10 min', pillColor: Color(0xFF1976D2),
                  ),
                  
                  // Show speaking lesson only when "View all" is pressed
                  if (showAll) ...[
                    const SizedBox(height: 8),
                    const _LessonTile(
                      icon: Icons.record_voice_over, iconBg: Color(0xFFFCE4EC), iconColor: Color(0xFFD81B60),
                      title: 'Speaking Practice', subtitle: 'Pronunciation • 25 min', pillColor: Color(0xFFD81B60),
                    ),
                    // Animation for the new item
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      color: Colors.transparent,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Quick Actions
          Text('Quick Actions', style: text.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _QuickAction(colorBg: Color(0xFFF3E8FF), icon: Icons.favorite, iconColor: Color(0xFFA855F7), title: 'Favorites', subtitle: '46 words'),
              _QuickAction(colorBg: Color(0xFFF0FDF4), icon: Icons.style, iconColor: Color(0xFF22C55E), title: 'Flashcards', subtitle: 'Study mode'),
              _QuickAction(colorBg: Color(0xFFFEF2F2), icon: Icons.trending_up, iconColor: Color(0xFFEF4444), title: 'Progress', subtitle: 'Statistics'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x1A000000), offset: Offset(0,2))],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.emoji, required this.value, required this.label});
  final String emoji, value, label;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Card(
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(value, style: text.headlineSmall),
        const SizedBox(height: 4),
        Text(label, style: text.bodySmall!.copyWith(color: Colors.black54)),
      ]),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.pillColor,
  });
  final IconData icon; final Color iconBg; final Color iconColor;
  final String title; final String subtitle; final Color pillColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        // Navigate to the corresponding skill page based on title
        if (title == 'Listening Practice') {
          context.pushNamed('ListeningSkillsPage');
        } else if (title == 'Reading Comprehension') {
          context.pushNamed('ReadingPage');
        } else if (title == 'Vocabulary Builder') {
          context.pushNamed('TvngvSpacedRepetitionPage');
        } else if (title == 'Speaking Practice') {
          context.pushNamed('SpeakingSkillsPage');
        }
      },
      child: _Card(
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: text.bodyMedium!.copyWith(color: Colors.black54)),
          ])),
          Icon(Icons.play_circle_fill, color: pillColor),
        ]),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.colorBg, required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
  });
  final Color colorBg, iconColor;
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(children: [
      Container(
        width: 60, height: 60, decoration: BoxDecoration(color: colorBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 28),
      ),
      const SizedBox(height: 6),
      Text(title, style: text.bodySmall!.copyWith(fontWeight: FontWeight.w500)),
      Text(subtitle, style: text.bodySmall!.copyWith(fontSize: 10, color: Colors.black54)),
    ]);
  }
}
