import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:english_for_community/feature/listening_comp/bloc_list/listening_comp_list_event.dart';
import 'package:english_for_community/feature/listening_comp/bloc_list/listening_comp_list_state.dart';

import '../../core/entity/listening_comp_entity.dart';
import 'bloc_list/listening_comp_list_bloc.dart';

class ListeningCompListPage extends StatefulWidget {
  const ListeningCompListPage({super.key});

  static const routeName = 'ListeningCompListPage';
  static const routePath = '/listening-comp-list';

  @override
  State<ListeningCompListPage> createState() => _ListeningCompListPageState();
}

class _ListeningCompListPageState extends State<ListeningCompListPage> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = const ['Beginner', 'Intermediate', 'Advanced'];

  String _getDifficultyForIndex(int index) {
    switch (_filters[index]) {
      case 'Beginner': return 'easy';
      case 'Intermediate': return 'medium';
      case 'Advanced': return 'hard';
      default: return 'easy';
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocProvider<ListeningCompListBloc>(
      create: (_) => getIt<ListeningCompListBloc>()
        ..add(FetchListeningCompList(difficulty: _getDifficultyForIndex(_selectedFilterIndex))),
      child: Builder(
        builder: (context) {
          void refreshList() {
            final difficulty = _getDifficultyForIndex(_selectedFilterIndex);
            context.read<ListeningCompListBloc>().add(FetchListeningCompList(difficulty: difficulty));
          }

          return Scaffold(
            backgroundColor: bgPage,
            appBar: AppBar(
              backgroundColor: bgPage,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: textMain),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Listening Comprehension',
                style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 17),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        clipBehavior: Clip.none,
                        children: [
                          const SizedBox(height: 8),
                          _buildHeader(context),
                          const SizedBox(height: 20),
                          _buildSearchBox(context, primaryColor),
                          const SizedBox(height: 16),
                          _FilterRow(
                            filters: _filters,
                            selectedIndex: _selectedFilterIndex,
                            primaryColor: primaryColor,
                            onSelected: (i) {
                              setState(() => _selectedFilterIndex = i);
                              context.read<ListeningCompListBloc>().add(
                                FetchListeningCompList(difficulty: _getDifficultyForIndex(i)),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          BlocBuilder<ListeningCompListBloc, ListeningCompListState>(
                            builder: (context, state) {
                              if (state.status == CompListStatus.loading) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              }
                              if (state.status == CompListStatus.error) {
                                return _ErrorView(
                                  message: state.errorMessage ?? 'Something went wrong',
                                  onRetry: refreshList,
                                );
                              }

                              final items = state.listData;
                              if (items.isEmpty && state.status == CompListStatus.success) {
                                return const _EmptyView();
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) => _ListeningCompCard(
                                  entity: items[index],
                                  primaryColor: primaryColor,
                                  onLessonFinished: refreshList,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF18181B), Color(0xFF27272A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listening Comprehension',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Listen to the audio and answer multiple choice questions.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.quiz_outlined, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context, Color primaryColor) {
    const borderColor = Color(0xFFE4E4E7);
    const textMuted = Color(0xFF71717A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        readOnly: true,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search topics, IDs...',
          hintStyle: const TextStyle(fontSize: 14, color: textMuted),
          prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
        ),
      ),
    );
  }
}

class _ListeningCompCard extends StatelessWidget {
  const _ListeningCompCard({
    required this.entity,
    required this.primaryColor,
    this.onLessonFinished,
  });

  final ListeningCompEntity entity;
  final Color primaryColor;
  final VoidCallback? onLessonFinished;

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFE4E4E7);

    final levelText = entity.difficulty == 'hard' ? 'Advanced' : (entity.difficulty == 'medium' ? 'Intermediate' : 'Beginner');
    final levelColor = entity.difficulty == 'hard' ? const Color(0xFFDC2626) : (entity.difficulty == 'medium' ? const Color(0xFFEA580C) : const Color(0xFF16A34A));

    final bool isCompleted = entity.userProgress >= 1.0;
    final int score = entity.highScore;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handlePress(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Badge(label: levelText, color: levelColor),
                              if (isCompleted) ...[
                                const SizedBox(width: 8),
                                const _Badge(label: 'Completed', color: Color(0xFF059669), filled: true, bgColor: Color(0xFFECFDF5)),
                              ]
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entity.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain, height: 1.3),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.format_list_bulleted, size: 14, color: textMuted),
                              const SizedBox(width: 4),
                              Text('${entity.totalQuestions} questions', style: const TextStyle(fontSize: 13, color: textMuted)),                              const SizedBox(width: 12),
                              const Icon(Icons.timer_outlined, size: 14, color: textMuted),
                              const SizedBox(width: 4),
                              Text('${entity.minutesToComplete} min', style: const TextStyle(fontSize: 13, color: textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.play_arrow_rounded, color: primaryColor, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: isCompleted
                          ? Text('High Score: $score%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green))
                          : const Text('Not started yet', style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic)),
                    ),
                    SizedBox(
                      height: 32,
                      child: isCompleted
                          ? OutlinedButton(
                        onPressed: () => _handlePress(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      )
                          : ElevatedButton(
                        onPressed: () => _handlePress(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Start', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePress(BuildContext context) async {
    // 🔥 ĐÃ FIX: Điều hướng sang trang làm bài
    await context.pushNamed(
      'ListeningCompPage', // Tên route này phải giống với name khai báo trong app_router.dart
      pathParameters: {'id': entity.id},
    );

    // Refresh lại trạng thái danh sách sau khi làm xong quay lại
    if (context.mounted) {
      onLessonFinished?.call();
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.filled = false, this.bgColor});
  final String label;
  final Color color;
  final bool filled;
  final Color? bgColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: filled ? bgColor : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: filled ? Colors.transparent : color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _EmptyView extends StatelessWidget { const _EmptyView(); @override Widget build(BuildContext context) => const Center(child: Text('No listening lessons found')); }
class _ErrorView extends StatelessWidget { final String message; final VoidCallback onRetry; const _ErrorView({required this.message, required this.onRetry}); @override Widget build(BuildContext context) => Center(child: Text(message)); }
class _FilterRow extends StatelessWidget {
  final List<String> filters; final int selectedIndex; final ValueChanged<int> onSelected; final Color primaryColor;
  const _FilterRow({required this.filters, required this.selectedIndex, required this.onSelected, required this.primaryColor});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(filters.length, (i) {
        final selected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: Container(
            margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: selected ? primaryColor : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? primaryColor : const Color(0xFFE4E4E7))),
            child: Text(filters[i], style: TextStyle(color: selected ? Colors.white : Colors.black, fontSize: 13)),
          ),
        );
      }),
    );
  }
}