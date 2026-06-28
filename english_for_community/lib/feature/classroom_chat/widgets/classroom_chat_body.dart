import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/widget/app_skeleton.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_bloc.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_event.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_state.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_pinned_banner.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_input_bar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_message_bubble.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_message_interaction_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Stable list identity for [ListView] children — prefer server id; index when needed.
String classroomChatMessageListKey(
  ClassroomChatMessage msg,
  int indexInList,
  List<ClassroomChatMessage> allMessages,
) {
  if (msg.id.isNotEmpty) {
    final dupes = allMessages.where((m) => m.id == msg.id).length;
    return dupes > 1 ? '${msg.id}_$indexInList' : msg.id;
  }
  final clientId = msg.clientId;
  if (clientId != null && clientId.isNotEmpty) return 'client_$clientId';
  return 'idx_$indexInList';
}

/// Reusable chat body — dùng cho full page hoặc mini window.
class ClassroomChatBody extends StatefulWidget {
  const ClassroomChatBody({
    super.key,
    required this.classroomId,
    required this.classroomName,
    required this.currentUserId,
    this.compact = false,
    this.highlightTeacherMessages = false,
  });

  final String classroomId;
  final String classroomName;
  final String currentUserId;
  final bool compact;
  /// Student chat: golden styling for teacher/co-teacher messages. Teacher dock uses default false.
  final bool highlightTeacherMessages;

  @override
  State<ClassroomChatBody> createState() => _ClassroomChatBodyState();
}

class _ClassroomChatBodyState extends State<ClassroomChatBody> {
  static const _nearBottomThreshold = 120.0;
  static const _loadMoreThreshold = 80.0;

  final ScrollController _scrollCtrl = ScrollController();
  final ChatMessageInteractionLock _interactionLock = ChatMessageInteractionLock();
  ClassroomChatMessage? _replyTo;

