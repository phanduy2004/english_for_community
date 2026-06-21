import 'dart:typed_data';

import 'package:english_for_community/core/datasource/classroom_chat_remote_datasource.dart';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_bloc.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_event.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_state.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_app_bar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_avatar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_group_cover_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Chọn ảnh và upload làm avatar nhóm lớp (GV chủ lớp).
abstract final class ChatGroupAvatarPicker {
  ChatGroupAvatarPicker._();

  static Future<void> pickAndUpload(BuildContext context) async {
    try {
      Uint8List? bytes;
      var fileName = 'group_avatar.jpg';

      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null || result.files.isEmpty || !context.mounted) return;
        final f = result.files.first;
        bytes = f.bytes ?? await platformFileBytes(f);
        if (f.name.isNotEmpty) fileName = f.name;
      } else {
        final picker = ImagePicker();
        final file = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          imageQuality: 85,
        );
        if (file == null || !context.mounted) return;
        bytes = await file.readAsBytes();
        if (file.name.isNotEmpty) fileName = file.name;
      }

      if (bytes == null || bytes.isEmpty) {
        if (context.mounted) {
          AppFeedback.error(context, 'Không đọc được ảnh');
        }
        return;
      }

      if (!context.mounted) return;
      context.read<ClassroomChatBloc>().add(ClassroomChatUploadGroupAvatar(
            fileName: fileName,
            bytes: bytes,
          ));
      AppFeedback.success(context, 'Đang cập nhật ảnh nhóm…');
    } catch (e) {
      if (context.mounted) {
        AppFeedback.error(context, 'Không chọn được ảnh: $e');
      }
    }
  }
}

/// Panel cài đặt bên trái cửa sổ chat — kiểu Facebook Messenger.
class ChatSettingsSidePanel extends StatelessWidget {
  const ChatSettingsSidePanel({
    super.key,
    required this.members,
    required this.classroomName,
    required this.currentUserId,
    required this.height,
    required this.onClose,
    this.onMinimize,
    this.onCloseChat,
    this.onMuteChat,
    this.onLeaveGroup,
  });

  static const double width = ClassroomChatUi.settingsPanelWidth;

