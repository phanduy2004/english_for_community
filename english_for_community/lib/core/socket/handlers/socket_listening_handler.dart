part of '../socket_service.dart';

extension SocketListeningHandler on SocketService {

  void joinListeningRoom(String listeningId) {
    if (!_isInitialized) init();

    // Lưu lại ID phòng để reconnect
    _currentListeningRoomId = listeningId;

    if (isConnected) {
      print('🎧 [Socket] Joining room: listening_$listeningId');
      _socket.emit('join_listening_room', listeningId);
    }
    // Không cần else vì onConnect ở file chính sẽ lo việc join lại
  }

  void leaveListeningRoom(String listeningId) {
    _currentListeningRoomId = null;

    if (isConnected) {
      print('🔇 [Socket] Leaving room: listening_$listeningId');
      _socket.emit('leave_listening_room', listeningId);

      // Hủy lắng nghe để tránh memory leak
      _socket.off('new_comment');
      _socket.off('comment_reaction_updated');
    }
  }

  void listenToNewComments(Function(dynamic) onNewComment) {
    if (!_isInitialized) init();

    _socket.off('new_comment');

    _socket.on('new_comment', (data) {
      print('💬 [Socket] New Comment Received: $data');
      onNewComment(data);
    });
  }

  void listenToReactionUpdates(Function(dynamic) onUpdate) {
    if (!_isInitialized) init();

    _socket.off('comment_reaction_updated');

    _socket.on('comment_reaction_updated', (data) {
      print('❤️ [Socket] Reaction Updated: $data');

      onUpdate(data);
    });
  }
}