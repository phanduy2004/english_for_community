import 'package:flutter/material.dart';

class WritingCard extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onHistoryTap;
  final String? taskType;
  final String? level;
  final int? submissions;
  final double? avgScore;
  final Color primaryColor;

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

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderCol),
                      ),
                      child: Icon(leadingIcon, color: textMain, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (taskType != null && taskType!.isNotEmpty) ...[
                            Text(
                              taskType!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textMain,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Nút History (Nếu có callback)
                    if (onHistoryTap != null)
                      InkWell(
                        onTap: onHistoryTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.history, color: textMuted, size: 22),
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right, color: Color(0xFFA1A1AA), size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (level != null && level!.isNotEmpty)
                      _InfoBadge(icon: Icons.signal_cellular_alt, text: level!),
                    const SizedBox(width: 12),
                    if (submissions != null && submissions! > 0)
                      _InfoBadge(icon: Icons.edit_outlined, text: '$submissions essays'),
                    const Spacer(),
                    if (avgScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: avgScore! >= 7.0 ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(4),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF71717A)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF52525B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}