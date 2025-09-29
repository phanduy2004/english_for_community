import 'package:english_for_community/core/entity/listening_entity.dart';
import 'package:equatable/equatable.dart';

enum ListeningStatus { initial, loading, success, error }

class ListeningState extends Equatable {
  final ListeningStatus status;
  final String? errorMessage;
  final ListeningEntity? listeningEntity;
  final List<ListeningEntity>? listListeningEntity;

  const ListeningState._({
    required this.status,
    this.errorMessage,
    this.listeningEntity,
    this.listListeningEntity,
  });

  factory ListeningState.initial() =>
      ListeningState._(status: ListeningStatus.initial);

  ListeningState copyWith({
    ListeningStatus? status,
    String? errorMessage,
    ListeningEntity? listeningEntity,
    List<ListeningEntity>? listListeningEntity,
  }) => ListeningState._(
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    listeningEntity: listeningEntity ?? this.listeningEntity,
    listListeningEntity: listListeningEntity ?? this.listListeningEntity,
  );

  @override
  // TODO: implement props,
  List<Object?> get props => [status, errorMessage, listeningEntity,listListeningEntity];
}
