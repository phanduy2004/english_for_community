import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfileDialog extends StatelessWidget {
  final String? avatarUrl;
  final String fullName;
  final String username;
  final DateTime? dateOfBirth;
  final String? bio;
  final String? gender;
  final int totalPoints;
  final int level;
  final int currentStreak;
  final bool isOnline;

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

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet + 2)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.outline, width: 2),
                    color: AppColors.surfaceSubtle,
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
                            style: StudentMobileUi.sectionTitle(context).copyWith(color: AppColors.textMuted),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.s5),
                Text(fullName, textAlign: TextAlign.center, style: StudentMobileUi.sectionTitle(context)),
                const SizedBox(height: AppSpacing.s2),
                Text('@$username', style: StudentMobileUi.body(context)),
                if (bio != null && bio!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    bio!,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: StudentMobileUi.body(context),
                  ),
                ],
                const SizedBox(height: AppSpacing.s6),
                AppCard(
                  variant: AppCardVariant.filled,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(context, Icons.local_fire_department_rounded, '$currentStreak', t.statStreak),
                      _verticalDivider(),
                      _buildStatItem(
                        context,
                        Icons.stars_rounded,
                        NumberFormat.compact().format(totalPoints),
                        t.statPoints,
                      ),
                      _verticalDivider(),
                      _buildStatItem(context, Icons.bar_chart_rounded, '$level', t.statLevelLabel),
                    ],
                  ),
                ),
                if (dateOfBirth != null || gender != null) ...[
                  const SizedBox(height: AppSpacing.s6),
                  AppCard(
                    variant: AppCardVariant.outline,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
                    child: Column(
                      children: [
                        if (dateOfBirth != null)
                          _buildDetailRow(
                            context,
                            icon: Icons.cake_outlined,
                            label: t.labelBirthday,
                            value: DateFormat('dd MMM yyyy').format(dateOfBirth!),
                            showDivider: gender != null,
                          ),
                        if (gender != null)
                          _buildDetailRow(
                            context,
                            icon: Icons.transgender_outlined,
                            label: t.labelGender,
                            value: _localizedGender(t, gender!),
                            showDivider: false,
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s7),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 24, color: AppColors.outline);
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StudentMobileUi.skillIconBox(icon, size: 36),
        const SizedBox(height: AppSpacing.s2),
        Text(value, style: StudentMobileUi.kpi(context)),
        Text(label, style: StudentMobileUi.caption(context)),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
          child: Row(
            children: [
              StudentMobileUi.skillIconBox(icon, size: 32),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: StudentMobileUi.caption(context)),
                    const SizedBox(height: AppSpacing.s1),
                    Text(value, style: StudentMobileUi.cardTitle(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 1, color: AppColors.outlineMuted),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _localizedGender(AppLocalizations t, String raw) {
    switch (raw.toLowerCase()) {
      case 'male':
        return t.genderMale;
      case 'female':
        return t.genderFemale;
      case 'other':
        return t.genderOther;
      default:
        return _capitalize(raw);
    }
  }
}
