import 'package:flutter/material.dart';

/// Khóa hover/action giữa các bubble — tránh dính sang tin nhắn khác khi chọn emoji.
class ChatMessageInteractionLock extends ChangeNotifier {
  String? _activeMessageId;
  bool _reactionPickerOpen = false;

  String? get activeMessageId => _activeMessageId;
  bool get reactionPickerOpen => _reactionPickerOpen;

  bool canHover(String messageId) =>
      _activeMessageId == null || _activeMessageId == messageId;

  void openReactionPicker(String messageId) {
    _activeMessageId = messageId;
    _reactionPickerOpen = true;
    notifyListeners();
  }

  void closeInteraction(String messageId) {
    if (_activeMessageId != messageId) return;
    _activeMessageId = null;
    _reactionPickerOpen = false;
    notifyListeners();
  }

  void clearAll() {
    if (_activeMessageId == null && !_reactionPickerOpen) return;
    _activeMessageId = null;
    _reactionPickerOpen = false;
    notifyListeners();
  }
}

class ChatMessageInteractionScope extends InheritedWidget {
  const ChatMessageInteractionScope({
    super.key,
    required this.lock,
    required super.child,
  });

  final ChatMessageInteractionLock lock;

  static ChatMessageInteractionLock of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ChatMessageInteractionScope>();
    assert(scope != null, 'ChatMessageInteractionScope not found in widget tree');
    return scope!.lock;
  }

  static ChatMessageInteractionLock? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ChatMessageInteractionScope>()
        ?.lock;
  }

  @override
  bool updateShouldNotify(ChatMessageInteractionScope oldWidget) =>
      oldWidget.lock != lock;
}
