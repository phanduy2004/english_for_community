import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../../theme/app_spacing.dart';
import 'app_skeleton.dart';

/// Mobile skeleton presets — `docs/ui-ux-system/20` §5.4.
abstract final class StudentMobileSkeleton {
  StudentMobileSkeleton._();

  static BorderRadius get _cardRadius => BorderRadius.circular(AppRadius.card);

  /// Danh sách bài (skill hub / list page) — Column, không ListView lồng scroll.
  static Widget skillList({int itemCount = 6}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s4),
          _listTile(),
        ],
      ],
    );
  }

  static Widget _listTile() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        borderRadius: _cardRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          AppSkeleton.box(
            height: 44,
            width: 44,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.box(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(AppRadius.xs)),
                const SizedBox(height: AppSpacing.s3),
                AppSkeleton.box(height: 10, width: 120, borderRadius: BorderRadius.circular(AppRadius.xs)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          AppSkeleton.box(height: 28, width: 56, borderRadius: BorderRadius.circular(AppRadius.chip)),
        ],
      ),
    );
  }

  /// Runner — khung câu hỏi + đáp án MCQ.
  static Widget runnerQuestion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton.box(height: 8, width: 80, borderRadius: BorderRadius.circular(AppRadius.xs)),
          const SizedBox(height: AppSpacing.s4),
          AppSkeleton.box(height: 18, width: double.infinity, borderRadius: BorderRadius.circular(AppRadius.xs)),
          const SizedBox(height: AppSpacing.s3),
          AppSkeleton.box(height: 18, width: double.infinity, borderRadius: BorderRadius.circular(AppRadius.xs)),
          const SizedBox(height: AppSpacing.s3),
          AppSkeleton.box(height: 120, width: double.infinity, borderRadius: _cardRadius),
          const SizedBox(height: AppSpacing.s5),
          for (var i = 0; i < 4; i++) ...[
            AppSkeleton.box(height: 52, width: double.infinity, borderRadius: _cardRadius),
            if (i < 3) const SizedBox(height: AppSpacing.s3),
          ],
        ],
      ),
    );
  }

  /// Flashcard SRS review.
  static Widget flashcard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: AppSkeleton.box(
          height: 220,
          width: double.infinity,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  /// Exam / integrated lobby.
  static Widget examLobby() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton.box(height: 22, width: 200, borderRadius: BorderRadius.circular(AppRadius.chip)),
          const SizedBox(height: AppSpacing.s3),
          AppSkeleton.box(height: 14, width: 160, borderRadius: BorderRadius.circular(AppRadius.xs)),
          const SizedBox(height: AppSpacing.s6),
          AppSkeleton.box(height: 88, width: double.infinity, borderRadius: _cardRadius),
          const SizedBox(height: AppSpacing.s5),
          AppSkeleton.box(height: 52, width: double.infinity, borderRadius: _cardRadius),
          const SizedBox(height: AppSpacing.s4),
          AppSkeleton.box(height: 52, width: double.infinity, borderRadius: _cardRadius),
          const SizedBox(height: AppSpacing.s6),
          AppSkeleton.box(height: 48, width: double.infinity, borderRadius: BorderRadius.circular(AppRadius.input)),
        ],
      ),
    );
  }
}
