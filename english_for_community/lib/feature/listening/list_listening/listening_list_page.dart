import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';

import '../listening_skill/bloc/cue_bloc.dart';
import '../listening_skill/bloc/cue_event.dart';
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
  int _selectedFilterIndex = 0;
  final List<String> _filters = const ['All', 'Beginner', 'Intermediate', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    // Màu nền và chữ chuẩn Shadcn
    const bgPage = Color(0xFFF9FAFB); // Zinc-50
    const borderCol = Color(0xFFE4E4E7); // Zinc-200
    const textMain = Color(0xFF09090B); // Zinc-950

    // Lấy màu Primary từ Theme của bạn (Màu Xanh)
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocProvider<ListeningBloc>(
      create: (context) => getIt<ListeningBloc>()..add(GetListListeningEvent()),
      child: Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: bgPage,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textMain),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Listening Practice',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 17),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined, color: textMain),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: textMain),
              onPressed: () {},
            ),
          ],
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
                      _buildHeader(context), // Giữ Banner Gradient tối màu cho sang trọng
                      const SizedBox(height: 20),
                      _buildSearchBox(context, primaryColor),
                      const SizedBox(height: 16),
                      _FilterRow(
                        filters: _filters,
                        selectedIndex: _selectedFilterIndex,
                        primaryColor: primaryColor, // Truyền màu xanh vào Filter
                        onSelected: (i) {
                          setState(() => _selectedFilterIndex = i);
                          context.read<ListeningBloc>().add(GetListListeningEvent());
                        },
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<ListeningBloc, ListeningState>(
                        builder: (context, state) {
                          switch (state.status) {
                            case ListeningStatus.loading:
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            case ListeningStatus.error:
                              return _ErrorView(
                                message: state.errorMessage ?? 'Something went wrong',
                                onRetry: () => context.read<ListeningBloc>().add(GetListListeningEvent()),
                              );
                            case ListeningStatus.success:
                              final items = state.listListeningEntity ?? const <ListeningEntity>[];
                              if (items.isEmpty) return const _EmptyView();

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) => _ListeningCard(
                                  entity: items[index],
                                  primaryColor: primaryColor, // Truyền màu xanh vào Card
                                ),
                              );
                            default:
                              return const SizedBox.shrink();
                          }
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
      ),
    );
  }

  // Banner giữ nguyên Dark Gradient (Rất hợp với Shadcn)
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
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dictation Master',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Improve listening and spelling skills with short daily exercises.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'Premium Content',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headphones, color: Colors.white, size: 32),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        readOnly: true,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search lessons, topics, or ID...',
          hintStyle: const TextStyle(fontSize: 14, color: textMuted),
          prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
          // Focus Border màu Xanh
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

class _ListeningCard extends StatelessWidget {
  const _ListeningCard({required this.entity, required this.primaryColor});
  final ListeningEntity entity;
  final Color primaryColor; // Nhận màu xanh từ cha

  String _difficultyLabel(ListeningDifficulty? d) {
    switch (d) {
      case ListeningDifficulty.easy: return 'Beginner';
      case ListeningDifficulty.medium: return 'Intermediate';
      case ListeningDifficulty.hard: return 'Advanced';
      default: return 'Unknown';
    }
  }

  Color _difficultyColor(ListeningDifficulty? d) {
    switch (d) {
      case ListeningDifficulty.easy: return const Color(0xFF16A34A);
      case ListeningDifficulty.medium: return const Color(0xFFEA580C);
      case ListeningDifficulty.hard: return const Color(0xFFDC2626);
      default: return const Color(0xFF71717A);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFE4E4E7);

    final title = entity.title;
    final totalCues = entity.totalCues ?? 0;
    final levelText = _difficultyLabel(entity.difficulty);
    final levelColor = _difficultyColor(entity.difficulty);

    final progress = (entity.userProgress ?? 0.0).clamp(0.0, 1.0);
    final isCompleted = progress >= 0.99;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
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
                          // Badges Row
                          Row(
                            children: [
                              _Badge(
                                label: levelText,
                                color: levelColor,
                                filled: false,
                              ),
                              if (isCompleted) ...[
                                const SizedBox(width: 8),
                                const _Badge(
                                  label: 'Completed',
                                  color: Color(0xFF059669),
                                  filled: true,
                                  bgColor: Color(0xFFECFDF5),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Info Row
                          Row(
                            children: [
                              const Icon(Icons.format_list_bulleted, size: 14, color: textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '$totalCues questions',
                                style: const TextStyle(fontSize: 13, color: textMuted),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.timer_outlined, size: 14, color: textMuted),
                              const SizedBox(width: 4),
                              const Text(
                                'Dictation',
                                style: TextStyle(fontSize: 13, color: textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Play Icon Box - Dùng màu Xanh
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1), // Nền xanh nhạt
                        borderRadius: BorderRadius.circular(10),
                        // border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.play_arrow_rounded, color: primaryColor, size: 28),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
                const SizedBox(height: 12),

                // Progress & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: const Color(0xFFF4F4F5),
                              // ✅ Progress bar dùng màu Xanh
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Progress: ${(progress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      height: 32,
                      child: isCompleted
                          ? OutlinedButton(
                        onPressed: () => _handlePress(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor, // Chữ xanh
                          side: BorderSide(color: primaryColor.withOpacity(0.5)), // Viền xanh nhạt
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Review'),
                      )
                          : ElevatedButton(
                        onPressed: () => _handlePress(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor, // Nền xanh
                          foregroundColor: Colors.white, // Chữ trắng
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Start'),
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<CueBloc>(
          create: (_) => getIt<CueBloc>()..add(LoadCuesAndAttempts(listeningId: entity.id)),
          child: ListeningSkillsPage(
            listeningId: entity.id,
            title: entity.title,
            levelText: _difficultyLabel(entity.difficulty),
            audioUrl: entity.audioUrl,
          ),
        ),
      ),
    );
    if (context.mounted) {
      context.read<ListeningBloc>().add(GetListListeningEvent());
    }
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
    required this.primaryColor,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(filters.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i == filters.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  // ✅ Selected background dùng màu Xanh
                  color: selected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    // ✅ Selected border dùng màu Xanh
                    color: selected ? primaryColor : const Color(0xFFE4E4E7),
                  ),
                  boxShadow: selected ? [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ] : [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2, offset: const Offset(0, 1))
                  ],
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    // ✅ Selected text dùng màu Trắng
                    color: selected ? Colors.white : const Color(0xFF52525B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
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
      decoration: BoxDecoration(
        color: filled ? bgColor : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: filled ? Colors.transparent : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    const textMuted = Color(0xFF71717A);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: const Icon(Icons.inbox_outlined, size: 40, color: textMuted),
          ),
          const SizedBox(height: 16),
          const Text('No listening lessons found', style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Color(0xFF71717A))),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF09090B),
                side: const BorderSide(color: Color(0xFFE4E4E7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}