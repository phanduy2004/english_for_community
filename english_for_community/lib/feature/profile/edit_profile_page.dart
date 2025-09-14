import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/entity/user_entity.dart';

/// Tiện cho UI: thêm copyWith cho UserEntity
extension UserEntityCopyWith on UserEntity {
  UserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? username,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
    String? goal,
    String? cefr,
    int? dailyMinutes,
    TimeOfDay? reminder,
    bool? strictCorrection,
    String? language,
    String? timezone,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bio: bio ?? this.bio,
      goal: goal ?? this.goal,
      cefr: cefr ?? this.cefr,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      reminder: reminder ?? this.reminder,
      strictCorrection: strictCorrection ?? this.strictCorrection,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
    );
  }
}

class EditProfilePage extends StatefulWidget {
  static String routeName = 'EditProfilePage';
  static String routePath = '/profile/edit';

  final UserEntity initialProfile;

  const EditProfilePage({super.key, required this.initialProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late UserEntity _profile;
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    // TODO: gọi API cập nhật hồ sơ tại đây
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu thay đổi')),
    );
    context.pop(true);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profile = _profile.copyWith(avatarUrl: pickedFile.path);
          _isDirty = true;
        });
      }
    }
  }

  Future<void> _confirmExit() async {
    if (!_isDirty) {
      context.pop();
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu thay đổi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bỏ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Ở lại'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveProfile();
    } else if (result == false) {
      if (mounted) context.pop();
    }
  }

  String _formatTimeOfDay(TimeOfDay? t) {
    if (t == null) return 'Chưa đặt';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return WillPopScope(
      onWillPop: () async {
        await _confirmExit();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmExit,
          ),
          title: const Text('Chỉnh sửa hồ sơ'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _isDirty && _formKey.currentState?.validate() == true
                    ? _saveProfile
                    : null,
                child: const Text('Lưu'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: () => setState(() => _isDirty = true),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _buildAvatarSection(cs),
                const SizedBox(height: 24),
                _buildPersonalInfoSection(cs, tt),
                const SizedBox(height: 16),
                _buildLearningHabitsSection(cs, tt),
                const SizedBox(height: 16),
                _buildLanguageSection(cs, tt),
                const SizedBox(height: 16),
                _buildOfflineSection(cs, tt),
                const SizedBox(height: 16),
                _buildSecuritySection(cs, tt),
                const SizedBox(height: 24),
                _buildDangerZone(cs, tt),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ColorScheme cs) {
    ImageProvider? provider;
    final url = _profile.avatarUrl;

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        provider = NetworkImage(url);
      } else {
        final file = File(url);
        if (file.existsSync()) provider = FileImage(file);
      }
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: cs.surfaceVariant,
          backgroundImage: provider,
          child: provider == null
              ? Icon(Icons.person, size: 44, color: cs.onSurfaceVariant)
              : null,
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
            border: Border.all(color: cs.surface, width: 2),
          ),
          child: IconButton(
            icon: const Icon(Icons.camera_alt, size: 20),
            color: cs.onPrimary,
            onPressed: _pickImage,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(ColorScheme cs, TextTheme tt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: _profile.fullName,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              validator: (value) =>
              value?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
              onChanged: (value) =>
              _profile = _profile.copyWith(fullName: value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _profile.email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                if (!value!.contains('@')) return 'Email không hợp lệ';
                return null;
              },
              onChanged: (value) => _profile = _profile.copyWith(email: value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _profile.goal,
              items: const [
                DropdownMenuItem(value: 'Giao tiếp', child: Text('Giao tiếp')),
                DropdownMenuItem(value: 'IELTS', child: Text('IELTS')),
                DropdownMenuItem(value: 'Du học', child: Text('Du học')),
                DropdownMenuItem(value: 'Công việc', child: Text('Công việc')),
              ],
              onChanged: (value) =>
              _profile = _profile.copyWith(goal: value ?? _profile.goal),
              decoration: const InputDecoration(labelText: 'Mục tiêu học'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _profile.cefr,
              items: const [
                DropdownMenuItem(value: 'A1', child: Text('A1 - Beginner')),
                DropdownMenuItem(value: 'A2', child: Text('A2 - Elementary')),
                DropdownMenuItem(value: 'B1', child: Text('B1 - Intermediate')),
                DropdownMenuItem(
                    value: 'B2', child: Text('B2 - Upper Intermediate')),
                DropdownMenuItem(value: 'C1', child: Text('C1 - Advanced')),
                DropdownMenuItem(value: 'C2', child: Text('C2 - Mastery')),
              ],
              onChanged: (value) =>
              _profile = _profile.copyWith(cefr: value ?? _profile.cefr),
              decoration: const InputDecoration(labelText: 'Trình độ hiện tại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningHabitsSection(ColorScheme cs, TextTheme tt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thói quen học', style: tt.titleMedium),
            const SizedBox(height: 16),
            Text('Thời lượng học mỗi ngày', style: tt.bodyMedium),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 15, label: Text('15 phút')),
                ButtonSegment(value: 30, label: Text('30 phút')),
                ButtonSegment(value: 45, label: Text('45 phút')),
                ButtonSegment(value: 60, label: Text('60 phút')),
              ],
              selected: {_profile.dailyMinutes ?? 15},
              onSelectionChanged: (selection) {
                setState(() => _profile =
                    _profile.copyWith(dailyMinutes: selection.first));
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Giờ nhắc học', style: tt.bodyMedium),
              trailing: Text(
                _formatTimeOfDay(_profile.reminder),
                style: tt.bodyMedium?.copyWith(color: cs.primary),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _profile.reminder ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _profile = _profile.copyWith(reminder: time));
                }
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Strict correction mặc định', style: tt.bodyMedium),
              value: _profile.strictCorrection ?? false,
              onChanged: (value) => setState(() =>
              _profile = _profile.copyWith(strictCorrection: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(ColorScheme cs, TextTheme tt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _profile.language ?? 'en',
              items: const [
                DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt (vi)')),
                DropdownMenuItem(value: 'en', child: Text('English (en)')),
              ],
              onChanged: (value) =>
              _profile = _profile.copyWith(language: value ?? 'en'),
              decoration: const InputDecoration(labelText: 'Ngôn ngữ'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _profile.timezone ?? 'Asia/Ho_Chi_Minh',
              items: const [
                DropdownMenuItem(
                    value: 'Asia/Ho_Chi_Minh', child: Text('Asia/Ho_Chi_Minh')),
                DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                DropdownMenuItem(value: 'Asia/Tokyo', child: Text('Asia/Tokyo')),
              ],
              onChanged: (value) =>
              _profile = _profile.copyWith(timezone: value ?? 'UTC'),
              decoration: const InputDecoration(labelText: 'Múi giờ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineSection(ColorScheme cs, TextTheme tt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nội dung Offline', style: tt.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.library_books),
              title: const Text('Bộ từ vựng'),
              subtitle: const Text('Đã tải 850MB'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.headphones),
              title: const Text('Audio luyện nghe'),
              subtitle: const Text('Đã tải 1.3GB'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed('OfflineManagePage'),
              child: const Text('Quản lý dung lượng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(ColorScheme cs, TextTheme tt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bảo mật', style: tt.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đổi mật khẩu'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed('ChangePasswordPage'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Xuất dữ liệu (GDPR)'),
              subtitle: const Text('Xuất toàn bộ dữ liệu cá nhân của bạn'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sẽ hỗ trợ trong bản sau')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(ColorScheme cs, TextTheme tt) {
    return Card(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vùng nguy hiểm',
                style: tt.titleMedium?.copyWith(color: cs.onErrorContainer)),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error),
              ),
              onPressed: _showDeleteConfirmation,
              child: const Text('Xóa tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập "DELETE" để xác nhận xóa tài khoản vĩnh viễn'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nhập "DELETE"',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text == 'DELETE'),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yêu cầu xóa đã được gửi')),
      );
    }
  }
}
