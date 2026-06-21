import 'package:flutter/material.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/entity/comment_entity.dart';
import '../../../core/locale/l10n_context.dart';
import '../../../l10n/generated/app_localizations.dart';

class MentionTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final text = value.text;
    final List<InlineSpan> children = [];
    text.splitMapJoin(
      RegExp(r'(@.+?\u200B)', unicode: true),
      onMatch: (Match match) {
        children.add(TextSpan(text: match[0], style: style?.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)));
        return '';
      },
      onNonMatch: (String nonMatch) {
        children.add(TextSpan(text: nonMatch, style: style));
        return '';
      },
    );
    return TextSpan(style: style, children: children);
  }
}

class DiscussionTab extends StatefulWidget {
  final List<CommentEntity> comments;
  final bool isLoading;
  final String currentUserId;
  final Function(String content, String? parentId) onSend;
  final Function(String commentId, ReactionType type) onReact;

  // 🔥 THÊM THAM SỐ TARGET
  final String? targetCommentId;

  const DiscussionTab({
    super.key,
    required this.comments,
    required this.isLoading,
    required this.currentUserId,
    required this.onSend,
    required this.onReact,
    this.targetCommentId,
  });

  @override
  State<DiscussionTab> createState() => _DiscussionTabState();
}

class _DiscussionTabState extends State<DiscussionTab> {
  final _commentCtrl = MentionTextEditingController();
  final ScrollController _scrollController = ScrollController();
  CommentEntity? _replyingTo;

  @override
  void didUpdateWidget(covariant DiscussionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comments.length > oldWidget.comments.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppMotion.base,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    String? finalParentId;
    if (_replyingTo != null) finalParentId = _replyingTo!.parentId ?? _replyingTo!.id;
    widget.onSend(content, finalParentId);
    _commentCtrl.clear();
    setState(() => _replyingTo = null);
    FocusScope.of(context).unfocus();
    _scrollToBottom();
  }

  void _handleReplyRequest(CommentEntity comment) {
    setState(() {
      _replyingTo = comment;
      if (comment.userId != widget.currentUserId) {
        _commentCtrl.text = "@${comment.userName}\u200B ";
        _commentCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _commentCtrl.text.length));
      }
    });
  }

  List<CommentEntity> _organizeComments(List<CommentEntity> flatList) {
    final roots = flatList.where((c) => c.parentId == null).toList();
    final replies = flatList.where((c) => c.parentId != null).toList();
    final organized = roots.map((root) {
      final children = replies.where((r) => r.parentId == root.id).toList();
      children.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return root.copyWith(replies: children);
    }).toList();
    organized.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return organized;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (widget.isLoading) return StudentMobileUi.runnerLoading();

    final organized = _organizeComments(widget.comments);

    return Column(
      children: [
        Expanded(
          child: organized.isEmpty
              ? Center(child: Text(t.discussionsEmpty, style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: organized.length,
            itemBuilder: (_, i) {
              final item = organized[i];

              // 🔥 LOGIC HIGHLIGHT
              // Kiểm tra xem comment cha này hoặc các con của nó có phải là target không
              bool isTarget = item.id == widget.targetCommentId;
              bool hasTargetChild = item.replies.any((r) => r.id == widget.targetCommentId);
              bool shouldHighlight = isTarget || hasTargetChild;

              return Container(
                // Tô màu nền nhẹ nếu là comment đang tìm kiếm
                decoration: shouldHighlight
                    ? BoxDecoration(
                    color: Colors.yellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3))
                )
                    : null,
                padding: shouldHighlight ? const EdgeInsets.all(8) : EdgeInsets.zero,
                margin: shouldHighlight ? const EdgeInsets.only(bottom: 16) : EdgeInsets.zero,

                child: CommentItem(
                  comment: item,
                  currentUserId: widget.currentUserId,
                  onReply: _handleReplyRequest,
                  onReact: widget.onReact,
                  // Truyền ID target xuống để highlight cụ thể item con (nếu muốn làm kỹ hơn)
                  targetId: widget.targetCommentId,
                ),
              );
            },
          ),
        ),

        // INPUT AREA (Giữ nguyên)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.outline)),
            color: AppColors.surfaceCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_replyingTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(AppRadius.input), border: Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 3))),
                  child: Row(children: [Expanded(child: Text(t.replyingToUser(_replyingTo!.userName), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600))), InkWell(onTap: () => setState(() => _replyingTo = null), child: const Icon(Icons.close, size: 16, color: Colors.grey))]),
                ),
              Row(children: [Expanded(child: TextField(controller: _commentCtrl, decoration: InputDecoration(hintText: _replyingTo != null ? t.commentHintReply : t.commentHintAsk, isDense: true, filled: true, fillColor: AppColors.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none)))), const SizedBox(width: 8), CircleAvatar(backgroundColor: Theme.of(context).primaryColor, child: IconButton(onPressed: _handleSend, icon: const Icon(Icons.send, size: 18, color: Colors.white)))]),
            ],
          ),
        ),
      ],
    );
  }
}

class CommentItem extends StatelessWidget {
  final CommentEntity comment;
  final String currentUserId;
  final Function(CommentEntity) onReply;
  final Function(String, ReactionType) onReact;
  final String? targetId; // 🔥 Để highlight chính xác item con

  const CommentItem({super.key, required this.comment, required this.currentUserId, required this.onReply, required this.onReact, this.targetId});

