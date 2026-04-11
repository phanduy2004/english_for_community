import 'package:equatable/equatable.dart';

import '../../../../core/entity/comment_entity.dart';

abstract class CueEvent extends Equatable {
  const CueEvent();
  @override
  List<Object?> get props => [];
}

class FetchCuesByListeningId extends CueEvent {
  final String listeningId;
  final int from;
  final int limit;
  const FetchCuesByListeningId({
    required this.listeningId,
    this.from = 0,
    this.limit = 200,
  });
  @override
  List<Object?> get props => [listeningId, from, limit];
}

class SelectCueByIndex extends CueEvent {
  final int index;
  const SelectCueByIndex(this.index);
  @override
  List<Object?> get props => [index];
}

class NextCue extends CueEvent {
  const NextCue();
}

class PrevCue extends CueEvent {
  const PrevCue();
}

class UpdateUserAnswer extends CueEvent {
  final String text;
  const UpdateUserAnswer(this.text);
  @override
  List<Object?> get props => [text];
}
class LoadCuesAndAttempts extends CueEvent {
  final String listeningId;
  final String? initialCueId;
  final bool isRetake; // 🔥 THÊM BIẾN NÀY

  const LoadCuesAndAttempts({
    required this.listeningId,
    this.initialCueId,
    this.isRetake = false, // Mặc định là false
  });

  @override
  List<Object?> get props => [listeningId, initialCueId, isRetake];
}
// 🔥 EVENT MỚI: Load danh sách comment của câu hiện tại
class LoadCommentsEvent extends CueEvent {
  final String cueId;
  final bool isLoadMore; // 🔥 Biến này để phân biệt load lần đầu hay load thêm

  const LoadCommentsEvent(this.cueId, {this.isLoadMore = false});

  @override
  List<Object?> get props => [cueId, isLoadMore];
}

// 🔥 EVENT MỚI: Gửi comment (kèm parentId nếu là reply)
class PostCommentEvent extends CueEvent {
  final String content;
  final String? parentId;

  const PostCommentEvent({required this.content, this.parentId});
  @override
  List<Object?> get props => [content, parentId];
}
class IncomingSocketComment extends CueEvent {
  final String cueId; // 🔥 Thêm trường này
  final CommentEntity comment;

  const IncomingSocketComment({
    required this.cueId,
    required this.comment
  });

  @override
  List<Object?> get props => [cueId, comment];
}
class ReactToCommentEvent extends CueEvent {
  final String commentId;
  final ReactionType type;
  final String userId; // 🔥 Thêm field này để Bloc biết ai đang react

  const ReactToCommentEvent({
    required this.commentId,
    required this.type,
    required this.userId,
  });

  @override
  List<Object?> get props => [commentId, type, userId];
}
class IncomingSocketReaction extends CueEvent {
  final String cueId; // 🔥 Thêm trường này
  final String commentId;
  final List<ReactionEntity> reactions;

  const IncomingSocketReaction({
    required this.cueId,
    required this.commentId,
    required this.reactions
  });

  @override
  List<Object?> get props => [cueId, commentId, reactions];
}
