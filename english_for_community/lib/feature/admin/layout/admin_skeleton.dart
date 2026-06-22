import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/app_skeleton.dart';
import 'package:flutter/material.dart';

/// Skeleton chuẩn cho web admin — thay `AppLoadingIndicator.center` ở
/// list/card/KPI lớn. Cùng kích thước content thật.
/// Spec: `docs/ui-ux-system/19-admin-web-audit-and-standards.md` §5.3.
abstract final class AdminSkeleton {
  static const _radius = AppRadius.card;

  static BorderRadius get _br => BorderRadius.circular(_radius);

  static Widget kpiGrid({int count = 4}) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          Expanded(child: AppSkeleton.box(height: 72, borderRadius: _br)),
          if (i != count - 1) const SizedBox(width: AppSpacing.s4),
        ],
      ],
    );
  }

  static Widget table({int rows = 6}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSkeleton.box(height: 32, borderRadius: _br),
        const SizedBox(height: AppSpacing.s3),
        for (var i = 0; i < rows; i++) ...[
          AppSkeleton.box(height: 40, borderRadius: _br),
          if (i != rows - 1) const SizedBox(height: AppSpacing.s2),
        ],
      ],
    );
  }

  static Widget cardList({int n = 3, double height = 76}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++) ...[
          AppSkeleton.box(height: height, borderRadius: _br),
          if (i != n - 1) const SizedBox(height: AppSpacing.s3),
        ],
      ],
    );
  }

  static Widget dashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kpiGrid(),
        const SizedBox(height: AppSpacing.s6),
        SizedBox(
          height: 300,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: AppSkeleton.box(height: 300, borderRadius: _br)),
              const SizedBox(width: AppSpacing.s4),
              Expanded(child: AppSkeleton.box(height: 300, borderRadius: _br)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget page(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s5,
        ),
        child: Align(alignment: Alignment.topCenter, child: child),
      );
}
