// feature/history/bloc/history_state.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../model/activity_model.dart';

enum HistoryStatus { initial, loading, success, error }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final String? errorMessage;

  // Dữ liệu gốc lấy từ API
  final List<ActivityModel> allActivities;

  // Dữ liệu đã lọc (Client-side filter theo tab)
  final List<ActivityModel> filteredActivities;

  // Khoảng thời gian hiện tại
  final DateTimeRange? dateRange;

  const HistoryState._({
    required this.status,
    this.errorMessage,
    this.allActivities = const [],
    this.filteredActivities = const [],
    this.dateRange,
  });

  factory HistoryState.initial() => const HistoryState._(status: HistoryStatus.initial);

  HistoryState copyWith({
    HistoryStatus? status,
    String? errorMessage,
    List<ActivityModel>? allActivities,
    List<ActivityModel>? filteredActivities,
    DateTimeRange? dateRange,
  }) {
    return HistoryState._(
      status: status ?? this.status,
      errorMessage: errorMessage,
      allActivities: allActivities ?? this.allActivities,
      filteredActivities: filteredActivities ?? this.filteredActivities,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, allActivities, filteredActivities, dateRange];
}