  @override
  Widget build(BuildContext context) {
    ReactionType? myReaction;
    try { myReaction = comment.reactions.firstWhere((r) => r.userId == currentUserId).type; } catch (_) {}
    final reactionCounts = <ReactionType, int>{};
    for (var r in comment.reactions) reactionCounts[r.type] = (reactionCounts[r.type] ?? 0) + 1;
    final displayReactions = (reactionCounts.keys.toList()..sort((a, b) => reactionCounts[b]!.compareTo(reactionCounts[a]!))).take(3).toList();

    return Column(
      children: [
        _buildBubble(context, comment, isRoot: true, myReaction: myReaction, displayReactions: displayReactions, totalReactions: comment.reactions.length, isHighlighted: comment.id == targetId),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 8),
            child: Column(
              children: comment.replies.map((r) {
                ReactionType? subReaction;
                try { subReaction = r.reactions.firstWhere((re) => re.userId == currentUserId).type; } catch (_) {}
                final subCounts = <ReactionType, int>{};
                for (var re in r.reactions) subCounts[re.type] = (subCounts[re.type] ?? 0) + 1;
                final subTop = (subCounts.keys.toList()..sort((a, b) => subCounts[b]!.compareTo(subCounts[a]!))).take(3).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildBubble(context, r, isRoot: false, myReaction: subReaction, displayReactions: subTop, totalReactions: r.reactions.length, isHighlighted: r.id == targetId),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBubble(BuildContext context, CommentEntity c, {required bool isRoot, ReactionType? myReaction, List<ReactionType>? displayReactions, int totalReactions = 0, bool isHighlighted = false}) {
    final t = context.l10n;
    final timeStr = DateFormat('HH:mm').format(c.createdAt.toLocal());
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(radius: isRoot ? 16 : 12, backgroundImage: NetworkImage(c.userAvatar ?? 'https://ui-avatars.com/api/?name=${c.userName}')),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              // 🔥 Đổi màu nền đậm hơn xíu nếu là target
              color: isHighlighted ? Colors.yellow.shade100 : AppColors.surfaceSubtle,
              border: isHighlighted ? Border.all(color: Colors.orange.withValues(alpha: 0.5)) : null,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 8), Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
              const SizedBox(height: 4),
              RichText(text: TextSpan(style: const TextStyle(fontSize: 14, fontFamily: 'Roboto', height: 1.4, color: Colors.black), children: _parseContentStyle(c.content))),
            ]),
          ),
          if (totalReactions > 0) Positioned(bottom: -10, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))]), child: Row(mainAxisSize: MainAxisSize.min, children: [...(displayReactions ?? []).map((t) => Padding(padding: const EdgeInsets.only(right: 2), child: _buildReactionIconWidget(t, size: 12))), Text("$totalReactions", style: const TextStyle(fontSize: 10, color: Colors.black54))]))),
        ]),
        Padding(padding: const EdgeInsets.only(left: 8, top: 6), child: Row(children: [GestureDetector(onTap: () => onReply(c), child: Text(t.discussionReply, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))), const SizedBox(width: 16), Theme(data: Theme.of(context).copyWith(popupMenuTheme: const PopupMenuThemeData(color: Colors.white)), child: PopupMenuButton<ReactionType>(tooltip: t.discussionReactTooltip, offset: const Offset(0, -45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)), elevation: 4, child: Row(children: [myReaction != null ? _buildReactionIconWidget(myReaction, size: 14) : const Icon(Icons.favorite_border, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(myReaction != null ? _getReactionLabel(myReaction, t) : t.reactionLike, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: myReaction != null ? _getReactionColor(myReaction) : Colors.grey))]), itemBuilder: (context) => ReactionType.values.map((type) => PopupMenuItem(value: type, padding: const EdgeInsets.symmetric(horizontal: 8), height: 40, child: Center(child: _buildReactionIconWidget(type, size: 24)))).toList(), onSelected: (type) => onReact(c.id, type)))])),
      ])),
    ]);
  }

  List<TextSpan> _parseContentStyle(String content) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'(@.+?\u200B)|([^@]+)', unicode: true);
    for (final match in regex.allMatches(content)) {
      final text = match.group(0)!;
      if (text.startsWith('@') && text.contains('\u200B')) spans.add(TextSpan(text: text, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)));
      else spans.add(TextSpan(text: text, style: const TextStyle(color: AppColors.textPrimary)));
    }
    return spans;
  }

  Widget _buildReactionIconWidget(ReactionType type, {double size = 16}) {
    switch (type) {
      case ReactionType.LIKE: return Icon(Icons.thumb_up, color: Colors.blue, size: size);
      case ReactionType.LOVE: return Text("❤️", style: TextStyle(fontSize: size));
      case ReactionType.HAHA: return Text("😂", style: TextStyle(fontSize: size));
      case ReactionType.WOW: return Text("😮", style: TextStyle(fontSize: size));
      case ReactionType.SAD: return Text("😢", style: TextStyle(fontSize: size));
      case ReactionType.ANGRY: return Text("😡", style: TextStyle(fontSize: size));
    }
  }

  String _getReactionLabel(ReactionType type, AppLocalizations t) {
    switch (type) {
      case ReactionType.LIKE: return t.reactionLike;
      case ReactionType.LOVE: return t.reactionLove;
      case ReactionType.HAHA: return t.reactionHaha;
      case ReactionType.WOW: return t.reactionWow;
      case ReactionType.SAD: return t.reactionSad;
      case ReactionType.ANGRY: return t.reactionAngry;
    }
  }

  Color _getReactionColor(ReactionType type) {
    switch (type) {
      case ReactionType.LIKE: return Colors.blue;
      case ReactionType.LOVE: return Colors.red;
      case ReactionType.HAHA: return Colors.orange;
      case ReactionType.WOW: return Colors.amber;
      case ReactionType.SAD: return Colors.orangeAccent;
      case ReactionType.ANGRY: return Colors.redAccent;
    }
  }
}