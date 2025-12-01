import 'package:equatable/equatable.dart';
import '../../../../../core/entity/speaking/speaking_set_entity.dart';

abstract class AdminSpeakingEvent extends Equatable {
  const AdminSpeakingEvent();
  @override
  List<Object?> get props => [];
}

class GetAdminSpeakingListEvent extends AdminSpeakingEvent {
  final int page;
  final int limit;
  const GetAdminSpeakingListEvent({this.page = 1, this.limit = 20});
}

class GetSpeakingDetailEvent extends AdminSpeakingEvent {
  final String id;
  const GetSpeakingDetailEvent(this.id);
}

class CreateSpeakingEvent extends AdminSpeakingEvent {
  final SpeakingSetEntity speakingSet;
  const CreateSpeakingEvent(this.speakingSet);
}

class UpdateSpeakingEvent extends AdminSpeakingEvent {
  final String id;
  final SpeakingSetEntity speakingSet;
  const UpdateSpeakingEvent({required this.id, required this.speakingSet});
}

class DeleteSpeakingEvent extends AdminSpeakingEvent {
  final String id;
  const DeleteSpeakingEvent(this.id);
}

class ClearSelectedSpeakingEvent extends AdminSpeakingEvent {}