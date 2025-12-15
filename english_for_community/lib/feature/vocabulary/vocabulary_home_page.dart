import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:english_for_community/core/entity/user_word_entity.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_bloc.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_event.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_state.dart';

import '../../core/get_it/get_it.dart';
import '../../core/repository/dictionary_repository.dart';
import '../../core/router/app_router.dart';
import 'vocabulary_tutorial_dialog.dart';

class VocabularyHomePage extends StatefulWidget {
  final int? initialIndex;
  const VocabularyHomePage({super.key,this.initialIndex});

  @override
  State<VocabularyHomePage> createState() => _VocabularyHomePageState();
}

class _VocabularyHomePageState extends State<VocabularyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final VocabularyBloc _vocabularyBloc;
  late final DictionaryRepository _dictionaryRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialIndex != null) {
      _tabController.index = widget.initialIndex!;
    }
    _vocabularyBloc = getIt<VocabularyBloc>();
    _dictionaryRepository = getIt<DictionaryRepository>();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _vocabularyBloc.add(const FetchVocabularyData());
  }

  void _showTutorial() {
    showDialog(context: context, builder: (context) => const VocabularyTutorialDialog());
  }

  Future<void> _navigateToDetail(String headword) async {
    // ... Logic giữ nguyên
    try {
      final result = await _dictionaryRepository.searchWord(headword, limit: 1);
      result.fold(
            (failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${failure.message}')));
        },
            (entries) {
          if (entries.isNotEmpty && entries.first.headword == headword) {
            if (mounted) {
              context.pushNamed(kDictDetailRouteName, extra: entries.first).then((_) => _loadData());
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No details found for "$headword"')));
          }
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);
    const borderCol = Color(0xFFE4E4E7);

    return BlocProvider.value(
      value: _vocabularyBloc,
      child: Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: const Text(
            'Vocabulary',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline_rounded, color: Colors.blue[600]), // Icon màu xanh
              tooltip: 'Tutorial',
              onPressed: _showTutorial,
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.search, color: textMain),
                tooltip: 'Search Dictionary',
                onPressed: () => context.pushNamed(kDictDemoRouteName).then((_) => _loadData()),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: borderCol)),
                color: Colors.white,
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: textMain,
                unselectedLabelColor: const Color(0xFF71717A),
                indicatorColor: textMain,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [Tab(text: 'Recently'), Tab(text: 'Learning'), Tab(text: 'Saved')],
              ),
            ),
          ),
        ),
        body: BlocBuilder<VocabularyBloc, VocabularyState>(
          builder: (context, state) {
            if (state.status == VocabularyStatus.loading) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            if (state.status == VocabularyStatus.error) {
              return _ErrorView(message: state.errorMessage ?? "Unknown error");
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _RecentTab(
                  words: state.recentWords,
                  onTap: _navigateToDetail,
                  onLearn: (w) => context.read<VocabularyBloc>().add(StartLearningWordEvent(w)),
                ),
                _LearningTab(words: state.learningWords, onTap: _navigateToDetail),
                _SavedTab(
                  words: state.savedWords,
                  onTap: _navigateToDetail,
                  onLearn: (w) => context.read<VocabularyBloc>().add(StartLearningWordEvent(w)),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.pushNamed(kReviewSessionRouteName),
          backgroundColor: textMain,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.play_lesson_rounded),
          label: const Text('Review Now', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// --- SUB TABS ---

class _RecentTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  final Function(UserWordEntity) onLearn;
  const _RecentTab({required this.words, required this.onTap, required this.onLearn});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const _EmptyView(message: 'No words looked up recently.', icon: Icons.history_rounded, color: Colors.blue);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = words[index];
        final isLearning = word.status == 'learning';
        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: true,
          // Recent Tab Action: Learn Button
          action: _ActionButton(
            icon: isLearning ? Icons.check_circle_rounded : Icons.school_rounded,
            color: isLearning ? Colors.green : const Color(0xFF71717A),
            bgColor: isLearning ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            onPressed: isLearning ? null : () => onLearn(word),
          ),
        );
      },
    );
  }
}

class _LearningTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  const _LearningTab({required this.words, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const _EmptyView(message: 'Start learning to build your deck.', icon: Icons.school_rounded, color: Color(0xFF10B981));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = words[index];
        final isDue = word.nextReviewDate.isBefore(DateTime.now());
        final nextReviewStr = "${word.nextReviewDate.day}/${word.nextReviewDate.month}";

        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: false,
          leadingIcon: Icons.school_rounded,
          leadingColor: const Color(0xFF10B981), // Emerald
          customSubtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDue ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDue ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Icon(isDue ? Icons.access_time_filled : Icons.check_circle,
                        size: 12,
                        color: isDue ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      isDue ? 'Review Now' : 'Review: $nextReviewStr',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: isDue ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Lv.${word.learningLevel}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF71717A))),
            ],
          ),
          action: isDue
              ? Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
          )
              : null,
        );
      },
    );
  }
}

class _SavedTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  final Function(UserWordEntity) onLearn;
  const _SavedTab({required this.words, required this.onTap, required this.onLearn});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const _EmptyView(message: 'Bookmark words to verify later.', icon: Icons.bookmark_rounded, color: Colors.amber);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = words[index];
        final isLearning = word.status == 'learning';
        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: true,
          leadingIcon: Icons.bookmark_rounded,
          leadingColor: Colors.amber[700], // Amber for Save
          action: _ActionButton(
            icon: isLearning ? Icons.check_circle_rounded : Icons.school_rounded,
            color: isLearning ? Colors.green : const Color(0xFF71717A),
            bgColor: isLearning ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            onPressed: isLearning ? null : () => onLearn(word),
          ),
        );
      },
    );
  }
}

// --- WIDGETS ---

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onPressed;
  const _ActionButton({required this.icon, required this.color, required this.bgColor, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final UserWordEntity word;
  final VoidCallback onTap;
  final bool showMeaning;
  final Widget? action;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final Widget? customSubtitle;

  const _WordCard({
    required this.word, required this.onTap, this.showMeaning = true,
    this.action, this.leadingIcon, this.leadingColor, this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Bo tròn nhiều hơn
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (leadingColor ?? Colors.grey).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(leadingIcon, size: 20, color: leadingColor ?? const Color(0xFF71717A)),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        text: TextSpan(children: [
                          TextSpan(text: word.headword, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF09090B), fontFamily: 'Inter')),
                          if (word.ipa != null && word.ipa!.isNotEmpty)
                            TextSpan(text: ' /${word.ipa}/', style: const TextStyle(fontSize: 14, color: Color(0xFF71717A), fontFamily: 'NotoSans', fontStyle: FontStyle.italic)),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      if (customSubtitle != null) customSubtitle!
                      else if (showMeaning)
                        Text(word.shortDefinition ?? 'No definition', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Color(0xFF52525B)))
                      else
                        Text(word.pos ?? 'Unknown type', style: const TextStyle(fontSize: 13, color: Color(0xFF71717A), fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  const _EmptyView({required this.message, required this.icon, this.color = Colors.grey});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF71717A), fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: const TextStyle(color: Colors.red)));
  }
}