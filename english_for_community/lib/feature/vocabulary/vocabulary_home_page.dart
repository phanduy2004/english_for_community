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

class VocabularyHomePage extends StatefulWidget {
  const VocabularyHomePage({super.key});

  @override
  State<VocabularyHomePage> createState() => _VocabularyHomePageState();
}

class _VocabularyHomePageState extends State<VocabularyHomePage>
    with SingleTickerProviderStateMixin {
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

  Future<void> _navigateToDetail(String headword) async {
    try {
      final result = await _dictionaryRepository.searchWord(headword, limit: 1);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi tra cứu: ${failure.message}')));
        },
        (entries) {
          if (entries.isNotEmpty && entries.first.headword == headword) {
            final entry = entries.first;
            if (mounted) {
              context
                  .pushNamed(kDictDetailRouteName, extra: entry)
                  .then((_) => _loadData());
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Không tìm thấy chi tiết cho "$headword"')));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi tra cứu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);
    const borderCol = Color(0xFFE4E4E7);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocProvider.value(
      value: _vocabularyBloc,
      child: Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: borderCol)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: const Color(0xFF71717A),
                indicatorColor: primaryColor,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Recently'),
                  Tab(text: 'Learning'),
                  Tab(text: 'Saved'),
                ],
              ),
            ),
          ),
          title: const Text(
            'Vocabulary',
            style: TextStyle(
                color: textMain, fontWeight: FontWeight.w600, fontSize: 17),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: textMain),
              onPressed: () {
                context.pushNamed(kDictDemoRouteName).then((_) => _loadData());
              },
            ),
          ],
        ),
        body: BlocBuilder<VocabularyBloc, VocabularyState>(
          builder: (context, state) {
            if (state.status == VocabularyStatus.loading) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2));
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
                    onLearn: (w) => context
                        .read<VocabularyBloc>()
                        .add(StartLearningWordEvent(w))),
                _LearningTab(
                    words: state.learningWords, onTap: _navigateToDetail),
                _SavedTab(
                    words: state.savedWords,
                    onTap: _navigateToDetail,
                    onLearn: (w) => context
                        .read<VocabularyBloc>()
                        .add(StartLearningWordEvent(w))),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.pushNamed(kReviewSessionRouteName),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Review Now',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB: RECENTLY VIEWED
// -----------------------------------------------------------------------------
class _RecentTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  final Function(UserWordEntity) onLearn;

  const _RecentTab(
      {required this.words, required this.onTap, required this.onLearn});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty)
      return const _EmptyView(message: 'No words looked up recently.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = words[index];
        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: true, // Hiển thị nghĩa
          action: IconButton(
            icon: Icon(
              word.status == 'learning'
                  ? Icons.check_circle
                  : Icons.school_outlined,
              color: word.status == 'learning'
                  ? Colors.green
                  : const Color(0xFF71717A),
            ),
            tooltip: 'Learn this word',
            onPressed: word.status == 'learning' ? null : () => onLearn(word),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB: LEARNING (KHÔNG HIỂN THỊ NGHĨA, CHỈ HIỆN TRẠNG THÁI)
// -----------------------------------------------------------------------------
class _LearningTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;

  const _LearningTab({required this.words, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty)
      return const _EmptyView(message: 'No words in learning queue.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = words[index];
        final isDue = word.nextReviewDate.isBefore(DateTime.now());
        final nextReviewStr =
            "${word.nextReviewDate.day}/${word.nextReviewDate.month}";

        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: false,
          // Ẩn nghĩa
          customSubtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isDue ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: isDue
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  isDue ? 'Review Now' : 'Review: $nextReviewStr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDue
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Level ${word.learningLevel}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
              ),
            ],
          ),
          action: Icon(
            Icons.circle,
            size: 12,
            color: isDue ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB: SAVED WORDS
// -----------------------------------------------------------------------------
class _SavedTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  final Function(UserWordEntity) onLearn;

  const _SavedTab(
      {required this.words, required this.onTap, required this.onLearn});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const _EmptyView(message: 'No saved words.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = words[index];
        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: true,
          // Hiển thị nghĩa
          leadingIcon: Icons.bookmark,
          leadingColor: Colors.blue,
          action: IconButton(
            icon: Icon(
              word.status == 'learning'
                  ? Icons.check_circle
                  : Icons.school_outlined,
              color: word.status == 'learning'
                  ? Colors.green
                  : const Color(0xFF71717A),
            ),
            onPressed: word.status == 'learning' ? null : () => onLearn(word),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED COMPONENT: WORD CARD (SHADCN STYLE)
// -----------------------------------------------------------------------------
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
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Leading Icon (Optional)
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 20, color: leadingColor ?? textMuted),
                  const SizedBox(width: 12),
                ],

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.headword,
                        maxLines: 1,
                        // Đảm bảo chỉ 1 dòng
                        overflow: TextOverflow.ellipsis,
                        // Nếu từ siêu dài thì hiện dấu ...
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                        ),
                      ),

// 2. PHIÊN ÂM (IPA) - Đưa xuống dưới
                      if (word.ipa != null && word.ipa!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        // Khoảng cách nhỏ giữa từ và phiên âm
                        Text(
                          word.ipa!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textMuted,
                            fontFamily: 'NotoSans',
                            fontStyle: FontStyle
                                .italic, // In nghiêng nhìn cho đẹp (tuỳ chọn)
                          ),
                        ),
                      ],

                      const SizedBox(height: 4),
                      // Khoảng cách trước khi đến nghĩa

// 3. NGHĨA HOẶC SUBTITLE (Giữ nguyên logic cũ)
                      if (customSubtitle != null)
                        customSubtitle!
                      else if (showMeaning)
                        Text(
                          word.shortDefinition ?? 'No definition',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 13, color: textMuted),
                        )
                      else
                        Text(
                          word.pos ?? 'Unknown type',
                          style: const TextStyle(
                              fontSize: 13,
                              color: textMuted,
                              fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),

                // Action Button
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

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    const textMuted = Color(0xFF71717A);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 40, color: textMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: textMuted, fontSize: 14)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF71717A))),
        ],
      ),
    );
  }
}
