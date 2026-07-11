import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_avatar.dart';
import 'package:flutter/material.dart';

/// Member row for grouped inset list (A5 / R2).
class StudentClassroomMemberTile extends StatelessWidget {
  const StudentClassroomMemberTile({
    super.key,
    required this.member,
    required this.isMe,
  });

  final ChatMember member;
  final bool isMe;

  static const double _rowMinHeight = 64;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final classColors = AppSkillColors.speaking;
    final roleLabel = member.isClassOwner
        ? l10n.studentClassMemberTeacher
        : member.role == 'co_teacher'
            ? l10n.studentClassMemberCoTeacher
            : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _rowMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            ChatAvatar(
              avatarUrl: member.avatarUrl,
              displayName: member.fullName,
              radius: 22,
              fontSize: 13,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.fullName,
                          style: StudentMobileUi.cardTitle(context).copyWith(
                            fontSize: AppTypography.mobileH2,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            l10n.studentClassMemberYou,
                            style: StudentMobileUi.caption(context).copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: AppTypography.mobileCaption,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${member.username}',
                    style: StudentMobileUi.caption(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (roleLabel != null) ...[
              const SizedBox(width: AppSpacing.s2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: classColors.tint,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: classColors.color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  roleLabel,
                  style: StudentMobileUi.caption(context).copyWith(
                    color: classColors.dark,
                    fontWeight: FontWeight.w600,
                    fontSize: AppTypography.mobileLabel,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
