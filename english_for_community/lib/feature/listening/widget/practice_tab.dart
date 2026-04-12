import 'package:flutter/material.dart';
import '../listening_skill/bloc/cue_state.dart';
import '../../../core/locale/l10n_context.dart';

class PracticeTab extends StatelessWidget {
  final CueState state;
  final TextEditingController controller;
  final Function(String) onTextChange;
  final VoidCallback onSubmit;
  final VoidCallback onReplay;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool showHint;
  final String? lastHint;
  final bool autoPlay;
  final Function(bool) onToggleAutoPlay;

  const PracticeTab({
    super.key,
    required this.state,
    required this.controller,
    required this.onTextChange,
    required this.onSubmit,
    required this.onReplay,
    required this.onNext,
    required this.onPrev,
    required this.showHint,
    this.lastHint,
    required this.autoPlay,
    required this.onToggleAutoPlay,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final isDone = state.completedIdx.contains(state.selectedIndex);
    final cue = state.currentCue;
    final isLast = state.selectedIndex == state.cues.length - 1;

    String btnText = t.dictationCheckButton;
    Color btnColor = Theme.of(context).primaryColor;
    VoidCallback onBtn = onSubmit;
    IconData btnIcon = Icons.check;

    if (isDone) {
      if (!isLast) {
        btnText = t.dictationNextButton;
        btnColor = const Color(0xFF10B981);
        btnIcon = Icons.arrow_forward;
        onBtn = onNext;
      } else {
        btnText = t.dictationFinishButton;
        btnColor = Colors.green;
        onBtn = () => Navigator.pop(context, true);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.listeningSentenceNumber(state.selectedIndex + 1), style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(children: [
                IconButton(onPressed: state.selectedIndex > 0 ? onPrev : null, icon: const Icon(Icons.chevron_left)),
                IconButton(onPressed: !isLast ? onNext : null, icon: const Icon(Icons.chevron_right)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t.dictationTypeWhatYouHearHint,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
            ),
            onChanged: onTextChange,
          ),
          if (showHint && lastHint != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: Text(lastHint!, style: const TextStyle(color: Color(0xFFB91C1C))),
            ),
          if (isDone && cue?.meaning != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.meaningLabel, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(cue!.meaning!, style: const TextStyle(color: Color(0xFF1E3A8A), fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: onBtn,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(btnIcon, size: 18),
              label: Text(btnText),
            )),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onReplay,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.replay),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text(t.listeningAutoPlayNext, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const Spacer(),
            Switch(value: autoPlay, onChanged: onToggleAutoPlay, activeColor: Theme.of(context).primaryColor),
          ]),
        ],
      ),
    );
  }
}