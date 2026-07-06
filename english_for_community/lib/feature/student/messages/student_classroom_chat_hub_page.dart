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

  /// Một hàng hội thoại. Nếu chưa đọc → bọc [Dismissible] để **vuốt trái
  /// đánh dấu đã đọc** (snap-back, không xóa khỏi list).
  Widget _buildRow(ClassroomChatRoomItem room) {
    final tile = ConversationTile(
      key: ValueKey(room.id),
      room: room,
      density: ConversationTileDensity.mobile,
      onTap: () => _openChat(room),
      onLongPress: () => _showConversationMenu(room),
      typingText: _controller.typingNameFor(room.id),
    );
    if (!room.hasUnread) return tile;
    return Dismissible(
      key: ValueKey('swipe_${room.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      confirmDismiss: (_) async {
        await _controller.markConversationRead(room.id, notify: true);
        return false; // snap back — chỉ đánh dấu đọc, giữ lại trong list
      },
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        color: AppColors.successBg,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.s5),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded, size: 18, color: AppColors.success),
            SizedBox(width: AppSpacing.s2),
            Text(
              'Đã đọc',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: tile,
    );
  }

  /// Nhấn-giữ hàng → menu: Ghim / Tắt tiếng / Đánh dấu đã đọc.
  void _showConversationMenu(ClassroomChatRoomItem room) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet + 2)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.s3),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s4,
                  AppSpacing.s5,
                  AppSpacing.s2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StudentMobileUi.cardTitle(context),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  room.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  room.isPinned ? 'Bỏ ghim' : 'Ghim lên đầu',
                  style: StudentMobileUi.body(context),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _controller.togglePin(room);
                },
              ),
              ListTile(
                leading: Icon(
                  room.muted
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  room.muted ? 'Bật thông báo' : 'Tắt thông báo',
                  style: StudentMobileUi.body(context),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _controller.toggleMute(room);
                },
              ),
              if (room.hasUnread)
                ListTile(
                  leading: const Icon(
                    Icons.done_all_rounded,
                    color: AppColors.textSecondary,
                  ),
                  title: Text(
                    'Đánh dấu đã đọc',
                    style: StudentMobileUi.body(context),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _controller.markConversationRead(room.id, notify: true);
                  },
                ),
              const SizedBox(height: AppSpacing.s3),
            ],
          ),
        );
      },
    );
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
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unread > 0)
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded, size: 20),
                      color: AppColors.primary,
                      tooltip: 'Đánh dấu tất cả đã đọc',
                      constraints:
                          const BoxConstraints(minWidth: 44, minHeight: 44),
                      onPressed: _controller.markAllConversationsRead,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s4),
                    child: Center(
                      child: unread > 0
                          ? _HubUnreadPill(
                              label: l10n.studentChatHubUnreadCount(unread),
                            )
                          : Text(
                              l10n.studentChatHubClassCount(total),
                              style: StudentMobileUi.caption(context)
                                  .copyWith(color: AppColors.textMuted),
                            ),
                    ),
                  ),
                ],
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

                  // Nhóm hiển thị: Ghim → Chưa đọc → Khác (chỉ tách khi xem
                  // Tất cả & không tìm kiếm). Dùng data sẵn có.
                  final showGroups =
                      _filter == _StudentChatHubFilter.all && !hasQuery;
                  final pinnedRooms = <ClassroomChatRoomItem>[];
                  final unreadRooms = <ClassroomChatRoomItem>[];
                  final otherRooms = <ClassroomChatRoomItem>[];
                  for (final r in filtered) {
                    if (showGroups && r.isPinned) {
                      pinnedRooms.add(r);
                    } else if (showGroups && r.hasUnread) {
                      unreadRooms.add(r);
                    } else {
                      otherRooms.add(r);
                    }
                  }
                  final sections = <_HubSection>[];
                  if (pinnedRooms.isNotEmpty) {
                    sections.add(_HubSection('Đã ghim', pinnedRooms));
                  }
                  if (unreadRooms.isNotEmpty) {
                    sections.add(_HubSection(
                      l10n.studentChatHubFilterUnread,
                      unreadRooms,
                      emphasize: true,
                    ));
                  }
                  if (otherRooms.isNotEmpty) {
                    sections.add(_HubSection(
                      sections.isEmpty ? '' : 'Trò chuyện',
                      otherRooms,
                    ));
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        StudentMobileUi.pageHPadding,
                        0,
                        StudentMobileUi.pageHPadding,
                        StudentMobileUi.pageBottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < sections.length; i++) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.s5),
                            if (sections[i].label.isNotEmpty) ...[
                              _GroupLabel(
                                label: sections[i].label,
                                count: sections[i].rooms.length,
                                emphasize: sections[i].emphasize,
                              ),
                              const SizedBox(height: AppSpacing.s2),
                            ],
                            _GroupedCard(
                              dividerIndent: dividerIndent,
                              children: [
                                for (final room in sections[i].rooms)
                                  _buildRow(room),
                              ],
                            ),
                          ],
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

/// Một nhóm hội thoại trong hub (Ghim / Chưa đọc / Khác).
class _HubSection {
  const _HubSection(this.label, this.rooms, {this.emphasize = false});

  final String label;
  final List<ClassroomChatRoomItem> rooms;
  final bool emphasize;
}

/// Nhãn nhóm nhỏ trên mỗi grouped card ("Chưa đọc" / "Đã đọc"). [emphasize] →
/// chấm accent + chữ đậm để nhóm chưa đọc nổi lên.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({
    required this.label,
    required this.count,
    this.emphasize = false,
  });

  final String label;
  final int count;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.s2, bottom: AppSpacing.s1),
      child: Row(
        children: [
          if (emphasize) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color:
                  emphasize ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill "N chưa đọc" ở header — nhuộm amber (accent) để báo có tin mới.
class _HubUnreadPill extends StatelessWidget {
  const _HubUnreadPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: StudentMobileUi.caption(context).copyWith(
          color: AppColors.accentDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
