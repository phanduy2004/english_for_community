import 'package:english_for_community/core/get_it/get_it.dart' as sl;
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_controller.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_list_panel.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_mini_window.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Overlay Messenger-style: panel danh sách + mini chat góc phải dưới.
class ClassroomChatDock extends StatefulWidget {
  const ClassroomChatDock({super.key, required this.child});

  final Widget child;

  @override
  State<ClassroomChatDock> createState() => _ClassroomChatDockState();
}

class _ClassroomChatDockState extends State<ClassroomChatDock> {
  late final ClassroomChatDockController _controller;

  @override
  void initState() {
    super.initState();
    registerClassroomChatDockController();
    _controller = sl.getIt<ClassroomChatDockController>();
    _controller.addListener(_onControllerChanged);
    _controller.attachInboxSocket();
    _controller.refreshInboxBadge();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = _controller.session;
    final userId = context.select<UserBloc, String?>(
          (b) => b.state.userEntity?.id,
        ) ??
        '';

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // Mini chat trước — khi mở danh sách thì list panel vẽ đè lên (Messenger-style).
        if (session != null && userId.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: session.minimized
                ? ClassroomChatMinimizedBar(
                    session: session,
                    onRestore: _controller.restoreChat,
                    onClose: _controller.closeChat,
                  )
                : ClassroomChatMiniWindow(
                    session: session,
                    controller: _controller,
                    currentUserId: userId,
                  ),
          ),
        if (_controller.listPanelOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _controller.closeListPanel,
              child: Container(color: Colors.black.withValues(alpha: 0.32)),
            ),
          ),
          ClassroomChatListPanel(
            controller: _controller,
            topOffset: TeacherWebUi.topBarHeight + 8,
          ),
        ],
      ],
    );
  }
}

/// Nút mở panel danh sách nhóm chat — đặt trên top bar.
class ClassroomChatDockButton extends StatelessWidget {
  const ClassroomChatDockButton({super.key});

  @override
  Widget build(BuildContext context) {
    registerClassroomChatDockController();
    final controller = sl.getIt<ClassroomChatDockController>();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final active = controller.listPanelOpen || controller.session != null;
        final unread = controller.unreadConversations;
        return IconButton(
          tooltip: 'Nhóm chat lớp',
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: Icon(
              active ? Icons.chat_bubble : Icons.chat_bubble_outline,
              size: 18,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          onPressed: controller.toggleListPanel,
        );
      },
    );
  }
}
