import 'dart:async';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/core/repository/classroom_chat_repository.dart';
import 'package:english_for_community/feature/classroom_chat/classroom_chat_page.dart';
import 'package:english_for_community/feature/classroom_chat/classroom_chat_session_cache.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_controller.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_room_tile.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:english_for_community/feature/student/messages/student_messenger_conversation_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _StudentChatHubFilter { all, unread }

/// Tab Tin nhắn — danh sách nhóm chat lớp (học sinh, mobile).
class StudentClassroomChatHubPage extends StatefulWidget {
  const StudentClassroomChatHubPage({super.key});

  @override
  State<StudentClassroomChatHubPage> createState() => _StudentClassroomChatHubPageState();
}

class _StudentClassroomChatHubPageState extends State<StudentClassroomChatHubPage>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _StudentChatHubFilter _filter = _StudentChatHubFilter.all;
  late final ClassroomChatDockController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    registerClassroomChatDockController();
    _controller = getIt<ClassroomChatDockController>();
    _controller.attachInboxSocket();
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _controller.loadRooms(force: true);
      if (!mounted) return;
      final repo = getIt<ClassroomChatRepository>();
      for (final room in _controller.rooms.take(3)) {
        ClassroomChatSessionCache.prefetch(
          classroomId: room.id,
          repo: repo,
          coverImageUrl: room.coverImageUrl,
          groupName: room.name,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  List<ClassroomChatRoomItem> get _filtered {
    var list = _controller.rooms;
    if (_filter == _StudentChatHubFilter.unread) {
      list = list.where((r) => r.hasUnread).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  void _openChat(ClassroomChatRoomItem room) {
    final userId = getIt<UserBloc>().state.userEntity?.id ?? '';
    if (userId.isEmpty) return;

    ClassroomChatSessionCache.prefetch(
      classroomId: room.id,
      repo: getIt<ClassroomChatRepository>(),
      coverImageUrl: room.coverImageUrl,
      groupName: room.name,
    );
    unawaited(_controller.markConversationRead(room.id, notify: true));

    context.push(
      ClassroomChatPage.studentRoutePath(room.id),
      extra: {
        'classroomName': room.name,
        'currentUserId': userId,
        'coverImageUrl': room.coverImageUrl,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final filtered = _filtered;

    return ColoredBox(
      color: AppColors.surface,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _controller.loadRooms(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: StudentMobileUi.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.navMessages, style: StudentMobileUi.greeting(context)),
                    const SizedBox(height: AppSpacing.s4),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: ClassroomChatUi.searchFieldDecoration(
                        hintText: l10n.studentChatHubSearchHint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          StudentChatHubFilterChip(
                            label: l10n.studentChatHubFilterAll,
                            selected: _filter == _StudentChatHubFilter.all,
                            onTap: () => setState(() => _filter = _StudentChatHubFilter.all),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          StudentChatHubFilterChip(
                            label: l10n.studentChatHubFilterUnread,
                            selected: _filter == _StudentChatHubFilter.unread,
                            onTap: () =>
                                setState(() => _filter = _StudentChatHubFilter.unread),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_controller.loadingRooms && _controller.rooms.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: AppLoadingIndicator.center()),
              )
            else if (_controller.roomsError != null && _controller.rooms.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ClassroomChatRoomListError(
                  message: _controller.roomsError!,
                  onRetry: () => _controller.loadRooms(force: true),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ClassroomChatRoomListEmpty(hasQuery: _query.trim().isNotEmpty),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  StudentMobileUi.pageHPadding,
                  AppSpacing.s2,
                  StudentMobileUi.pageHPadding,
                  StudentMobileUi.pageBottomPadding,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => StudentMessengerConversationTile(
                      room: filtered[i],
                      onTap: () => _openChat(filtered[i]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
