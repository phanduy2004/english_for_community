import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_group_cover_avatar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_prefs.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class StudentClassroomInfoSheet {
  StudentClassroomInfoSheet._();

  static Future<void> show(
    BuildContext context, {
    required String classroomId,
    required Map<String, dynamic> classroom,
    required String Function(AppLocalizations l10n, Map<String, dynamic>? c) teacherLine,
    required String Function(AppLocalizations l10n, String? policy) joinPolicyLabel,
    required int Function(Map<String, dynamic>? c, String key) memberCount,
    required bool allowStudentInvite,
    String? coverImageUrl,
    Future<void> Function()? onLeaveClass,
  }) {
    final l10n = context.l10n;
    final name = (classroom['name'] as String?)?.trim() ?? l10n.studentClassDetailTitle;
    final desc = (classroom['description'] as String?)?.trim() ?? '';
    final inviteCode = (classroom['inviteCode'] as String?)?.trim() ?? '';
    final teacher = teacherLine(l10n, classroom);
    final active = memberCount(classroom, 'memberCountActive');
    final policy = joinPolicyLabel(l10n, classroom['joinPolicy'] as String?);
    final created = _formatDate(context, classroom['createdAt']);
    final updated = _formatDate(context, classroom['updatedAt']);

    final classAccent = AppSkillColors.speaking;
    final identity = ClassroomChatUi.groupAvatarColors(name);

    return StudentBottomSheet.show(
      context,
      StudentBottomSheet(
        title: l10n.studentClassInfoTitle,
        child: _StudentClassroomInfoBody(
          classroomId: classroomId,
          name: name,
          desc: desc,
          inviteCode: inviteCode,
          teacher: teacher,
          active: active,
          policy: policy,
          created: created,
          updated: updated,
          classAccent: classAccent,
          identity: identity,
          allowStudentInvite: allowStudentInvite,
          coverImageUrl: coverImageUrl,
          onLeaveClass: onLeaveClass,
        ),
      ),
    );
  }

  static String? _formatDate(BuildContext context, dynamic raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    return DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(dt.toLocal());
  }
}

class _StudentClassroomInfoBody extends StatefulWidget {
  const _StudentClassroomInfoBody({
    required this.classroomId,
    required this.name,
    required this.desc,
    required this.inviteCode,
    required this.teacher,
    required this.active,
    required this.policy,
    required this.created,
    required this.updated,
    required this.classAccent,
    required this.identity,
    required this.allowStudentInvite,
    this.coverImageUrl,
    this.onLeaveClass,
  });

  final String classroomId;
  final String name;
  final String desc;
  final String inviteCode;
  final String teacher;
  final int active;
  final String policy;
  final String? created;
  final String? updated;
  final SkillColorSet classAccent;
  final ({Color background, Color foreground}) identity;
  final bool allowStudentInvite;
  final String? coverImageUrl;
  final Future<void> Function()? onLeaveClass;

  @override
  State<_StudentClassroomInfoBody> createState() => _StudentClassroomInfoBodyState();
}

class _StudentClassroomInfoBodyState extends State<_StudentClassroomInfoBody> {
  bool _muted = false;
  bool _muteLoading = true;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _loadMute();
  }

  Future<void> _loadMute() async {
    final muted = await StudentClassroomPrefs.isMuted(widget.classroomId);
    if (!mounted) return;
    setState(() {
      _muted = muted;
      _muteLoading = false;
    });
  }

  Future<void> _toggleMute(bool value) async {
    setState(() => _muted = value);
    await StudentClassroomPrefs.setMuted(widget.classroomId, value);
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.studentClassLeaveConfirmTitle),
        content: Text(l10n.studentClassLeaveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.studentClassLeaveAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || widget.onLeaveClass == null) return;
    setState(() => _leaving = true);
    await widget.onLeaveClass!();
    if (mounted) setState(() => _leaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showInvite = widget.allowStudentInvite && widget.inviteCode.isNotEmpty;

    return SingleChildScrollView(
      padding: StudentMobileUi.pagePadding.copyWith(top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChatGroupCoverAvatar(
                coverImageUrl: widget.coverImageUrl,
                radius: 24,
                groupName: widget.name,
                useInitialsFallback: true,
                backgroundColor: widget.identity.background,
                fallbackIconColor: widget.identity.foreground,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: StudentMobileUi.sectionTitle(context)),
                    if (widget.teacher.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        widget.teacher,
                        style: StudentMobileUi.body(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              _metaChip(
                Icons.people_outline,
                l10n.studentClassMemberCount(widget.active),
                widget.classAccent.color,
                widget.classAccent.tint,
              ),
              _metaChip(
                Icons.lock_open_outlined,
                widget.policy,
                AppColors.info,
                AppColors.infoBg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            widget.desc.isNotEmpty ? widget.desc : l10n.studentClassNoDescription,
            style: StudentMobileUi.body(context).copyWith(
              height: 1.5,
              color: widget.desc.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
          if (widget.created != null || widget.updated != null) ...[
            const SizedBox(height: AppSpacing.s4),
            if (widget.created != null)
              Text(l10n.studentClassCreatedAt(widget.created!), style: StudentMobileUi.caption(context)),
            if (widget.updated != null) ...[
              const SizedBox(height: AppSpacing.s1),
              Text(l10n.studentClassUpdatedAt(widget.updated!), style: StudentMobileUi.caption(context)),
            ],
          ],
          const SizedBox(height: AppSpacing.s4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _muted,
            onChanged: _muteLoading ? null : _toggleMute,
            title: Text(l10n.studentClassMuteNotifications),
            subtitle: Text(
              l10n.studentClassMuteNotificationsHint,
              style: StudentMobileUi.caption(context),
            ),
          ),
          if (showInvite) ...[
            const SizedBox(height: AppSpacing.s3),
            AppCard(
              variant: AppCardVariant.outline,
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.studentClassInviteCodeLabel,
                    style: StudentMobileUi.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.inviteCode,
                          style: StudentMobileUi.cardTitle(context).copyWith(
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.inviteCode));
                          AppFeedback.success(context, l10n.copiedToClipboard);
                        },
                        child: Text(l10n.copyInviteCode),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (widget.onLeaveClass != null) ...[
            const SizedBox(height: AppSpacing.s5),
            OutlinedButton.icon(
              onPressed: _leaving ? null : _confirmLeave,
              icon: _leaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout, size: 18),
              label: Text(l10n.studentClassLeaveAction),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s6),
        ],
      ),
    );
  }

  static Widget _metaChip(IconData icon, String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
