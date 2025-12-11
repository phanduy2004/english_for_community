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
import 'vocabulary_tutorial_dialog.dart'; // Đảm bảo import đúng file dialog bạn vừa tạo

class VocabularyHomePage extends StatefulWidget {
  const VocabularyHomePage({super.key});

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
    showDialog(
      context: context,
      builder: (context) => const VocabularyTutorialDialog(),
    );
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
    // Shadcn Colors
    const bgPage = Color(0xFFF9FAFB); // Zinc 50
    const textMain = Color(0xFF09090B); // Zinc 950
    const borderCol = Color(0xFFE4E4E7); // Zinc 200
    final primaryColor = Theme.of(context).colorScheme.primary;

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
            style: TextStyle(color: textMain, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: textMain),
              tooltip: 'How to use',
              onPressed: _showTutorial,
            ),
            IconButton(
              icon: const Icon(Icons.search, color: textMain),
              tooltip: 'Search Dictionary',
              onPressed: () {
                context.pushNamed(kDictDemoRouteName).then((_) => _loadData());
              },
            ),
            const SizedBox(width: 8),
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
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Recently'),
                  Tab(text: 'Learning'),
                  Tab(text: 'Saved'),
                ],
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
          backgroundColor: textMain, // Black button styled
          foregroundColor: Colors.white,
          elevation: 2,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Review Now', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// --- SUB TABS --- (Logic giữ nguyên, chỉ chỉnh UI trong _WordCard)

class _RecentTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  final Function(UserWordEntity) onLearn;
  const _RecentTab({required this.words, required this.onTap, required this.onLearn});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const _EmptyView(message: 'No words looked up recently.', icon: Icons.history);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = words[index];
        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: true,
          action: IconButton(
            icon: Icon(word.status == 'learning' ? Icons.check_circle : Icons.school_outlined),
            color: word.status == 'learning' ? Colors.green : const Color(0xFF71717A),
            onPressed: word.status == 'learning' ? null : () => onLearn(word),
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
    if (words.isEmpty) return const _EmptyView(message: 'No words in learning queue.', icon: Icons.school_outlined);
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
          customSubtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDue ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDue ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  isDue ? 'Review Now' : 'Review: $nextReviewStr',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isDue ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Level ${word.learningLevel}', style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
            ],
          ),
          action: isDue
              ? Container(
            width: 8, height: 8,
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
    if (words.isEmpty) return const _EmptyView(message: 'No saved words.', icon: Icons.bookmark_border);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = words[index];
        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: true,
          leadingIcon: Icons.bookmark,
          leadingColor: Colors.amber[700],
          action: IconButton(
            icon: Icon(word.status == 'learning' ? Icons.check_circle : Icons.school_outlined),
            color: word.status == 'learning' ? Colors.green : const Color(0xFF71717A),
            onPressed: word.status == 'learning' ? null : () => onLearn(word),
          ),
        );
      },
    );
  }
}

// --- SHADCN WORD CARD ---
class _WordCard extends StatelessWidget {
  final UserWordEntity word;
  final VoidCallback onTap;
  final bool showMeaning;
  final Widget? action;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final Widget? customSubtitle;

  const _WordCard({
    required this.word,
    required this.onTap,
    this.showMeaning = true,
    this.action,
    this.leadingIcon,
    this.leadingColor,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)), // Zinc 200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 20, color: leadingColor ?? const Color(0xFF71717A)),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            word.headword,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF09090B)),
                          ),
                          if (word.ipa != null && word.ipa!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '/${word.ipa}/',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF71717A), fontFamily: 'NotoSans', fontStyle: FontStyle.italic),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (customSubtitle != null)
                        customSubtitle!
                      else if (showMeaning)
                        Text(
                          word.shortDefinition ?? 'No definition',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF52525B)),
                        )
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
  const _EmptyView({required this.message, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFF4F4F5), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: const Color(0xFFA1A1AA)),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
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