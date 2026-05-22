import 'package:flutter/material.dart';

/// Phân tách layout theo `docs/ui-ux-system/01-design-philosophy.md`:
///
/// - **Học sinh:** không bọc scope (hoặc [useWebDensity] = false) → typography / rhythm **mobile-first**
///   kể cả khi chạy Flutter web.
/// - **Giáo viên / Admin:** bọc [useWebDensity] = true trong shell → typography & mật độ **web workspace**.
///
/// Dùng với [AppTypography.useWebScale] và [AppTheme.mergeWorkspaceWeb].
class WorkspaceLayoutScope extends InheritedWidget {
  const WorkspaceLayoutScope({
    super.key,
    required this.useWebDensity,
    required super.child,
  });

  /// Bật mật độ/scale typography web (teacher & admin console).
  final bool useWebDensity;

  static WorkspaceLayoutScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WorkspaceLayoutScope>();
  }

  static bool isWebWorkspace(BuildContext context) {
    return maybeOf(context)?.useWebDensity ?? false;
  }

  @override
  bool updateShouldNotify(WorkspaceLayoutScope oldWidget) {
    return oldWidget.useWebDensity != useWebDensity;
  }
}
