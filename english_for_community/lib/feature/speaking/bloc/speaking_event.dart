// lib/feature/speaking/bloc/speaking_event.dart
import 'package:equatable/equatable.dart';
import 'package:english_for_community/feature/speaking/speaking_hub_page.dart';

abstract class SpeakingEvent extends Equatable {
  const SpeakingEvent();

  @override
  List<Object> get props => [];
}

/// Sự kiện được gọi khi trang Hub tải, hoặc khi user thay đổi filter
class FetchSpeakingSetsEvent extends SpeakingEvent {
  final SpeakingMode mode;
  final String level;
  final int page;
  final int limit;

  const FetchSpeakingSetsEvent({
    required this.mode,
    required this.level,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object> get props => [mode, level, page, limit];
}