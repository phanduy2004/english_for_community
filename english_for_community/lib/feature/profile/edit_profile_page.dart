// lib/feature/profile/edit_profile_page.dart
// Refactor: remove constructor initialProfile; load from UserBloc (and fetch if missing)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/entity/user_entity.dart';
import '../../core/ui/widget/app_card.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';

/// Helper: copyWith for UI editing (non-invasive to domain)
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

  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  UserEntity? _profile; // now sourced from UserBloc
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _firedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firedLoad) return;
    _firedLoad = true;

    final st = context.read<UserBloc>().state;
    if (st.userEntity != null) {
      // seed local editable copy
      _profile = st.userEntity;
    } else {
      // fetch profile once
      context.read<UserBloc>().add(GetProfileEvent());
    }
  }

  Map<String, int>? _toReminderMap(TimeOfDay? t) =>
      t == null ? null : {"hour": t.hour, "minute": t.minute};

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    if (!_formKey.currentState!.validate()) return;

    context.read<UserBloc>().add(UpdateProfileEvent(
      fullName: _profile!.fullName,
      bio: _profile!.bio,
      avatarUrl: _profile!.avatarUrl,
      goal: _profile!.goal,
      cefr: _profile!.cefr,
      dailyMinutes: _profile!.dailyMinutes,
      reminder: _toReminderMap(_profile!.reminder),
      strictCorrection: _profile!.strictCorrection,
      language: _profile!.language,
      timezone: _profile!.timezone,
    ));
  }

  Future<void> _pickImage() async {
    if (_profile == null) return;
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

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, maxWidth: 2048);
    if (pickedFile != null && mounted) {
      setState(() {
        _profile = _profile!.copyWith(avatarUrl: pickedFile.path);
        _isDirty = true;
      });
    }
  }

  Future<void> _confirmExit() async {
    if (!_isDirty) {
      if (mounted) context.pop();
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
          FilledButton(
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

    if (!mounted) return;

    if (result == true) {
      await _saveProfile();
    } else if (result == false) {
      context.pop();
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

    return BlocConsumer<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.status != curr.status || prev.userEntity != curr.userEntity,
      listener: (context, state) {
        // Seed local profile when first loaded
        if (_profile == null && state.userEntity != null) {
          setState(() => _profile = state.userEntity);
        }

        if (state.status == UserStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }

        // Only pop after an edit save (avoid popping after GetProfile success)
        final saved = state.status == UserStatus.successfullyEditedProfile ||
            (state.status == UserStatus.success && _isDirty);
        if (saved) {
          _isDirty = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu thay đổi')),
          );
          context.pop(true);
        }
      },
      builder: (context, state) {
        if (_profile == null && state.userEntity != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _profile = state.userEntity);
          });
        }
        final isSaving = state.status == UserStatus.loading;

        return WillPopScope(
          onWillPop: () async {
            await _confirmExit();
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: cs.background,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: cs.onBackground),
                onPressed: _confirmExit,
              ),
              title: Text('Chỉnh sửa hồ sơ',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500)),
              actions: [
                if (isSaving)
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
                    onPressed: _profile != null && _isDirty && (_formKey.currentState?.validate() ?? false)
                        ? _saveProfile
                        : null,
                    child: const Text('Lưu'),
                  ),
              ],
              centerTitle: true,
            ),
            body: _profile == null
                ? const Center(child: CircularProgressIndicator())
                : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    _buildSecuritySection(cs, tt),
                    const SizedBox(height: 24),
                    _buildDangerZone(cs, tt),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(ColorScheme cs) {
    final profile = _profile!;
    ImageProvider? provider;
    final url = profile.avatarUrl;

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
            tooltip: 'Đổi ảnh đại diện',
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(ColorScheme cs, TextTheme tt) {
    final profile = _profile!;
    // allowed lists
    const goals = ['Giao tiếp', 'IELTS', 'Du học', 'Công việc'];
    const cefrs = ['A1','A2','B1','B2','C1','C2'];

    // ✅ sanitize: nếu rỗng/không thuộc items -> để null
    final String? safeGoal = (profile.goal != null && profile.goal!.isNotEmpty && goals.contains(profile.goal))
        ? profile.goal
        : null;
    final String? safeCefr = (profile.cefr != null && cefrs.contains(profile.cefr))
        ? profile.cefr
        : null;

    return AppCard(
      variant: AppCardVariant.filled,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: profile.fullName,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
              onChanged: (value) => setState(() => _profile = profile.copyWith(fullName: value.trim())),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: profile.email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Vui lòng nhập email';
                if (!v.contains('@')) return 'Email không hợp lệ';
                return null;
              },
              onChanged: (value) => setState(() => _profile = profile.copyWith(email: value.trim())),
            ),
            const SizedBox(height: 16),

            // ✅ GOAL
            DropdownButtonFormField<String>(
              value: safeGoal, // quan trọng
              hint: const Text('Chọn mục tiêu'),
              items: const [
                DropdownMenuItem(value: 'Giao tiếp', child: Text('Giao tiếp')),
                DropdownMenuItem(value: 'IELTS', child: Text('IELTS')),
                DropdownMenuItem(value: 'Du học', child: Text('Du học')),
                DropdownMenuItem(value: 'Công việc', child: Text('Công việc')),
              ],
              onChanged: (value) => setState(() => _profile = profile.copyWith(goal: value)),
              decoration: const InputDecoration(labelText: 'Mục tiêu học'),
            ),
            const SizedBox(height: 16),

            // ✅ CEFR
            DropdownButtonFormField<String>(
              value: safeCefr, // quan trọng
              hint: const Text('Chọn trình độ'),
              items: const [
                DropdownMenuItem(value: 'A1', child: Text('A1 - Beginner')),
                DropdownMenuItem(value: 'A2', child: Text('A2 - Elementary')),
                DropdownMenuItem(value: 'B1', child: Text('B1 - Intermediate')),
                DropdownMenuItem(value: 'B2', child: Text('B2 - Upper Intermediate')),
                DropdownMenuItem(value: 'C1', child: Text('C1 - Advanced')),
                DropdownMenuItem(value: 'C2', child: Text('C2 - Mastery')),
              ],
              onChanged: (value) => setState(() => _profile = profile.copyWith(cefr: value)),
              decoration: const InputDecoration(labelText: 'Trình độ hiện tại'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLearningHabitsSection(ColorScheme cs, TextTheme tt) {
    final profile = _profile!;
    final allowed = const [15, 30, 45, 60];
    final selectedMinutes = allowed.contains(profile.dailyMinutes) ? profile.dailyMinutes! : 15;

    return AppCard(
      variant: AppCardVariant.filled,
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
              selected: {selectedMinutes}, // ✅ an toàn
              onSelectionChanged: (selection) {
                setState(() => _profile = profile.copyWith(dailyMinutes: selection.first));
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Giờ nhắc học', style: tt.bodyMedium),
              trailing: Text(
                _formatTimeOfDay(profile.reminder),
                style: tt.bodyMedium?.copyWith(color: cs.primary),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: profile.reminder ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _profile = profile.copyWith(reminder: time));
                }
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Strict correction mặc định', style: tt.bodyMedium),
              value: profile.strictCorrection ?? false,
              onChanged: (value) => setState(() => _profile = profile.copyWith(strictCorrection: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(ColorScheme cs, TextTheme tt) {
    final profile = _profile!;
    return AppCard(
      variant: AppCardVariant.filled,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: profile.language ?? 'en',
              items: const [
                DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt (vi)')),
                DropdownMenuItem(value: 'en', child: Text('English (en)')),
              ],
              onChanged: (value) => _profile = profile.copyWith(language: value ?? 'en'),
              decoration: const InputDecoration(labelText: 'Ngôn ngữ'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: profile.timezone ?? 'Asia/Ho_Chi_Minh',
              items: const [
                DropdownMenuItem(value: 'Asia/Ho_Chi_Minh', child: Text('Asia/Ho_Chi_Minh')),
                DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                DropdownMenuItem(value: 'Asia/Tokyo', child: Text('Asia/Tokyo')),
              ],
              onChanged: (value) => _profile = profile.copyWith(timezone: value ?? 'UTC'),
              decoration: const InputDecoration(labelText: 'Múi giờ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(ColorScheme cs, TextTheme tt) {
    return AppCard(
      variant: AppCardVariant.filled,
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
    return AppCard(
      variant: AppCardVariant.filled,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vùng nguy hiểm', style: tt.titleMedium?.copyWith(color: cs.onErrorContainer)),
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
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text == 'DELETE'),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!mounted || confirmed != true) return;

    context.read<UserBloc>().add(DeleteAccountEvent());
  }
}
