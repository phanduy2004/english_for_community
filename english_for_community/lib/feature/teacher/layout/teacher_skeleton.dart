import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/app_skeleton.dart';
import 'package:flutter/material.dart';

/// Skeleton chuẩn cho web teacher — thay `AppLoadingIndicator.center` ở
/// list/card/KPI lớn. Cùng kích thước content thật.
/// Spec: `docs/ui-ux-system/18-teacher-web-audit-and-standards.md` §5.4.
abstract final class TeacherSkeleton {
  static const _radius = AppRadius.card;

  static BorderRadius get _br => BorderRadius.circular(_radius);

  /// Lưới KPI 4 ô (mặc định) cho dashboard / grading hub.
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

  /// Bảng: header + N hàng (gradebook, danh sách).
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

  /// Danh sách card (inbox, grading queue, exams list).
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

  /// Dashboard tổng: KPI grid + 2 panel work-zone.
  static Widget dashboard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
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

  /// Bọc trong padding trang để căn giống content thật.
  static Widget page(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s5,
        ),
        child: Align(alignment: Alignment.topCenter, child: child),
      );

  /// Lịch tháng + panel sự kiện (calendar page) — fixed heights for scroll scaffold.
  static Widget calendar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSkeleton.box(height: 44, borderRadius: _br),
        const SizedBox(height: AppSpacing.s4),
        AppSkeleton.box(height: 420, borderRadius: _br),
      ],
    );
  }

  /// Analytics: KPI strip + 2 chart placeholders.
  static Widget analytics() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kpiGrid(count: 4),
        const SizedBox(height: AppSpacing.s6),
        AppSkeleton.box(height: 200, borderRadius: _br),
        const SizedBox(height: AppSpacing.s6),
        AppSkeleton.box(height: 200, borderRadius: _br),
      ],
    );
  }
}
