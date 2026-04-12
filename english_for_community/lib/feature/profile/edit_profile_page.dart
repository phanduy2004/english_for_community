import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/entity/user_entity.dart';      
import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/auth/bloc/user_state.dart';
import '../../core/locale/l10n_context.dart';

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
      _selectedGender = user.gender;

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

    context.read<UserBloc>().add(UpdateProfileEvent(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      dateOfBirth: _profile!.dateOfBirth,
      avatarFile: _pickedImageFile,
      gender: _selectedGender,

      // Giữ nguyên các settings cũ
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
    // Shadcn Zinc Colors
    const bgPage = Color(0xFFF9FAFB); // Zinc 50
    const textMain = Color(0xFF09090B); // Zinc 950
    final primaryColor = Theme.of(context).primaryColor;

    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.success && _isDirty) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.profileUpdatedSuccess)));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == UserStatus.loading;
        final t = context.l10n;

        return Scaffold(
          backgroundColor: bgPage,
          appBar: AppBar(
            backgroundColor: bgPage,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textMain),
              onPressed: () => context.pop(),
            ),
            title: Text(
                t.editProfileTitle,
                style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 17)
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: (_isDirty && !isLoading) ? _save : null,
                  style: TextButton.styleFrom(
                    backgroundColor: (_isDirty && !isLoading) ? primaryColor : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                    t.saveChanges,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: (_isDirty && !isLoading) ? Colors.white : const Color(0xFF71717A),
                    ),
                  ),
                ),
              )
            ],
          ),
          body: _profile == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // --- 1. AVATAR SECTION ---
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white, // Nền trắng đơn giản
                            ),
                            child: Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE4E4E7), width: 1), // Zinc 200 Border
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
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: textMain,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- 2. PUBLIC INFO (Blue Accents) ---
                _SectionHeader(t.sectionPublicInfo),
                _ColorfulGroup(
                  children: [
                    _ColorfulInput(
                      icon: Icons.person_rounded,
                      iconColor: Colors.blue,
                      label: t.labelFullName,
                      controller: _fullNameController,
                      onChanged: (_) => _markDirty(),
                      validator: (v) => v!.isEmpty ? t.fieldRequired : null,
                    ),
                    const _Divider(),
                    _ColorfulInput(
                      icon: Icons.alternate_email_rounded,
                      iconColor: Colors.indigo,
                      label: t.labelUsername,
                      controller: _usernameController,
                      prefixText: '@',
                      onChanged: (_) => _markDirty(),
                      validator: (v) => v!.isEmpty ? t.fieldRequired : null,
                    ),
                    const _Divider(),
                    _ColorfulInput(
                      icon: Icons.edit_note_rounded,
                      iconColor: Colors.cyan,
                      label: t.labelBio,
                      controller: _bioController,
                      hint: t.hintBio,
                      maxLines: 3,
                      onChanged: (_) => _markDirty(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 3. PRIVATE DETAILS (Warm Accents) ---
                _SectionHeader(t.sectionPrivateDetails),
                _ColorfulGroup(
                  children: [
                    _ColorfulDropdown(
                      icon: Icons.wc_rounded,
                      iconColor: Colors.pink,
                      label: t.labelGender,
                      value: _selectedGender,
                      items: [
                        ('Male', t.genderMale),
                        ('Female', t.genderFemale),
                        ('Other', t.genderOther),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedGender = val;
                          _isDirty = true;
                        });
                      },
                    ),
                    const _Divider(),
                    _ColorfulInput(
                      icon: Icons.cake_rounded,
                      iconColor: Colors.orange,
                      label: t.labelBirthday,
                      controller: _dobController,
                      readOnly: true,
                      hint: t.hintSelectDate,
                      onTap: _pickDate,
                      suffixIcon: Icons.calendar_today_rounded,
                    ),
                    const _Divider(),
                    _ColorfulInput(
                      icon: Icons.phone_rounded,
                      iconColor: Colors.green,
                      label: t.labelPhone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      hint: t.hintPhoneShort,
                      onChanged: (_) => _markDirty(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 4. SYSTEM INFO (Neutral Accents) ---
                _SectionHeader(t.sectionSystemInfo),
                _ColorfulGroup(
                  children: [
                    _ColorfulInput(
                      icon: Icons.email_rounded,
                      iconColor: Colors.teal,
                      label: t.labelEmail,
                      initialValue: _profile!.email,
                      readOnly: true,
                      enabled: false,
                      suffixIcon: _profile!.isVerified ? Icons.verified_rounded : Icons.info_outline,
                      suffixColor: _profile!.isVerified ? Colors.blue : Colors.orange,
                    ),
                    const _Divider(),
                    _ColorfulInput(
                      icon: Icons.security_rounded,
                      iconColor: Colors.blueGrey,
                      label: t.labelRole,
                      initialValue: _profile!.role.toUpperCase(),
                      readOnly: true,
                      enabled: false,
                    ),
                    const _Divider(),
                    _ColorfulInput(
                      icon: Icons.fingerprint_rounded,
                      iconColor: Colors.grey,
                      label: t.labelUserId,
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
// 🎨 COLORFUL & CLEAN COMPONENTS (SHADCN COLORS)
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
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF71717A), // Zinc 500
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ColorfulGroup extends StatelessWidget {
  final List<Widget> children;
  const _ColorfulGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)), // Zinc 200 Border
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5), indent: 52); // Zinc 100
}

// ✨ Icon với nền màu Pastel (Điểm nhấn màu sắc)
class _ColorIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ColorIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Nền màu rất nhạt
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _ColorfulInput extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
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

  const _ColorfulInput({
    required this.icon,
    required this.iconColor,
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
    // Màu chữ chuẩn Shadcn
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const textPlaceholder = Color(0xFFA1A1AA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            // Icon
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 4 : 0),
              child: _ColorIcon(icon, iconColor),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Layout: Label bên trái, Input bên phải (Right Aligned)
                  if (maxLines == 1)
                    Row(
                      children: [
                        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMain)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            initialValue: initialValue,
                            readOnly: readOnly,
                            enabled: enabled,
                            textAlign: TextAlign.right, // Đẩy input sang phải cho gọn
                            style: TextStyle(fontSize: 14, color: enabled ? const Color(0xFF52525B) : textMuted),
                            decoration: InputDecoration.collapsed(
                              hintText: hint,
                              hintStyle: const TextStyle(color: textPlaceholder, fontWeight: FontWeight.normal),
                            ),
                            onChanged: onChanged,
                            validator: validator,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Layout: Label trên, Input dưới (cho Bio nhiều dòng)
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMain)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller,
                      initialValue: initialValue,
                      readOnly: readOnly,
                      enabled: enabled,
                      maxLines: maxLines,
                      style: TextStyle(fontSize: 14, color: enabled ? const Color(0xFF52525B) : textMuted),
                      decoration: InputDecoration.collapsed(
                        hintText: hint,
                        hintStyle: const TextStyle(color: textPlaceholder),
                      ),
                      onChanged: onChanged,
                      validator: validator,
                    ),
                  ]
                ],
              ),
            ),

            // Suffix
            if (isCopyable)
              GestureDetector(
                onTap: () {
                  final text = controller?.text ?? initialValue ?? '';
                  if (text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.copiedToClipboard), duration: const Duration(seconds: 1)));
                  }
                },
                child: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.copy_rounded, size: 16, color: textPlaceholder)),
              )
            else if (suffixIcon != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(suffixIcon, size: 18, color: suffixColor ?? textPlaceholder),
              )
          ],
        ),
      ),
    );
  }
}

class _ColorfulDropdown extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  /// API values (e.g. Male/Female/Other) with localized labels.
  final List<(String, String)> items;
  final ValueChanged<String?> onChanged;

  const _ColorfulDropdown({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textPlaceholder = Color(0xFFA1A1AA);
    final selectHint = context.l10n.selectPlaceholder;
    final values = items.map((e) => e.$1).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _ColorIcon(icon, iconColor),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMain)),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (value != null && values.contains(value)) ? value : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textPlaceholder),
              style: const TextStyle(fontSize: 14, color: Color(0xFF52525B), fontWeight: FontWeight.w500),
              hint: Text(selectHint, style: const TextStyle(color: textPlaceholder, fontSize: 14)),
              items: items.map((e) => DropdownMenuItem<String>(value: e.$1, child: Text(e.$2))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}