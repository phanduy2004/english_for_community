import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/entity/reading/reading_entity.dart';
import '../../core/entity/reading/reading_progress_entity.dart';
import '../../core/get_it/get_it.dart';
import '../../core/repository/reading_repository.dart';
import 'reading_detail_page.dart';
import 'bloc/reading_bloc.dart';
import 'bloc/reading_event.dart';
import 'bloc/reading_state.dart';

class ReadingListPage extends StatefulWidget {
  const ReadingListPage({super.key});

  static const String routeName = 'ReadingListPage';
  static const String routePath = '/reading-list';

  @override
  State<ReadingListPage> createState() => _ReadingListPageState();
}

class _ReadingListPageState extends State<ReadingListPage> {
  String _selectedDifficulty = 'easy';

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB); // Zinc-50
    const borderCol = Color(0xFFE4E4E7); // Zinc-200
    const textMain = Color(0xFF09090B); // Zinc-950
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocProvider(
      create: (context) => ReadingBloc(
        readingRepository: getIt<ReadingRepository>(),
      )..add(FetchReadingListEvent(
        difficulty: _selectedDifficulty,
        page: 1,
        limit: 10,
      )),
      child: Builder(
          builder: (blocContext) {
            return Scaffold(
              backgroundColor: bgPage,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(color: borderCol, height: 1),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: textMain),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: const Text(
                  'Reading Practice',
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 17),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart_outlined, color: textMain),
                    onPressed: () {},
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          _buildFilterRow(blocContext, primaryColor),
                          const SizedBox(height: 20),
                          BlocBuilder<ReadingBloc, ReadingState>(
                            builder: (context, state) {
                              if (state.status == ReadingStatus.loading) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 48.0),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              }
                              if (state.status == ReadingStatus.error) {
                                return _ErrorView(
                                  message: state.errorMessage ?? 'Something went wrong',
                                  onRetry: () => _retry(blocContext),
                                );
                              }

                              if (state.readings.isEmpty) {
                                return const _EmptyView();
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.readings.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) => _ReadingCard(
                                  reading: state.readings[index],
                                  primaryColor: primaryColor,
                                  onAction: () => _handleAction(context, blocContext, state.readings[index]),
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
            );
          }
      ),
    );
  }

  void _retry(BuildContext context) {
    context.read<ReadingBloc>().add(FetchReadingListEvent(
      difficulty: _selectedDifficulty,
      page: 1,
      limit: 10,
    ));
  }

  void _handleAction(BuildContext context, BuildContext blocContext, ReadingEntity reading) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingDetailPage(reading: reading),
      ),
    ).then((_) {
      if (context.mounted) {
        blocContext.read<ReadingBloc>().add(FetchReadingListEvent(
          difficulty: _selectedDifficulty,
          page: 1,
          limit: 10,
        ));
      }
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF18181B), Color(0xFF27272A)], // Zinc Dark Gradient
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
                  'Reading Skills',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Improve comprehension and vocabulary with curated articles.',
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
                    'Daily Articles',
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
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext blocContext, Color primaryColor) {
    final filters = [
      {'id': 'easy', 'label': 'Beginner'},
      {'id': 'medium', 'label': 'Intermediate'},
      {'id': 'hard', 'label': 'Advanced'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedDifficulty == filter['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDifficulty = filter['id']!);
                blocContext.read<ReadingBloc>().add(FetchReadingListEvent(
                  difficulty: _selectedDifficulty,
                  page: 1,
                  limit: 10,
                ));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? primaryColor : const Color(0xFFE4E4E7),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ] : [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2, offset: const Offset(0, 1))
                  ],
                ),
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF52525B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.reading,
    required this.onAction,
    required this.primaryColor,
  });

  final ReadingEntity reading;
  final VoidCallback onAction;
  final Color primaryColor;

  String _getLevelText(ReadingDifficulty? difficulty) {
    switch (difficulty) {
      case ReadingDifficulty.easy: return 'Beginner';
      case ReadingDifficulty.medium: return 'Intermediate';
      case ReadingDifficulty.hard: return 'Advanced';
      default: return 'Unknown';
    }
  }

  Color _getLevelColor(ReadingDifficulty? difficulty) {
    switch (difficulty) {
      case ReadingDifficulty.easy: return const Color(0xFF16A34A);
      case ReadingDifficulty.medium: return const Color(0xFFEA580C);
      case ReadingDifficulty.hard: return const Color(0xFFDC2626);
      default: return const Color(0xFF71717A);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFE4E4E7);

    final progress = reading.progress;
    final bool isCompleted = progress?.status == ProgressStatus.completed;
    final String? scoreText = (progress != null && progress.highScore > 0)
        ? 'Score: ${progress.highScore.toStringAsFixed(0)}%'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onAction,
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
                              _Badge(
                                label: _getLevelText(reading.difficulty),
                                color: _getLevelColor(reading.difficulty),
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
                            reading.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reading.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.article_outlined, color: primaryColor, size: 24),
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
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _IconText(icon: Icons.schedule, text: '${reading.minutesToRead} min'),
                          if (reading.questions.isNotEmpty)
                            _IconText(icon: Icons.quiz_outlined, text: '${reading.questions.length} quiz'),
                          if (scoreText != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(scoreText, style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: isCompleted
                          ? OutlinedButton(
                        onPressed: onAction,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Review'),
                      )
                          : ElevatedButton(
                        onPressed: onAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
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

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF71717A)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
      ],
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
            child: const Icon(Icons.article_outlined, size: 40, color: textMuted),
          ),
          const SizedBox(height: 16),
          const Text('No reading articles found', style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
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