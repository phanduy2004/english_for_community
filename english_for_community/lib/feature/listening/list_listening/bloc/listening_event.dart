abstract class ListeningEvent {}

class GetListListeningEvent extends ListeningEvent {
  final String? difficulty;
  final bool forceRefresh;

  GetListListeningEvent({this.difficulty, this.forceRefresh = false});
}

class GetListeningByIdEvent extends ListeningEvent {
  final String id;

  GetListeningByIdEvent({required this.id});
}
