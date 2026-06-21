import 'dart:async';

import 'package:english_for_community/core/datasource/classroom_chat_remote_datasource.dart';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_attachment_staging.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'chat_reply_preview.dart';

/// Giới hạn upload chat (khớp multer backend).
const int kChatUploadMaxBytes = 50 * 1024 * 1024;

class ChatInputBar extends StatefulWidget {
  final List<ChatMember> members;
  final ClassroomChatMessage? replyTo;
  final void Function(String content, List<String> mentionIds) onSendText;
  final void Function(ChatUploadPayload payload) onSendFile;
  final void Function() onCancelReply;
  final void Function(bool isTyping) onTypingChanged;
  final bool compact;
  final bool isUploading;

  const ChatInputBar({
    super.key,
    required this.members,
    required this.onSendText,
    required this.onSendFile,
    required this.onCancelReply,
    required this.onTypingChanged,
    this.replyTo,
    this.compact = false,
    this.isUploading = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  Timer? _typingTimer;
  List<ChatMember> _mentionSuggestions = [];
  final List<String> _mentionIds = [];
  final List<ChatPendingAttachment> _pending = [];

  bool get _canSend =>
      !widget.isUploading &&
      (_ctrl.text.trim().isNotEmpty || _pending.isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _focusNode.onKeyEvent = _handleWebKeyEvent;
    }
  }

  KeyEventResult _handleWebKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    if (_mentionSuggestions.isNotEmpty) return KeyEventResult.ignored;
    if (!_canSend) return KeyEventResult.handled;

    _sendAll();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _handleTypingIndicator();
    _handleMentionAutocomplete(value);
    setState(() {});
  }

  void _handleTypingIndicator() {
    if (!_isTyping) {
      _isTyping = true;
      widget.onTypingChanged(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      widget.onTypingChanged(false);
    });
  }

  void _handleMentionAutocomplete(String text) {
    final cursor = _ctrl.selection.baseOffset;
    if (cursor < 0) return;
    final before = text.substring(0, cursor.clamp(0, text.length));
    final match = RegExp(r'@(\S*)$').firstMatch(before);
    if (match != null) {
      final query = match.group(1)!.toLowerCase();
      setState(() {
        _mentionSuggestions = widget.members
            .where((m) =>
                m.fullName.toLowerCase().contains(query) ||
                m.username.toLowerCase().contains(query))
            .take(6)
            .toList();
      });
    } else if (_mentionSuggestions.isNotEmpty) {
      setState(() => _mentionSuggestions = []);
    }
  }

  void _insertMention(ChatMember member) {
    final text = _ctrl.text;
    final cursor = _ctrl.selection.baseOffset.clamp(0, text.length);
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);
    final atIdx = before.lastIndexOf('@');
    if (atIdx < 0) return;

