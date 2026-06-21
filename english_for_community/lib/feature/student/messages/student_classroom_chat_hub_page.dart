import 'dart:async';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/classroom_chat_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
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
  State<StudentClassroomChatHubPage> createState() => _StudentClassroomChatHubPageState();
}

class _StudentClassroomChatHubPageState extends State<StudentClassroomChatHubPage>
    with AutomaticKeepAliveClientMixin {
  static const _skill = SkillType.speaking;

  final _searchCtrl = TextEditingController();
  String _query = '';
  _StudentChatHubFilter _filter = _StudentChatHubFilter.all;
  late final ClassroomChatDockController _controller;

  List<ClassroomChatRoomItem>? _cachedFiltered;
  String _cachedFilterKey = '';

  @override
  bool get wantKeepAlive => true;

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
    final v = _searchCtrl.text;
    if (v != _query && mounted) setState(() => _query = v);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClassroomChatRoomItem> _filteredRooms(List<ClassroomChatRoomItem> rooms) {
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
    final dividerIndent = ConversationTile.dividerIndent(ConversationTileDensity.mobile);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
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
                    Text(l10n.navMessages, style: StudentMobileUi.greeting(context)),
                    const SizedBox(height: AppSpacing.s2),
                    Text(l10n.studentChatHubSubtitle, style: StudentMobileUi.body(context)),
                    const SizedBox(height: AppSpacing.s4),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        final total = _controller.rooms.length;
                        final unread = _controller.unreadConversations;
                        return StudentMobileUi.skillHubBanner(
                          context: context,
                          title: l10n.studentChatHubOverviewTitle,
                          subtitle: l10n.studentChatHubOverviewBody,
                          icon: Icons.forum_rounded,
                          skill: _skill,
                          badge: total > 0 ? _hubBadge(l10n, unread, total) : null,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.s4),
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
                      skill: _skill,
                      onSelected: (i) => setState(
                        () => _filter = _StudentChatHubFilter.values[i],
                      ),
                    ),
                    const SizedBox(height: StudentMobileUi.sectionGap),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        final filtered = _filteredRooms(_controller.rooms);
                        return _SectionHeader(
                          title: l10n.studentChatHubSectionConversations,
                          count: filtered.length,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.s3),
                  ]),
                ),
              ),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final filtered = _filteredRooms(_controller.rooms);

                  if (_controller.loadingRooms && _controller.rooms.isEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: StudentMobileUi.pageBottomPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const ConversationTileSkeleton(
                            density: ConversationTileDensity.mobile,
                          ),
                          childCount: 5,
                        ),
                      ),
                    );
                  }

                  if (_controller.roomsError != null && _controller.rooms.isEmpty) {
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
                        icon: hasQuery ? Icons.search_off_outlined : Icons.forum_outlined,
                        skill: _skill,
                        title: hasQuery
                            ? l10n.studentChatHubSearchEmptyTitle
                            : l10n.studentChatHubEmptyTitle,
                        body: hasQuery
                            ? l10n.studentChatHubSearchEmptyBody
                            : l10n.studentChatHubEmptyBody,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: StudentMobileUi.pageBottomPadding),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          if (i.isOdd) {
                            return Divider(
                              height: 1,
                              indent: dividerIndent,
                              endIndent: AppSpacing.s4,
                              color: AppColors.outlineMuted,
                            );
                          }
                          final room = filtered[i ~/ 2];
                          return ConversationTile(
                            key: ValueKey(room.id),
                            room: room,
                            density: ConversationTileDensity.mobile,
                            onTap: () => _openChat(room),
                          );
                        },
                        childCount: filtered.length * 2 - 1,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: StudentMobileUi.sectionTitle(context))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppSkillColors.speaking.tint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppSkillColors.speaking.color.withValues(alpha: 0.25)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppSkillColors.speaking.dark,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
