import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Local UI state (có thể map sang state mgmt của bạn)
  bool _dailyReminder = true;
  bool _correctionEnabled = true;
  String _reminderTime = '07:30';
  String _language = 'Tiếng Việt';
  String _timezone = 'GMT+7 (Asia/Ho_Chi_Minh)';
  int _dailyMinutes = 30;

  // Điều hướng (đổi sang route thực tế của bạn)
  void _goEditProfile() => context.pushNamed('EditProfilePage');
  void _goDailyMinutes() => context.pushNamed('DailyMinutesPage');
  void _goReminderTime() => context.pushNamed('ReminderTimePage');
  void _goLanguage() => context.pushNamed('LanguagePickerPage');
  void _goTimezone() => context.pushNamed('TimezonePickerPage');
  void _goTheme() => context.pushNamed('ThemeSettingPage');
  void _goOfflineManager() => context.pushNamed('OfflineManagerPage');
  void _goChangePassword() => context.pushNamed('ChangePasswordPage');
  void _goExportData() => context.pushNamed('ExportDataPage');
  void _goDeleteAccount() => context.pushNamed('DeleteAccountPage');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text('Hồ sơ & Cài đặt',
            style: txt.headlineMedium?.copyWith(fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: cs.onBackground),
            onPressed: _goEditProfile,
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Header gradient card
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.secondary],
                    begin: const Alignment(1, -1),
                    end: const Alignment(-1, 1),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1580008006944-bb3b7e890d5d?auto=format&fit=crop&w=256&q=80',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name + email + chips
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nguyễn Minh Anh',
                                style: txt.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                )),
                            Text('minh.anh@email.com',
                                style: txt.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(.9),
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                _ChipPill(label: 'CEFR B2', fg: Colors.white),
                                _ChipPill(label: 'Goal: Giao tiếp', fg: Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _goEditProfile,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: cs.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Chỉnh sửa', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),

              // Cài đặt học tập
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Cài đặt học tập',
                children: [
                  _SettingRow(
                    title: 'Thời lượng học mỗi ngày',
                    subtitle: '$_dailyMinutes phút',
                    onTap: _goDailyMinutes,
                  ),
                  _SettingRow(
                    title: 'Nhắc học hằng ngày',
                    trailing: Switch(
                      value: _dailyReminder,
                      onChanged: (v) => setState(() => _dailyReminder = v),
                    ),
                  ),
                  if (_dailyReminder)
                    _SettingRow(
                      title: 'Giờ nhắc học',
                      subtitle: _reminderTime,
                      onTap: _goReminderTime,
                    ),
                  _SettingRow(
                    title: 'Auto correction mặc định',
                    subtitle: 'Áp dụng cho Speaking & Writing',
                    trailing: Switch(
                      value: _correctionEnabled,
                      onChanged: (v) => setState(() => _correctionEnabled = v),
                    ),
                  ),
                ],
              ),

              // Giao diện & Ngôn ngữ
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Giao diện & Ngôn ngữ',
                children: [
                  _SettingRow(
                    title: 'Ngôn ngữ giao diện',
                    subtitle: _language,
                    onTap: _goLanguage,
                  ),
                  _SettingRow(
                    title: 'Múi giờ',
                    subtitle: _timezone,
                    onTap: _goTimezone,
                  ),
                  _SettingRow(
                    title: 'Chủ đề',
                    subtitle: 'Theo hệ thống',
                    onTap: _goTheme,
                  ),
                ],
              ),

              // Nội dung Offline
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Nội dung Offline',
                trailingRight: _PillValue(label: '2.1 GB'),
                children: [
                  _SettingRow(
                    title: 'Bộ từ vựng cơ bản',
                    subtitle: 'Đã tải • 850 MB',
                    leadingIcon: Icons.download_done_rounded,
                    leadingColor: Colors.green,
                    onTap: _goOfflineManager,
                  ),
                  _SettingRow(
                    title: 'Audio Pack – Everyday',
                    subtitle: 'Chưa tải • 420 MB',
                    leadingIcon: Icons.download_rounded,
                    leadingColor: cs.primary,
                    onTap: _goOfflineManager,
                  ),
                ],
              ),

              // Bảo mật & Tài khoản
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Bảo mật & Tài khoản',
                children: [
                  _SettingRow(
                    title: 'Đổi mật khẩu',
                    subtitle: 'Cập nhật lần cuối: 2 tháng trước',
                    onTap: _goChangePassword,
                  ),
                  _SettingRow(
                    title: 'Xuất dữ liệu',
                    subtitle: 'Nhận link tải qua email',
                    onTap: _goExportData,
                  ),
                  _SettingRow(
                    title: 'Xoá tài khoản',
                    subtitle: 'Thao tác này không thể hoàn tác',
                    titleColor: Theme.of(context).colorScheme.error,
                    leadingIcon: Icons.delete_forever_rounded,
                    leadingColor: Theme.of(context).colorScheme.error,
                    onTap: _goDeleteAccount,
                  ),
                ],
              ),

              // About
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Phiên bản ứng dụng: 2.4.1',
                          style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('© 2024 Language Learning App',
                          style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Reusable UI ----------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.children = const [],
    this.trailingRight,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailingRight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (trailingRight != null) trailingRight!,
                ],
              ),
            ),
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              children[i],
            ]
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.leadingIcon,
    this.leadingColor,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              if (leadingIcon != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Icon(leadingIcon, size: 20, color: leadingColor ?? cs.onSurface),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: txt.bodyMedium?.copyWith(
                          color: titleColor ?? cs.onSurface,
                        )),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                            style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.label, this.fg = Colors.white});
  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(color: Colors.white.withOpacity(.25), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _PillValue extends StatelessWidget {
  const _PillValue({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(label,
          style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
