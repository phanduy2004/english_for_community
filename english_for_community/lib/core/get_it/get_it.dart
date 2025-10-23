import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/feature/listening/list_listening/bloc/listening_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../feature/listening/listening_skill/bloc/cue_bloc.dart';
import '../api/api_client.dart';
import '../datasource/cue_remote_datasource.dart';
import '../datasource/listening_remote_datasource.dart';
import '../datasource/user_remote_datasource.dart';
import '../datasource/auth_remote_datasource.dart';
import '../datasource/writing_remote_datasource.dart';
import '../repository/auth_repository.dart';
import '../repository/cue_repository.dart';
import '../repository/listening_repository.dart';
import '../repository/user_repository.dart';
import '../repository_impl/auth_repository_impl.dart';
import '../repository_impl/cue_repository_impl.dart';
import '../repository_impl/listening_repository_impl.dart';
import '../repository_impl/user_repository_impl.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../repository_impl/writing_repository_impl.dart';

var getIt = GetIt.instance;

void setup() {
 registerApiClient();
 registerDataSource();
 registerRepositories();
 registerBloc();
}

void registerApiClient() {
 getIt.registerSingleton(ApiClient());
}

void registerDataSource() {
 final api = getIt<ApiClient>();

 // ⚠️ Tạo 2 Dio tách biệt
 final dioPublic = api.getDio(authorized: false); // login/register
 final dioAuth   = api.getDio(authorized: true);  // profile, update, delete

 getIt.registerSingleton<AuthRemoteDatasource>(
  AuthRemoteDatasource(dio: dioPublic),
 );
 getIt.registerSingleton<UserRemoteDatasource>(
  UserRemoteDatasource(dio: dioAuth),
 );
 getIt.registerSingleton<ListeningRemoteDatasource>(
  ListeningRemoteDatasource(dio: dioAuth),
 );
 getIt.registerSingleton<CueRemoteDatasource>(
  CueRemoteDatasource(dio: dioAuth),
 );
 getIt.registerSingleton<WritingRemoteDataSource>(
  WritingRemoteDataSource(dio: dioAuth),
 );
}

void registerRepositories() {
 getIt.registerSingleton<AuthRepository>(
  AuthRepositoryImpl(authRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<UserRepository>(
  UserRepositoryImpl(userRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<ListeningRepository>(
  ListeningRepositoryImpl(listeningRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<CueRepository>(
  CueRepositoryImpl(cueRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<WritingRepository>(
  WritingRepositoryImpl(writingRemoteDataSource: getIt()),
 );
}

void registerBloc() {
 getIt.registerFactory(() => UserBloc(
  authRepository: getIt(),
  userRepository: getIt(),
 ));
 getIt.registerFactory(() => ListeningBloc(listeningRepository: getIt()
 ));
 getIt.registerFactory(() => CueBloc(cueRepository: getIt()
 ));
 getIt.registerFactory(() => WritingBloc(writingRepository: getIt()
 ));
}
