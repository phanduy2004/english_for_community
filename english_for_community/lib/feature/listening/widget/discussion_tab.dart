import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../../core/entity/comment_entity.dart';

// Controller tùy chỉnh để tô màu User Tag
class MentionTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = value.text;
    final List<InlineSpan> children = [];

    // Regex tìm chuỗi bắt đầu bằng @ và kết thúc bằng ký tự tàng hình \u200B
    text.splitMapJoin(
      RegExp(r'(@.+?\u200B)', unicode: true),
      onMatch: (Match match) {
        children.add(TextSpan(
          text: match[0],
          style: style?.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
        ));
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

  const DiscussionTab({
    super.key,
    required this.comments,
    required this.isLoading,
    required this.currentUserId,
    required this.onSend,
    required this.onReact,
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;

    String? finalParentId;
    if (_replyingTo != null) {
      finalParentId = _replyingTo!.parentId ?? _replyingTo!.id;
    }

    widget.onSend(content, finalParentId);

    _commentCtrl.clear();
    setState(() => _replyingTo = null);
    FocusScope.of(context).unfocus();
    _scrollToBottom();
  }

  void _handleReplyRequest(CommentEntity comment) {
    setState(() {
      _replyingTo = comment;
      if (comment.userId == widget.currentUserId) {
      } else {
        _commentCtrl.text = "@${comment.userName}\u200B ";
        _commentCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _commentCtrl.text.length),
        );
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
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());

    final organized = _organizeComments(widget.comments);

    // Logic cuộn xuống dưới cùng khi mới mở tab
    if (organized.isNotEmpty && _scrollController.hasClients == false) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if(_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }

    return Column(
      children: [
        Expanded(
          child: organized.isEmpty
              ? Center(child: Text("No discussions yet", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: organized.length,
            itemBuilder: (_, i) => CommentItem(
              comment: organized[i],
              currentUserId: widget.currentUserId,
              onReply: _handleReplyRequest,
              onReact: widget.onReact,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE4E4E7))),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_replyingTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 3)),
                  ),
                  child: Row(children: [
                    Text("Replying to ", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(_replyingTo!.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _replyingTo = null),
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    )
                  ]),
                ),

              Row(children: [
                Expanded(child: TextField(
                  controller: _commentCtrl,
                  decoration: InputDecoration(
                    hintText: _replyingTo != null ? 'Write a reply...' : 'Ask a question...',
                    isDense: true, filled: true, fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                )),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(onPressed: _handleSend, icon: const Icon(Icons.send, size: 18, color: Colors.white)),
                ),
              ]),
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

  const CommentItem({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onReply,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    ReactionType? myReaction;
    try {
      myReaction = comment.reactions.firstWhere((r) => r.userId == currentUserId).type;
    } catch (_) {}

    final reactionCounts = <ReactionType, int>{};
    for (var r in comment.reactions) {
      reactionCounts[r.type] = (reactionCounts[r.type] ?? 0) + 1;
    }

    final topReactions = reactionCounts.keys.toList()
      ..sort((a, b) => reactionCounts[b]!.compareTo(reactionCounts[a]!));
    final displayReactions = topReactions.take(3).toList();

    return Column(
      children: [
        _buildBubble(
          context,
          comment,
          isRoot: true,
          myReaction: myReaction,
          displayReactions: displayReactions,
          totalReactions: comment.reactions.length,
        ),

        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 8),
            child: Column(
              children: comment.replies.map((r) {
                ReactionType? subReaction;
                try { subReaction = r.reactions.firstWhere((re) => re.userId == currentUserId).type; } catch (_) {}

                final subCounts = <ReactionType, int>{};
                for (var re in r.reactions) subCounts[re.type] = (subCounts[re.type] ?? 0) + 1;
                final subTop = subCounts.keys.toList()..sort((a, b) => subCounts[b]!.compareTo(subCounts[a]!));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildBubble(
                      context, r,
                      isRoot: false,
                      myReaction: subReaction,
                      displayReactions: subTop.take(3).toList(),
                      totalReactions: r.reactions.length
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBubble(BuildContext context, CommentEntity c, {
    required bool isRoot,
    ReactionType? myReaction,
    List<ReactionType>? displayReactions,
    int totalReactions = 0
  }) {
    final localTime = c.createdAt.toLocal();
    final timeStr = DateFormat('HH:mm').format(localTime);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(
        radius: isRoot ? 16 : 12,
        backgroundImage: NetworkImage(c.userAvatar ?? 'https://ui-avatars.com/api/?name=${c.userName}'),
      ),
      const SizedBox(width: 10),

      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 4),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, fontFamily: 'Roboto', height: 1.4, color: Colors.black),
                      children: _parseContentStyle(c.content),
                    ),
                  ),
                ]),
              ),

              if (totalReactions > 0)
                Positioned(
                  bottom: -10,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...(displayReactions ?? []).map((t) => Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: _buildReactionIconWidget(t, size: 12),
                        )),
                        Text("$totalReactions", style: const TextStyle(fontSize: 10, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onReply(c),
                  child: const Text("Reply", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                ),

                const SizedBox(width: 16),

                Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
                  ),
                  child: PopupMenuButton<ReactionType>(
                    tooltip: 'React',
                    offset: const Offset(0, -45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 4,
                    child: Row(
                      children: [
                        myReaction != null
                            ? _buildReactionIconWidget(myReaction, size: 14)
                            : const Icon(Icons.favorite_border, size: 14, color: Colors.grey),

                        const SizedBox(width: 4),

                        Text(
                          myReaction != null ? _getReactionLabel(myReaction) : "Like",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: myReaction != null ? _getReactionColor(myReaction) : Colors.grey
                          ),
                        ),
                      ],
                    ),
                    itemBuilder: (context) => ReactionType.values.map((type) => PopupMenuItem(
                      value: type,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 40,
                      child: Center(child: _buildReactionIconWidget(type, size: 24)),
                    )).toList(),
                    onSelected: (type) => onReact(c.id, type),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }

  List<TextSpan> _parseContentStyle(String content) {
    final List<TextSpan> spans = [];
    // Regex tìm nhóm 1: @...tới...\u200B (Tên người dùng)
    // Nhóm 2: Các ký tự còn lại
    final regex = RegExp(r'(@.+?\u200B)|([^@]+)', unicode: true);
    final matches = regex.allMatches(content);

    for (final match in matches) {
      final String text = match.group(0)!;
      // Kiểm tra xem có phải là tag (có chứa ký tự tàng hình) không
      if (text.startsWith('@') && text.contains('\u200B')) {
        spans.add(TextSpan(
          text: text,
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ));
      } else {
        spans.add(TextSpan(
          text: text,
          style: const TextStyle(color: Color(0xFF1F2937)),
        ));
      }
    }
    return spans;
  }

  Widget _buildReactionIconWidget(ReactionType type, {double size = 16}) {
    switch (type) {
      case ReactionType.LIKE:
        return Icon(Icons.thumb_up, color: Colors.blue, size: size);
      case ReactionType.LOVE:
        return Text("❤️", style: TextStyle(fontSize: size));
      case ReactionType.HAHA:
        return Text("😂", style: TextStyle(fontSize: size));
      case ReactionType.WOW:
        return Text("😮", style: TextStyle(fontSize: size));
      case ReactionType.SAD:
        return Text("😢", style: TextStyle(fontSize: size));
      case ReactionType.ANGRY:
        return Text("😡", style: TextStyle(fontSize: size));
    }
  }

  String _getReactionLabel(ReactionType type) {
    switch (type) {
      case ReactionType.LIKE: return "Like";
      case ReactionType.LOVE: return "Love";
      case ReactionType.HAHA: return "Haha";
      case ReactionType.WOW: return "Wow";
      case ReactionType.SAD: return "Sad";
      case ReactionType.ANGRY: return "Angry";
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