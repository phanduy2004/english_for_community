import 'package:english_for_community/core/datasource/auth_remote_datasource.dart';
import 'package:get_it/get_it.dart';

import '../../feature/auth/bloc/user_bloc.dart';
import '../api/api_client.dart';
import '../repository/auth_repository.dart';
import '../repository_impl/auth_repository_impl.dart';

var getIt = GetIt.instance;

void setup() {
 registerApiClient();
 registerDataSource();
 registerRepositories();
 registerBloc();
}

// void registerGoogleSignIn() {
//  getIt.registerSingleton(GoogleSignIn(
//   scopes: const ['email', 'profile'],
//  ));
// }

void registerApiClient() {
 getIt.registerSingleton(ApiClient());
}

void registerDataSource() {
 final dio = getIt<ApiClient>().getDio();
 //final dioWithToken = getIt<ApiClient>().getDio(tokenInterceptor: true);

 getIt.registerSingleton(AuthRemoteDatasource(dio: dio));


}

void registerRepositories() {
 getIt.registerSingleton<AuthRepository>(
  AuthRepositoryImpl(authRemoteDatasource: getIt()),
 );

}

void registerBloc() {
 getIt.registerFactory(() => UserBloc(authRepository: getIt()));


}
