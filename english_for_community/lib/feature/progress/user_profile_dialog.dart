import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfileDialog extends StatelessWidget {
  final String? avatarUrl;
  final String fullName;
  final String username; // Thêm username để hiển thị phụ
  final DateTime? dateOfBirth;
  final String? bio;
  final String? gender;
  final int totalPoints;
  final int level;
  final int currentStreak;
  final bool isOnline; // Thêm trạng thái online nếu muốn

  const UserProfileDialog({
    super.key,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.dateOfBirth,
    this.bio,
    this.gender,
    this.totalPoints = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.isOnline = false,
  });

  // Color Palette (Shadcn Style)
  static const Color bgSurface = Colors.white;
  static const Color textMain = Color(0xFF09090B);
  static const Color textMuted = Color(0xFF71717A);
  static const Color borderCol = Color(0xFFE4E4E7);
  static const Color primaryCol = Color(0xFF18181B);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: bgSurface,
      surfaceTintColor: bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380), // Giới hạn chiều rộng cho đẹp
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- 1. AVATAR & STATUS ---
                Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderCol, width: 2),
                        color: const Color(0xFFF4F4F5),
                        image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? DecorationImage(
                          image: NetworkImage(avatarUrl!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: (avatarUrl == null || avatarUrl!.isEmpty)
                          ? Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                          ),
                        ),
                      )
                          : null,
                    ),
                    // Online Badge
                    if (isOnline)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- 2. NAME & USERNAME ---
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  style: const TextStyle(fontSize: 14, color: textMuted),
                ),

                // --- 3. BIO (Optional) ---
                if (bio != null && bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    bio!,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF52525B), // Zinc-600
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // --- 4. STATS ROW (Gamification) ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA), // Zinc-50
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFF97316), // Orange
                        value: '$currentStreak',
                        label: 'Streak',
                      ),
                      _verticalDivider(),
                      _buildStatItem(
                        icon: Icons.stars_rounded,
                        color: const Color(0xFFEAB308), // Yellow
                        value: NumberFormat.compact().format(totalPoints),
                        label: 'XP',
                      ),
                      _verticalDivider(),
                      _buildStatItem(
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFF3B82F6), // Blue
                        value: '$level',
                        label: 'Level',
                      ),
                    ],
                  ),
                ),

                // --- 5. PERSONAL DETAILS (Chỉ hiện nếu có dữ liệu) ---
                if (dateOfBirth != null || gender != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      children: [
                        if (dateOfBirth != null)
                          _buildDetailRow(
                            icon: Icons.cake_outlined,
                            label: 'Birthday',
                            value: DateFormat('dd MMM yyyy').format(dateOfBirth!),
                            showDivider: gender != null, // Hiện gạch ngang nếu có dòng gender bên dưới
                          ),
                        if (gender != null)
                          _buildDetailRow(
                            icon: Icons.transgender_outlined,
                            label: 'Gender',
                            value: _capitalize(gender!),
                            showDivider: false,
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // --- 6. ACTIONS ---
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textMain,
                            side: const BorderSide(color: borderCol),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    // Có thể thêm nút "Add Friend" hoặc "Chat" ở đây nếu cần trong tương lai
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE4E4E7),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: textMuted),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textMain,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}