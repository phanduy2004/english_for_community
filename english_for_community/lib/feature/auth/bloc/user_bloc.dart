import 'dart:async';

import 'package:english_for_community/core/repository/user_repository.dart';
import 'package:english_for_community/feature/auth/bloc/user_event.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:bloc/bloc.dart';

import '../../../core/repository/auth_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState>{
  final AuthRepository authRepository;
  final UserRepository userRepository;

  UserBloc({required this.authRepository, required this.userRepository}) : super(UserState.initial()) {
    on<LoginEvent>(onLoginEvent);
    on<GetProfileEvent>(onGetProfileEvent);
    on<DeleteAccountEvent>(onDeleteAccountEvent);
    on<UpdateProfileEvent>(onUpdateProfileEvent);


  }
  Future onDeleteAccountEvent(DeleteAccountEvent event, Emitter<UserState> emit)async{
    emit(state.copyWith(status: UserStatus.loading));
    var result = await userRepository.deleteAccount();
    result.fold((l){
      emit(state.copyWith(status: UserStatus.error, errorMessage: l.message));
    }, (r){
      emit(state.copyWith(status: UserStatus.success));
    });
  }
  Future onUpdateProfileEvent(UpdateProfileEvent event, Emitter<UserState> emit)async{
    emit(state.copyWith(status: UserStatus.loading));
    var result = await userRepository.updateProfile(fullName: event.fullName, timezone: event.timezone,language: event.language, strictCorrection: event.strictCorrection, reminder: event.reminder, dailyMinutes: event.dailyMinutes, cefr: event.cefr, goal: event.goal, avatarUrl: event.avatarUrl, bio: event.bio);
    result.fold((l){
      emit(state.copyWith(status: UserStatus.error, errorMessage: l.message));
    }, (r){
      emit(state.copyWith(status: UserStatus.success));
    });
  }
  Future onGetProfileEvent(GetProfileEvent event, Emitter<UserState> emit)async{
    emit(state.copyWith(status: UserStatus.loading));
    var result = await userRepository.getProfile();
    result.fold((l){
      emit(state.copyWith(status: UserStatus.error, errorMessage: l.message));
    }, (r){
      emit(state.copyWith(status: UserStatus.success, userEntity: r));
    });
  }

  Future onLoginEvent(LoginEvent event, Emitter<UserState> emit) async{
    emit(state.copyWith(status: UserStatus.loading));
    var result = await authRepository.login(event.email, event.password);
    result.fold((l){
      emit(state.copyWith(status: UserStatus.error, errorMessage: l.message));
    }, (r){
      emit(state.copyWith(status: UserStatus.success,  userEntity: r));
    });
  }
}