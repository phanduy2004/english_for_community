// feature/writing/bloc/writing_topics_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_event.dart';
import 'package:english_for_community/feature/writing/bloc/writing_state.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';

class WritingTopicsPage extends StatefulWidget {
  const WritingTopicsPage({super.key});

  static const routeName = 'WritingTopicsPage';
  static const routePath = '/writing-topics';

  @override
  State<WritingTopicsPage> createState() => _WritingTopicsPageState();
}

class _WritingTopicsPageState extends State<WritingTopicsPage> {
  final _filters = const ['By Topic', 'By Essay Type'];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // gọi API lấy topics
    context.read<WritingBloc>().add(GetWritingTopicsEvent());
  }

  void _onSearchTap() {
    // TODO: mở trang search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open search page…')),
    );
  }

  void _onCardTap(WritingTopicEntity item) {
    // TODO: điều hướng sang màn “Start writing” cho topic item.id
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open "${item.name}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Writing Topics')),
      body: SafeArea(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                readOnly: true,
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
                onTap: _onSearchTap,
              ),
            ),
            const SizedBox(height: 10),

            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _FilterRow(
                filters: _filters,
                selectedIndex: _selectedIndex,
                onSelected: (i) {
                  setState(() => _selectedIndex = i);
                  // TODO: phát event lọc nếu cần (theo Essay Type/Topic)
                },
              ),
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: BlocBuilder<WritingBloc, WritingState>(
                builder: (context, state) {
                  if (state.status == WritingStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == WritingStatus.error) {

                  }

                  final topics = state.topics;
                  if (topics.isEmpty) {
                    return const Center(child: Text('No topics yet'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<WritingBloc>().add(GetWritingTopicsEvent());
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: topics.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final t = topics[i];
                        final tags = _buildTagsFromTopic(t);
                        final icon = _iconFromString(t.icon);
                        return WritingCard(
                          title: t.name,
                          tags: tags,
                          leadingIcon: icon,
                          onTap: () => _onCardTap(t),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tạo danh sách chip tag từ dữ liệu topic (aiConfig/stats)
  List<String> _buildTagsFromTopic(WritingTopicEntity t) {
    final tags = <String>[];
    if (t.aiConfig?.defaultTaskType != null) {
      tags.add(t.aiConfig!.defaultTaskType!); // ví dụ: Discuss both views...
    }
    if (t.aiConfig?.level != null) {
      tags.add(t.aiConfig!.level!); // Intermediate/Advanced...
    }
    if ((t.stats?.submissionsCount ?? 0) > 0) {
      tags.add('${t.stats!.submissionsCount} submissions');
    }
    if (t.stats?.avgScore != null) {
      tags.add('Avg ${t.stats!.avgScore!.toStringAsFixed(1)}');
    }
    return tags;
  }

  // Map string icon từ backend -> IconData Material
  IconData _iconFromString(String? name) {
    switch (name) {
      case 'brush':
        return Icons.brush_rounded;
      case 'memory':
        return Icons.memory_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'public':
        return Icons.public_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'diversity_3':
        return Icons.diversity_3_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'location_city':
        return Icons.location_city_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'family_restroom':
        return Icons.family_restroom_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      default:
        return Icons.library_books_rounded;
    }
  }
}

/// Row filter chips (horizontal)
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
              onSelected: (_) => onSelected(i),
              selectedColor: scheme.primary,
              labelStyle: TextStyle(color: selected ? scheme.onPrimary : null),
              backgroundColor: scheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Card chủ đề viết (giữ nguyên như bạn đã có)
class WritingCard extends StatelessWidget {
  const WritingCard({
    super.key,
    required this.title,
    required this.tags,
    this.leadingIcon = Icons.library_books_rounded,
    this.onTap,
  });

  final String title;
  final List<String> tags;
  final IconData leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon trái
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),

              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags
                          .map(
                            (t) => _TagChip(
                          text: t,
                          background: scheme.primary.withOpacity(.12),
                          foreground: scheme.primary,
                        ),
                      )
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
