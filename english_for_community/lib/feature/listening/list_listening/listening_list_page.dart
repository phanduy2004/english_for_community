import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDifficultyForIndex(int index) {
    switch (index) {
      case 0:
        return 'easy';
      case 1:
        return 'medium';
      case 2:
        return 'hard';
      default:
        return 'easy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final filterLabels = [t.difficultyBeginner, t.difficultyIntermediate, t.difficultyAdvanced];
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocProvider<ListeningBloc>(
      // 1. Khởi tạo BLoC với bộ lọc mặc định ('easy')
      create: (_) => getIt<ListeningBloc>()
        ..add(GetListListeningEvent(
            difficulty: _getDifficultyForIndex(_selectedFilterIndex))),
      // 2. Sử dụng Builder để lấy Context mới (chứa Provider)
      child: Builder(
        builder: (context) {
          // 3. Định nghĩa hàm refresh tại đây (sử dụng context mới)
          void refreshList() {
            final difficulty = _getDifficultyForIndex(_selectedFilterIndex);
            context.read<ListeningBloc>().add(
              GetListListeningEvent(difficulty: difficulty),
            );
          }

          return Scaffold(
            backgroundColor: bgPage,
            appBar: AppBar(
              backgroundColor: bgPage,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: textMain),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                t.listeningPracticeTitle,
                style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 17),
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
                          _buildHeader(context, t),
                          const SizedBox(height: 20),
                          _buildSearchBox(context, primaryColor, t),
                          const SizedBox(height: 16),
                          _FilterRow(
                            filters: filterLabels,
                            selectedIndex: _selectedFilterIndex,
                            primaryColor: primaryColor,
                            onSelected: (i) {
                              setState(() => _selectedFilterIndex = i);
                              // 4. Gọi BLoC với filter mới
                              context.read<ListeningBloc>().add(
                                GetListListeningEvent(
                                    difficulty: _getDifficultyForIndex(i)),
                              );
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
                                    message: state.errorMessage ?? t.loadDataFailed,
                                    onRetry: refreshList, // Dùng hàm refreshList đã định nghĩa
                                  );
                                case ListeningStatus.success:
                                  final allItems = state.listListeningEntity ?? const <ListeningEntity>[];
                                  final items = allItems.where((item) => _matchesPrefix(item.title, _searchQuery)).toList();
                                  if (items.isEmpty) return const _EmptyView();

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                                    itemBuilder: (context, index) => _ListeningCard(
                                      t: t,
                                      entity: items[index],
                                      primaryColor: primaryColor,
                                      onLessonFinished: refreshList, // Truyền callback refresh
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
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations t) {
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
                Text(
                  t.listeningHeaderTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.listeningHeaderSubtitle,
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
                  child: Text(
                    t.listeningPremiumBadge,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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

  Widget _buildSearchBox(BuildContext context, Color primaryColor, AppLocalizations t) {
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
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: t.listeningSearchHint,
          hintStyle: const TextStyle(fontSize: 14, color: textMuted),
          prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          suffixIcon: _searchQuery.trim().isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16, color: textMuted),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
        ),
      ),
    );
  }

  bool _matchesPrefix(String source, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return source.trimLeft().toLowerCase().startsWith(normalizedQuery);
  }
}
class _ListeningCard extends StatelessWidget {
  const _ListeningCard({
    required this.t,
    required this.entity,
    required this.primaryColor,
    this.onLessonFinished,
  });

  final AppLocalizations t;
  final ListeningEntity entity;
  final Color primaryColor;
  final VoidCallback? onLessonFinished;

  String _difficultyLabel(ListeningDifficulty? d) {
    switch (d) {
      case ListeningDifficulty.easy: return t.difficultyBeginner;
      case ListeningDifficulty.medium: return t.difficultyIntermediate;
      case ListeningDifficulty.hard: return t.difficultyAdvanced;
      default: return t.unknownLevel;
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

    final progress = entity.userProgress.clamp(0.0, 1.0);
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
          onTap: () => _handlePress(context, isRetake: false),
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
                              _Badge(label: levelText, color: levelColor, filled: false),
                              if (isCompleted) ...[
                                const SizedBox(width: 8),
                                _Badge(label: t.completedBadge, color: Color(0xFF059669), filled: true, bgColor: Color(0xFFECFDF5)),
                              ]
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain, height: 1.3),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.format_list_bulleted, size: 14, color: textMuted),
                              const SizedBox(width: 4),
                              Text(t.questionsCount(totalCues), style: const TextStyle(fontSize: 13, color: textMuted)),
                              const SizedBox(width: 12),
                              const Icon(Icons.timer_outlined, size: 14, color: textMuted),
                              const SizedBox(width: 4),
                              Text(t.listeningDictation, style: const TextStyle(fontSize: 13, color: textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded, color: primaryColor, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
                const SizedBox(height: 12),

                // 🔥 NÚT BẤM CẬP NHẬT Ở ĐÂY
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
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.progressPercentLabel((progress * 100).toInt()),
                            style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    if (isCompleted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 32,
                            child: OutlinedButton.icon(
                              onPressed: () => _handlePress(context, isRetake: false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textMuted,
                                side: const BorderSide(color: borderCol),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                              label: Text(t.reviewAction, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: () => _handlePress(context, isRetake: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                foregroundColor: primaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.replay, size: 16),
                              label: Text(t.retakeAction, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => _handlePress(context, isRetake: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: Text(t.startAction),
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

  // 🔥 TRUYỀN BIẾN isRetake VÀO HÀM NÀY
  Future<void> _handlePress(BuildContext context, {bool isRetake = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<CueBloc>(
          // 🔥 TRUYỀN isRetake VÀO EVENT CỦA BLOC
          create: (_) => getIt<CueBloc>()..add(LoadCuesAndAttempts(
            listeningId: entity.id,
            isRetake: isRetake, // Thêm dòng này
          )),
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
      onLessonFinished?.call();
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
                  color: selected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
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
          Text(context.l10n.noListeningLessonsFound, style: const TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
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
    final t = context.l10n;
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
              child: Text(t.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}