  bool _stickToBottom = true;
  int _prevMessageCount = 0;
  String? _prevErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _interactionLock.dispose();
    super.dispose();
  }

  bool get _isNearBottom {
    if (!_scrollCtrl.hasClients) return true;
    return _scrollCtrl.offset <= _nearBottomThreshold;
  }

  void _onScroll() {
    if (!mounted) return;
    _interactionLock.clearAll();
    if (!_scrollCtrl.hasClients) return;

    final pos = _scrollCtrl.position;
    _stickToBottom = pos.pixels <= _nearBottomThreshold;

    if (pos.maxScrollExtent - pos.pixels > _loadMoreThreshold) return;

    final bloc = context.read<ClassroomChatBloc>();
    final st = bloc.state;
    if (!st.hasMore || st.status == ClassroomChatStatus.loadingMore) return;

    bloc.add(const ClassroomChatLoadMore());
  }

  void _scrollToBottom({bool animated = true}) {
    if (!mounted || !_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(0);
    }
    _stickToBottom = true;
  }

  void _scrollToMessage(String messageId, List<ClassroomChatMessage> messages, bool hasMore) {
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    final bloc = context.read<ClassroomChatBloc>();
    if (hasMore && idx < messages.length ~/ 4) {
      bloc.add(const ClassroomChatLoadMore());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureMessageVisible(messageId, messages);
    });
  }

  void _ensureMessageVisible(String messageId, List<ClassroomChatMessage> messages) {
    if (!mounted) return;
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx < 0 || !_scrollCtrl.hasClients) return;

    // Reverse list: index 0 = newest at bottom (offset 0).
    const estItemHeight = 96.0;
    final listIndex = messages.length - 1 - idx;
    final target = (listIndex * estItemHeight).clamp(
      0.0,
      _scrollCtrl.position.maxScrollExtent,
    );
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _handlePin(ClassroomChatMessage msg, ClassroomChatState state) {
    final bloc = context.read<ClassroomChatBloc>();
    if (state.pinnedMessage?.id == msg.id) {
      bloc.add(const ClassroomChatUnpinMessage());
    } else {
      bloc.add(ClassroomChatPinMessage(msg.id));
    }
  }

  void _handleMessagesChanged(ClassroomChatState state) {
    final count = state.messages.length;
    final countDelta = count - _prevMessageCount;

    if (countDelta <= 0) {
      _prevMessageCount = count;
      return;
    }

    final last = state.messages.last;
    final shouldScroll = last.senderId == widget.currentUserId ||
        last.isPending ||
        _stickToBottom ||
        _isNearBottom;

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToBottom();
      });
    }

    _prevMessageCount = count;
  }

  @override
  Widget build(BuildContext context) {
    return ChatMessageInteractionScope(
      lock: _interactionLock,
      child: BlocConsumer<ClassroomChatBloc, ClassroomChatState>(
      listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
          p.messages.length != c.messages.length ||
          p.status != c.status ||
          p.isUploading != c.isUploading ||
          p.isSending != c.isSending,
      listener: (context, state) {
        if (!context.mounted) return;
        if (state.errorMessage != null && state.errorMessage != _prevErrorMessage) {
          final toastCtx = rootNavigatorKey.currentContext ?? context;
          if (toastCtx.mounted) {
            AppFeedback.error(toastCtx, state.errorMessage!);
          }
        }
        _prevErrorMessage = state.errorMessage;
        _handleMessagesChanged(state);
      },
      builder: (context, state) {
        if (state.status == ClassroomChatStatus.loading && state.messages.isEmpty) {
          return _ChatLoadingShell(compact: widget.compact);
        }
        if (state.status == ClassroomChatStatus.error && state.messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(state.errorMessage ?? 'Lỗi tải tin nhắn',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.read<ClassroomChatBloc>().add(const ClassroomChatLoaded()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (state.isUploading || state.isSending)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.primaryTint,
                color: AppColors.primary,
              ),
            if (state.errorMessage != null && state.status == ClassroomChatStatus.ready)
              Material(
                color: AppColors.danger.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.danger),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                        onPressed: () => context
                            .read<ClassroomChatBloc>()
                            .add(const ClassroomChatDismissError()),
                      ),
                    ],
                  ),
                ),
              ),
            if (state.pinnedMessage != null)
              ChatPinnedBanner(
                message: state.pinnedMessage!,
                compact: widget.compact,
                onTap: () => _scrollToMessage(
                  state.pinnedMessage!.id,
                  state.messages,
                  state.hasMore,
                ),
                onUnpin: state.isClassOwner(widget.currentUserId)
                    ? () => context.read<ClassroomChatBloc>().add(const ClassroomChatUnpinMessage())
                    : null,
              ),
            Expanded(
              child: ClipRect(
                child: DecoratedBox(
                  decoration: ClassroomChatUi.chatCanvas(compact: widget.compact),
                  child: _MessageList(
                    messages: state.messages,
                    currentUserId: widget.currentUserId,
                    hasMore: state.hasMore,
                    isLoadingMore: state.status == ClassroomChatStatus.loadingMore,
                    scrollController: _scrollCtrl,
                    compact: widget.compact,
                    highlightTeacherMessages: widget.highlightTeacherMessages,
                    interactionLock: _interactionLock,
                    canPin: state.isClassOwner(widget.currentUserId),
                    pinnedMessageId: state.pinnedMessage?.id,
                    members: state.members,
                    onReply: (msg) => setState(() => _replyTo = msg),
                    onReact: (msg, emoji) => context.read<ClassroomChatBloc>().add(
                          ClassroomChatReact(messageId: msg.id, emoji: emoji),
                        ),
                    onDelete: (msg) => _confirmDelete(context, msg),
                    onEdit: (msg) => _showEditDialog(context, msg),
                    onPin: (msg) => _handlePin(msg, state),
                  ),
                ),
              ),
            ),
            _TypingIndicator(
              state: state,
              currentUserId: widget.currentUserId,
              compact: widget.compact,
            ),
            ChatInputBar(
              members: state.members,
              compact: widget.compact,
              isUploading: state.isUploading,
              replyTo: _replyTo,
              onSendText: (content, mentionIds) {
                context.read<ClassroomChatBloc>().add(ClassroomChatSendText(
                      content: content,
                      replyTo: _replyTo,
                      mentionIds: mentionIds,
                    ));
                setState(() => _replyTo = null);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _scrollToBottom();
                });
              },
              onSendFile: (payload) {
                context.read<ClassroomChatBloc>().add(ClassroomChatSendMedia(
                      filePath: payload.filePath,
                      bytes: payload.bytes,
                      fileName: payload.fileName,
                      mimeType: payload.mimeType,
                      replyTo: _replyTo,
                    ));
                setState(() => _replyTo = null);
              },
              onCancelReply: () => setState(() => _replyTo = null),
              onTypingChanged: (isTyping) =>
                  context.read<ClassroomChatBloc>().emitTyping(isTyping),
            ),
          ],
        );
      },
    ),
    );
  }

  void _confirmDelete(BuildContext context, ClassroomChatMessage msg) {
    final dialogContext = rootNavigatorKey.currentContext ?? context;
    showDialog(
      context: dialogContext,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tin nhắn'),
        content: const Text('Tin nhắn sẽ bị xóa với tất cả thành viên. Tiếp tục?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ClassroomChatBloc>().add(ClassroomChatDeleteMessage(msg.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ClassroomChatMessage msg) {
    final ctrl = TextEditingController(text: msg.content);
    final dialogContext = rootNavigatorKey.currentContext ?? context;
    showDialog(
      context: dialogContext,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa tin nhắn'),
        content: TextField(
          controller: ctrl,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              context.read<ClassroomChatBloc>().add(
                    ClassroomChatEditMessage(messageId: msg.id, newContent: text),
                  );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.compact,
    this.highlightTeacherMessages = false,
    required this.interactionLock,
    required this.canPin,
    this.pinnedMessageId,
    required this.onReply,
    required this.onReact,
    required this.onDelete,
    required this.onEdit,
    this.onPin,
    this.members = const [],
  });

  final List<ClassroomChatMessage> messages;
  final String currentUserId;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final bool compact;
  final bool highlightTeacherMessages;
  final ChatMessageInteractionLock interactionLock;
  final bool canPin;
  final String? pinnedMessageId;
  final void Function(ClassroomChatMessage) onReply;
  final void Function(ClassroomChatMessage, String emoji) onReact;
  final void Function(ClassroomChatMessage) onDelete;
  final void Function(ClassroomChatMessage) onEdit;
  final void Function(ClassroomChatMessage)? onPin;
  final List<ChatMember> members;

  @override
  Widget build(BuildContext context) {
    final mobile = !compact && ClassroomChatUi.isMobileLayout(context);

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_outlined, size: compact ? 40 : 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Chưa có tin nhắn',
                style: TextStyle(
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hãy chào cả lớp và bắt đầu trò chuyện!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      clipBehavior: Clip.hardEdge,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      addAutomaticKeepAlives: false,
      cacheExtent: 800,
      padding: ClassroomChatUi.messageListPadding(compact: compact, mobile: mobile),
      itemCount: messages.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasMore && index == messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: isLoadingMore
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Center(
                    child: Text(
                      'Cuộn lên để xem tin cũ hơn',
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          );
        }

        final msgIndex = messages.length - 1 - index;
        final msg = messages[msgIndex];
        final listKey = classroomChatMessageListKey(msg, msgIndex, messages);
        final isMe = msg.senderId == currentUserId;
        final showSenderInfo =
            !isMe && _isFirstInGroup(messages, msgIndex, _isSameDay);
        final showAvatar =
            !isMe && _shouldShowAvatar(messages, msgIndex, _isSameDay);
        final showTail = _isLastInGroup(messages, msgIndex, _isSameDay);
        final showDate = msgIndex == 0 ||
            !_isSameDay(msg.createdAt, messages[msgIndex - 1].createdAt);

        return Column(
          key: ValueKey(listKey),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _DateSeparator(date: msg.createdAt),
            RepaintBoundary(
              child: ChatMessageBubble(
                  message: msg,
                  isMe: isMe,
                  showSenderInfo: showSenderInfo,
                  showAvatar: showAvatar,
                  showTail: showTail,
                  currentUserId: currentUserId,
                  compact: compact,
                  highlightTeacherMessages: highlightTeacherMessages,
                  interactionLock: interactionLock,
                  members: members,
                  onReply: onReply,
                  onReact: onReact,
                  onDelete: onDelete,
                  onEdit: onEdit,
                  canPin: canPin,
                  isPinned: pinnedMessageId == msg.id,
                onPin: onPin,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _sameGroup(
  List<ClassroomChatMessage> messages,
  int a,
  int b,
  bool Function(DateTime, DateTime) isSameDay,
) {
  final msgA = messages[a];
  final msgB = messages[b];
  if (msgA.senderId != msgB.senderId) return false;
  if (!isSameDay(msgA.createdAt, msgB.createdAt)) return false;
  final diff = msgB.createdAt.difference(msgA.createdAt).inMinutes.abs();
  return diff <= 5;
}

/// Avatar anchors on the last non-deleted message in a sender group; if the
/// whole group is deleted, falls back to the chronologically last row.
int _avatarAnchorIndex(
  List<ClassroomChatMessage> messages,
  int index,
  bool Function(DateTime, DateTime) isSameDay,
) {
  var groupStart = index;
  while (groupStart > 0 && _sameGroup(messages, groupStart - 1, groupStart, isSameDay)) {
    groupStart--;
  }
  var groupEnd = index;
  while (groupEnd < messages.length - 1 &&
      _sameGroup(messages, groupEnd, groupEnd + 1, isSameDay)) {
    groupEnd++;
  }
  for (var i = groupEnd; i >= groupStart; i--) {
    if (!messages[i].isDeleted) return i;
  }
  return groupEnd;
}

bool _shouldShowAvatar(
  List<ClassroomChatMessage> messages,
  int index,
  bool Function(DateTime, DateTime) isSameDay,
) {
  return index == _avatarAnchorIndex(messages, index, isSameDay);
}

bool _isFirstInGroup(
  List<ClassroomChatMessage> messages,
  int index,
  bool Function(DateTime, DateTime) isSameDay,
) {
  if (index == 0) return true;
  final msg = messages[index];
  final prev = messages[index - 1];
  if (prev.senderId != msg.senderId) return true;
  if (!isSameDay(prev.createdAt, msg.createdAt)) return true;
  if (msg.createdAt.difference(prev.createdAt).inMinutes > 5) return true;
  return false;
}

bool _isLastInGroup(
  List<ClassroomChatMessage> messages,
  int index,
  bool Function(DateTime, DateTime) isSameDay,
) {
  if (index >= messages.length - 1) return true;
  final msg = messages[index];
  final next = messages[index + 1];
  if (next.senderId != msg.senderId) return true;
  if (!isSameDay(msg.createdAt, next.createdAt)) return true;
  if (next.createdAt.difference(msg.createdAt).inMinutes > 5) return true;
  return false;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final local = date.toLocal();
    String label;
    if (_isSameDay(local, now)) {
      label = 'Hôm nay';
    } else if (_isSameDay(local, now.subtract(const Duration(days: 1)))) {
      label = 'Hôm qua';
    } else {
      label = DateFormat('dd/MM/yyyy').format(local);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.outlineMuted, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineMuted),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.outlineMuted, thickness: 0.5)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({
    required this.state,
    required this.currentUserId,
    required this.compact,
  });
  final ClassroomChatState state;
  final String currentUserId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final typers = state.typingMembers(currentUserId);
    if (typers.isEmpty) return const SizedBox.shrink();

    final label = typers.length == 1
        ? '${typers.first.fullName} đang nhập…'
        : '${typers.map((m) => m.fullName).join(', ')} đang nhập…';

    return Padding(
      padding: EdgeInsets.only(
        left: compact ? 10 : 12,
        right: compact ? 10 : 12,
        bottom: 4,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineMuted),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TypingDots(),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          children: List.generate(3, (i) {
            final delay = i / 3;
            final v = (((_ctrl.value + delay) % 1.0) * 2 - 1).abs();
            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.4 + v * 0.6),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ChatLoadingShell extends StatelessWidget {
  const _ChatLoadingShell({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: ClassroomChatUi.chatCanvas(compact: compact),
            child: ListView(
              padding: ClassroomChatUi.messageListPadding(compact: compact),
              children: const [
                _MessageBubbleSkeleton(alignEnd: false, widthFactor: 0.62),
                SizedBox(height: 10),
                _MessageBubbleSkeleton(alignEnd: true, widthFactor: 0.48),
                SizedBox(height: 10),
                _MessageBubbleSkeleton(alignEnd: false, widthFactor: 0.74),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(compact ? 8 : 12, 6, compact ? 8 : 12, 8),
          child: Row(
            children: [
              AppSkeleton.box(
                height: 40,
                width: 40,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSkeleton.box(
                  height: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubbleSkeleton extends StatelessWidget {
  const _MessageBubbleSkeleton({
    required this.alignEnd,
    this.widthFactor = 0.6,
  });

  final bool alignEnd;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: AppSkeleton.box(height: 44, borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
