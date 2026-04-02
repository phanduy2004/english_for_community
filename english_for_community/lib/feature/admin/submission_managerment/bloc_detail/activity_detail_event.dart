import 'package:equatable/equatable.dart';
import '../model/activity_model.dart';

abstract class ActivityDetailEvent extends Equatable {
  const ActivityDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchActivityDetailEvent extends ActivityDetailEvent {
  final String id;
  final ActivityType type;
  final String? subType;

  const FetchActivityDetailEvent({
    required this.id,
    required this.type,
    this.subType,
  });

  @override
  List<Object?> get props => [id, type, subType];
}