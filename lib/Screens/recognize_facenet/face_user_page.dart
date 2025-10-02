// lib/pages/face_users_page.dart
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:recognize_face/screens/recognize_facenet/recognize_face_camera_page.dart';
import '../../services/facenet_service/face_dataset_repository_v2.dart';

class FaceUsersPage extends StatefulWidget {
  const FaceUsersPage({super.key});
  @override
  State<FaceUsersPage> createState() => _FaceUsersPageState();
}

class _FaceUsersPageState extends State<FaceUsersPage> {
  final _repo = FaceDatasetRepositorySqlite();
  final _picker = ImagePicker();

  List<_FaceUser> _all = [];
  String _q = '';
  bool _loading = true;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _repo.listUsers(withAvatar: true);
      _all = rows
          .map<_FaceUser>(
            (m) => _FaceUser(
              id: (m['id'] ?? 0) as int,
              name: (m['name'] ?? '').toString(),
              count: (m['image_count'] ?? 0) as int,
              avatar: m['avatar'] as Uint8List?,
            ),
          )
          .toList()
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_FaceUser> get _filtered {
    final k = _q.trim().toLowerCase();
    if (k.isEmpty) return _all;
    return _all.where((u) => u.name.toLowerCase().contains(k)).toList();
  }

  Future<void> _rename(_FaceUser u) async {
    final c = TextEditingController(text: u.name);
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Rename user'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: c,
            autofocus: true,
            placeholder: 'New name',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => Navigator.of(ctx).pop(true),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final newName = c.text.trim();
    if (ok != true || newName.isEmpty || newName == u.name) return;

    await _repo.renameUser(id: u.id, newName: newName);
    if (mounted) await _load();
  }

  Future<void> _delete(_FaceUser u) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete user'),
        content: Text('Delete "${u.name}" and all embeddings?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _repo.deleteUserById(u.id);
    if (mounted) await _load();
  }

  Future<void> _changeAvatar(_FaceUser u) async {
    if (_isPickingImage) return; // Prevent multiple simultaneous calls

    final source = await showCupertinoModalPopup<ImageSource?>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Change avatar'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (source == null) return;

    setState(() => _isPickingImage = true);

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();

      await _repo.setAvatarById(u.id, bytes);
      if (mounted) await _load();
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _clearAvatar(_FaceUser u) async {
    await _repo.clearAvatarById(u.id);
    if (mounted) await _load();
  }

  Future<void> _userMenu(_FaceUser u) async {
    final v = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(u.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'rename'),
            child: const Text('Rename'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'avatar'),
            child: const Text('Change avatar'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'clear_avatar'),
            child: const Text('Clear avatar'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Delete user'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );

    switch (v) {
      case 'rename':
        await _rename(u);
        break;
      case 'avatar':
        await _changeAvatar(u);
        break;
      case 'clear_avatar':
        await _clearAvatar(u);
        break;
      case 'delete':
        await _delete(u);
        break;
    }
  }

  void _openCamera() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => const RecognizeFaceCameraPage()));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(middle: Text('Face Users')),
      child: Stack(
        children: [
          // Nội dung cuộn
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: CupertinoSearchTextField(
                      placeholder: 'Search user...',
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  ),
                ),
                CupertinoSliverRefreshControl(onRefresh: _load),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (_filtered.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No users\nAdd by capturing on the camera screen',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: CupertinoColors.systemGrey),
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: CupertinoFormSection.insetGrouped(
                      header: const Text('USERS'),
                      children: _filtered.map((u) {
                        final cell = _UserCell(
                          user: u,
                          onMore: () => _userMenu(u),
                          onTap: () => _showUserInfo(u),
                        );
                        return Dismissible(
                          key: ValueKey('u_${u.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: CupertinoColors.systemRed.resolveFrom(
                              context,
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(
                              CupertinoIcons.delete_solid,
                              color: CupertinoColors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            await _delete(u);
                            return false; // giữ item, vì _load() sẽ refresh
                          },
                          child: cell,
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Hai nút nổi xếp dọc ở góc phải dưới
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _fab(icon: CupertinoIcons.camera_fill, onPressed: _openCamera),
                const SizedBox(height: 12),
                _fab(
                  icon: CupertinoIcons.refresh,
                  onPressed: _load,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserInfo(_FaceUser u) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(u.name),
        content: Column(
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(
                width: 80,
                height: 80,
                child: (u.avatar != null && u.avatar!.isNotEmpty)
                    ? Image.memory(u.avatar!, fit: BoxFit.cover)
                    : Container(
                        color: CupertinoColors.systemGrey5,
                        child: Center(
                          child: Text(
                            u.initials,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Samples: ${u.count}\nID: ${u.id}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _UserCell extends StatelessWidget {
  final _FaceUser user;
  final VoidCallback onMore;
  final VoidCallback onTap;
  const _UserCell({
    required this.user,
    required this.onMore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 44,
                height: 44,
                child: (user.avatar != null && user.avatar!.isNotEmpty)
                    ? Image.memory(user.avatar!, fit: BoxFit.cover)
                    : Container(
                        color: CupertinoColors.systemGrey5,
                        child: Center(
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.count} sample(s)',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 10,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onMore,
              child: const Icon(CupertinoIcons.ellipsis_vertical),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceUser {
  final int id;
  final String name;
  final int count;
  final Uint8List? avatar;
  _FaceUser({
    required this.id,
    required this.name,
    required this.count,
    this.avatar,
  });

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

Widget _fab({
  required IconData icon,
  required VoidCallback onPressed,
  Color? color,
}) {
  return CupertinoButton(
    padding: const EdgeInsets.all(12),
    minSize: 0, // để kích thước theo padding
    borderRadius: BorderRadius.circular(28),
    color: color ?? CupertinoColors.activeBlue,
    onPressed: onPressed,
    child: Icon(icon, size: 22, color: CupertinoColors.white),
  );
}
