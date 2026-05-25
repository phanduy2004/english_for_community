import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_theme.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:english_for_community/feature/admin/content_management/content_dashboard_page.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/feature/admin/layout/admin_account_menu.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/ops_center/admin_ops_center_page.dart';
import 'package:english_for_community/feature/admin/release_management/release_management_page.dart';
import 'package:english_for_community/feature/admin/report_management/report_management_page.dart';
import 'package:english_for_community/feature/admin/submission_managerment/activity_history_page.dart';
import 'package:english_for_community/feature/admin/teacher_applications/admin_teacher_applications_page.dart';
import 'package:english_for_community/feature/admin/user_management/user_management_page.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Web shell: sidebar + sticky top bar wrapping admin routes.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < AdminWebUi.minFallbackWidth) {
          return _AdminMobileFallback();
        }
        final effectiveCollapsed = _collapsed || c.maxWidth < AdminWebUi.sidebarExpandedMinWidth;
        final sidebarW = effectiveCollapsed ? AdminWebUi.sidebarCollapsedWidth : AdminWebUi.sidebarWidth;
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AdminSidebar(
                collapsed: effectiveCollapsed,
                width: sidebarW,
                onToggle: () => setState(() => _collapsed = !_collapsed),
              ),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopBar(
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

class _AdminMobileFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.laptop_mac_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: AppSpacing.s7),
                Text(l10n.adminShellDesktopTitle, style: AdminWebUi.webH1(context), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  l10n.adminShellDesktopBody,
                  style: AdminWebUi.webBody(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavGroup {
  const _NavGroup({required this.label, required this.items});

  final String label;
  final List<_NavItem> items;
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

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.collapsed,
    required this.width,
    required this.onToggle,
  });

  final bool collapsed;
  final double width;
  final VoidCallback onToggle;

  static bool _matchesPath(String itemPath, String loc) {
    if (itemPath == AdminDashboardPage.routePath) {
      return loc == itemPath || loc == '/admin-dashboard/';
    }
    if (itemPath == ActivityHistoryPage.routePath) {
      return loc.startsWith(ActivityHistoryPage.routePath);
    }
    return loc == itemPath || loc.startsWith('$itemPath/');
  }

  List<_NavGroup> _groups(AppLocalizations l10n) => [
        _NavGroup(
          label: l10n.adminShellNavGroup,
          items: [
            _NavItem(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              label: l10n.adminDashboard,
              path: AdminDashboardPage.routePath,
            ),
          ],
        ),
        _NavGroup(
          label: l10n.adminShellOpsGroup,
          items: [
            _NavItem(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: l10n.usersMenuTitle,
              path: UserManagementPage.routePath,
            ),
            _NavItem(
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              label: l10n.adminNavSubmissions,
              path: ActivityHistoryPage.routePath,
            ),
            _NavItem(
              icon: Icons.flag_outlined,
              selectedIcon: Icons.flag,
              label: l10n.reportsMenuTitle,
              path: ReportManagementPage.routePath,
            ),
            _NavItem(
              icon: Icons.how_to_reg_outlined,
              selectedIcon: Icons.how_to_reg,
              label: l10n.adminTeacherApplicationsTitle,
              path: AdminTeacherApplicationsPage.routePath,
            ),
            _NavItem(
              icon: Icons.tune_outlined,
              selectedIcon: Icons.tune,
              label: l10n.adminNavOps,
              path: AdminOpsCenterPage.routePath,
            ),
            _NavItem(
              icon: Icons.system_update_alt_outlined,
              selectedIcon: Icons.system_update_alt,
              label: l10n.adminNavReleases,
              path: ReleaseManagementPage.routePath,
            ),
          ],
        ),
        _NavGroup(
          label: l10n.adminShellContentGroup,
          items: [
            _NavItem(
              icon: Icons.library_books_outlined,
              selectedIcon: Icons.library_books,
              label: l10n.contentManagerTile,
              path: ContentDashboardPage.routePath,
            ),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loc = GoRouterState.of(context).uri.toString();
    final groups = _groups(l10n);

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
              padding: EdgeInsets.fromLTRB(collapsed ? 10 : 16, 16, collapsed ? 10 : 12, 8),
              child: collapsed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.onPrimary),
                        ),
                        IconButton(
                          tooltip: l10n.adminShellExpandSidebar,
                          icon: const Icon(Icons.chevron_right, size: 18),
                          onPressed: onToggle,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.onPrimary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.adminShellAppName,
                            style: AdminWebUi.webBody(context).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.adminShellCollapseSidebar,
                          icon: const Icon(Icons.chevron_left, size: 18),
                          onPressed: onToggle,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 6 : 8, vertical: 4),
                children: [
                  for (final group in groups) ...[
                    if (!collapsed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Text(group.label, style: AdminWebUi.webTableHead(context)),
                      ),
                    for (final item in group.items)
                      _SidebarNavTile(
                        item: item,
                        selected: _matchesPath(item.path, loc),
                        collapsed: collapsed,
                        onTap: () => context.go(item.path),
                      ),
                  ],
                ],
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
            height: AdminWebUi.sidebarItemHeight,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(selected ? item.selectedIcon : item.icon, size: 18, color: fg),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AdminWebUi.webBody(context).copyWith(
                            fontSize: 13,
                            fontWeight: weight,
                            color: fg,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                  onTap: () => showAdminAccountMenu(context),
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
                    Text(name, style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(email, style: AdminWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.adminAccountOpenMenu,
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => showAdminAccountMenu(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.collapsed, required this.onToggleSidebar});

  final bool collapsed;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AdminWebUi.topBarHeight,
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
          IconButton(
            style: AdminWebUi.compactHeaderIconStyle(),
            icon: const Icon(Icons.notifications_outlined, size: 18),
            color: AppColors.textSecondary,
            onPressed: () {},
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
    return Text(_labelForPath(l10n, path), style: AdminWebUi.webBody(context).copyWith(color: AppColors.textSecondary));
  }

  String _labelForPath(AppLocalizations l10n, String path) {
    if (path == AdminDashboardPage.routePath) return l10n.adminDashboard;
    if (path.startsWith(UserManagementPage.routePath)) return l10n.usersMenuTitle;
    if (path.startsWith(ActivityHistoryPage.routePath)) return l10n.adminNavSubmissions;
    if (path.startsWith(ReportManagementPage.routePath)) return l10n.reportsMenuTitle;
    if (path.startsWith(AdminTeacherApplicationsPage.routePath)) return l10n.adminTeacherApplicationsTitle;
    if (path.startsWith(AdminOpsCenterPage.routePath)) return l10n.adminNavOps;
    if (path.startsWith(ReleaseManagementPage.routePath)) return l10n.adminNavReleases;
    if (path.startsWith(ContentDashboardPage.routePath)) return l10n.contentManagerTile;
    return l10n.adminConsoleTitle;
  }
}
