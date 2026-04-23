import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../admin/submission_managerment/model/activity_model.dart';

enum MyExerciseHistoryStatus { initial, loading, success, error }

class MyExerciseHistoryState extends Equatable {
  final MyExerciseHistoryStatus status;
  final String? errorMessage;
  final List<ActivityModel> items;
  final DateTimeRange dateRange;
  final ActivityType? skillFilter;
  final int page;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;

  const MyExerciseHistoryState({
    required this.status,
    this.errorMessage,
    this.items = const [],
    required this.dateRange,
    this.skillFilter,
    this.page = 1,
    this.total = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  factory MyExerciseHistoryState.initial() {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    return MyExerciseHistoryState(
      status: MyExerciseHistoryStatus.initial,
      dateRange: DateTimeRange(start: start, end: end),
    );
  }

  MyExerciseHistoryState copyWith({
    MyExerciseHistoryStatus? status,
    String? errorMessage,
    List<ActivityModel>? items,
    DateTimeRange? dateRange,
    ActivityType? skillFilter,
    bool setSkillFilter = false,
    int? page,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MyExerciseHistoryState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      items: items ?? this.items,
      dateRange: dateRange ?? this.dateRange,
      skillFilter: setSkillFilter ? skillFilter : this.skillFilter,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [status, errorMessage, items, dateRange, skillFilter, page, total, hasMore, isLoadingMore];
}
