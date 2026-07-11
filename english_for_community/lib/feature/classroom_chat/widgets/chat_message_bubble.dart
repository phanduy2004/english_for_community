import 'package:cached_network_image/cached_network_image.dart';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'chat_attachment_staging.dart';
import 'chat_avatar.dart';
import 'chat_media_actions.dart';
import 'chat_video_thumbnail.dart';
import 'chat_message_interaction_scope.dart';
import 'chat_reaction_bar.dart';
import 'chat_reply_preview.dart';
import 'classroom_chat_ui.dart';

/// Trạng thái tin của mình: chưa hiện / đã gửi (✓) / đã xem (✓✓).
enum ChatReadStatus { none, sent, seen }

class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showSenderInfo,
    required this.currentUserId,
    required this.onReply,
    required this.onReact,
    required this.onDelete,
    required this.onEdit,
    this.onPin,
    this.isPinned = false,
    this.canPin = false,
    this.compact = false,
    this.showAvatar = true,
    this.showTail = true,
    this.highlightTeacherMessages = false,
    this.readStatus = ChatReadStatus.none,
    required this.interactionLock,
    this.members = const [],
  });

  final ClassroomChatMessage message;
  final bool isMe;
  final bool showSenderInfo;
  final bool showAvatar;
  final bool showTail;
  final String currentUserId;
  final void Function(ClassroomChatMessage) onReply;
  final void Function(ClassroomChatMessage, String emoji) onReact;
  final void Function(ClassroomChatMessage) onDelete;
  final void Function(ClassroomChatMessage) onEdit;
  final void Function(ClassroomChatMessage)? onPin;
  final bool isPinned;
  final bool canPin;
  final bool compact;
  final bool highlightTeacherMessages;
  final ChatReadStatus readStatus;
  final ChatMessageInteractionLock interactionLock;
  final List<ChatMember> members;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _hovered = false;

  ClassroomChatMessage get message => widget.message;
  bool get isMe => widget.isMe;

  ChatMessageInteractionLock get _lock => widget.interactionLock;

  bool get _senderIsTeacher {
    if (!widget.highlightTeacherMessages) return false;
    for (final m in widget.members) {
      if (m.id == message.senderId) return m.isTeacher;
    }
    return false;
  }

  void _openActionsMenu() => _showContextMenu(context);

  void _openReactionPicker() {
    final lock = _lock;
    if (lock.activeMessageId == message.id && lock.reactionPickerOpen) {
      _closeInteraction();
      return;
    }
    setState(() => _hovered = true);
    lock.openReactionPicker(message.id);
  }

  void _closeInteraction() {
    if (!mounted) return;
    setState(() => _hovered = false);
    _lock.closeInteraction(message.id);
  }

  void _pickReaction(String emoji) {
    widget.onReact(message, emoji);
    _closeInteraction();
  }

  void _handleEnter() {
    final lock = _lock;
    if (!lock.canHover(message.id)) return;
    setState(() => _hovered = true);
  }

  void _handleExit() {
    final lock = _lock;
    if (lock.activeMessageId == message.id && lock.reactionPickerOpen) return;
    setState(() => _hovered = false);
    lock.closeInteraction(message.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.isDeleted;
    final lock = _lock;

    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) {
        final showPicker = !isDeleted &&
            lock.reactionPickerOpen &&
            lock.activeMessageId == message.id;
        final hoverSupported = ClassroomChatUi.supportsHoverActions(context);
        final mobile = !widget.compact && ClassroomChatUi.isMobileLayout(context);
        final denseReaction = widget.compact || mobile;
        final avatarColumn = ClassroomChatUi.avatarColumnWidth;
        final reserveSideActionRail =
            !isDeleted && hoverSupported && lock.canHover(message.id);
        final showSideActions =
            reserveSideActionRail && (_hovered || showPicker);

        final sideActions = _MessageSideActions(
          compact: widget.compact,
          onReactTap: _openReactionPicker,
          onReply: () {
            widget.onReply(message);
            _closeInteraction();
          },
          onMore: _openActionsMenu,
        );

        Widget sideActionsOverlay({required Widget child}) {
          if (!showSideActions) return child;
          final railW = ClassroomChatUi.messageSideRailWidth(compact: widget.compact);
          final gap = ClassroomChatUi.messageSideRailGap(compact: widget.compact);
          // Action rail hướng vào trong: tin mình (phải) → rail trái bubble; tin người khác (trái) → rail phải bubble.
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? railW + gap : 0,
                  right: isMe ? 0 : railW + gap,
                ),
                child: child,
              ),
              Positioned(
                left: isMe ? 0 : null,
                right: isMe ? null : 0,
                top: 0,
                bottom: 0,
                child: Center(child: sideActions),
              ),
            ],
          );
        }

        final bubbleContent = LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;
            if (!totalW.isFinite || totalW <= 0) {
              return const SizedBox.shrink();
            }

            const avatarGap = 8.0;
            final showPeerAvatar = !isMe && widget.showAvatar;
            final peerLeadingW = !isMe
                ? (showPeerAvatar
                    ? (_senderIsTeacher
                            ? ClassroomChatUi.teacherAvatarOuterSize()
                            : 32.0) +
                        avatarGap
                    : ClassroomChatUi.avatarColumnWidth)
                : 0.0;
            final messageW = (totalW - peerLeadingW).clamp(0.0, totalW);
            final bubbleMaxW = ClassroomChatUi.bubbleContentMaxWidth(
              parentMaxWidth: messageW,
              compact: widget.compact,
              reserveSideActionRail: false,
            );

            final bubble = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: bubbleMaxW),
              child: _BubbleBody(
                message: message,
                isMe: isMe,
                isTeacher: _senderIsTeacher,
                showTail: widget.showTail,
                maxWidth: bubbleMaxW,
              ),
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  if (showPeerAvatar)
                    _Avatar(sender: message.sender, teacherHighlight: _senderIsTeacher)
                  else
                    SizedBox(width: ClassroomChatUi.avatarColumnWidth),
                  if (showPeerAvatar) const SizedBox(width: avatarGap),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showPicker)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: AnimatedScale(
                            scale: showPicker ? 1 : 0.92,
                            duration: ClassroomChatUi.reactionStrip,
                            curve: ClassroomChatUi.hoverCurve,
                            child: AnimatedOpacity(
                              opacity: showPicker ? 1 : 0,
                              duration: ClassroomChatUi.reactionStrip,
                              child: Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: _ReactionPickerStrip(
                                    dense: denseReaction,
                                    onPick: _pickReaction,
                                    onMore: () {
                                      _closeInteraction();
                                      _showReactionPicker(context);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: sideActionsOverlay(child: bubble),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );

        final useSwipeReply = mobile && !kIsWeb;

        return MouseRegion(
          onEnter: (_) => _handleEnter(),
          onExit: (_) => _handleExit(),
          child: GestureDetector(
            onLongPress: isDeleted ? null : _openActionsMenu,
            onSecondaryTap: isDeleted ? null : _openActionsMenu,
            behavior: HitTestBehavior.deferToChild,
            child: Padding(
              padding: ClassroomChatUi.bubbleMargin(
                isMe: isMe,
                compact: widget.compact,
                mobile: mobile,
                showSenderInfo: !isMe && widget.showSenderInfo,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe && widget.showSenderInfo)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SenderName(message: message, isTeacher: _senderIsTeacher),
                    ),
                  if (useSwipeReply)
                    _SwipeToReply(
                      isMe: isMe,
                      onReply: () => widget.onReply(message),
                      child: bubbleContent,
                    )
                  else
                    bubbleContent,
                  if (message.reactions.isNotEmpty && !isDeleted)
                    Padding(
                      padding: EdgeInsets.only(left: isMe ? 0 : avatarColumn, top: 2),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: ChatReactionBar(
                          reactions: message.reactions,
                          currentUserId: widget.currentUserId,
                          isMe: isMe,
                          onTap: (emoji) => widget.onReact(message, emoji),
                        ),
                      ),
                    ),
                  if (message.isPending &&
                      message.type != ChatMessageType.image &&
                      message.type != ChatMessageType.video)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 2),
                      child: Text(
                        'Đang gửi…',
                        style: TextStyle(fontSize: AppTypography.mobileCaption, color: AppColors.textMuted),
                      ),
                    )
                  else if (!message.isPending)
                    Padding(
                      padding: EdgeInsets.only(left: isMe ? 0 : avatarColumn, top: 2),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: (isMe && widget.readStatus != ChatReadStatus.none)
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TimeStamp(message: message),
                                  const SizedBox(width: 4),
                                  Icon(
                                    widget.readStatus == ChatReadStatus.seen
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded,
                                    size: 14,
                                    color:
                                        widget.readStatus == ChatReadStatus.seen
                                            ? ClassroomChatUi.bubbleSent
                                            : AppColors.textMuted,
                                  ),
                                ],
                              )
                            : _TimeStamp(message: message),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;

    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    final dialogContext = rootNavigatorKey.currentContext ?? context;

    showMenu<String>(
      context: dialogContext,
      useRootNavigator: true,
      position: RelativeRect.fromSize(
        Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height),
        overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'reply',
          child: _MenuItem(icon: Icons.reply, label: 'Trả lời'),
        ),
        const PopupMenuItem(
          value: 'react',
          child: _MenuItem(icon: Icons.emoji_emotions_outlined, label: 'Thả cảm xúc'),
        ),
        if (message.type == ChatMessageType.text && message.content.isNotEmpty)
          const PopupMenuItem(
            value: 'copy',
            child: _MenuItem(icon: Icons.copy_outlined, label: 'Sao chép'),
          ),
        if ((message.type == ChatMessageType.image ||
                message.type == ChatMessageType.video) &&
            message.media != null &&
            message.media!.url.isNotEmpty)
          const PopupMenuItem(
            value: 'download',
            child: _MenuItem(icon: Icons.download_outlined, label: 'Tải về'),
          ),
        if (isMe && message.type == ChatMessageType.text)
          const PopupMenuItem(
            value: 'edit',
            child: _MenuItem(icon: Icons.edit_outlined, label: 'Sửa'),
          ),
        if (widget.canPin && widget.onPin != null)
          PopupMenuItem(
            value: 'pin',
            child: _MenuItem(
              icon: widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              label: widget.isPinned ? 'Bỏ ghim' : 'Ghim tin nhắn',
            ),
          ),
        if (isMe)
          const PopupMenuItem(
            value: 'delete',
            child: _MenuItem(
              icon: Icons.delete_outline,
              label: 'Xóa',
              isDestructive: true,
            ),
          ),
      ],
    ).then((value) {
      if (!mounted) return;
      switch (value) {
        case 'reply':
          widget.onReply(message);
        case 'react':
          _openReactionPicker();
        case 'copy':
          Clipboard.setData(ClipboardData(text: message.content));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã sao chép'), duration: Duration(seconds: 1)),
          );
        case 'download':
          if (message.media != null) {
            ChatMediaActions.downloadFile(context, media: message.media!);
          }
        case 'edit':
          widget.onEdit(message);
        case 'pin':
          widget.onPin?.call(message);
        case 'delete':
          widget.onDelete(message);
      }
    });
  }

  void _showReactionPicker(BuildContext context) {
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '😡', '🎉', '👏'];
    final dialogContext = rootNavigatorKey.currentContext ?? context;

    showDialog<void>(
      context: dialogContext,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thả cảm xúc',
                style: TextStyle(fontSize: AppTypography.mobileH1, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: emojis
                    .map(
                      (e) => InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onReact(message, e);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(e, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile — kéo tin về phía ngược để trả lời (trái→phải / phải→trái).
class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    required this.isMe,
    required this.onReply,
    required this.child,
  });

  final bool isMe;
  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  static const _threshold = 56.0;
  static const _maxDrag = 72.0;

  double _offset = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    final next = _offset + details.delta.dx;
    setState(() {
      if (widget.isMe) {
        _offset = next.clamp(-_maxDrag, 0);
      } else {
        _offset = next.clamp(0, _maxDrag);
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final triggered = widget.isMe ? _offset <= -_threshold : _offset >= _threshold;
    if (triggered) {
      HapticFeedback.mediumImpact();
      widget.onReply();
    }
    setState(() => _offset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_offset.abs() / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.translucent,
      child: ClipRect(
        child: Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.hardEdge,
          children: [
            AnimatedContainer(
              duration: _offset == 0 ? const Duration(milliseconds: 180) : Duration.zero,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: widget.child,
            ),
            Positioned(
              left: widget.isMe ? null : 0,
              right: widget.isMe ? 0 : null,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: progress,
                  child: Align(
                    alignment:
                        widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: widget.isMe ? 0 : 12,
                        right: widget.isMe ? 12 : 0,
                      ),
                      child: Transform.scale(
                        scale: 0.85 + progress * 0.15,
                        child: Icon(
                          Icons.reply_rounded,
                          size: 22,
                          color: AppColors.primary
                              .withValues(alpha: 0.45 + progress * 0.55),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3 nút tròn cạnh bubble khi hover — kiểu Messenger.
class _MessageSideActions extends StatelessWidget {
  const _MessageSideActions({
    required this.compact,
    required this.onReactTap,
    required this.onReply,
    required this.onMore,
  });

  final bool compact;
  final VoidCallback onReactTap;
  final VoidCallback onReply;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 26.0 : 30.0;
    final iconSize = compact ? 15.0 : 17.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleActionButton(
          size: size,
          icon: Icons.favorite,
          iconSize: iconSize,
          iconColor: AppColors.danger,
          tooltip: 'Thả cảm xúc',
          onTap: onReactTap,
        ),
        SizedBox(width: compact ? 3 : 4),
        _CircleActionButton(
          size: size,
          icon: Icons.reply,
          iconSize: iconSize,
          tooltip: 'Trả lời',
          onTap: onReply,
        ),
        SizedBox(width: compact ? 3 : 4),
        _CircleActionButton(
          size: size,
          icon: Icons.more_vert,
          iconSize: iconSize,
          tooltip: 'Thêm',
          onTap: onMore,
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.onTap,
    this.tooltip,
    this.iconColor,
  });

  final double size;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: AppColors.surfaceCard,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      shape: CircleBorder(side: BorderSide(color: AppColors.outlineMuted)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        hoverColor: AppColors.primaryStrong,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: iconColor ?? AppColors.textSecondary),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

/// Thanh emoji nổi phía trên bubble khi bấm nút react.
class _ReactionPickerStrip extends StatelessWidget {
  const _ReactionPickerStrip({
    required this.dense,
    required this.onPick,
    required this.onMore,
  });

  final bool dense;
  final ValueChanged<String> onPick;
  final VoidCallback onMore;

  static const _emojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

  @override
  Widget build(BuildContext context) {
    final emojiSize = dense ? 16.0 : 24.0;
    final plusSize = dense ? 22.0 : 30.0;

    final strip = Material(
      elevation: dense ? 6 : 8,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(dense ? 22 : 28),
      color: AppColors.surfaceInverse.withValues(alpha: 0.92),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 5 : 10,
          vertical: dense ? 3 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._emojis.map(
              (emoji) => _ReactionEmojiButton(
                emoji: emoji,
                size: emojiSize,
                compact: dense,
                onTap: () => onPick(emoji),
              ),
            ),
            SizedBox(width: dense ? 1 : 4),
            Material(
              color: Colors.white.withValues(alpha: 0.18),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onMore,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: plusSize,
                  height: plusSize,
                  child: Icon(
                    Icons.add,
                    size: dense ? 14 : 18,
                    color: AppColors.textInverse.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!dense) return strip;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: strip,
    );
  }
}

class _ReactionEmojiButton extends StatelessWidget {
  const _ReactionEmojiButton({
    required this.emoji,
    required this.size,
    required this.onTap,
    this.compact = false,
  });

  final String emoji;
  final double size;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? 1.0 : 3.0;
    final boxExtra = compact ? 2.0 : 4.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: compact ? 1 : 2),
        child: SizedBox(
          width: size + boxExtra,
          height: size + boxExtra,
          child: Center(
            child: ClassroomChatUi.reactionGlyph(emoji, size: size),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({this.sender, this.teacherHighlight = false});
  final ChatSender? sender;
  final bool teacherHighlight;
  @override
  Widget build(BuildContext context) {
    return ChatAvatar(
      avatarUrl: sender?.avatarUrl,
      displayName: sender?.fullName ?? sender?.username ?? '',
      radius: 16,
      teacherHighlight: teacherHighlight,
    );
  }
}

class _SenderName extends StatelessWidget {
  const _SenderName({required this.message, this.isTeacher = false});
  final ClassroomChatMessage message;
  final bool isTeacher;
  @override
  Widget build(BuildContext context) {
    final name = message.sender?.fullName ?? '';
    return Padding(
      padding: EdgeInsets.only(left: ClassroomChatUi.avatarColumnWidth, bottom: 2),
      child: Text(name, style: ClassroomChatUi.senderName(isTeacher: isTeacher)),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.message,
    required this.isMe,
    this.isTeacher = false,
    this.showTail = true,
    this.maxWidth,
  });
  final ClassroomChatMessage message;
  final bool isMe;
  final bool isTeacher;
  final bool showTail;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: const _DeletedBubbleContent(),
      );
    }

    final fg = isTeacher
        ? ClassroomChatUi.teacherMessageText
        : (isMe ? AppColors.textInverse : AppColors.textPrimary);
    final radius = ClassroomChatUi.bubbleBorderRadius(isMe: isMe, isTail: showTail);
    final decoration =
        ClassroomChatUi.bubbleDecoration(isMe: isMe, isTail: showTail, isTeacher: isTeacher);

    switch (message.type) {
      case ChatMessageType.image:
        return _ImageBubble(
          message: message,
          radius: radius,
          isMe: isMe,
          isTeacher: isTeacher,
          maxWidth: maxWidth,
          onTap: () => ChatMediaActions.openMessageMedia(context, message),
        );
      case ChatMessageType.video:
        return _VideoBubble(
          message: message,
          isMe: isMe,
          isTeacher: isTeacher,
          radius: radius,
          maxWidth: maxWidth,
          onTap: () => ChatMediaActions.openMessageMedia(context, message),
        );
      case ChatMessageType.file:
        return _FileBubble(
          message: message,
          isMe: isMe,
          isTeacher: isTeacher,
          decoration: decoration,
          fg: fg,
          icon: Icons.insert_drive_file_outlined,
          maxWidth: maxWidth,
          onTap: () => ChatMediaActions.openMessageMedia(context, message),
        );
      case ChatMessageType.text:
        return _TextBubble(
          message: message,
          isMe: isMe,
          isTeacher: isTeacher,
          decoration: decoration,
          fg: fg,
          maxWidth: maxWidth,
        );
    }
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.isMe,
    this.isTeacher = false,
    required this.decoration,
    required this.fg,
    this.maxWidth,
  });
  final ClassroomChatMessage message;
  final bool isMe;
  final bool isTeacher;
  final BoxDecoration decoration;
  final Color fg;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Container(
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyTo != null)
              ChatReplyPreview(
                snapshot: message.replyTo!,
                isMe: isMe,
                embeddedInBubble: true,
                isTeacherBubble: isTeacher,
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, message.replyTo != null ? 4 : 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MentionText(text: message.content, isMe: isMe, isTeacher: isTeacher, fg: fg),
                  if (message.isEdited)
                    Text(
                      '· đã sửa',
                      style: ClassroomChatUi.timestamp().copyWith(
                        color: fg.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({
    required this.message,
    required this.radius,
    required this.isMe,
    this.isTeacher = false,
    this.maxWidth,
    this.onTap,
  });
  final ClassroomChatMessage message;
  final BorderRadius radius;
  final bool isMe;
  final bool isTeacher;
  final double? maxWidth;
  final VoidCallback? onTap;

  static const double _preferredWidth = 220;
  static const double _preferredHeight = 180;

  @override
  Widget build(BuildContext context) {
    final cap = maxWidth ?? _preferredWidth;
    final width = cap < _preferredWidth ? cap : _preferredWidth;
    final height = width * (_preferredHeight / _preferredWidth);
    final media = message.media!;
    final useLocal = message.isPending && media.hasLocalPreview;

    Widget image;
    if (useLocal) {
      image = buildChatBubbleLocalMedia(
        type: ChatMessageType.image,
        media: media,
        isPending: message.isPending,
        width: width,
        height: height,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: media.url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: AppColors.primaryTint,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: AppColors.primaryTint,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
      if (message.isPending) {
        image = Stack(
          fit: StackFit.passthrough,
          children: [
            image,
            const ChatMediaUploadOverlay(),
          ],
        );
      }
    }

    Widget wrapImage(Widget child) {
      if (onTap == null || message.isPending) return child;
      return ChatMediaTapTarget(onTap: onTap!, child: child);
    }

    if (message.replyTo == null) {
      if (!isTeacher) {
        return ClipRRect(
          borderRadius: radius,
          child: wrapImage(image),
        );
      }
      return Container(
        decoration: ClassroomChatUi.bubbleDecoration(isMe: isMe, isTail: true, isTeacher: true),
        clipBehavior: Clip.antiAlias,
        child: wrapImage(image),
      );
    }

    return Container(
      width: width,
      decoration: ClassroomChatUi.bubbleDecoration(isMe: isMe, isTail: true, isTeacher: isTeacher),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatReplyPreview(
            snapshot: message.replyTo!,
            isMe: isMe,
            embeddedInBubble: true,
            isTeacherBubble: isTeacher,
          ),
          wrapImage(image),
        ],
      ),
    );
  }
}

class _VideoBubble extends StatelessWidget {
  const _VideoBubble({
    required this.message,
    required this.isMe,
    this.isTeacher = false,
    required this.radius,
    this.maxWidth,
    this.onTap,
  });

  final ClassroomChatMessage message;
  final bool isMe;
  final bool isTeacher;
  final BorderRadius radius;
  final double? maxWidth;
  final VoidCallback? onTap;

  static const double _preferredWidth = 220;
  static const double _preferredHeight = 140;

  @override
  Widget build(BuildContext context) {
    final media = message.media!;
    final cap = maxWidth ?? _preferredWidth;
    final width = cap < _preferredWidth ? cap : _preferredWidth;
    final height = width * (_preferredHeight / _preferredWidth);
    final useLocal = message.isPending && media.hasLocalPreview;
    final thumbUrl = resolveChatVideoThumbnailUrl(media);

    Widget preview;
    if (useLocal) {
      preview = buildChatBubbleLocalMedia(
        type: ChatMessageType.video,
        media: media,
        isPending: message.isPending,
        width: width,
        height: height,
      );
    } else if (thumbUrl != null) {
      preview = Container(
        width: width,
        height: height,
        color: Colors.black87,
        child: CachedNetworkImage(
          imageUrl: thumbUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: width,
            height: height,
            color: AppColors.primaryTint,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => chatVideoThumbnailPlaceholder(
            width: width,
            height: height,
          ),
        ),
      );
      if (message.isPending) {
        preview = Stack(
          fit: StackFit.passthrough,
          children: [
            preview,
            const ChatMediaUploadOverlay(),
          ],
        );
      }
    } else {
      preview = chatVideoThumbnailPlaceholder(width: width, height: height);
    }

    if (onTap != null && !message.isPending) {
      preview = ChatMediaTapTarget(onTap: onTap!, showPlayOverlay: true, child: preview);
    }

    if (message.replyTo == null) {
      return ClipRRect(borderRadius: radius, child: preview);
    }

    return Container(
      width: width,
      decoration: ClassroomChatUi.bubbleDecoration(isMe: isMe, isTail: true, isTeacher: isTeacher),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatReplyPreview(
            snapshot: message.replyTo!,
            isMe: isMe,
            embeddedInBubble: true,
            isTeacherBubble: isTeacher,
          ),
          preview,
        ],
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  const _FileBubble({
    required this.message,
    required this.isMe,
    this.isTeacher = false,
    required this.decoration,
    required this.fg,
    required this.icon,
    this.maxWidth,
    this.onTap,
  });
  final ClassroomChatMessage message;
  final bool isMe;
  final bool isTeacher;
  final BoxDecoration decoration;
  final Color fg;
  final IconData icon;
  final double? maxWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sizeKb = (message.media!.size / 1024).toStringAsFixed(0);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.replyTo != null)
          ChatReplyPreview(
            snapshot: message.replyTo!,
            isMe: isMe,
            embeddedInBubble: true,
            isTeacherBubble: isTeacher,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 28),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: (maxWidth ?? 240) - 62),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.media!.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: AppTypography.mobileH3, color: fg),
                    ),
                    Text(
                      '$sizeKb KB',
                      style: TextStyle(fontSize: AppTypography.mobileCaption, color: fg.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.download_outlined, size: 18, color: fg.withValues(alpha: 0.75)),
              ],
            ],
          ),
        ),
      ],
    );

    final borderRadius = decoration.borderRadius is BorderRadius
        ? decoration.borderRadius! as BorderRadius
        : BorderRadius.circular(16);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          hoverColor: AppColors.primaryStrong,
          child: Ink(
            decoration: decoration,
            child: body,
          ),
        ),
      ),
    );
  }
}

