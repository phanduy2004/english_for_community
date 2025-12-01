import 'package:equatable/equatable.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object> get props => [];
}

class FetchProgressData extends ProgressEvent {
  final String range; // 'day', 'week', 'month'
  const FetchProgressData({this.range = 'week'}); // Mặc định là 'week'
  @override
  List<Object> get props => [range];
}
class FetchStatDetail extends ProgressEvent {
  final String statKey; // 'reading', 'speaking', 'vocab',...
  final String range; // 'day', 'week', 'month'

  const FetchStatDetail({
    required this.statKey,
    required this.range,
  });

  @override
  List<Object> get props => [statKey, range];
}
class FetchLeaderboard extends ProgressEvent {}