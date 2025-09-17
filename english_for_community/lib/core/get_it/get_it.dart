import 'package:get_it/get_it.dart';
import '../api/api_client.dart';
import '../datasource/user_remote_datasource.dart';
import '../datasource/auth_remote_datasource.dart';
import '../repository/auth_repository.dart';
import '../repository/user_repository.dart';
import '../repository_impl/auth_repository_impl.dart';
import '../repository_impl/user_repository_impl.dart';
import '../../feature/auth/bloc/user_bloc.dart';

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
}

void registerRepositories() {
 getIt.registerSingleton<AuthRepository>(
  AuthRepositoryImpl(authRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<UserRepository>(
  UserRepositoryImpl(userRemoteDatasource: getIt()),
 );
}

void registerBloc() {
 getIt.registerFactory(() => UserBloc(
  authRepository: getIt(),
  userRepository: getIt(),
 ));
}
