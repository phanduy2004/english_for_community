import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GamificationNotificationPage extends StatefulWidget {
  const GamificationNotificationPage({super.key});

  static String routeName = 'GamificationNotificationPage';
  static String routePath = '/gamification';

  @override
  State<GamificationNotificationPage> createState() =>
      _GamificationNotificationPageState();
}

class _GamificationNotificationPageState
    extends State<GamificationNotificationPage> {
  // State
  bool _smartReminders = true;
  bool _dailyReview = true;
  bool _goalCompletion = true;
  bool _streakMotivation = false;

  String _leaderboardRange = 'This Week';

  // Actions (đổi theo route thực tế nếu cần)
  void _openSettings() => context.pushNamed('NotificationSettingsPage');
  void _viewAllBadges() => context.pushNamed('AllBadgesPage');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text('Progress & Rewards',
            style: txt.headlineLarge?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.settings, color: cs.onBackground),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // Header gradient
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  height: 200,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + subtitle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Progress',
                                style: txt.headlineMedium?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 8),
                            Text(
                              "Keep up the great work! You're on a 7-day streak.",
                              style: txt.bodyMedium?.copyWith(
                                color: cs.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _HeaderStat(
                              value: '127',
                              label: 'XP Today',
                              color: cs.onPrimary,
                            ),
                            _HeaderStat(
                              value: '7',
                              label: 'Day Streak',
                              color: cs.onPrimary,
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.local_fire_department,
                                  color: cs.onPrimary, size: 32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Achievements
              _SectionCard(
                title: 'Achievements',
                trailing: InkWell(
                  onTap: _viewAllBadges,
                  child: Text('View All',
                      style: txt.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                child: GridView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  primary: false,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  children: const [
                    _BadgeItem(
                      title: 'First Steps',
                      gradient: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      icon: Icons.emoji_events,
                      unlocked: true,
                    ),
                    _BadgeItem(
                      title: 'Scholar',
                      gradient: [Color(0xFFC0C0C0), Color(0xFF808080)],
                      icon: Icons.school,
                      unlocked: true,
                    ),
                    _BadgeItem(
                      title: 'Speed Demon',
                      gradient: null,
                      icon: Icons.speed,
                      unlocked: false,
                    ),
                    _BadgeItem(
                      title: 'Memory Master',
                      gradient: null,
                      icon: Icons.psychology,
                      unlocked: false,
                    ),
                  ],
                ),
              ),

              // Leaderboard
              _SectionCard(
                title: 'Leaderboard',
                trailing: _RangeDropdown(
                  value: _leaderboardRange,
                  items: const ['This Week', 'This Month', 'All Time'],
                  onChanged: (v) => setState(() => _leaderboardRange = v!),
                ),
                child: Column(
                  children: [
                    _LeaderRow(
                      rank: 1,
                      name: 'You',
                      group: 'Advanced Spanish',
                      xp: '2,847 XP',
                      highlight: true,
                      chipColor: const Color(0xFFFFD700),
                    ),
                    const SizedBox(height: 8),
                    _LeaderRow(
                      rank: 2,
                      name: 'Maria Rodriguez',
                      group: 'Advanced Spanish',
                      xp: '2,654 XP',
                      chipColor: const Color(0xFFC0C0C0),
                    ),
                    const SizedBox(height: 8),
                    _LeaderRow(
                      rank: 3,
                      name: 'James Chen',
                      group: 'Advanced Spanish',
                      xp: '2,431 XP',
                      chipColor: const Color(0xFFCD7F32),
                    ),
                  ],
                ),
              ),

              // Smart Reminders
              _SectionCard(
                title: 'Smart Reminders',
                trailing: Switch(
                  value: _smartReminders,
                  onChanged: (v) => setState(() => _smartReminders = v),
                  activeColor: cs.primary,
                ),
                description:
                    'Get personalized notifications to help you stay on track with your learning goals.',
                child: Column(
                  children: [
                    _ReminderRow(
                      icon: Icons.schedule,
                      title: 'Daily Review Reminder',
                      value: _dailyReview,
                      onChanged: (v) => setState(() => _dailyReview = v),
                    ),
                    const SizedBox(height: 8),
                    _ReminderRow(
                      icon: Icons.assignment,
                      title: 'Goal Completion',
                      value: _goalCompletion,
                      onChanged: (v) => setState(() => _goalCompletion = v),
                    ),
                    const SizedBox(height: 8),
                    _ReminderRow(
                      icon: Icons.favorite,
                      title: 'Streak Motivation',
                      value: _streakMotivation,
                      onChanged: (v) => setState(() => _streakMotivation = v),
                    ),
                  ],
                ),
              ),

              // Recent Notifications
              _SectionCard(
                title: 'Recent Notifications',
                child: Column(
                  children: const [
                    _NotificationTile(
                      iconBgOpacity: .15,
                      icon: Icons.schedule,
                      title: 'Time for your daily review!',
                      subtitle: '15 vocabulary words are ready for review',
                      time: '2 hours ago',
                    ),
                    SizedBox(height: 8),
                    _NotificationTile(
                      iconBgOpacity: .15,
                      icon: Icons.emoji_events,
                      title: 'Achievement unlocked!',
                      subtitle:
                          "You've earned the 'Scholar' badge for completing 50 lessons",
                      time: 'Yesterday',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Reusable pieces =====

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final txt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
            style: txt.displaySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            )),
        Text(label,
            style: txt.labelMedium?.copyWith(
              color: color,
            )),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.trailing,
    this.description,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: txt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description!,
                    style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.title,
    required this.icon,
    required this.unlocked,
    this.gradient,
  });

  final String title;
  final IconData icon;
  final bool unlocked;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    final circle = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked && gradient != null
            ? LinearGradient(
                colors: gradient!,
                begin: const Alignment(1, -1),
                end: const Alignment(-1, 1),
              )
            : null,
        color: !unlocked ? cs.surfaceVariant : null,
      ),
      child: Icon(
        icon,
        size: 28,
        color: unlocked ? Colors.white : cs.onSurfaceVariant,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(opacity: unlocked ? 1 : 0.5, child: circle),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: txt.bodySmall?.copyWith(
            fontSize: 10,
            color: unlocked ? cs.onSurface : cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RangeDropdown extends StatelessWidget {
  const _RangeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurface, size: 18),
          style: txt.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.group,
    required this.xp,
    this.highlight = false,
    required this.chipColor,
  });

  final int rank;
  final String name;
  final String group;
  final String xp;
  final bool highlight;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: highlight ? cs.tertiaryContainer.withOpacity(.35) : cs.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank chip
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: txt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rank == 3 ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1696778089330-48995c755358?auto=format&fit=crop&w=80&q=60'),
            ),
            const SizedBox(width: 12),
            // Name + group
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: txt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(group, style: txt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // XP
            Text(
              xp,
              style: txt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? cs.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Text(title, style: txt.bodyMedium),
        ]),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: cs.primary,
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    this.iconBgOpacity = .15,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final double iconBgOpacity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(iconBgOpacity),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: txt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: txt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: txt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
