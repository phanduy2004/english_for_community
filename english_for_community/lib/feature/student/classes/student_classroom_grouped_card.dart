import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Inset grouped card — iOS/Telegram style (A5 / `23` §3.4).
class StudentClassroomGroupedCard extends StatelessWidget {
  const StudentClassroomGroupedCard({
    super.key,
    required this.children,
    required this.dividerIndent,
    this.accentColor,
  });

  final List<Widget> children;
  final double dividerIndent;
  final Color? accentColor;

  static double memberDividerIndent() =>
      AppSpacing.s4 + 44 + AppSpacing.s3;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: dividerIndent,
          endIndent: AppSpacing.s4,
          color: AppColors.outlineMuted,
        ));
      }
      rows.add(children[i]);
    }

    final radius = BorderRadius.circular(AppRadius.card);
    final accent = accentColor;
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: radius,
              border: Border.all(
                color: accent?.withValues(alpha: 0.28) ?? AppColors.outline,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowHairline,
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: rows),
          ),
          if (accent != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: accent),
            ),
        ],
      ),
    );
  }
}
