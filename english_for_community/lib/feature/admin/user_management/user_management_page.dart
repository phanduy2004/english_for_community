import 'dart:async';

import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/feature/admin/user_management/widgets/user_card..dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/datasource/admin_remote_datasource.dart';
import '../../../core/get_it/get_it.dart';
import '../../../core/socket/socket_service.dart';
import '../dashboard_home/bloc/admin_bloc.dart';
import '../dashboard_home/bloc/admin_event.dart';
import '../dashboard_home/bloc/admin_state.dart';

// Enum for Tab management
enum UserFilter { all, today, online }

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key, this.initialFilter = UserFilter.today});

  final UserFilter initialFilter;
  static const String routeName = 'UserManagementPage';
  static const String routePath = '/admin/users';

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AdminBloc>(),
      child: _UserManagementView(initialFilter: initialFilter),
    );
  }
}

class _UserManagementView extends StatefulWidget {
  final UserFilter initialFilter;
  const _UserManagementView({required this.initialFilter});

  @override
  State<_UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<_UserManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  int _page = 1;
  int _rowsPerPage = kAdminDefaultRowsPerPage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    switch (widget.initialFilter) {
      case UserFilter.all: _tabController.index = 0; break;
      case UserFilter.today: _tabController.index = 1; break;
      case UserFilter.online: _tabController.index = 2; break;
    }

    // 1. Call API initially
    _fetchUsers();

    // 2. Listen to Tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _page = 1);
        _fetchUsers();
      }
    });

    // --- 3. ACTIVATE SOCKET (IMPORTANT) ---
    _initSocketListener();
  }

  // Function to listen for changes from Server
  void _initSocketListener() {
    final socket = getIt<SocketService>();

    // Ensure socket is connected
    socket.init();

    // Admin joins room to receive messages
    socket.joinAdminRoom();

    // Register callback: When alert received, reload list
    socket.listenToUserStatus((data) {
      if (!mounted) return;
      if (data is Map) {
        final userId = data['userId']?.toString();
        final isOnline = data['isOnline'] == true;
        if (userId != null && userId.isNotEmpty) {
          context.read<AdminBloc>().add(
                PatchUserOnlineStatusEvent(userId: userId, isOnline: isOnline),
              );
          return;
        }
      }
      _fetchUsers();
    });
  }

  void _fetchUsers() {
    String filter = 'all';
    if (_tabController.index == 1) filter = 'today';
    if (_tabController.index == 2) filter = 'online';

    context.read<AdminBloc>().add(GetAllUsersEvent(
        page: _page,
        limit: _rowsPerPage,
        filter: filter,
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null
    ));
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(AppMotion.debounce, () {
      setState(() => _page = 1);
      _fetchUsers();
    });
  }

  Future<void> _openDeletedUsersSheet() async {
    final l10n = context.l10n;
    final datasource = getIt<AdminRemoteDatasource>();
    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            side: const BorderSide(color: AppColors.outline),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restore_from_trash_outlined, size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      const Text('Deleted Users', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const Text(
                    'Restore user accounts that were soft-deleted.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder(
                      future: datasource.getDeletedUsers(page: 1, limit: 50),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return AdminSkeleton.page(AdminSkeleton.cardList());
                        }
                        final users = snapshot.data!.data;
                        if (users.isEmpty) {
                          return const Center(child: Text('Trash is empty'));
                        }
                        return ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final u = users[index];
                            return ListTile(
                              leading: AdminWebUi.userAvatarCircle(
                                avatarUrl: u.avatarUrl,
                                displayName: u.fullName,
                                radius: 20,
                              ),
                              title: Text(u.fullName),
                              subtitle: Text(u.email),
                              trailing: OutlinedButton(
                                onPressed: () async {
                                  await datasource.restoreUser(u.id);
                                  if (!mounted) return;
                                  AppCornerToast.show(context, l10n.adminUserRestored(u.fullName));
                                  Navigator.pop(ctx);
                                  _fetchUsers();
                                },
                                child: const Text('Restore'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminPageScaffold(
      title: l10n.adminUserManagementTitle,
      subtitle: l10n.usersMenuSub,
      scrollable: false,
      maxWidth: AdminWebUi.contentMaxTable,
      breadcrumbs: [
        AdminBreadcrumb(label: l10n.adminOverviewTitle, location: AdminDashboardPage.routePath),
        AdminBreadcrumb(label: l10n.usersMenuTitle),
      ],
      actions: [
        OutlinedButton.icon(
          onPressed: _openDeletedUsersSheet,
          icon: const Icon(Icons.restore_from_trash_outlined, size: 16),
          label: Text(l10n.adminUsersTrash),
          style: AdminWebUi.compactOutlinedStyle(context),
        ),
      ],
      headerBottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Today'),
          Tab(text: 'Online'),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s5),
            child: AdminSearchField(
              controller: _searchController,
              hint: l10n.adminSearchUsersHint,
              onChanged: _onSearchChanged,
              width: double.infinity,
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) {
                if (state.status == AdminStatus.loading && state.users == null) {
                  return AdminSkeleton.page(AdminSkeleton.cardList());
                }

                final users = state.users?.data ?? [];
                final pagination = state.users?.pagination;

                if (users.isEmpty) {
                  return Center(
                    child: AdminEmptyCard(
                      message: l10n.adminNoUsersFound,
                      icon: Icons.search_off_rounded,
                      actionLabel: _searchController.text.trim().isNotEmpty ? l10n.retry : null,
                      onAction: _searchController.text.trim().isNotEmpty
                          ? () {
                              _searchController.clear();
                              setState(() => _page = 1);
                              _fetchUsers();
                            }
                          : null,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                        itemCount: users.length,
                        separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.s4),
                        itemBuilder: (context, index) => UserCard(user: users[index]),
                      ),
                    ),
                    if (pagination != null && pagination.totalPages > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s4, bottom: AppSpacing.s7),
                        child: AdminPaginationBar(
                          page: pagination.page,
                          totalPages: pagination.totalPages,
                          totalRows: pagination.total,
                          rowsPerPage: _rowsPerPage,
                          onRowsPerPageChanged: (v) {
                            setState(() {
                              _rowsPerPage = v;
                              _page = 1;
                            });
                            _fetchUsers();
                          },
                          onPageChanged: (p) {
                            setState(() => _page = p);
                            _fetchUsers();
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



