import 'package:equatable/equatable.dart';

abstract class SpeakingPhase2Event extends Equatable {
  const SpeakingPhase2Event();

  @override
  List<Object?> get props => [];
}

class LoadSpeakingScenariosEvent extends SpeakingPhase2Event {
  final String? level;

  const LoadSpeakingScenariosEvent({this.level});

  @override
  List<Object?> get props => [level];
}

class LoadSpeakingProgressEvent extends SpeakingPhase2Event {
  final String range;

  const LoadSpeakingProgressEvent({this.range = 'week'});

  @override
  List<Object?> get props => [range];
}

class LoadSpeakingNotebookEvent extends SpeakingPhase2Event {
  final int limit;

  const LoadSpeakingNotebookEvent({this.limit = 40});

  @override
  List<Object?> get props => [limit];
}
