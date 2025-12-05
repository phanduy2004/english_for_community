import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng Clipboard
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/entity/user_entity.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';

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

  // Controllers
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGender;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserBloc>().state.userEntity;
    if (user != null) {
      _profile = user;
      _fullNameController.text = user.fullName;
      _usernameController.text = user.username;
      _bioController.text = user.bio ?? '';
      _phoneController.text = user.phone ?? '';
      _selectedGender = user.gender; // Giả sử UserEntity đã có field gender như bạn yêu cầu

      if (user.dateOfBirth != null) {
        _dobController.text = DateFormat('dd/MM/yyyy').format(user.dateOfBirth!);
      }
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
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

    final old = context.read<UserBloc>().state.userEntity!;

    // Dispatch Update Event
    context.read<UserBloc>().add(UpdateProfileEvent(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      dateOfBirth: _profile!.dateOfBirth,
      avatarFile: _pickedImageFile,

      // 🔥 Thêm Gender vào Event (Bạn cần update UpdateProfileEvent để nhận field này)
      gender: _selectedGender,

      // Giữ nguyên settings cũ
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
    const textMuted = Color(0xFF71717A);

    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.success && _isDirty) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công')));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == UserStatus.loading;

        return Scaffold(
          backgroundColor: bgPage,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: textMain),
              onPressed: () => context.pop(),
            ),
            title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFE4E4E7), height: 1),
            ),
            actions: [
              TextButton(
                onPressed: (_isDirty && !isLoading) ? _save : null,
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700, color: _isDirty ? Theme.of(context).primaryColor : textMuted)),
              )
            ],
          ),
          body: _profile == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // --- 1. AVATAR SECTION ---
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF4F4F5),
                          border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: _pickedImageFile != null
                                ? FileImage(_pickedImageFile!)
                                : (_profile!.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(_profile!.avatarUrl!) as ImageProvider
                                : const AssetImage('assets/avatar.png'), // Placeholder
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE4E4E7)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.camera_alt_outlined, color: textMain, size: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(_profile!.email, style: const TextStyle(fontSize: 13, color: textMuted)),
                ),
                const SizedBox(height: 32),

                // --- 2. PUBLIC INFO ---
                const _SectionHeader('THÔNG TIN CÔNG KHAI'),
                _ShadcnGroup(
                  children: [
                    _ShadcnInput(
                      icon: Icons.person_outline,
                      label: 'Họ và tên',
                      controller: _fullNameController,
                      onChanged: (_) => _markDirty(),
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const _Divider(),
                    _ShadcnInput(
                      icon: Icons.alternate_email,
                      label: 'Username',
                      controller: _usernameController,
                      prefixText: '@',
                      onChanged: (_) => _markDirty(),
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập username' : null,
                    ),
                    const _Divider(),
                    _ShadcnInput(
                      icon: Icons.edit_note,
                      label: 'Tiểu sử',
                      controller: _bioController,
                      hint: 'Giới thiệu ngắn về bạn...',
                      maxLines: 3,
                      onChanged: (_) => _markDirty(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 3. PRIVATE DETAILS ---
                const _SectionHeader('CHI TIẾT CÁ NHÂN'),
                _ShadcnGroup(
                  children: [
                    _ShadcnDropdown(
                      icon: Icons.transgender_outlined,
                      label: 'Giới tính',
                      value: _selectedGender,
                      items: const ['Male', 'Female', 'Other'],
                      onChanged: (val) {
                        setState(() {
                          _selectedGender = val;
                          _isDirty = true;
                        });
                      },
                    ),
                    const _Divider(),
                    _ShadcnInput(
                      icon: Icons.cake_outlined,
                      label: 'Ngày sinh',
                      controller: _dobController,
                      readOnly: true,
                      hint: 'DD/MM/YYYY',
                      onTap: _pickDate,
                      suffixIcon: Icons.calendar_today_rounded,
                    ),
                    const _Divider(),
                    _ShadcnInput(
                      icon: Icons.phone_outlined,
                      label: 'Số điện thoại',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      hint: 'Thêm số điện thoại',
                      onChanged: (_) => _markDirty(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 4. SYSTEM INFO (READ ONLY) ---
                const _SectionHeader('THÔNG TIN HỆ THỐNG'),
                _ShadcnGroup(
                  children: [
                    _ShadcnInput(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      initialValue: _profile!.email,
                      readOnly: true,
                      enabled: false, // Gray out
                      suffixIcon: _profile!.isVerified ? Icons.verified : Icons.warning_amber_rounded,
                      suffixColor: _profile!.isVerified ? Colors.blue : Colors.orange,
                    ),
                    const _Divider(),
                    _ShadcnInput(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Vai trò',
                      initialValue: _profile!.role.toUpperCase(),
                      readOnly: true,
                      enabled: false,
                    ),
                    const _Divider(),
                    _ShadcnInput(
                      icon: Icons.key,
                      label: 'User ID',
                      initialValue: _profile!.id,
                      readOnly: true,
                      enabled: false,
                      isCopyable: true,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// ✨ SHADCN / FOURI INSPIRED WIDGETS
// -----------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF71717A), letterSpacing: 0.5),
      ),
    );
  }
}

class _ShadcnGroup extends StatelessWidget {
  final List<Widget> children;
  const _ShadcnGroup({required this.children});
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
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5), indent: 48); // indent để icon không bị cắt
}

class _ShadcnInput extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? prefixText;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final Color? suffixColor;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool isCopyable;

  const _ShadcnInput({
    required this.icon,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.prefixText,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
    this.suffixColor,
    this.onTap,
    this.onChanged,
    this.validator,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            // Icon bên trái
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
              child: Icon(icon, size: 20, color: const Color(0xFF71717A)),
            ),
            const SizedBox(width: 12),

            // Label và Input field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Label nhỏ phía trên (giống Material Design nhưng tinh tế hơn)
                  // Hoặc Label bên trái?
                  // Ở đây tôi chọn style: Label là placeholder hoặc label nhỏ nếu có value
                  TextFormField(
                    controller: controller,
                    initialValue: initialValue,
                    readOnly: readOnly,
                    enabled: enabled,
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                    onTap: onTap,
                    onChanged: onChanged,
                    validator: validator,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: enabled ? const Color(0xFF09090B) : const Color(0xFF71717A)
                    ),
                    decoration: InputDecoration(
                      labelText: label, // Label sẽ trôi lên trên khi nhập
                      labelStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
                      floatingLabelStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w600),
                      hintText: hint,
                      hintStyle: const TextStyle(color: Color(0xFFD4D4D8)),
                      prefixText: prefixText,
                      prefixStyle: const TextStyle(color: Color(0xFF71717A)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      alignLabelWithHint: maxLines > 1,
                    ),
                  ),
                ],
              ),
            ),

            // Suffix Icon (Copy hoặc Custom Icon)
            if (isCopyable)
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Color(0xFF71717A)),
                onPressed: () {
                  final text = controller?.text ?? initialValue ?? '';
                  if (text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép'), duration: Duration(seconds: 1)));
                  }
                },
              )
            else if (suffixIcon != null)
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
                child: Icon(suffixIcon, size: 18, color: suffixColor ?? const Color(0xFFA1A1AA)),
              )
          ],
        ),
      ),
    );
  }
}

class _ShadcnDropdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _ShadcnDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF71717A)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: (value != null && items.contains(value)) ? value : null,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFFA1A1AA)),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF09090B)),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
                floatingLabelStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w600),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}