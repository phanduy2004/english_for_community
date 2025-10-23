import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';

import '../listening_skill/listening_skills_page.dart';
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return BlocProvider<ListeningBloc>(
      create: (context) => getIt<ListeningBloc>()..add(GetListListeningEvent()),
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          elevation: 0,
          title: Text('Listening Exercises', style: text.headlineMedium),
          actions: [
            IconButton(
              onPressed: () {/* TODO: mở bộ lọc nâng cao */},
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
                  onTap: () {/* TODO: mở trang search */},
                ),
              ),

              // Filter chips (UI only demo)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _FilterRow(
                  filters: const ['All', 'Beginner', 'Intermediate', 'Advanced'],
                  selectedIndex: 0,
                  onSelected: (_) {
                    // TODO: phát event lọc
                    // context.read<ListeningBloc>().add(GetListListeningEventFiltered(level: ...));
                  },
                ),
              ),

              // Nội dung theo state
              Expanded(
                child: BlocBuilder<ListeningBloc, ListeningState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case ListeningStatus.loading:
                        return const Center(child: CircularProgressIndicator());

                      case ListeningStatus.error:
                        return _ErrorView(
                          message: state.errorMessage ?? 'Something went wrong',
                          onRetry: () => context
                              .read<ListeningBloc>()
                              .add(GetListListeningEvent()),
                        );

                      case ListeningStatus.success:
                        final items =
                            state.listListeningEntity ?? const <ListeningEntity>[];
                        if (items.isEmpty) return const _EmptyView();

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
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Card map từ ListeningEntity (lessonId là OBJECT LessonEntity)
/// ─────────────────────────────────────────────────────────────────────────
/// Card gọn, an toàn tràn: icon | nội dung | nút
class _ListeningCard extends StatelessWidget {
  const _ListeningCard({required this.entity});
  final ListeningEntity entity;

  String _difficultyLabel(ListeningDifficulty? d) {
    switch (d) {
      case ListeningDifficulty.easy:   return 'Beginner';
      case ListeningDifficulty.medium: return 'Intermediate';
      case ListeningDifficulty.hard:   return 'Advanced';
      default: return '—';
    }
  }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final title     = entity.title;
    final totalCues = entity.totalCues ?? 0;
    final level     = _difficultyLabel(entity.difficulty);
    final lesson    = entity.lessonId?.name ?? '';

    final progress = entity.userProgress; // <-- SỬA Ở ĐÂY
    const double? avgWer = null; // (Bạn có thể tính avgWer ở backend nếu muốn)
    return Material(
      color: cs.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon trái
            Container(
              width: 48, height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.headset_rounded),
            ),
            const SizedBox(width: 12),

            // nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: [
                      const _Tag(label: 'Listening', filled: true),
                      if (lesson.isNotEmpty) _Tag(label: lesson),
                      _Tag(label: 'Cues: $totalCues'),
                      _Tag(label: 'Level: $level'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress, // <-- Giờ nó sẽ dùng giá trị thật
                      minHeight: 6, backgroundColor: cs.surfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalCues == 0
                        ? 'Not started'
                        : 'Progress: ${(progress * 100).toStringAsFixed(0)}% • WER avg: ${((avgWer ?? 0) * 100).toStringAsFixed(0)}%', // <-- Tự động cập nhật
                    style: tt.bodySmall?.copyWith(color: Colors.black54),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // cột nút
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 84, maxWidth: 92),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async { // <-- 1. Thêm async
                        // Điều hướng sang trang làm bài, truyền id + audioUrl + metadata
                        await Navigator.of(context).push( // <-- 2. Thêm await
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<ListeningBloc>(),
                              child: ListeningSkillsPage(
                                listeningId: entity.id,
                                title: entity.title,
                                levelText: _difficultyLabel(entity.difficulty),
                                audioUrl: entity.audioUrl,
                              ),
                            ),
                          ),
                        );

                        // 3. SAU KHI QUAY LẠI: Phát event để tải lại danh sách
                        if (context.mounted) {
                          context.read<ListeningBloc>().add(GetListListeningEvent());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Start'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black45, size: 20),
                ],
              ),
            ),
          ],
        ),
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
    return const Center(child: Text('No listenings found'));
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
