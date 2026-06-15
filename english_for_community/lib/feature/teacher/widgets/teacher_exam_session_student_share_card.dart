import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Explains what teachers should share with students in the live session console.
class TeacherExamSessionStudentShareCard extends StatelessWidget {
  const TeacherExamSessionStudentShareCard({
    super.key,
    required this.audience,
    this.publicJoinToken,
    this.roomCode,
  });

  final String? audience;
  final String? publicJoinToken;
  final String? roomCode;

  bool get _isPublic => audience == 'public_link';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final token = (publicJoinToken ?? '').trim();
    final room = (roomCode ?? '').trim();

    return DecoratedBox(
      decoration: ExamSystemUi.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teacherExamSessionShareTitle,
              style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _isPublic ? l10n.teacherExamSessionSharePublic : l10n.teacherExamSessionShareClassroom,
              style: ExamSystemUi.captionSecondary.copyWith(height: 1.45),
            ),
            if (_isPublic && token.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                token,
                style: ExamSystemUi.captionSecondary.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: token));
                    if (context.mounted) {
                      AppCornerToast.show(context, l10n.dashboardPublicTokenCopied);
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(l10n.teacherExamSessionSharePublicCopy),
                ),
              ),
            ],
            if (room.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${l10n.examSessionRoomCode}: $room',
                style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                l10n.teacherExamSessionRoomCodeHint,
                style: ExamSystemUi.captionMuted.copyWith(fontSize: 11, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
