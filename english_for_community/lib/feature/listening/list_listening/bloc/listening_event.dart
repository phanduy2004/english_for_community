abstract class ListeningEvent {}

class GetListListeningEvent extends ListeningEvent{
  final String? difficulty;

  GetListListeningEvent({this.difficulty});

  @override
  List<Object?> get props => [difficulty]; // Cần thêm Equatable để BLoC hoạt động tốt
}
class GetListeningByIdEvent extends ListeningEvent{
  final String id;

  GetListeningByIdEvent({required this.id});
}