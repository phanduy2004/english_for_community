import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/get_it/get_it.dart';
import '../../../../core/repository/admin_repository.dart'; // Đảm bảo bạn đã có AdminRepository
import '../../../../core/entity/user_entity.dart'; // Hoặc model User của bạn
import '../activity_history_page.dart'; // Import constants màu sắc

class UserSearchSheet extends StatefulWidget {
  const UserSearchSheet({super.key});

  @override
  State<UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<UserSearchSheet> {
  // Logic
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // Data State
  List<UserEntity> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Load trang 1 ngay khi mở
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Xử lý tìm kiếm (Debounce để tránh spam API)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchKeyword = query;
        _users.clear();
        _currentPage = 1;
        _hasMore = true;
      });
      _fetchUsers();
    });
  }

  // Xử lý cuộn để load thêm (Pagination)
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchUsers();
      }
    }
  }

  // Gọi API (Sử dụng AdminRepository)
  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Gọi repository admin (đã viết trước đó)
      // getAllUsers(page, limit, filter, search)
      final result = await getIt<AdminRepository>().getAllUsers(
        page: _currentPage,
        limit: 15, // Load 15 người mỗi lần
        search: _searchKeyword,
      );

      result.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
            (response) {
          setState(() {
            _users.addAll(response.data);
            _currentPage++;
            // Nếu số lượng trả về ít hơn limit -> Hết dữ liệu
            if (response.data.length < 15) _hasMore = false;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Chiếm 85% màn hình
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. HEADER & SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text("Select User", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextMain)),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Search by name or email...",
                    prefixIcon: const Icon(Icons.search, color: kTextMuted),
                    filled: true,
                    fillColor: kBgPage,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          // 2. USER LIST
          Expanded(
            child: _users.isEmpty && !_isLoading
                ? const Center(child: Text("No users found", style: TextStyle(color: kTextMuted)))
                : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _users.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == _users.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                }
                final user = _users[index];
                return _buildUserItem(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(UserEntity user) {
    return InkWell(
      onTap: () {
        // Trả về user đã chọn và đóng sheet
        Navigator.pop(context, user);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kWhite,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.avatarUrl ?? ''),
              backgroundColor: kBgPage,
              onBackgroundImageError: (_,__) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextMain)),
                  Text(user.email ?? '', style: const TextStyle(fontSize: 12, color: kTextMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kBorder),
          ],
        ),
      ),
    );
  }
}