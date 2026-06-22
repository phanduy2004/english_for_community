import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'dart:async';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import '../../../../core/get_it/get_it.dart';
import '../../../../core/repository/admin_repository.dart';
import '../../../../core/entity/user_entity.dart';

// --- COLORS ---
const Color kWhite = Colors.white;
const Color kBorder = AppColors.outline;
const Color kTextMain = AppColors.textPrimary;
const Color kTextMuted = AppColors.textMuted;
const Color kPrimary = AppColors.textPrimary;
const Color kBgPage = AppColors.surfaceSubtle;

class UserDropdownSearch extends StatefulWidget {
  final UserEntity? selectedUser;
  final Function(UserEntity?) onUserSelected;

  const UserDropdownSearch({
    super.key,
    required this.selectedUser,
    required this.onUserSelected,
  });

  @override
  State<UserDropdownSearch> createState() => _UserDropdownSearchState();
}

class _UserDropdownSearchState extends State<UserDropdownSearch> {
  final SearchController _searchController = SearchController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<UserEntity> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Initial load
    _scrollController.addListener(_onScroll);

    // Listen to search controller changes
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchKeyword == query) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(AppMotion.debounce, () {
      if (!mounted) return;
      setState(() {
        _searchKeyword = query;
        _users.clear();
        _currentPage = 1;
        _hasMore = true;
      });
      _fetchUsers();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoading && _hasMore) {
        _fetchUsers();
      }
    }
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await getIt<AdminRepository>().getAllUsers(
        page: _currentPage,
        limit: 10,
        search: _searchKeyword,
      );

      result.fold(
            (failure) {},
            (response) {
          if (!mounted) return;
          setState(() {
            _users.addAll(response.data);
            _currentPage++;
            if (response.data.length < 10) _hasMore = false;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasUser = widget.selectedUser != null;

    return MenuAnchor(
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hasUser ? kPrimary.withValues(alpha: 0.05) : kWhite,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: hasUser ? kPrimary : kBorder),
            ),
            child: Row(
              children: [
                if (hasUser)
                  AdminWebUi.userAvatarCircle(
                    avatarUrl: widget.selectedUser!.avatarUrl,
                    displayName: widget.selectedUser!.fullName,
                    radius: 10,
                  )
                else
                  const Icon(Icons.person_search_outlined, size: 18, color: kTextMain),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Filter User", style: TextStyle(fontSize: 10, color: hasUser ? kPrimary : kTextMuted, fontWeight: FontWeight.w500)),
                      Text(
                          hasUser ? widget.selectedUser!.fullName : "All Users",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasUser ? kPrimary : kTextMain)
                      ),
                    ],
                  ),
                ),

                if (hasUser)
                  InkWell(
                    onTap: () => widget.onUserSelected(null), // Clear filter
                    child: const Icon(Icons.close, size: 16, color: kTextMuted),
                  )
                else
                  const Icon(Icons.keyboard_arrow_down, color: kTextMuted),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        // SEARCH BOX
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 250, // Chiều rộng menu
            height: 40,
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search user...',
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(kBgPage),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
              leading: const Icon(Icons.search, size: 18, color: kTextMuted),
            ),
          ),
        ),

        // USER LIST (Trong MenuAnchor cần dùng SizedBox giới hạn chiều cao)
        SizedBox(
          width: 266, // 250 + padding
          height: 300, // Chiều cao tối đa của dropdown
          child: _users.isEmpty && !_isLoading
              ? const Center(child: Text("No users found", style: TextStyle(fontSize: 12, color: kTextMuted)))
              : ListView.builder(
            controller: _scrollController,
            itemCount: _users.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _users.length) {
                return const Center(child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 16, height: 16, child: AppLoadingIndicator(strokeWidth: 2))));
              }
              final user = _users[index];
              return MenuItemButton(
                onPressed: () => widget.onUserSelected(user),
                child: Row(
                  children: [
                    AdminWebUi.userAvatarCircle(
                      avatarUrl: user.avatarUrl,
                      displayName: user.fullName,
                      radius: 12,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextMain)),
                          Text(user.email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kTextMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


