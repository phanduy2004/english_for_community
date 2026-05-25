abstract class ListeningEvent {}

class GetListListeningEvent extends ListeningEvent{
  final String? difficulty;

  GetListListeningEvent({this.difficulty});
}
class GetListeningByIdEvent extends ListeningEvent{
  final String id;

  GetListeningByIdEvent({required this.id});
}