    final replaced = '${before.substring(0, atIdx)}@${member.fullName} $after';
    _ctrl.text = replaced;
    _ctrl.selection =
        TextSelection.collapsed(offset: atIdx + member.fullName.length + 2);
    if (!_mentionIds.contains(member.id)) _mentionIds.add(member.id);
    setState(() => _mentionSuggestions = []);
  }

  void _sendAll() {
    if (!_canSend) return;

    final text = _ctrl.text.trim();
    final pending = List<ChatPendingAttachment>.from(_pending);

    if (text.isNotEmpty) {
      widget.onSendText(text, List.from(_mentionIds));
    }
    for (final item in pending) {
      widget.onSendFile(item.toPayload());
    }

    _ctrl.clear();
    _mentionIds.clear();
    setState(() => _pending.clear());
    _isTyping = false;
    widget.onTypingChanged(false);
    _typingTimer?.cancel();
    widget.onCancelReply();
  }

  void _showFeedback(String message, {bool error = false}) {
    final ctx = rootNavigatorKey.currentContext ?? context;
    AppFeedback.error(ctx, message);
  }

  void _deferPick(Future<void> Function() pick) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pick().catchError((Object e) {
        if (mounted) {
          _showFeedback('Không chọn được tệp: $e', error: true);
        }
      });
    });
  }

  String _nextAttachmentId() => 'att_${DateTime.now().microsecondsSinceEpoch}';

  ChatAttachmentKind _kindFromMime(String mime) {
    if (mime.startsWith('image/')) return ChatAttachmentKind.image;
    if (mime.startsWith('video/')) return ChatAttachmentKind.video;
    return ChatAttachmentKind.file;
  }

  void _addPending({
    required String fileName,
    required String mimeType,
    String? filePath,
    Uint8List? bytes,
    int size = 0,
  }) {
    setState(() {
      _pending.add(ChatPendingAttachment(
        id: _nextAttachmentId(),
        fileName: fileName,
        mimeType: mimeType,
        kind: _kindFromMime(mimeType),
        filePath: filePath,
        bytes: bytes,
        size: size,
      ));
    });
  }

  Future<void> _stagePickedFile(PlatformFile f, String mimeType) async {
    if (f.size > kChatUploadMaxBytes) {
      _showFeedback('Tệp quá lớn (tối đa 50MB)', error: true);
      return;
    }

    final isVideo = mimeType.startsWith('video/');
    if (kIsWeb || !isVideo) {
      final bytes = await platformFileBytes(f);
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          _showFeedback('Không đọc được tệp đính kèm', error: true);
        }
        return;
      }
      _addPending(fileName: f.name, mimeType: mimeType, bytes: bytes, size: f.size);
      return;
    }

    if (f.path != null) {
      _addPending(
        fileName: f.name,
        mimeType: mimeType,
        filePath: f.path,
        size: f.size,
      );
      return;
    }

    final bytes = await platformFileBytes(f);
    if (bytes == null || bytes.isEmpty) {
      _showFeedback('Không đọc được tệp đính kèm', error: true);
      return;
    }
    _addPending(fileName: f.name, mimeType: mimeType, bytes: bytes, size: f.size);
  }

  Future<void> _stageXFile(XFile file, String mimeType) async {
    try {
      final length = await file.length();
      if (length > kChatUploadMaxBytes) {
        _showFeedback('Tệp quá lớn (tối đa 50MB)', error: true);
        return;
      }
      final name = file.name.trim().isNotEmpty ? file.name : p.basename(file.path);
      final isVideo = mimeType.startsWith('video/');

      if (!kIsWeb && isVideo && file.path.isNotEmpty) {
        _addPending(
          fileName: name,
          mimeType: mimeType,
          filePath: file.path,
          size: length,
        );
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _showFeedback('Tệp rỗng', error: true);
        return;
      }
      _addPending(
        fileName: name,
        mimeType: mimeType,
        bytes: bytes,
        filePath: file.path.isNotEmpty ? file.path : null,
        size: length,
      );
    } catch (e) {
      _showFeedback('Không đọc được tệp: $e', error: true);
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final mime = lookupMimeType(f.name) ?? 'image/jpeg';
      await _stagePickedFile(f, mime);
      return;
    }

    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final mime = lookupMimeType(file.name) ?? lookupMimeType(file.path) ?? 'image/jpeg';
    await _stageXFile(file, mime);
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final mime = lookupMimeType(f.name) ?? 'video/mp4';
      await _stagePickedFile(f, mime);
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final mime = lookupMimeType(file.name) ?? lookupMimeType(file.path) ?? 'video/mp4';
    await _stageXFile(file, mime);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final mime = lookupMimeType(f.name) ?? 'application/octet-stream';
    await _stagePickedFile(f, mime);
  }

  void _removePending(String id) {
    setState(() => _pending.removeWhere((a) => a.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final mobile = !compact && ClassroomChatUi.isMobileLayout(context);
    final effectiveCompact = compact || mobile;
    final hPad = effectiveCompact ? AppSpacing.s3 : AppSpacing.s4;

    return Material(
      color: AppColors.surfaceCard,
      child: DecoratedBox(
        decoration: ClassroomChatUi.inputBarSurface(),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_mentionSuggestions.isNotEmpty)
                _MentionSuggestions(
                  suggestions: _mentionSuggestions,
                  onSelect: _insertMention,
                ),
              if (widget.replyTo != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, AppSpacing.s3, hPad, 0),
                  child: ChatReplyPreview(
                    snapshot: ChatReplySnapshot(
                      messageId: widget.replyTo!.id,
                      senderId: widget.replyTo!.senderId,
                      senderName: widget.replyTo!.sender?.fullName ?? '',
                      contentPreview: widget.replyTo!.isDeleted
                          ? '[Tin nhắn đã bị xóa]'
                          : widget.replyTo!.type == ChatMessageType.text
                              ? widget.replyTo!.content
                              : widget.replyTo!.media?.name ?? '',
                      messageType: widget.replyTo!.type.name,
                    ),
                    isMe: false,
                    inInputBar: true,
                    onDismiss: widget.onCancelReply,
                  ),
                ),
              ChatAttachmentPreviewStrip(
                attachments: _pending,
                compact: effectiveCompact,
                isUploading: widget.isUploading,
                onRemove: _removePending,
                onAdd: () => _deferPick(_pickImage),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, AppSpacing.s2, hPad, AppSpacing.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AttachButton(
                      compact: effectiveCompact,
                      onPickImage: () => _deferPick(_pickImage),
                      onPickVideo: () => _deferPick(_pickVideo),
                      onPickFile: () => _deferPick(_pickFile),
                    ),
                    SizedBox(width: effectiveCompact ? AppSpacing.s2 : AppSpacing.s3),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: effectiveCompact ? 96 : 120),
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          onChanged: _onTextChanged,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                          decoration: ClassroomChatUi.composerDecoration(compact: effectiveCompact),
                        ),
                      ),
                    ),
                    SizedBox(width: effectiveCompact ? AppSpacing.s2 : AppSpacing.s3),
                    if (!_canSend)
                      SizedBox(width: effectiveCompact ? 34 : 38)
                    else
                      _SendButton(
                        compact: effectiveCompact,
                        onSend: _sendAll,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({
    required this.compact,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onPickFile,
  });

  final bool compact;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 38.0;
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: 'Đính kèm',
        offset: const Offset(0, -120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: AppColors.surfaceCard,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outlineMuted),
          ),
          child: const Icon(Icons.add, size: 20, color: AppColors.primary),
        ),
        onSelected: (v) {
          if (v == 'image') onPickImage();
          if (v == 'video') onPickVideo();
          if (v == 'file') onPickFile();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'image', child: _AttachItem(icon: Icons.image_outlined, label: 'Hình ảnh')),
          PopupMenuItem(value: 'video', child: _AttachItem(icon: Icons.videocam_outlined, label: 'Video')),
          PopupMenuItem(value: 'file', child: _AttachItem(icon: Icons.attach_file_outlined, label: 'Tệp tài liệu')),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.compact, required this.onSend});

  final bool compact;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 38.0;
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSend,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.arrow_upward_rounded, color: AppColors.textInverse, size: 18),
        ),
      ),
    );
  }
}

class _MentionSuggestions extends StatelessWidget {
  const _MentionSuggestions({required this.suggestions, required this.onSelect});
  final List<ChatMember> suggestions;
  final void Function(ChatMember) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: ListView(
        shrinkWrap: true,
        children: suggestions
            .map(
              (m) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryTint,
                  child: Text(
                    m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
                title: Text(m.fullName, style: const TextStyle(fontSize: 13)),
                subtitle: Text('@${m.username}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                onTap: () => onSelect(m),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AttachItem extends StatelessWidget {
  const _AttachItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
}
