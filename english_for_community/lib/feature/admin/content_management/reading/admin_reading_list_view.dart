import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// 👇 Import GetIt để lấy Dependency (Repository/Bloc)
import '../../../../../core/get_it/get_it.dart';
import '../../../../../core/entity/reading/reading_entity.dart';
import '../content_widgets.dart';
import 'bloc/admin_reading_bloc.dart';
import 'bloc/admin_reading_event.dart';
import 'bloc/admin_reading_state.dart';

// ==========================================
// 1. CLASS PUBLIC (Dùng để gọi trong Router)
// Nhiệm vụ: Cung cấp Bloc (BlocProvider)
// ==========================================
class AdminReadingListView extends StatelessWidget {
  final String skillType;

  const AdminReadingListView({super.key, required this.skillType});

  @override
  Widget build(BuildContext context) {
    // 👇 WRAP BẰNG BLOC PROVIDER TẠI ĐÂY
    return BlocProvider(
      // Sử dụng getIt để tạo Bloc mới mỗi khi vào trang này
      create: (_) => getIt<AdminReadingBloc>(),
      child: _AdminReadingListBody(skillType: skillType),
    );
  }
}

// ==========================================
// 2. CLASS PRIVATE (Logic UI & State)
// Nhiệm vụ: Hiển thị UI, Fetch data
// ==========================================
class _AdminReadingListBody extends StatefulWidget {
  final String skillType;

  const _AdminReadingListBody({required this.skillType});

  @override
  State<_AdminReadingListBody> createState() => _AdminReadingListBodyState();
}

class _AdminReadingListBodyState extends State<_AdminReadingListBody> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    // Lúc này context đã nằm dưới BlocProvider nên sẽ tìm thấy Bloc
    context.read<AdminReadingBloc>().add(
      const GetAdminReadingListEvent(limit: 9999, page: 1),
    );
  }

  void _openEditor(BuildContext context, String? id) async {
    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': widget.skillType},
      extra: id,
    );

    if (mounted) {
      context.read<AdminReadingBloc>().add(
        const GetAdminReadingListEvent(limit: 9999, page: 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextMain),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${widget.skillType[0].toUpperCase()}${widget.skillType.substring(
              1)} Management',
          style: const TextStyle(
              color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: kBorder, height: 1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kTextMain),
              tooltip: 'Thêm bài mới',
              onPressed: () => _openEditor(context, null),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: BlocBuilder<AdminReadingBloc, AdminReadingState>(
              builder: (context, state) {
                if (state.status == AdminReadingStatus.loading &&
                    state.readings.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == AdminReadingStatus.failure &&
                    state.readings.isEmpty) {
                  return Center(
                      child: Text("Lỗi: ${state.errorMessage ?? 'Unknown'}"));
                }

                if (state.readings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                            Icons.menu_book, size: 64, color: kTextMuted),
                        const SizedBox(height: 16),
                        const Text("Chưa có bài đọc nào.",
                            style: TextStyle(color: kTextMuted)),
                        TextButton.icon(
                          onPressed: () => _openEditor(context, null),
                          icon: const Icon(Icons.add),
                          label: const Text("Tạo bài đầu tiên"),
                        )
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<AdminReadingBloc>().add(
                      const GetAdminReadingListEvent(limit: 9999, page: 1),
                    );
                  },
                  child: _buildListItems(context, state.readings),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kWhite,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm bài tập...',
                  prefixIcon: Icon(Icons.search, size: 18, color: kTextMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(8)),
            child:
            const Center(child: Icon(Icons.filter_list, color: kTextMuted)),
          )
        ],
      ),
    );
  }
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa bài đọc này không? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Đóng dialog
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog trước
              // Gọi Event Xóa
              context.read<AdminReadingBloc>().add(DeleteReadingEvent(id));
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildListItems(BuildContext context, List<ReadingEntity> readings) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: readings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reading = readings[index];
        return ShadcnCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Chỉnh padding
          onTap: () => _openEditor(context, reading.id),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    image: (reading.imageUrl != null && reading.imageUrl!.startsWith('http'))
                        ? DecorationImage(image: NetworkImage(reading.imageUrl!), fit: BoxFit.cover)
                        : null
                ),
                child: (reading.imageUrl == null || !reading.imageUrl!.startsWith('http'))
                    ? Center(child: Text(reading.title.isNotEmpty ? reading.title[0] : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMuted)))
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reading.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("${reading.difficulty?.name.toUpperCase() ?? 'UNKNOWN'} • ${reading.minutesToRead} mins",
                        style: const TextStyle(fontSize: 12, color: kTextMuted)),
                  ],
                ),
              ),

              // 👇 NÚT XÓA (Thùng rác)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  // Dừng sự kiện onTap của Card để tránh mở Editor
                  // (Tuy nhiên IconButton đã tự capture touch event nên ổn)
                  _confirmDelete(context, reading.id);
                },
              ),

              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: kTextMuted, size: 20),
            ],
          ),
        );
      },
    );
  }
}