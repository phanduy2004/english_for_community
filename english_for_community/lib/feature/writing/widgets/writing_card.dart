import 'package:flutter/material.dart';

import '../../../core/locale/l10n_context.dart';

class WritingCard extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onHistoryTap;
  final String? taskType;
  final String? level;
  final int? submissions;
  final double? avgScore;
  final Color primaryColor; // 🔥 Đây là màu của ICON (Màu gốc)

  const WritingCard({
    super.key,
    required this.title,
    this.leadingIcon = Icons.article_outlined,
    this.onTap,
    this.onHistoryTap,
    this.taskType,
    this.level,
    this.submissions,
    this.avgScore,
    required this.primaryColor,
  });

  // 👇 Hàm lấy màu riêng cho Badge Level
  Color _getBadgeColor(String? lvl) {
    switch (lvl?.toLowerCase()) {
      case 'beginner': return const Color(0xFF16A34A); // Green
      case 'intermediate': return const Color(0xFFEA580C); // Orange
      case 'advanced': return const Color(0xFFDC2626); // Red
      default: return const Color(0xFF71717A); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    // Màu Icon: Dùng primaryColor (Màu tím/xanh gốc của app)
    final iconBg = primaryColor.withOpacity(0.08);

    // Màu Badge: Tự tính theo level
    final badgeColor = _getBadgeColor(level);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ICON: Giữ màu Gốc (primaryColor)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Icon(leadingIcon, color: primaryColor, size: 24),
                ),

                const SizedBox(width: 16),

                // 2. NỘI DUNG
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // 👇 BADGE LEVEL: Dùng màu riêng (badgeColor)
                          if (level != null && level!.isNotEmpty)
                            _Badge(
                              text: level!,
                              bgColor: badgeColor.withOpacity(0.1),
                              textColor: badgeColor,
                            ),

                          if (submissions != null && submissions! > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 4),
                                Icon(Icons.description_outlined, size: 14, color: textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.writingSubmissionsCount(submissions!),
                                  style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. CỘT PHẢI
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (onHistoryTap != null)
                      InkWell(
                        onTap: onHistoryTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(Icons.history, color: textMuted.withOpacity(0.6), size: 22),
                        ),
                      ),

                    if (avgScore != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: avgScore! >= 7.0 ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: avgScore! >= 7.0 ? const Color(0xFF86EFAC) : const Color(0xFFFFEDD5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rate_rounded,
                              size: 14,
                              color: avgScore! >= 7.0 ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              avgScore!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: avgScore! >= 7.0 ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget _Badge
class _Badge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _Badge({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}