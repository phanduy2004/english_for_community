import 'dart:async';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/classroom_chat_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
// (messages tab dùng Editorial Black primary, không dùng skill color)
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/classroom_chat/classroom_chat_page.dart';
import 'package:english_for_community/feature/classroom_chat/classroom_chat_session_cache.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_controller.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/conversation_tile.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _StudentChatHubFilter { all, unread }

/// Tab Tin nhắn — danh sách nhóm chat lớp (học sinh, mobile).
class StudentClassroomChatHubPage extends StatefulWidget {
  const StudentClassroomChatHubPage({super.key});

  @override
  State<StudentClassroomChatHubPage> createState() =>
      _StudentClassroomChatHubPageState();
}

class _StudentClassroomChatHubPageState
    extends State<StudentClassroomChatHubPage>
    with AutomaticKeepAliveClientMixin {
  // Tab Messages dùng màu primary (Editorial Black) — KHÔNG nhuộm skill color.

  final _searchCtrl = TextEditingController();
  String _query = '';
  _StudentChatHubFilter _filter = _StudentChatHubFilter.all;
  late final ClassroomChatDockController _controller;

  List<ClassroomChatRoomItem>? _cachedFiltered;
  String _cachedFilterKey = '';

  @override
  bool get wantKeepAlive => true;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    registerClassroomChatDockController();
    _controller = getIt<ClassroomChatDockController>();
    _controller.attachInboxSocket();
    _searchCtrl.addListener(_onSearchChanged);
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

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      final v = _searchCtrl.text;
      if (v != _query && mounted) setState(() => _query = v);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClassroomChatRoomItem> _filteredRooms(
      List<ClassroomChatRoomItem> rooms) {
    final key =
        '${rooms.length}|${rooms.map((r) => '${r.id}:${r.unreadCount}:${r.lastMessageAt?.millisecondsSinceEpoch}').join(';')}|$_query|$_filter';
    if (_cachedFiltered != null && _cachedFilterKey == key) {
      return _cachedFiltered!;
    }

    var list = rooms;
    if (_filter == _StudentChatHubFilter.unread) {
      list = list.where((r) => r.hasUnread).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) => r.name.toLowerCase().contains(q)).toList();
    }

    _cachedFiltered = list;
    _cachedFilterKey = key;
    return list;
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

  String _hubBadge(AppLocalizations l10n, int unread, int total) {
    if (unread > 0) return l10n.studentChatHubUnreadCount(unread);
    return l10n.studentChatHubClassCount(total);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final hasQuery = _query.trim().isNotEmpty;
    final dividerIndent =
        ConversationTile.dividerIndent(ConversationTileDensity.mobile);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.appBar(
        context,
        title: l10n.navMessages,
        showBack: false,
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final total = _controller.rooms.length;
              if (total == 0) return const SizedBox.shrink();
              final unread = _controller.unreadConversations;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s4),
                child: Center(
                  child: Text(
                    _hubBadge(l10n, unread, total),
                    style: StudentMobileUi.caption(context)
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceCard,
          onRefresh: () => _controller.loadRooms(force: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: StudentMobileUi.pagePadding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    StudentMobileUi.searchField(
                      controller: _searchCtrl,
                      hintText: l10n.studentChatHubSearchHint,
                      showClear: hasQuery,
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    StudentMobileUi.filterRow(
                      labels: [
                        l10n.studentChatHubFilterAll,
                        l10n.studentChatHubFilterUnread,
                      ],
                      selectedIndex: _filter.index,
                      onSelected: (i) => setState(
                        () => _filter = _StudentChatHubFilter.values[i],
                      ),
                    ),
                  ]),
                ),
              ),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final filtered = _filteredRooms(_controller.rooms);

                  if (_controller.loadingRooms && _controller.rooms.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          StudentMobileUi.pageHPadding,
                          0,
                          StudentMobileUi.pageHPadding,
                          StudentMobileUi.pageBottomPadding,
                        ),
                        child: _GroupedCard(
                          dividerIndent: dividerIndent,
                          children: List.generate(
                            5,
                            (_) => const ConversationTileSkeleton(
                              density: ConversationTileDensity.mobile,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (_controller.roomsError != null &&
                      _controller.rooms.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: StudentMobileUi.pagePadding,
                        child: StudentMobileUi.errorBanner(
                          message: _controller.roomsError!,
                          onRetry: () => _controller.loadRooms(force: true),
                          retryLabel: l10n.retry,
                        ),
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: StudentMobileUi.emptyState(
                        context,
                        icon: hasQuery
                            ? Icons.search_off_outlined
                            : Icons.forum_outlined,
                        title: hasQuery
                            ? l10n.studentChatHubSearchEmptyTitle
                            : l10n.studentChatHubEmptyTitle,
                        body: hasQuery
                            ? l10n.studentChatHubSearchEmptyBody
                            : l10n.studentChatHubEmptyBody,
                      ),
                    );
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        StudentMobileUi.pageHPadding,
                        0,
                        StudentMobileUi.pageHPadding,
                        StudentMobileUi.pageBottomPadding,
                      ),
                      child: _GroupedCard(
                        dividerIndent: dividerIndent,
                        children: [
                          for (final room in filtered)
                            ConversationTile(
                              key: ValueKey(room.id),
                              room: room,
                              density: ConversationTileDensity.mobile,
                              onTap: () => _openChat(room),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inset grouped card — bọc các hàng hội thoại trong 1 thẻ bo tròn + shadow
/// nhẹ + divider inset giữa hàng (kiểu iOS/Telegram). Editorial Black tokens.
class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children, required this.dividerIndent});

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: dividerIndent,
          endIndent: AppSpacing.s4,
          color: AppColors.outlineMuted,
        ));
      }
      rows.add(children[i]);
    }

    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: radius,
        border: Border.all(color: AppColors.outline),
        // Flat to match AppCard(outline) elsewhere — only a 1px hairline lift,
        // không double-shadow nặng (docs/ui-ux-system/23 §3.4 — hàng phẳng).
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowHairline,
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }
}
