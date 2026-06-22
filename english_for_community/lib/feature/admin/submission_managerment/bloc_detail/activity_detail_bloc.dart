import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart';
import 'package:english_for_community/core/entity/reading/reading_attempt_entity.dart';
import 'package:english_for_community/core/entity/speaking/speaking_set_entity.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';
import 'package:english_for_community/core/entity/listening_comp_entity.dart';

import 'package:english_for_community/core/repository/history_repository.dart';
import '../model/activity_model.dart';
import 'activity_detail_event.dart'; // 🔥 NHỚ IMPORT TỪ FILE EVENT MỚI TẠO
import 'activity_detail_state.dart';

class ActivityDetailBloc extends Bloc<ActivityDetailEvent, ActivityDetailState> {
  final HistoryRepository _repository = getIt<HistoryRepository>();

  ActivityDetailBloc() : super(const ActivityDetailState()) {
    on<FetchActivityDetailEvent>(_onFetchDetail);
  }

  Future<void> _onFetchDetail(
      FetchActivityDetailEvent event,
      Emitter<ActivityDetailState> emit,
      ) async {
    emit(state.copyWith(status: DetailStatus.loading));

    final result = event.useUserActivityApi
        ? await _repository.getMyActivityDetail(
            event.id,
            event.type,
            subType: event.subType,
          )
        : await _repository.getActivityDetail(
            event.id,
            event.type,
            subType: event.subType,
          );
    result.fold(
          (failure) => emit(state.copyWith(
          status: DetailStatus.error,
          errorMessage: failure.message
      )),
          (data) {
        switch (event.type) {
          case ActivityType.writing:
            emit(state.copyWith(status: DetailStatus.success, writingData: data as WritingSubmissionEntity));
            break;
          case ActivityType.reading:
            emit(state.copyWith(status: DetailStatus.success, readingData: data as ReadingAttemptEntity));
            break;
          case ActivityType.speaking:
            emit(state.copyWith(status: DetailStatus.success, speakingData: data as SpeakingSetEntity));
            break;

          case ActivityType.listening:
            if (event.subType == 'Comprehension') {
              final mapData = data as Map<String, dynamic>;
              emit(state.copyWith(
                status: DetailStatus.success,
                listeningCompData: mapData['attempt'] as ListeningCompAttemptResult,
                listeningCompDetail: mapData['detail'] as ListeningCompEntity,
              ));
            } else {
              emit(state.copyWith(
                  status: DetailStatus.success,
                  listeningData: data as List<DictationAttemptEntity>
              ));
            }
            break;

          default:
            emit(state.copyWith(status: DetailStatus.error, errorMessage: "Unknown data type"));
        }
      },
    );
  }
}