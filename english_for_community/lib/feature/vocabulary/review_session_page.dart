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
      create: (context) => ReviewBloc(
        userVocabRepository: getIt<UserVocabRepository>(),
      )..add(FetchReviewWords()),
      child: const _ReviewSessionView(),
    );
  }
}

// ✍️ CHUYỂN THÀNH STATEFUL WIDGET ĐỂ ĐẾM GIỜ
class _ReviewSessionView extends StatefulWidget {
  const _ReviewSessionView();

  @override
  State<_ReviewSessionView> createState() => _ReviewSessionViewState();
}

class _ReviewSessionViewState extends State<_ReviewSessionView> {
  // 👇 Biến lưu thời gian bắt đầu hiện thẻ
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now(); // Bắt đầu đếm cho từ đầu tiên
  }

  // 👇 Hàm tính thời gian đã trôi qua và reset đồng hồ
  int _getElapsedSeconds() {
    if (_startTime == null) return 0;
    final now = DateTime.now();
    final difference = now.difference(_startTime!).inSeconds;
    _startTime = now; // Reset cho từ tiếp theo
    return difference;
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        // ... (Code AppBar giữ nguyên)
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Review Session',
          style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        // 👇 Dùng BlocConsumer để lắng nghe khi chuyển từ mới thì reset giờ (để chắc chắn)
        listener: (context, state) {
          if (state.status == ReviewStatus.success && state.currentWord != null) {
            // Khi load xong từ mới hoặc chuyển từ, đảm bảo start time được cập nhật
            // Tuy nhiên logic _getElapsedSeconds ở nút bấm đã xử lý việc reset rồi,
            // listener này để dự phòng nếu có logic async khác.
          }
        },
        builder: (context, state) {
          if (state.status == ReviewStatus.loading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state.status == ReviewStatus.error) {
            return _ErrorView(message: state.errorMessage ?? 'An error occurred');
          }
          if (state.status == ReviewStatus.complete || state.currentWord == null) {
            return const _CompleteView();
          }

          final word = state.currentWord!;
          final progress = (state.currentIndex + 1) / state.wordsToReview.length;

          return SafeArea(
            child: Column(
              children: [
                // ... (Phần Header Progress Bar giữ nguyên)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Card ${state.currentIndex + 1} of ${state.wordsToReview.length}',
                            style: const TextStyle(color: Color(0xFF71717A), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(color: textMain, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE4E4E7),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GestureDetector(
                      onTap: () => context.read<ReviewBloc>().add(FlipCard()),
                      child: Container(
                        // ... (Phần UI Card giữ nguyên)
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              word.headword,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (state.isFlipped) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  word.ipa ?? '/.../',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'NotoSans',
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Divider(height: 1, color: Color(0xFFF4F4F5)),
                              ),
                              const SizedBox(height: 32),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  word.shortDefinition ?? 'No definition',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Color(0xFF52525B),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 48),
                              const Text(
                                'Tap to flip',
                                style: TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                _buildControlButtons(context, state),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, ReviewState state) {
    final word = state.currentWord!;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (!state.isFlipped) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () => context.read<ReviewBloc>().add(FlipCard()),
            child: const Text('Show Answer'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _FeedbackButton(
              label: 'Hard',
              color: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              // ✍️ TRUYỀN THÊM DURATION VÀO EVENT
              onPressed: () => context.read<ReviewBloc>().add(
                  SubmitFeedback(
                      feedback: 'hard',
                      word: word,
                      duration: _getElapsedSeconds() // <--- Thêm cái này
                  )
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FeedbackButton(
              label: 'Good',
              color: const Color(0xFF22C55E),
              bgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              // ✍️ TRUYỀN THÊM DURATION VÀO EVENT
              onPressed: () => context.read<ReviewBloc>().add(
                  SubmitFeedback(
                      feedback: 'good',
                      word: word,
                      duration: _getElapsedSeconds() // <--- Thêm cái này
                  )
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FeedbackButton(
              label: 'Easy',
              color: const Color(0xFF3B82F6),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              // ✍️ TRUYỀN THÊM DURATION VÀO EVENT
              onPressed: () => context.read<ReviewBloc>().add(
                  SubmitFeedback(
                      feedback: 'easy',
                      word: word,
                      duration: _getElapsedSeconds() // <--- Thêm cái này
                  )
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onPressed;

  const _FeedbackButton({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _CompleteView extends StatelessWidget {
  const _CompleteView();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Done!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF09090B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have reviewed all words for now.\nGreat job!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF71717A), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
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
          const Icon(Icons.error_outline, size: 40, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF71717A))),
        ],
      ),
    );
  }
}