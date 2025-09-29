abstract class ListeningEvent {}

class GetListListeningEvent extends ListeningEvent{

}
class GetListeningByIdEvent extends ListeningEvent{
  final String id;

  GetListeningByIdEvent({required this.id});
}