  final List<ChatMember> members;
  final String classroomName;
  final String currentUserId;
  final double height;
  final VoidCallback onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onCloseChat;
  final VoidCallback? onMuteChat;
  final VoidCallback? onLeaveGroup;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      elevation: 0,
      child: Container(
        width: ChatSettingsSidePanel.width,
        height: height,
        decoration: ClassroomChatUi.panelShell(radius: 12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ChatSettingsPanelHeader(onBack: onClose),
            Expanded(
              child: ChatSettingsPanelContent(
                members: members,
                classroomName: classroomName,
                currentUserId: currentUserId,
                onMuteChat: onMuteChat,
                onLeaveGroup: onLeaveGroup,
                onClose: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nội dung menu cài đặt — mỗi mục mở dialog giữa màn hình.
class ChatSettingsPanelContent extends StatefulWidget {
  const ChatSettingsPanelContent({
    super.key,
    required this.members,
    required this.classroomName,
    required this.currentUserId,
    required this.onClose,
    this.onMuteChat,
    this.onLeaveGroup,
  });

  final List<ChatMember> members;
  final String classroomName;
  final String currentUserId;
  final VoidCallback onClose;
  final VoidCallback? onMuteChat;
  final VoidCallback? onLeaveGroup;

  @override
  State<ChatSettingsPanelContent> createState() => _ChatSettingsPanelContentState();
}

class _ChatSettingsPanelContentState extends State<ChatSettingsPanelContent> {
  Future<T?> _showCenterDialog<T>(Widget dialog) {
    final ctx = rootNavigatorKey.currentContext ?? context;
    return showDialog<T>(
      context: ctx,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => dialog,
    );
  }

  Future<void> _pickGroupAvatar(BuildContext context) =>
      ChatGroupAvatarPicker.pickAndUpload(context);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassroomChatBloc, ClassroomChatState>(
      builder: (context, state) {
        final isOwner = state.isClassOwner(widget.currentUserId);
        final displayName = state.displayName(widget.classroomName);
        final coverUrl = state.coverImageUrl;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner) ...[
                _GroupProfileHeader(
                  name: displayName,
                  coverImageUrl: coverUrl,
                  isUpdating: state.isUpdatingSettings,
                  onChangeAvatar: () => _pickGroupAvatar(context),
                ),
                _MenuItem(
                  icon: Icons.drive_file_rename_outline,
                  iconBg: AppColors.primaryTint,
                  iconColor: AppColors.primary,
                  label: 'Đổi tên nhóm',
                  onTap: () => _showRenameDialog(context, displayName),
                ),
                _MenuItem(
                  icon: Icons.push_pin_outlined,
                  iconBg: AppColors.primaryTint,
                  iconColor: AppColors.primary,
                  label: 'Tin nhắn đã ghim',
                  onTap: () => _showPinnedDialog(context, state),
                ),
                const _MenuDivider(),
                _MenuItem(
                  icon: Icons.groups_outlined,
                  iconBg: AppColors.primaryTint,
                  iconColor: AppColors.primary,
                  label: 'Thành viên',
                  trailing: Text(
                    '${widget.members.length}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  onTap: _showMembersDialog,
                ),
                _MenuItem(
                  icon: Icons.person_add_outlined,
                  iconBg: AppColors.primaryTint,
                  iconColor: AppColors.primary,
                  label: 'Mời thành viên',
                  onTap: _showInviteDialog,
                ),
                const _MenuDivider(),
                _MenuItem(
                  icon: Icons.notifications_off_outlined,
                  iconBg: AppColors.surfaceSubtle,
                  iconColor: AppColors.textSecondary,
                  label: 'Tắt thông báo nhóm',
                  onTap: _showMuteConfirmDialog,
                ),
              ] else ...[
                _MenuItem(
                  icon: Icons.groups_outlined,
                  iconBg: AppColors.primaryTint,
                  iconColor: AppColors.primary,
                  label: 'Thành viên',
                  trailing: Text(
                    '${widget.members.length}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  onTap: _showMembersDialog,
                ),
                const _MenuDivider(),
                _MenuItem(
                  icon: Icons.notifications_off_outlined,
                  iconBg: AppColors.surfaceSubtle,
                  iconColor: AppColors.textSecondary,
                  label: 'Tắt thông báo nhóm',
                  onTap: _showMuteConfirmDialog,
                ),
                _MenuItem(
                  icon: Icons.logout,
                  iconBg: AppColors.danger.withValues(alpha: 0.08),
                  iconColor: AppColors.danger,
                  label: 'Rời nhóm',
                  labelColor: AppColors.danger,
                  onTap: _showLeaveConfirmDialog,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    _showCenterDialog(
      _ChatCenterDialogShell(
        title: 'Đổi tên nhóm',
        icon: Icons.drive_file_rename_outline,
        body: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên lớp học',
            border: OutlineInputBorder(),
          ),
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(rootNavigatorKey.currentContext ?? context).pop(),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(rootNavigatorKey.currentContext ?? context).pop();
                context.read<ClassroomChatBloc>().add(ClassroomChatUpdateGroupName(name));
                AppFeedback.success(context, 'Đã cập nhật tên nhóm');
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinnedDialog(BuildContext context, ClassroomChatState state) {
    final pinned = state.pinnedMessage;
    _showCenterDialog(
      _ChatCenterDialogShell(
        title: 'Tin nhắn đã ghim',
        icon: Icons.push_pin_outlined,
        body: pinned == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin_outlined, size: 40, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có tin nhắn ghim',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nhấn giữ tin nhắn và chọn "Ghim tin nhắn".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pinned.sender?.fullName ?? 'Thành viên',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    classroomChatMessagePreview(pinned, maxLen: 200),
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
        footer: pinned != null
            ? Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(rootNavigatorKey.currentContext ?? context).pop();
                    context.read<ClassroomChatBloc>().add(const ClassroomChatUnpinMessage());
                    AppFeedback.success(context, 'Đã bỏ ghim tin nhắn');
                  },
                  child: const Text('Bỏ ghim'),
                ),
              )
            : null,
      ),
    );
  }

  void _showMembersDialog() {
    _showCenterDialog(
      _ChatCenterDialogShell(
        title: 'Thành viên (${widget.members.length})',
        icon: Icons.groups_outlined,
        width: 480,
        maxBodyHeight: 460,
        body: _MembersListBody(
          members: widget.members,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _showInviteDialog() {
    _showCenterDialog(
      _ChatCenterDialogShell(
        title: 'Mời thành viên',
        icon: Icons.person_add_outlined,
        body: const Text(
          'Chia sẻ mã lớp hoặc link mời trong trang quản lý lớp học để thêm học sinh vào nhóm chat.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        footer: Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.of(rootNavigatorKey.currentContext ?? context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ),
      ),
    );
  }

  Future<void> _showMuteConfirmDialog() async {
    final ok = await _showCenterDialog<bool>(
      _ChatCenterDialogShell(
        title: 'Tắt thông báo nhóm',
        icon: Icons.notifications_off_outlined,
        body: const Text(
          'Bạn sẽ không nhận thông báo đẩy từ nhóm chat này. Bạn vẫn có thể xem tin nhắn khi mở chat.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(rootNavigatorKey.currentContext ?? context).pop(false),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(rootNavigatorKey.currentContext ?? context).pop(true),
              child: const Text('Tắt thông báo'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      widget.onMuteChat?.call();
      AppFeedback.success(context, 'Đã tắt thông báo nhóm này');
    }
  }

  Future<void> _showLeaveConfirmDialog() async {
    final ok = await _showCenterDialog<bool>(
      _ChatCenterDialogShell(
        title: 'Rời nhóm',
        icon: Icons.logout,
        body: Text(
          'Bạn có chắc muốn rời nhóm chat "${widget.classroomName}"? '
          'Bạn sẽ không nhận tin nhắn mới từ lớp này.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(rootNavigatorKey.currentContext ?? context).pop(false),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(rootNavigatorKey.currentContext ?? context).pop(true),
              child: const Text('Rời nhóm'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      widget.onLeaveGroup?.call();
      widget.onClose();
    }
  }
}

// ─── Group profile (teacher) ───────────────────────────────────────────────────

class _GroupProfileHeader extends StatelessWidget {
  const _GroupProfileHeader({
    required this.name,
    this.coverImageUrl,
    required this.isUpdating,
    required this.onChangeAvatar,
  });

  final String name;
  final String? coverImageUrl;
  final bool isUpdating;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isUpdating ? null : onChangeAvatar,
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ChatGroupCoverAvatar(
                    coverImageUrl: coverImageUrl,
                    radius: 36,
                    fallbackIconSize: 32,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Icon(
                      isUpdating ? Icons.hourglass_empty : Icons.camera_alt_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Chạm ảnh để đổi ảnh nhóm',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog shell & bodies ────────────────────────────────────────────────────

class _ChatCenterDialogShell extends StatelessWidget {
  const _ChatCenterDialogShell({
    required this.title,
    required this.body,
    this.icon,
    this.footer,
    this.width = 440,
    this.maxBodyHeight = 360,
  });

  final String title;
  final IconData? icon;
  final Widget body;
  final Widget? footer;
  final double width;
  final double maxBodyHeight;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxBodyHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: body,
                ),
              ),
            ),
            if (footer != null) ...[
              const Divider(height: 1, color: AppColors.outline),
              Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 18), child: footer!),
            ],
          ],
        ),
      ),
    );
  }
}

class _MembersListBody extends StatelessWidget {
  const _MembersListBody({required this.members, required this.currentUserId});

  final List<ChatMember> members;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final teachers = members.where((m) => m.isTeacher).toList();
    final students = members.where((m) => !m.isTeacher).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (teachers.isNotEmpty) ...[
          const _SectionLabel('Giáo viên'),
          ...teachers.map((m) => _MemberRow(member: m, isMe: m.id == currentUserId)),
        ],
        _SectionLabel('Học sinh (${students.length})'),
        ...students.map((m) => _MemberRow(member: m, isMe: m.id == currentUserId)),
      ],
    );
  }
}

// ─── Menu widgets ─────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.trailing,
    this.labelColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: labelColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 14, endIndent: 14);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isMe});
  final ChatMember member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      leading: ChatAvatar(
        avatarUrl: member.avatarUrl,
        displayName: member.fullName,
        radius: 20,
        fontSize: 12,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.fullName,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Bạn',
                style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '@${member.username}',
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: member.isTeacher
          ? Text(
              member.role == 'teacher' ? 'GV' : 'GV phụ',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: '@${member.username}'));
        AppFeedback.success(context, 'Đã sao chép @${member.username}');
      },
    );
  }
}

/// Bottom sheet wrapper (mobile full-page chat).
class ChatSettingsSheet {
  ChatSettingsSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<ChatMember> members,
    required String classroomName,
    required String currentUserId,
  }) {
    final bloc = context.read<ClassroomChatBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.78,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classroomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${members.length} thành viên',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<ClassroomChatBloc, ClassroomChatState>(
                  builder: (context, state) {
                    return ChatSettingsPanelContent(
                      members: members,
                      classroomName: state.displayName(classroomName),
                      currentUserId: currentUserId,
                      onClose: () => Navigator.pop(ctx),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
