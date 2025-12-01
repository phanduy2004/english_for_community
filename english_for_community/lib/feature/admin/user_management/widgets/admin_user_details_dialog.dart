import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/entity/user_entity.dart';
import '../../../../core/get_it/get_it.dart';
import '../../../../core/repository/user_repository.dart';

class AdminUserDetailsDialog extends StatefulWidget {
  final String userId;

  const AdminUserDetailsDialog({super.key, required this.userId});

  @override
  State<AdminUserDetailsDialog> createState() => _AdminUserDetailsDialogState();
}

class _AdminUserDetailsDialogState extends State<AdminUserDetailsDialog> {
  late Future<dynamic> _userFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0; // 0: Stats, 1: Personal Info

  // Colors Palette
  static const Color textMain = Color(0xFF09090B);
  static const Color textMuted = Color(0xFF71717A);
  static const Color borderCol = Color(0xFFE4E4E7);
  static const Color bgSubtle = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _userFuture = getIt<UserRepository>().getUserById(widget.userId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Hàm chuyển đổi giữa 2 trang
  void _togglePage() {
    if (_currentPage == 0) {
      _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
        child: Column(
          children: [
            // --- HEADER DIALOG (Fixed) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    _currentPage == 0 ? 'Hồ sơ học tập' : 'Thông tin cá nhân',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain),
                  ),
                  const Spacer(),
                  // Nút chuyển đổi nhanh
                  TextButton(
                    onPressed: _togglePage,
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    child: Text(_currentPage == 0 ? 'Xem Info >' : '< Xem Stats'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: borderCol),

            // --- BODY (PAGE VIEW) ---
            Expanded(
              child: FutureBuilder(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  return snapshot.data!.fold(
                        (failure) => Center(child: Text(failure.message)),
                        (UserEntity user) => Column(
                      children: [
                        // 1. IDENTITY HEADER (Luôn hiển thị và có thể click để trượt)
                        _buildIdentityHeader(user),
                        const Divider(height: 1, color: borderCol),

                        // 2. SLIDING CONTENT
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (idx) => setState(() => _currentPage = idx),
                            children: [
                              _buildLearningStats(user), // Page 0
                              _buildPersonalInfo(user),  // Page 1
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PHẦN 1: HEADER ĐỊNH DANH (Click để trượt) ---
  Widget _buildIdentityHeader(UserEntity user) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _togglePage, // 🔥 Nhấn vào đây sẽ trượt trang
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _buildAvatar(user),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)),
                        const SizedBox(width: 8),
                        if (_currentPage == 0)
                          const Icon(Icons.info_outline, size: 16, color: Colors.blue) // Gợi ý nhấn
                        else
                          const Icon(Icons.bar_chart, size: 16, color: Colors.blue)
                      ],
                    ),
                    Text(user.email, style: const TextStyle(fontSize: 13, color: textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusBadge(label: user.isOnline ? 'Online' : 'Offline', color: user.isOnline ? Colors.green : Colors.grey),
                        const SizedBox(width: 8),
                        _StatusBadge(label: 'Level ${user.level ?? 1}', color: Colors.blue),
                        _StatusBadge(label: '${user.totalPoints ?? 1} Exp', color: Colors.amber[700]!),

                      ],
                    )
                  ],
                ),
              ),
              Icon(
                _currentPage == 0 ? Icons.chevron_right : Icons.chevron_left,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PAGE 0: THỐNG KÊ HỌC TẬP (Cũ) ---
  Widget _buildLearningStats(UserEntity user) {
    final summary = user.progressSummary;
    final stats = summary?.statsGrid;
    final studyTime = summary?.studyTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HIGHLIGHTS
          const Text('TỔNG QUAN HỌC TẬP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Tổng thời gian', value: _fmtMinutes(studyTime?.totalMinutesInRange ?? 0), icon: Icons.history_toggle_off, color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Mục tiêu ngày', value: '${studyTime?.goalMinutes ?? 30} phút', icon: Icons.flag_circle, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),

          // STATS GRID
          const Text('CHỈ SỐ CHI TIẾT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 12, mainAxisSpacing: 12,
            children: [
              _StatSmallItem(icon: Icons.library_books, label: 'Bài học xong', value: '${stats?.lessonsCompleted ?? 0}', color: Colors.indigo),
              _StatSmallItem(icon: Icons.translate, label: 'Từ vựng', value: '${stats?.vocabLearned ?? 0}', color: Colors.purple),
              _StatSmallItem(icon: Icons.headphones, label: 'Listening Acc', value: '${stats?.dictationAccuracy ?? 0}%', color: Colors.blue),
              _StatSmallItem(icon: Icons.menu_book, label: 'Reading Acc', value: '${stats?.readingAccuracy ?? 0}%', color: Colors.cyan),
              _StatSmallItem(icon: Icons.mic, label: 'Speaking Acc', value: '${stats?.speakingAccuracy ?? 0}%', color: Colors.red),
              _StatSmallItem(icon: Icons.edit, label: 'Writing Avg', value: '${stats?.avgWritingScore ?? 0}/10', color: Colors.orange),
            ],
          ),
          const SizedBox(height: 24),

          // CHART
          const Text('HOẠT ĐỘNG 7 NGÀY QUA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Container(
            height: 120, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(color: bgSubtle, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderCol)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: (summary?.weeklyChart.minutes ?? []).asMap().entries.map((entry) {
                final h = (entry.value / ((summary?.weeklyChart.minutes.reduce((a, b) => a > b ? a : b) ?? 1))) * 60;
                return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(width: 20, height: h == 0 ? 4 : h, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Text(summary?.weeklyChart.labels[entry.key] ?? '', style: const TextStyle(fontSize: 10, color: textMuted)),
                ]);
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  // --- PAGE 1: THÔNG TIN CÁ NHÂN (Mới - Từ UserProfileDialog) ---
  Widget _buildPersonalInfo(UserEntity user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const Text('GIỚI THIỆU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bgSubtle, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderCol)),
              child: Text(user.bio!, style: const TextStyle(fontSize: 14, color: textMain, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 24),
          ],

          // Thông tin chi tiết
          const Text('THÔNG TIN CHI TIẾT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol)),
            child: Column(
              children: [
                _DetailRow(icon: Icons.alternate_email, label: 'Username', value: '@${user.username}'),
                const Divider(height: 1, color: bgSubtle),
                _DetailRow(icon: Icons.cake_outlined, label: 'Ngày sinh', value: _fmtDate(user.dateOfBirth)),
                const Divider(height: 1, color: bgSubtle),
                _DetailRow(icon: Icons.transgender_outlined, label: 'Giới tính', value: _capitalize(user.gender)),
                const Divider(height: 1, color: bgSubtle),
                _DetailRow(icon: Icons.phone_outlined, label: 'Số điện thoại', value: user.phone),
                const Divider(height: 1, color: bgSubtle),
                _DetailRow(icon: Icons.location_on_outlined, label: 'Múi giờ', value: user.timezone),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Thông tin hệ thống
          const Text('HỆ THỐNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: bgSubtle, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol)),
            child: Column(
              children: [
                _DetailRow(icon: Icons.key, label: 'User ID', value: user.id, isCopyable: true),
                const Divider(height: 1, color: borderCol),
                _DetailRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Vai trò',
                  value: user.role.toUpperCase(),
                  valueColor: user.role == 'admin' ? Colors.red : Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildAvatar(UserEntity user) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bgSubtle, border: Border.all(color: borderCol),
        image: (user.avatarUrl != null) ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover) : null,
      ),
      child: (user.avatarUrl == null) ? Center(child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMuted))) : null,
    );
  }

  String _fmtMinutes(int min) => min < 60 ? '$min p' : '${(min/60).toStringAsFixed(1)} h';
  String _fmtDate(DateTime? d) => d != null ? DateFormat('dd/MM/yyyy').format(d) : 'Chưa cập nhật';
  String _capitalize(String? s) => (s != null && s.isNotEmpty) ? '${s[0].toUpperCase()}${s.substring(1)}' : 'Chưa cập nhật';
}

// Widget dòng chi tiết (Dùng cho Page 1)
class _DetailRow extends StatelessWidget {
  final IconData icon; final String label; final String? value; final bool isCopyable; final Color? valueColor;
  const _DetailRow({required this.icon, required this.label, required this.value, this.isCopyable = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF71717A)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF71717A))),
          const Spacer(),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: isCopyable && value != null ? () {
                Clipboard.setData(ClipboardData(text: value!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)));
              } : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      (value == null || value!.isEmpty) ? 'N/A' : value!,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? const Color(0xFF09090B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCopyable) ...[const SizedBox(width: 4), const Icon(Icons.copy, size: 12, color: Color(0xFF71717A))]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Giữ nguyên _SummaryCard, _StatSmallItem, _StatusBadge từ code trước)
class _SummaryCard extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE4E4E7)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF09090B))), Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)))]));
  }
}
class _StatSmallItem extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _StatSmallItem({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)]))]));
  }
}
class _StatusBadge extends StatelessWidget {
  final String label; final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)));
  }
}