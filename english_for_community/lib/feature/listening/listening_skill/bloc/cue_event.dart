import 'package:equatable/equatable.dart';

abstract class CueEvent extends Equatable {
  const CueEvent();
  @override
  List<Object?> get props => [];
}

class FetchCuesByListeningId extends CueEvent {
  final String listeningId;
  final int from;
  final int limit;
  const FetchCuesByListeningId({
    required this.listeningId,
    this.from = 0,
    this.limit = 200,
  });
  @override
  List<Object?> get props => [listeningId, from, limit];
}

class SelectCueByIndex extends CueEvent {
  final int index;
  const SelectCueByIndex(this.index);
  @override
  List<Object?> get props => [index];
}

class NextCue extends CueEvent {
  const NextCue();
}

class PrevCue extends CueEvent {
  const PrevCue();
}

class UpdateUserAnswer extends CueEvent {
  final String text;
  const UpdateUserAnswer(this.text);
  @override
  List<Object?> get props => [text];
}
class LoadCuesAndAttempts extends CueEvent {
  final String listeningId;

  LoadCuesAndAttempts({required this.listeningId});
}
