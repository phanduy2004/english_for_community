import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/dtos/speaking_response_dto.dart';
import '../../core/locale/l10n_context.dart';
import '../../l10n/generated/app_localizations.dart';
import '../speaking/speaking_skills_page.dart';
import 'bloc/speaking_bloc.dart';
import 'bloc/speaking_event.dart';
import 'bloc/speaking_state.dart';

enum SpeakingMode {
  readAloud,
  shadowing,
  pronunciation,
  freeSpeaking,
}

extension SpeakingModeL10n on SpeakingMode {
  String titleLocalized(AppLocalizations t) {
    switch (this) {
      case SpeakingMode.readAloud:
        return t.speakingModeReadAloud;
      case SpeakingMode.shadowing:
        return t.speakingModeShadowing;
      case SpeakingMode.pronunciation:
        return t.speakingModePronunciation;
      case SpeakingMode.freeSpeaking:
        return t.speakingModeFreeSpeaking;
    }
  }
}

class SpeakingHubPage extends StatelessWidget {
  final SpeakingMode mode;

  const SpeakingHubPage({
    super.key,
    required this.mode,
  });

  static const routeName = 'SpeakingHubPage';
  static const routePath = '/speaking-hub/:modeName';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SpeakingBloc>()
        ..add(FetchSpeakingSetsEvent(
          mode: mode,
          level: 'Beginner',
        )),
      child: _SpeakingHubView(mode: mode),
    );
  }
}

class _SpeakingHubView extends StatefulWidget {
  final SpeakingMode mode;
  const _SpeakingHubView({required this.mode});

  @override
  State<_SpeakingHubView> createState() => _SpeakingHubViewState();
}

class _SpeakingHubViewState extends State<_SpeakingHubView> {
  int _selectedFilterIndex = 0;

  /// Backend expects English level names.
  static const _apiLevels = ['Beginner', 'Intermediate', 'Advanced'];

  void _fetchData() {
    final selectedLevel = _apiLevels[_selectedFilterIndex];
    context.read<SpeakingBloc>().add(
      FetchSpeakingSetsEvent(
        mode: widget.mode,
        level: selectedLevel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final levels = [t.difficultyBeginner, t.difficultyIntermediate, t.difficultyAdvanced];
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    final primaryColor = Theme.of(context).colorScheme.primary;

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.mode.titleLocalized(t),
          style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: textMain),
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
                    const SizedBox(height: 20),
                    _buildHeader(context, t),
                    const SizedBox(height: 20),
                    _buildSearchBox(context, primaryColor, t),
                    const SizedBox(height: 16),
                    _FilterRow(
                      filters: levels,
                      selectedIndex: _selectedFilterIndex,
                      primaryColor: primaryColor,
                      onSelected: (i) {
                        setState(() => _selectedFilterIndex = i);
                        _fetchData();
                      },
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<SpeakingBloc, SpeakingState>(
                      builder: (context, state) {
                        if (state.status == SpeakingStatus.loading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        if (state.status == SpeakingStatus.error) {
                          return _ErrorView(
                            message: state.errorMessage ?? t.loadDataFailed,
                            onRetry: _fetchData,
                          );
                        }
                        if (state.status == SpeakingStatus.success) {
                          if (state.sets.isEmpty) return const _EmptyView();

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.sets.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _LessonCard(
                                set: state.sets[index],
                                levelApi: _apiLevels[_selectedFilterIndex],
                                levelLabel: levels[_selectedFilterIndex],
                                primaryColor: primaryColor,
                                // 👇 THÊM DÒNG NÀY: Truyền hàm _fetchData vào để gọi lại khi quay về
                                onReturn: _fetchData,
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
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
                  t.speakingMasteryTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.speakingMasterySubtitle,
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
                    t.aiPoweredBadge,
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
            child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 32),
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
        readOnly: true,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: t.searchTopicHint,
          hintStyle: const TextStyle(fontSize: 14, color: textMuted),
          prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
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

class _LessonCard extends StatelessWidget {
  final SpeakingSetProgressEntity set;
  final String levelApi;
  final String levelLabel;
  final Color primaryColor;
  final VoidCallback onReturn;

  const _LessonCard({
    required this.set,
    required this.levelApi,
    required this.levelLabel,
    required this.primaryColor,
    required this.onReturn,
  });

  Color _getLevelColor(String lvl) {
    switch (lvl.toLowerCase()) {
      case 'beginner': return const Color(0xFF16A34A);
      case 'intermediate': return const Color(0xFFEA580C);
      case 'advanced': return const Color(0xFFDC2626);
      default: return const Color(0xFF71717A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFE4E4E7);

    final levelColor = _getLevelColor(levelApi);
    final bool isResumed = set.isResumed;

    final bool hasScore = set.bestScore != null && set.bestScore! > 0;
    final String scoreText = hasScore ? '${set.bestScore}%' : t.noAttemptsYet;

    // 🔥 ĐỊNH NGHĨA TRẠNG THÁI COMPLETED TẠI ĐÂY (Vd: progress >= 99%)
    final bool isCompleted = set.progress >= 0.99;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToDetail(context, isRetake: false), // Mặc định là Review/Start
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Badge(label: levelLabel, color: levelColor),
                    Icon(Icons.mic_rounded, size: 20, color: textMuted.withOpacity(0.5)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  set.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  t.lessonMetaLine(set.totalSentences, t.topicDailyLife),
                  style: const TextStyle(fontSize: 13, color: textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: set.progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF4F4F5),
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.percentDone((set.progress * 100).toInt()),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMain),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
                const SizedBox(height: 12),

                // Bottom Row: Best Score vs Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasScore ? const Color(0xFFFFF7ED) : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasScore ? const Color(0xFFFFEDD5) : const Color(0xFFE4E4E7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 16, color: hasScore ? const Color(0xFFEA580C) : textMuted),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.bestScoreLabel, style: TextStyle(fontSize: 10, color: hasScore ? const Color(0xFFC2410C) : textMuted)),
                              Text(scoreText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: hasScore ? const Color(0xFF9A3412) : textMain)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 🔥 LOGIC NÚT BẤM REVIEW & RETAKE
                    if (isCompleted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateToDetail(context, isRetake: false), // Nút Review
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textMuted,
                                side: const BorderSide(color: borderCol),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                              label: Text(t.reviewAction, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToDetail(context, isRetake: true), // Nút Retake
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                foregroundColor: primaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.replay, size: 16),
                              label: Text(t.retakeAction, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => _navigateToDetail(context, isRetake: false), // Nút Start
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: Text(isResumed ? t.resumeAction : t.startAction),
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

  // 🔥 TRUYỀN CỜ isRetake QUA URL
  Future<void> _navigateToDetail(BuildContext context, {bool isRetake = false}) async {
    await context.pushNamed(
      SpeakingSkillsPage.routeName,
      pathParameters: {'setId': set.id},
      queryParameters: {'isRetake': isRetake.toString()}, // Ném lên URL cho chắc ăn
    );
    onReturn();
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
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
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
    final t = context.l10n;
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
            child: const Icon(Icons.mic_off_outlined, size: 40, color: textMuted),
          ),
          const SizedBox(height: 16),
          Text(t.noSpeakingLessonsFound, style: const TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
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