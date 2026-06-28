import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_group_cover_avatar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';

/// Classroom row on "My classes" hub — flat, cover avatar, no long description.
class StudentClassroomHubTile extends StatelessWidget {
  const StudentClassroomHubTile({
    super.key,
    required this.name,
    this.coverImageUrl,
    this.teacherLine,
    this.joinPolicy,
    this.onTap,
  });

  final String name;
  final String? coverImageUrl;
  final String? teacherLine;
  /// `open` | `approval_required` | null
  final String? joinPolicy;
  final VoidCallback? onTap;

  static const double rowMinHeight = 72;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final identity = ClassroomChatUi.groupAvatarColors(name);
    final classColors = AppSkillColors.speaking;
    final policyLabel = joinPolicy == 'approval_required'
        ? l10n.studentClassJoinPolicyApproval
        : null;

    return StudentMobileUi.inkTap(
      onTap: onTap,
      materialColor: AppColors.surfaceCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: rowMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            children: [
              ChatGroupCoverAvatar(
                coverImageUrl: coverImageUrl,
                radius: 22,
                groupName: name,
                useInitialsFallback: true,
                backgroundColor: identity.background,
                fallbackIconColor: identity.foreground,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StudentMobileUi.cardTitle(context).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (teacherLine != null && teacherLine!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        teacherLine!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StudentMobileUi.caption(context),
                      ),
                    ],
                    if (policyLabel != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          policyLabel,
                          style: StudentMobileUi.caption(context).copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: classColors.color.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
