import 'package:english_for_community/core/get_it/get_it.dart' as di;
import 'package:english_for_community/core/repository/classroom_chat_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_bloc.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_event.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_state.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_controller.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_settings_menu.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_app_bar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_body.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cửa sổ chat nổi góc phải dưới — kiểu Facebook Messenger.
class ClassroomChatMiniWindow extends StatefulWidget {
  const ClassroomChatMiniWindow({
    super.key,
    required this.session,
    required this.controller,
    required this.currentUserId,
  });

  final ClassroomChatSession session;
  final ClassroomChatDockController controller;
  final String currentUserId;

  static const double width = ClassroomChatUi.miniWindowWidth;
  static const double height = ClassroomChatUi.miniWindowHeight;
  static const double settingsGap = 8;

  @override
  State<ClassroomChatMiniWindow> createState() => _ClassroomChatMiniWindowState();
}

class _ClassroomChatMiniWindowState extends State<ClassroomChatMiniWindow> {
  bool _settingsOpen = false;

  void _toggleSettings() => setState(() => _settingsOpen = !_settingsOpen);
  void _closeSettings() => setState(() => _settingsOpen = false);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(widget.session.classroomId),
      create: (_) => ClassroomChatBloc(
        classroomId: widget.session.classroomId,
        currentUserId: widget.currentUserId,
        repo: di.getIt<ClassroomChatRepository>(),
        socket: di.getIt<SocketService>(),
      )..add(const ClassroomChatLoaded()),
      child: BlocListener<ClassroomChatBloc, ClassroomChatState>(
        listenWhen: (p, c) {
          if (widget.controller.session?.minimized ?? true) return false;
          if (c.status == ClassroomChatStatus.ready && p.status != ClassroomChatStatus.ready) {
            return true;
          }
          return c.messages.length != p.messages.length;
        },
        listener: (_, __) {
          widget.controller.markConversationRead(
            widget.session.classroomId,
            notify: true,
          );
        },
        child: BlocBuilder<ClassroomChatBloc, ClassroomChatState>(
        buildWhen: (p, c) =>
            p.members != c.members ||
            p.groupName != c.groupName ||
            p.coverImageUrl != c.coverImageUrl ||
            p.isUpdatingSettings != c.isUpdatingSettings,
        builder: (context, state) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_settingsOpen) ...[
                ChatSettingsSidePanel(
                  members: state.members,
                  classroomName: state.displayName(widget.session.classroomName),
                  currentUserId: widget.currentUserId,
                  height: ClassroomChatMiniWindow.height,
                  onClose: _closeSettings,
                  onMinimize: widget.controller.minimizeChat,
                  onCloseChat: widget.controller.closeChat,
                  onMuteChat: widget.controller.closeChat,
                  onLeaveGroup: widget.controller.closeChat,
                ),
                const SizedBox(width: ClassroomChatMiniWindow.settingsGap),
              ],
              _ChatWindowCard(
                session: widget.session,
                controller: widget.controller,
                currentUserId: widget.currentUserId,
                settingsOpen: _settingsOpen,
                onToggleSettings: _toggleSettings,
                memberCount: state.members.length,
                displayName: state.displayName(widget.session.classroomName),
                coverImageUrl: state.coverImageUrl,
                isClassOwner: state.isClassOwner(widget.currentUserId),
                coverUploading: state.isUpdatingSettings,
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}

class _ChatWindowCard extends StatelessWidget {
  const _ChatWindowCard({
    required this.session,
    required this.controller,
    required this.currentUserId,
    required this.settingsOpen,
    required this.onToggleSettings,
    required this.memberCount,
    required this.displayName,
    this.coverImageUrl,
    this.isClassOwner = false,
    this.coverUploading = false,
  });

  final ClassroomChatSession session;
  final ClassroomChatDockController controller;
  final String currentUserId;
  final bool settingsOpen;
  final VoidCallback onToggleSettings;
  final int memberCount;
  final String displayName;
  final String? coverImageUrl;
  final bool isClassOwner;
  final bool coverUploading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: ClassroomChatMiniWindow.width,
        height: ClassroomChatMiniWindow.height,
        decoration: ClassroomChatUi.panelShell(radius: 12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ClassroomChatHeader(
              title: displayName,
              subtitle: memberCount > 0
                  ? '$memberCount thành viên'
                  : 'Nhóm lớp học',
              coverImageUrl: coverImageUrl,
              compact: true,
              settingsOpen: settingsOpen,
              onTitleTap: onToggleSettings,
              onCoverTap: isClassOwner
                  ? () => ChatGroupAvatarPicker.pickAndUpload(context)
                  : null,
              coverUploading: coverUploading,
              onMinimize: controller.minimizeChat,
              onClose: controller.closeChat,
            ),
            Expanded(
              child: ClipRect(
                child: ClassroomChatBody(
                  classroomId: session.classroomId,
                  classroomName: session.classroomName,
                  currentUserId: currentUserId,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh thu nhỏ khi minimize — click để mở lại.
class ClassroomChatMinimizedBar extends StatelessWidget {
  const ClassroomChatMinimizedBar({
    super.key,
    required this.session,
    required this.onRestore,
    required this.onClose,
  });

  final ClassroomChatSession session;
  final VoidCallback onRestore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        onTap: onRestore,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ClassroomChatUi.dockShadow(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.textInverse, size: 18),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  session.classroomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  Icons.close,
                  color: AppColors.textInverse.withValues(alpha: 0.75),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
