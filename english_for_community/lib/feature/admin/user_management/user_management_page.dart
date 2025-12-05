import 'dart:async';

import 'package:english_for_community/core/entity/user_entity.dart';
import 'package:english_for_community/feature/admin/user_management/widgets/user_card..dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  // Colors
  final bgPage = const Color(0xFFF8FAFC);
  final textMain = const Color(0xFF0F172A);
  final textMuted = const Color(0xFF64748B);
  final borderCol = const Color(0xFFE2E8F0);
  final white = Colors.white;
  final primary = const Color(0xFF0F172A);

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
      print("⚡ Socket Alert: User status changed. Reloading list...");

      // Check mounted to avoid setState error if widget is closed
      if (mounted) {
        _fetchUsers(); // Reload list immediately
      }
    });
  }

  void _fetchUsers() {
    String filter = 'all';
    if (_tabController.index == 1) filter = 'today';
    if (_tabController.index == 2) filter = 'online';

    context.read<AdminBloc>().add(GetAllUsersEvent(
        page: 1,
        limit: 20,
        filter: filter,
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null
    ));
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchUsers();
    });
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
    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('User Management', style: TextStyle(color: textMain, fontWeight: FontWeight.w700, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: white,
            child: TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: textMuted,
              indicatorColor: primary,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Today'),
                Tab(text: 'Online'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: white,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(color: textMain, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: textMuted),
                  prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // List
          Expanded(
            child: BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) {
                if (state.status == AdminStatus.loading && state.users == null) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }

                final users = state.users?.data ?? [];

                if (users.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return UserCard(user: users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text("No users found", style: TextStyle(color: textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}