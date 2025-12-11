import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/user_vocab_repository.dart';

import 'bloc_review/review_bloc.dart';
import 'bloc_review/review_event.dart';
import 'bloc_review/review_state.dart';

class ReviewSessionPage extends StatelessWidget {
  const ReviewSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReviewBloc(userVocabRepository: getIt<UserVocabRepository>())..add(FetchReviewWords()),
      child: const _ReviewSessionView(),
    );
  }
}

class _ReviewSessionView extends StatefulWidget {
  const _ReviewSessionView();
  @override
  State<_ReviewSessionView> createState() => _ReviewSessionViewState();
}

class _ReviewSessionViewState extends State<_ReviewSessionView> {
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  int _getElapsedSeconds() {
    if (_startTime == null) return 0;
    final now = DateTime.now();
    final diff = now.difference(_startTime!).inSeconds;
    _startTime = now;
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Review Session', style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE4E4E7), height: 1),
        ),
      ),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state.status == ReviewStatus.loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          if (state.status == ReviewStatus.error) return Center(child: Text(state.errorMessage ?? 'Error'));
          if (state.status == ReviewStatus.complete || state.currentWord == null) return const _CompleteView();

          final word = state.currentWord!;
          final progress = (state.currentIndex + 1) / state.wordsToReview.length;

          return Column(
            children: [
              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 6,
                    backgroundColor: const Color(0xFFE4E4E7),
                    color: textMain, // Black progress
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () => context.read<ReviewBloc>().add(FlipCard()),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(word.headword, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textMain)),
                          if (state.isFlipped) ...[
                            const SizedBox(height: 16),
                            Text('/${word.ipa ?? "..."}/', style: const TextStyle(fontSize: 18, color: Color(0xFF71717A), fontFamily: 'NotoSans')),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(word.shortDefinition ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Color(0xFF52525B))),
                            ),
                          ] else ...[
                            const SizedBox(height: 48),
                            const Text("Tap to see meaning", style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14)),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildButtons(context, state),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButtons(BuildContext context, ReviewState state) {
    if (!state.isFlipped) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: () => context.read<ReviewBloc>().add(FlipCard()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF09090B), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Show Answer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    final word = state.currentWord!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _FeedbackBtn(label: 'Hard', color: Colors.red, onPressed: () => context.read<ReviewBloc>().add(SubmitFeedback(feedback: 'hard', word: word, duration: _getElapsedSeconds())))),
          const SizedBox(width: 12),
          Expanded(child: _FeedbackBtn(label: 'Good', color: Colors.orange, onPressed: () => context.read<ReviewBloc>().add(SubmitFeedback(feedback: 'good', word: word, duration: _getElapsedSeconds())))),
          const SizedBox(width: 12),
          Expanded(child: _FeedbackBtn(label: 'Easy', color: Colors.green, onPressed: () => context.read<ReviewBloc>().add(SubmitFeedback(feedback: 'easy', word: word, duration: _getElapsedSeconds())))),
        ],
      ),
    );
  }
}

class _FeedbackBtn extends StatelessWidget {
  final String label;
  final MaterialColor color;
  final VoidCallback onPressed;
  const _FeedbackBtn({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color[700],
          backgroundColor: color[50],
          side: BorderSide(color: color[200]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _CompleteView extends StatelessWidget {
  const _CompleteView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          const Text("Session Complete!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("You've reviewed all words for now.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text("Back to Home"),
          )
        ],
      ),
    );
  }
}