class _DeletedBubbleContent extends StatelessWidget {
  const _DeletedBubbleContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.not_interested, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            'Tin nhắn đã bị xóa',
            style: TextStyle(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              fontSize: AppTypography.mobileBody,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeStamp extends StatelessWidget {
  const _TimeStamp({required this.message});
  final ClassroomChatMessage message;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm().format(message.createdAt.toLocal());
    return Text(time, style: ClassroomChatUi.timestamp());
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.isDestructive = false});
  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : null;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

/// Renders @mention tags with highlight color inside plain text.
class _MentionText extends StatelessWidget {
  const _MentionText({
    required this.text,
    required this.isMe,
    this.isTeacher = false,
    required this.fg,
  });
  final String text;
  final bool isMe;
  final bool isTeacher;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'@\S+');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: ClassroomChatUi.messageBody(isMe: isMe, isTeacher: isTeacher).copyWith(color: fg),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: ClassroomChatUi.messageBody(isMe: isMe, isTeacher: isTeacher).copyWith(
          color: isTeacher
              ? ClassroomChatUi.teacherRingDark
              : (isMe ? const Color(0xFFE0F2FE) : ClassroomChatUi.bubbleSent),
          fontWeight: FontWeight.w700,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: ClassroomChatUi.messageBody(isMe: isMe, isTeacher: isTeacher).copyWith(color: fg),
      ));
    }
    if (spans.isEmpty) return const SizedBox.shrink();
    return Text.rich(TextSpan(children: spans));
  }
}
