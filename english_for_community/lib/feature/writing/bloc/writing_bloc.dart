import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/feature/writing/bloc/writing_event.dart';
import 'package:english_for_community/feature/writing/bloc/writing_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WritingBloc extends Bloc<WritingEvent, WritingState>{
  final WritingRepository writingRepository;

  WritingBloc({required this.writingRepository}): super(WritingState.initial()){
    on<GetWritingTopicsEvent>(onGetWritingTopicsEvent);
  }
  Future onGetWritingTopicsEvent(GetWritingTopicsEvent event, Emitter<WritingState> emit)async{
    emit(state.copyWith(status: WritingStatus.loading));
    var result = await writingRepository.getWritingTopics();
    result.fold((l){
      emit(state.copyWith(status: WritingStatus.error, errorMessage: l.message));
    }, (r){
      emit(state.copyWith(status: WritingStatus.success, topics: r));
    });
  }
}