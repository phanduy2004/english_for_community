import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Nền shimmer dùng chung — cảm giác “app thương mại” khi chờ API.
class AppSkeleton {
  AppSkeleton._();

  static const Color base = Color(0xFFE4E4E7);
  static const Color highlight = Color(0xFFF4F4F5);

  static Widget box({
    required double height,
    double? width,
    BorderRadius? borderRadius,
  }) {
    final r = borderRadius ?? BorderRadius.circular(8);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: base, borderRadius: r),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: highlight.withValues(alpha: 0.85),
        );
  }
}

/// Skeleton cho danh sách lịch sử bài tập (card giống layout thật).
class ExerciseHistoryListSkeleton extends StatelessWidget {
  final int itemCount;

  const ExerciseHistoryListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _HistoryCardSkeleton(),
    );
  }
}

class _HistoryCardSkeleton extends StatelessWidget {
  const _HistoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton.box(height: 12, width: 120, borderRadius: BorderRadius.circular(4)),
              const Spacer(),
              AppSkeleton.box(height: 20, width: 56, borderRadius: BorderRadius.circular(6)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton.box(height: 40, width: 40, borderRadius: BorderRadius.circular(8)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.box(height: 10, width: 80, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    AppSkeleton.box(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 6),
                    AppSkeleton.box(height: 14, width: 200, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppSkeleton.box(height: 44, width: 48, borderRadius: BorderRadius.circular(8)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton cho card biểu đồ trên Home.
class WeeklyStudyChartSkeleton extends StatelessWidget {
  const WeeklyStudyChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton.box(height: 14, width: 180, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          AppSkeleton.box(height: 12, width: 120, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = 40.0 + (i % 4) * 22.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AppSkeleton.box(
                      height: h,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh nhỏ khi load more (thay vòng xoay).
class LoadMoreSkeletonBar extends StatelessWidget {
  const LoadMoreSkeletonBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AppSkeleton.box(height: 8, width: double.infinity, borderRadius: BorderRadius.circular(4)),
    );
  }
}

/// Skeleton gọn cho tab Home khi chờ [UserBloc].
class HomeContentSkeleton extends StatelessWidget {
  const HomeContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.box(height: 22, width: 200, borderRadius: BorderRadius.circular(6)),
                    const SizedBox(height: 10),
                    AppSkeleton.box(height: 14, width: 160, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
              AppSkeleton.box(height: 48, width: 48, borderRadius: BorderRadius.circular(24)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppSkeleton.box(height: 88, borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 16),
          const WeeklyStudyChartSkeleton(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AppSkeleton.box(height: 72, borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(height: 72, borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(height: 72, borderRadius: BorderRadius.circular(12))),
            ],
          ),
        ],
      ),
    );
  }
}
