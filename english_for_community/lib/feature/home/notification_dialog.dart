import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Import Bloc & Entity
import '../../../../core/entity/notification_entity.dart';
import 'bloc_noti/notification_bloc.dart';
import 'bloc_noti/notification_event.dart';
import 'bloc_noti/notification_state.dart';

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({super.key});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 🔥 Gọi event load data (Reload lại list để cập nhật mới nhất)
    // Dùng context.read vì Bloc đã được cung cấp bởi HomePage qua BlocProvider.value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(const NotificationLoadStarted(isRefresh: true));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // ❌ QUAN TRỌNG: KHÔNG ĐƯỢC GỌI bloc.close() Ở ĐÂY
    // Vì Bloc này thuộc về HomePage, nếu đóng ở đây thì HomePage sẽ bị lỗi.
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<NotificationBloc>().add(NotificationLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE4E4E7);
    const primaryText = Color(0xFF09090B);
    const mutedText = Color(0xFF71717A);
    const bgHover = Color(0xFFF4F4F5);

    // Không cần BlocProvider ở đây nữa vì đã wrap ở HomePage rồi
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Thông báo",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                    letterSpacing: -0.5,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    context.read<NotificationBloc>().add(NotificationMarkAllRead());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      "Đánh dấu đã đọc",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BODY LIST ---
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500),
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  // Chỉ hiện loading nếu danh sách rỗng (load lần đầu)
                  if (state.status == NotificationStatus.loading && state.notifications.isEmpty) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }

                  if (state.notifications.isEmpty) {
                    return const _EmptyState(primaryText: primaryText, mutedText: mutedText);
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: state.hasReachedMax
                        ? state.notifications.length
                        : state.notifications.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: borderColor),
                    itemBuilder: (context, index) {
                      if (index >= state.notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final item = state.notifications[index];
                      return _NotificationItem(
                        item: item,
                        primaryText: primaryText,
                        mutedText: mutedText,
                        bgHover: bgHover,
                        onTap: () {
                          // Đánh dấu đã đọc
                          context.read<NotificationBloc>().add(NotificationMarkRead(item.id));

                          // TODO: Xử lý điều hướng
                          // Navigator.pop(context); // Nếu muốn đóng dialog
                          // context.push(...)
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // --- FOOTER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: mutedText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Giữ nguyên class _NotificationItem, _EmptyState như cũ)
class _NotificationItem extends StatelessWidget {
  final NotificationEntity item;
  final Color primaryText;
  final Color mutedText;
  final Color bgHover;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.item,
    required this.primaryText,
    required this.mutedText,
    required this.bgHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = item.isRead ? Colors.white : const Color(0xFFF8FAFC);

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                      image: item.senderAvatar != null && item.senderAvatar!.isNotEmpty
                          ? DecorationImage(image: NetworkImage(item.senderAvatar!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: item.senderAvatar == null || item.senderAvatar!.isEmpty
                        ? Icon(Icons.person, size: 20, color: mutedText)
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
                        ],
                      ),
                      child: _getTypeIcon(item.type),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: primaryText, height: 1.4),
                        children: [
                          TextSpan(
                            text: "${item.senderName} ",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: item.message,
                            style: const TextStyle(color: Color(0xFF3F3F46)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(item.createdAt),
                      style: TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTypeIcon(String type) {
    switch (type) {
      case 'COMMENT_REPLY':
        return const Icon(Icons.reply_rounded, size: 12, color: Colors.blue);
      case 'COMMENT_REACTION':
        return const Icon(Icons.favorite_rounded, size: 12, color: Colors.redAccent);
      case 'SYSTEM_ANNOUNCEMENT':
        return const Icon(Icons.campaign_rounded, size: 12, color: Colors.amber);
      default:
        return const Icon(Icons.notifications_rounded, size: 12, color: Colors.grey);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return DateFormat('dd/MM HH:mm').format(time);
  }
}

class _EmptyState extends StatelessWidget {
  final Color primaryText;
  final Color mutedText;
  const _EmptyState({required this.primaryText, required this.mutedText});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF4F4F5), shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 32, color: mutedText),
          ),
          const SizedBox(height: 16),
          Text("Chưa có thông báo nào", style: TextStyle(color: primaryText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("Bạn sẽ nhận được thông báo tại đây.", style: TextStyle(color: mutedText, fontSize: 13)),
        ],
      ),
    );
  }
}