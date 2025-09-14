import 'dart:async';

import 'package:english_for_community/feature/auth/bloc/user_event.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:bloc/bloc.dart';

import '../../../core/repository/auth_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState>{
  final AuthRepository authRepository;


  UserBloc({required this.authRepository}) : super(UserState.initial()) {
    on<LoginEvent>(onLoginEvent);

  }

  Future onLoginEvent(LoginEvent event, Emitter<UserState> emit) async{
    emit(state.copyWith(status: UserStatus.loading));
    var result = await authRepository.login(event.email, event.password);
    result.fold((l){
      emit(state.copyWith(status: UserStatus.error, errorMessage: l.message));
    }, (r){
      emit(state.copyWith(status: UserStatus.success));
    });
  }
}