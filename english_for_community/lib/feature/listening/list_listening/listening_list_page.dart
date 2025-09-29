import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';

import 'bloc/listening_bloc.dart';
import 'bloc/listening_event.dart';
import 'bloc/listening_state.dart';

class ListeningListPage extends StatefulWidget {
  const ListeningListPage({super.key});

  static const routeName = 'ListeningListPage';
  static const routePath = '/listening-list';

  @override
  State<ListeningListPage> createState() => _ListeningListPageState();
}

class _ListeningListPageState extends State<ListeningListPage> {
  @override
  void initState() {
    super.initState();
    // gọi lấy danh sách ngay khi vào trang
    context.read<ListeningBloc>().add(GetListListeningEvent());
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
        title: Text('Listening Exercises', style: text.headlineMedium),
        actions: [
          IconButton(
            onPressed: () { /* TODO: mở bộ lọc nâng cao */ },
            icon: const Icon(Icons.tune_rounded),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search box (UI only demo)
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
                onTap: () { /* TODO: mở trang search */ },
              ),
            ),

            // Filter chips (UI only demo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _FilterRow(
                filters: const ['All', 'Beginner', 'Intermediate', 'Advanced'],
                selectedIndex: 0,
                onSelected: (_) {
                  // TODO: phát event lọc (ví dụ: level -> beginner/intermediate/advanced)
                  // context.read<ListeningBloc>().add(GetListListeningEventFiltered(level: ...));
                },
              ),
            ),

            // List content theo state
            Expanded(
              child: BlocBuilder<ListeningBloc, ListeningState>(
                builder: (context, state) {
                  switch (state.status) {
                    case ListeningStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case ListeningStatus.error:
                      return _ErrorView(
                        message: state.errorMessage ?? 'Something went wrong',
                        onRetry: () => context.read<ListeningBloc>().add(GetListListeningEvent()),
                      );
                    case ListeningStatus.success:
                      final items = state.listListeningEntity ?? const <ListeningEntity>[];
                      if (items.isEmpty) {
                        return const _EmptyView();
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ListeningBloc>().add(GetListListeningEvent());
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => _ListeningCard(entity: items[i]),
                        ),
                      );
                    case ListeningStatus.initial:
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Card map từ ListeningEntity (lessonId là OBJECT LessonEntity)
class _ListeningCard extends StatelessWidget {
  const _ListeningCard({required this.entity});
  final ListeningEntity entity;

  String _difficultyLabel(ListeningDifficulty? d) {
    switch (d) {
      case ListeningDifficulty.easy: return 'Beginner';
      case ListeningDifficulty.medium: return 'Intermediate';
      case ListeningDifficulty.hard: return 'Advanced';
      default: return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final title = entity.title;
    final code = entity.code ?? '';
    final totalCues = entity.totalCues ?? 0;
    final level = _difficultyLabel(entity.difficulty);
    final lessonName = entity.lessonId.name; // vì lessonId là LessonEntity
    // Bạn có thể show progress thật nếu BE trả, hiện demo 0
    final progress = 0.0;
    final avgWer = null as double?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x1A000000), offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Thumbnail/icon
          Container(
            width: 56, height: 56,
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
                        title,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (code.isNotEmpty)
                      Text(code, style: text.bodySmall?.copyWith(color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: -6,
                  children: [
                    const _Tag(label: 'Listening', filled: true),
                    if (lessonName.isNotEmpty) _Tag(label: lessonName),
                    _Tag(label: 'Cues: $totalCues'),
                    _Tag(label: 'Level: $level'),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress (demo 0%)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: scheme.surfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalCues == 0
                      ? 'Not started'
                      : 'Progress: ${(progress * 100).toStringAsFixed(0)}% • WER avg: ${((avgWer ?? 0) * 100).toStringAsFixed(0)}%',
                  style: text.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: điều hướng sang trang Listening Detail, truyền entity (hoặc id)
                  // Navigator.pushNamed(context, ListeningDetailPage.routePath, arguments: entity.id);
                },
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
              onSelected: (_) => onSelected(i),
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
/// Empty & Error views
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No listenings found'),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
