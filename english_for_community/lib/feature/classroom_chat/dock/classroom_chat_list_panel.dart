import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_controller.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_room_tile.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';

/// Panel trượt danh sách nhóm lớp — kiểu Messenger dropdown.
class ClassroomChatListPanel extends StatefulWidget {
  const ClassroomChatListPanel({
    super.key,
    required this.controller,
    required this.topOffset,
  });

  final ClassroomChatDockController controller;
  final double topOffset;

  @override
  State<ClassroomChatListPanel> createState() => _ClassroomChatListPanelState();
}

class _ClassroomChatListPanelState extends State<ClassroomChatListPanel> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClassroomChatRoomItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.controller.rooms;
    return widget.controller.rooms
        .where((r) => r.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final filtered = _filtered;
    final activeId = c.session?.classroomId;

    return Positioned(
      top: widget.topOffset,
      right: 16,
      child: Material(
        color: AppColors.surfaceCard,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.outline),
        ),
        child: Container(
          width: ClassroomChatUi.listPanelWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          decoration: BoxDecoration(
            boxShadow: ClassroomChatUi.dockShadow(elevation: 20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PanelHeader(onClose: c.closeListPanel),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  0,
                  AppSpacing.s4,
                  AppSpacing.s3,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: ClassroomChatUi.searchFieldDecoration(hintText: 'Tìm nhóm lớp…'),
                ),
              ),
              Flexible(
                child: c.loadingRooms
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: AppLoadingIndicator.center()),
                      )
                    : c.roomsError != null
                        ? SingleChildScrollView(
                            child: ClassroomChatRoomListError(
                              message: c.roomsError!,
                              onRetry: () => c.loadRooms(force: true),
                            ),
                          )
                        : filtered.isEmpty
                            ? SingleChildScrollView(
                                child: ClassroomChatRoomListEmpty(
                                  hasQuery: _query.trim().isNotEmpty,
                                  compact: true,
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  indent: 68,
                                  endIndent: AppSpacing.s4,
                                  color: AppColors.outlineMuted,
                                ),
                                itemBuilder: (_, i) {
                                  final room = filtered[i];
                                  return ClassroomChatRoomTile(
                                    room: room,
                                    isActive: room.id == activeId,
                                    onTap: () => c.openChat(
                                      classroomId: room.id,
                                      classroomName: room.name,
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, AppSpacing.s2, AppSpacing.s3),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhóm chat lớp',
                  style: ClassroomChatUi.headerTitle().copyWith(fontSize: 15),
                ),
                Text(
                  'Chọn lớp để trò chuyện',
                  style: ClassroomChatUi.headerSubtitle(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Đóng',
            color: AppColors.textSecondary,
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
