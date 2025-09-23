import 'package:flutter/material.dart';

class ListeningListPage extends StatelessWidget {
  const ListeningListPage({super.key});

  static const routeName = 'ListeningListPage';
  static const routePath = '/listening-list';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: Text('Listening Exercises', style: text.headlineMedium),
        actions: [
          IconButton(
            onPressed: () {}, // TODO: mở màn hình bộ lọc nâng cao
            icon: const Icon(Icons.tune_rounded),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                readOnly: true, // UI only
                decoration: InputDecoration(
                  hintText: 'Search lesson, topic, or code…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: scheme.surfaceVariant.withOpacity(.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onTap: () {
                  // TODO: mở search page
                },
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _FilterRow(
                filters: const ['All', 'Beginner', 'Intermediate', 'Advanced'],
                selectedIndex: 0, // UI only
                onSelected: (_) {}, // TODO
              ),
            ),

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: _mockItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _ListeningCard(item: _mockItems[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Card cho từng bài listening (UI only)
class _ListeningCard extends StatelessWidget {
  const _ListeningCard({required this.item});
  final _ListeningItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Color(0x1A000000), offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail/icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.headset_rounded),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + code
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.code, style: text.bodySmall?.copyWith(color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: -6,
                  children: [
                    const _Tag(label: 'Listening', filled: true),
                    _Tag(label: 'Cues: ${item.totalCues}'),
                    _Tag(label: 'Level: ${item.level}'),
                    if (item.minutes != null) _Tag(label: '${item.minutes} min'),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.progress).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: scheme.surfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.totalCues == 0
                      ? 'Not started'
                      : 'Progress: ${(item.progress * 100).toStringAsFixed(0)}% • WER avg: ${((item.avgWer ?? 0) * 100).toStringAsFixed(0)}%',
                  style: text.bodySmall?.copyWith(color: Colors.black54),
                ),

                if (item.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: null, // UI only, chưa gắn sự kiện
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Start'),
              ),
              const SizedBox(height: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.black45),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Filter chips hàng ngang (UI only)
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i == filters.length - 1 ? 0 : 8),
            child: ChoiceChip(
              label: Text(filters[i]),
              selected: selected,
              onSelected: (_) => onSelected(i), // UI only
              selectedColor: scheme.primary,
              labelStyle: TextStyle(color: selected ? scheme.onPrimary : null),
              backgroundColor: scheme.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Tag nhỏ
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

/// ─────────────────────────────────────────────────────────────────────────
/// Mock data dùng để vẽ UI
class _ListeningItem {
  _ListeningItem({
    required this.title,
    required this.code,
    required this.level,
    required this.totalCues,
    this.minutes,
    this.description,
    this.progress = 0,
    this.avgWer,
  });

  final String title;
  final String code;
  final String level; // Beginner / Intermediate / Advanced
  final int totalCues;
  final int? minutes;
  final String? description;
  final double progress; // 0..1
  final double? avgWer;
}

final _mockItems = <_ListeningItem>[
  _ListeningItem(
    title: 'Wake-up Call',
    code: 'p1_wakeup',
    level: 'Beginner',
    totalCues: 12,
    minutes: 4,
    description: 'Daily conversation at home. Dictation mode.',
    progress: 0.35,
    avgWer: 0.22,
  ),
  _ListeningItem(
    title: 'Ordering Office Supplies',
    code: 'p3_002',
    level: 'Intermediate',
    totalCues: 8,
    minutes: 3,
    description: 'Office small talk about supplies and ordering.',
    progress: 0.6,
    avgWer: 0.18,
  ),
  _ListeningItem(
    title: 'Airport Gate Announcement',
    code: 'p4_001',
    level: 'Intermediate',
    totalCues: 6,
    minutes: 2,
    description: 'Public announcement at the airport. Part 4 vibe.',
    progress: 0.0,
    avgWer: null,
  ),
  _ListeningItem(
    title: 'Team Stand-up Meeting',
    code: 'p3_110',
    level: 'Advanced',
    totalCues: 10,
    minutes: 5,
    description: 'Engineering stand-up, quick updates, action items.',
    progress: 0.8,
    avgWer: 0.12,
  ),
];
