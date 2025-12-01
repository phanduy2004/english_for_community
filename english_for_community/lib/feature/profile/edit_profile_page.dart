import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/entity/user_entity.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';

// Helper để copyWith (Giữ nguyên extension cũ của bạn nếu có hoặc dùng cái này)
extension UserEntityCopyWith on UserEntity {
  UserEntity copyWith({
    String? fullName, String? username, String? phone,
    DateTime? dateOfBirth, String? bio, String? avatarUrl
    // Các field khác giữ nguyên từ entity gốc...
  }) {
    return UserEntity(
        id: id, email: email,
        fullName: fullName ?? this.fullName,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        bio: bio ?? this.bio,
        goal: goal, cefr: cefr, dailyMinutes: dailyMinutes, reminder: reminder,
        strictCorrection: strictCorrection, language: language, timezone: timezone, dailyActivityGoal: dailyActivityGoal, dailyActivityProgress: dailyActivityProgress, currentStreak: currentStreak, totalPoints: totalPoints, level: level
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
  final _formKey = GlobalKey<FormState>();
  UserEntity? _profile;
  File? _pickedImageFile;
  final TextEditingController _dobController = TextEditingController();
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo data
    final user = context.read<UserBloc>().state.userEntity;
    if (user != null) {
      _profile = user;
      if (user.dateOfBirth != null) {
        _dobController.text = DateFormat('dd/MM/yyyy').format(user.dateOfBirth!);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (file != null) {
      setState(() {
        _pickedImageFile = File(file.path);
        _isDirty = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _profile?.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _profile = _profile!.copyWith(dateOfBirth: picked);
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
        _isDirty = true;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _profile == null) return;

    // Dispatch Update Event với dữ liệu đã clean
    // Lưu ý: Cần truyền lại các field Setting cũ (goal, dailyMinutes) để không bị null
    // Hoặc UserBloc của bạn đã handle việc merge. Ở đây mình giả định Event cần full field.
    final old = context.read<UserBloc>().state.userEntity!;

    context.read<UserBloc>().add(UpdateProfileEvent(
      fullName: _profile!.fullName,
      username: _profile!.username,
      phone: _profile!.phone,
      bio: _profile!.bio,
      dateOfBirth: _profile!.dateOfBirth,
      avatarFile: _pickedImageFile,

      // Giữ nguyên settings (vì trang này ko sửa settings nữa)
      goal: old.goal,
      cefr: old.cefr,
      dailyMinutes: old.dailyMinutes,
      reminder: old.reminder == null ? null : {"hour": old.reminder!.hour, "minute": old.reminder!.minute},
      strictCorrection: old.strictCorrection,
      language: old.language,
      timezone: old.timezone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);

    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.success && _isDirty) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == UserStatus.loading;

        return Scaffold(
          backgroundColor: bgPage,
          appBar: AppBar(
            backgroundColor: bgPage,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: textMain),
              onPressed: () => context.pop(),
            ),
            title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: (_isDirty && !isLoading) ? _save : null,
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Lưu', style: TextStyle(fontWeight: FontWeight.w600, color: _isDirty ? Theme.of(context).primaryColor : Colors.grey)),
              )
            ],
          ),
          body: _profile == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            onChanged: () => setState(() => _isDirty = true),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // 1. AVATAR SECTION
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: _pickedImageFile != null
                                ? FileImage(_pickedImageFile!)
                                : (_profile!.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(_profile!.avatarUrl!) as ImageProvider
                                : const AssetImage('assets/avatar.png'),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: textMain, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 2. FORM SECTION
                const _SectionLabel('THÔNG TIN CÁ NHÂN'),
                _ShadcnInputCard(
                  children: [
                    _MinimalInput(
                      label: 'Họ và tên',
                      initialValue: _profile!.fullName,
                      onChanged: (v) => _profile = _profile!.copyWith(fullName: v),
                      validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const _Divider(),
                    _MinimalInput(
                      label: 'Username',
                      initialValue: _profile!.username,
                      prefixText: '@',
                      onChanged: (v) => _profile = _profile!.copyWith(username: v),
                    ),
                    const _Divider(),
                    _MinimalInput(
                      label: 'Tiểu sử',
                      initialValue: _profile!.bio,
                      maxLines: 3,
                      hint: 'Viết vài dòng về bạn...',
                      onChanged: (v) => _profile = _profile!.copyWith(bio: v),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const _SectionLabel('THÔNG TIN LIÊN HỆ'),
                _ShadcnInputCard(
                  children: [
                    _MinimalInput(
                      label: 'Số điện thoại',
                      initialValue: _profile!.phone,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => _profile = _profile!.copyWith(phone: v),
                    ),
                    const _Divider(),
                    _MinimalInput(
                      label: 'Ngày sinh',
                      controller: _dobController,
                      readOnly: true,
                      hint: 'DD/MM/YYYY',
                      suffixIcon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- WIDGETS TRANG TRÍ (Clean & Minimal) ---

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF71717A))),
    );
  }
}

class _ShadcnInputCard extends StatelessWidget {
  final List<Widget> children;
  const _ShadcnInputCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5), indent: 16);
}

class _MinimalInput extends StatelessWidget {
  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? hint;

  const _MinimalInput({
    required this.label,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.keyboardType,
    this.prefixText,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF09090B))),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: initialValue,
              controller: controller,
              onChanged: onChanged,
              validator: validator,
              maxLines: maxLines,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 14, color: Color(0xFF09090B)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixText: prefixText,
                prefixStyle: const TextStyle(color: Color(0xFF71717A)),
                suffixIcon: suffixIcon != null
                    ? Icon(suffixIcon, size: 18, color: const Color(0xFFA1A1AA))
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}