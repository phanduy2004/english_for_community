import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/notification/app_notification_listener.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_bloc.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_state.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_theme.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_account_menu.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_analytics_page.dart';
import 'package:english_for_community/feature/teacher/teacher_calendar_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exams_list_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Web shell: sidebar + sticky top bar wrapping teacher routes.
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key, required this.child});

  final Widget child;

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < TeacherWebUi.minFallbackWidth) {
          return _TeacherMobileShell(child: widget.child);
        }
        final effectiveCollapsed = _collapsed || c.maxWidth < TeacherWebUi.sidebarExpandedMinWidth;
        final sidebarW = effectiveCollapsed ? TeacherWebUi.sidebarCollapsedWidth : TeacherWebUi.sidebarWidth;
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TeacherSidebar(
                collapsed: effectiveCollapsed,
                width: sidebarW,
                onToggle: () => setState(() => _collapsed = !_collapsed),
              ),
              Expanded(
                child: Column(
                  children: [
                    _TeacherTopBar(
                      collapsed: effectiveCollapsed,
                      onToggleSidebar: () => setState(() => _collapsed = !_collapsed),
                    ),
                    Expanded(
                      child: WorkspaceLayoutScope(
                        useWebDensity: true,
                        child: Theme(
                          data: AppTheme.mergeWorkspaceWeb(context),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Teacher hub on phone / narrow tablet — bottom nav + mobile density.
class _TeacherMobileShell extends StatelessWidget {
  const _TeacherMobileShell({required this.child});

  final Widget child;

  static int _indexForPath(String path) {
    if (path.startsWith(TeacherExamsListPage.routePath)) return 1;
    if (path.startsWith(TeacherCalendarPage.routePath)) return 2;
    if (path.startsWith(TeacherAnalyticsPage.routePath)) return 3;
    return 0;
  }

  static const _roots = [
    TeacherDashboardPage.routePath,
    TeacherExamsListPage.routePath,
    TeacherCalendarPage.routePath,
    TeacherAnalyticsPage.routePath,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = GoRouterState.of(context).uri.path;
    final index = _indexForPath(path);
    final showNav = _roots.any((r) => path == r || path == '$r/');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: showNav
          ? AppBar(
              backgroundColor: AppColors.surfaceCard,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(_mobileTitle(l10n, path), style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600)),
              actions: [
                IconButton(
                  tooltip: l10n.teacherAccountOpenMenu,
                  icon: const Icon(Icons.account_circle_outlined, size: 22),
                  onPressed: () => showTeacherAccountMenu(context),
                ),
              ],
            )
          : null,
      body: WorkspaceLayoutScope(
        useWebDensity: false,
        child: child,
      ),
      bottomNavigationBar: showNav
          ? NavigationBar(
              selectedIndex: index,
              height: 60,
              onDestinationSelected: (i) {
                if (i >= 0 && i < _roots.length) context.go(_roots[i]);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: l10n.teacherNavDashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.folder_open_outlined),
                  selectedIcon: const Icon(Icons.folder_open),
                  label: l10n.teacherNavExams,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(Icons.calendar_month),
                  label: l10n.teacherNavCalendar,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(Icons.insights),
                  label: l10n.teacherNavAnalytics,
                ),
              ],
            )
          : null,
    );
  }

  static String _mobileTitle(AppLocalizations l10n, String path) {
    if (path.startsWith(TeacherExamsListPage.routePath)) return l10n.teacherNavExams;
    if (path.startsWith(TeacherCalendarPage.routePath)) return l10n.teacherNavCalendar;
    if (path.startsWith(TeacherAnalyticsPage.routePath)) return l10n.teacherNavAnalytics;
    return l10n.teacherNavDashboard;
  }
}

class _TeacherSidebar extends StatelessWidget {
  const _TeacherSidebar({
    required this.collapsed,
    required this.width,
    required this.onToggle,
  });

  final bool collapsed;
  final double width;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loc = GoRouterState.of(context).uri.toString();
    final items = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: l10n.teacherNavDashboard,
        path: TeacherDashboardPage.routePath,
      ),
      _NavItem(
        icon: Icons.folder_open_outlined,
        selectedIcon: Icons.folder_open,
        label: l10n.teacherNavExams,
        path: TeacherExamsListPage.routePath,
      ),
      _NavItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: l10n.teacherNavCalendar,
        path: TeacherCalendarPage.routePath,
      ),
      _NavItem(
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights,
        label: l10n.teacherNavAnalytics,
        path: TeacherAnalyticsPage.routePath,
      ),
    ];

    return Material(
      color: AppColors.surfaceCard,
      child: Container(
        width: width,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.outline, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(collapsed ? 8 : 16, 16, collapsed ? 8 : 12, 8),
              child: collapsed
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.school_outlined, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              tooltip: l10n.teacherShellExpandSidebar,
                              icon: const Icon(Icons.chevron_right, size: 18),
                              onPressed: onToggle,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.school_outlined, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.teacherShellAppName,
                            style: TeacherWebUi.webH2(context).copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.teacherShellCollapseSidebar,
                          icon: const Icon(Icons.chevron_left, size: 18),
                          onPressed: onToggle,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
            ),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(l10n.teacherShellNavGroup, style: TeacherWebUi.webTableHead(context)),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 6 : 8, vertical: 4),
                children: items.map((item) {
                  final selected = loc == item.path || (item.path != '/teacher' && loc.startsWith(item.path));
                  return _SidebarNavTile(
                    item: item,
                    selected: selected,
                    collapsed: collapsed,
                    onTap: () => context.go(item.path),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            _SidebarUserFooter(collapsed: collapsed),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primaryTint : Colors.transparent;
    final fg = selected ? AppColors.primaryDark : AppColors.textPrimary;
    final weight = selected ? FontWeight.w600 : FontWeight.w400;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 40,
            child: collapsed
                ? Tooltip(
                    message: item.label,
                    waitDuration: const Duration(milliseconds: 400),
                    child: Center(
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: fg,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(selected ? item.selectedIcon : item.icon, size: 18, color: fg),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TeacherWebUi.webBody(context).copyWith(
                                fontSize: 13,
                                fontWeight: weight,
                                color: fg,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SidebarUserFooter extends StatelessWidget {
  const _SidebarUserFooter({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        final user = state.userEntity;
        final name = user?.fullName.trim().isNotEmpty == true ? user!.fullName : '—';
        final email = user?.email ?? '';
        if (collapsed) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Tooltip(
                message: name,
                waitDuration: const Duration(milliseconds: 400),
                child: InkWell(
                  onTap: () => showTeacherAccountMenu(context),
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryTint,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryTint,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(email, style: TeacherWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.teacherAccountOpenMenu,
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => showTeacherAccountMenu(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeacherTopBar extends StatelessWidget {
  const _TeacherTopBar({required this.collapsed, required this.onToggleSidebar});

  final bool collapsed;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TeacherWebUi.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: Row(
        children: [
          if (collapsed)
            IconButton(
              icon: const Icon(Icons.menu, size: 20),
              onPressed: onToggleSidebar,
              color: AppColors.textSecondary,
            ),
          Expanded(child: _RouteContextLabel()),
          BlocBuilder<NotificationBloc, NotificationState>(
            bloc: getIt<NotificationBloc>(),
            builder: (context, state) {
              final unread = state.unreadCount;
              return IconButton(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: const Icon(Icons.notifications_outlined, size: 18),
                ),
                color: AppColors.textSecondary,
                onPressed: () => showAppNotificationsDialog(context),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RouteContextLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = GoRouterState.of(context).uri.path;
    final label = _labelForPath(l10n, path);
    return Text(label, style: TeacherWebUi.webBody(context).copyWith(color: AppColors.textSecondary));
  }

  String _labelForPath(AppLocalizations l10n, String path) {
    if (path == TeacherDashboardPage.routePath || path == '/teacher/') return l10n.teacherNavDashboard;
    if (path.startsWith(TeacherExamsListPage.routePath)) return l10n.teacherNavExams;
    if (path.startsWith(TeacherCalendarPage.routePath)) return l10n.teacherNavCalendar;
    if (path.startsWith(TeacherAnalyticsPage.routePath)) return l10n.teacherNavAnalytics;
    if (path.contains('/classroom/')) return l10n.teacherClassroomDetailTitle;
    if (path.contains('/exam-grading/')) return l10n.teacherDashboardSectionGrading;
    if (path.contains('/exam-console/')) return l10n.teacherDashboardSectionLive;
    if (path.contains('/assign')) return l10n.teacherAssignmentWizardTitle;
    if (path.contains('/integrated-edit') || path.contains('/edit')) return l10n.teacherExamEditorTitle;
    return l10n.teacherDashboardTitle;
  }
}
