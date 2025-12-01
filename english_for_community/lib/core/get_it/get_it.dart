import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/feature/listening/list_listening/bloc/listening_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../feature/admin/content_management/listening/bloc/admin_listening_bloc.dart';
import '../../feature/admin/content_management/reading/bloc/admin_reading_bloc.dart';
import '../../feature/admin/content_management/speaking/bloc/admin_speaking_bloc.dart';
import '../../feature/admin/dashboard_home/bloc/admin_bloc.dart';
import '../../feature/home/bloc_ai/ai_chat_bloc.dart';
import '../../feature/listening/listening_skill/bloc/cue_bloc.dart';
import '../../feature/progress/bloc/progress_bloc.dart';
import '../../feature/reading/bloc/reading_bloc.dart';
import '../../feature/reading/reading_attempt_bloc/reading_attempt_bloc.dart';
import '../../feature/speaking/bloc/speaking_bloc.dart';
import '../../feature/speaking/speaking_lesson_bloc/speaking_lesson_bloc.dart';
import '../../feature/vocabulary/bloc_review/review_bloc.dart';
import '../api/api_client.dart';
import '../datasource/admin_remote_datasource.dart';
import '../datasource/ai_chat_remote_datasource.dart';
import '../datasource/dictionary_local_datasource.dart';
import '../datasource/listening_remote_datasource.dart';
import '../datasource/progress_remote_datasource.dart';
import '../datasource/reading_remote_datasource.dart';
import '../datasource/speaking_remote_datasource.dart';
import '../datasource/user_remote_datasource.dart';
import '../datasource/auth_remote_datasource.dart';
import '../datasource/user_vocab_remote_datasource.dart';
import '../datasource/writing_remote_datasource.dart';
import '../repository/admin_repository.dart';
import '../repository/ai_chat_repository.dart';
import '../repository/auth_repository.dart';
import '../repository/dictionary_repository.dart';
import '../repository/listening_repository.dart';
import '../repository/progress_repository.dart';
import '../repository/reading_repository.dart';
import '../repository/speaking_repository.dart';
import '../repository/user_repository.dart';
import '../repository/user_vocab_repository.dart';
import '../repository_impl/admin_repository_impl.dart';
import '../repository_impl/ai_chat_repository_impl.dart';
import '../repository_impl/auth_repository_impl.dart';
import '../repository_impl/dictionary_repository_impl.dart';
import '../repository_impl/listening_repository_impl.dart';
import '../repository_impl/progress_repository_impl.dart';
import '../repository_impl/reading_repository_impl.dart';
import '../repository_impl/speaking_repository_impl.dart';
import '../repository_impl/user_repository_impl.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../repository_impl/user_vocab_repository_impl.dart';
import '../repository_impl/writing_repository_impl.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_bloc.dart';

import '../socket/socket_service.dart';

var getIt = GetIt.instance;

void setup() {
 registerApiClient();
 registerServices();
 registerDataSource();
 registerRepositories();
 registerBloc();
}

void registerApiClient() {
 getIt.registerSingleton(ApiClient());
}
void registerServices() {
 getIt.registerLazySingleton<SocketService>(() => SocketService());
}
void registerDataSource() {
 final api = getIt<ApiClient>();

 final dioPublic = api.getDio(authorized: false);
 final dioAuth = api.getDio(authorized: true);

 // ----- Remote Datasources -----
 getIt.registerSingleton<AuthRemoteDatasource>(
  AuthRemoteDatasource(dio: dioPublic),
 );
 getIt.registerSingleton<UserRemoteDatasource>(
  UserRemoteDatasource(dio: dioAuth),
 );
 getIt.registerSingleton<ListeningRemoteDatasource>(
  ListeningRemoteDatasource(dio: dioAuth),
 );
 getIt.registerSingleton<WritingRemoteDataSource>(
  WritingRemoteDataSource(dio: dioAuth),
 );
 getIt.registerSingleton<SpeakingRemoteDatasource>(
  SpeakingRemoteDatasource(dio: dioAuth),
 );
 getIt.registerSingleton<ReadingRemoteDatasource>(
  ReadingRemoteDatasource(dio: dioAuth),
 );

 getIt.registerSingleton(
  DictionaryLocalDatasource(),
 );
 getIt.registerSingleton<UserVocabRemoteDatasource>(
  UserVocabRemoteDatasource(dio: dioAuth),
 );
 getIt.registerSingleton<ProgressRemoteDatasource>(
  ProgressRemoteDatasource(dio: dioAuth),
 );
 getIt.registerSingleton<AiChatRemoteDataSource>(
  AiChatRemoteDataSource(dio: dioAuth),
 );
 getIt.registerSingleton<AdminRemoteDatasource>(
  AdminRemoteDatasource(dio: dioAuth),
 );
}

void registerRepositories() {
 // ----- Remote Repositories -----
 getIt.registerSingleton<AuthRepository>(
  AuthRepositoryImpl(authRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<UserRepository>(
  UserRepositoryImpl(userRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<ListeningRepository>(
  ListeningRepositoryImpl(listeningRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<WritingRepository>(
  WritingRepositoryImpl(writingRemoteDataSource: getIt()),
 );
 getIt.registerSingleton<SpeakingRepository>(
  SpeakingRepositoryImpl(speakingRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<ReadingRepository>(
  ReadingRepositoryImpl(readingRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<DictionaryRepository>(
  DictionaryRepositoryImpl(dictionaryLocalDatasource: getIt()),
 );
 getIt.registerSingleton<UserVocabRepository>(
  UserVocabRepositoryImpl(userVocabRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<ProgressRepository>(
  ProgressRepositoryImpl(progressRemoteDatasource: getIt()),
 );
 getIt.registerSingleton<AiChatRepository>(
  AiChatRepositoryImpl(remoteDataSource: getIt()),
 );
 getIt.registerSingleton<AdminRepository>(
  AdminRepositoryImpl(adminRemoteDatasource: getIt()),
 );
}

void registerBloc() {
 getIt.registerLazySingleton<UserBloc>(() => UserBloc(
  authRepository: getIt(),
     userRepository: getIt(),
 ));
 getIt.registerFactory(
         () => ListeningBloc(listeningRepository: getIt()));
 getIt.registerFactory(() => CueBloc(listeningRepository: getIt()));
 getIt.registerFactory(() => WritingBloc(writingRepository: getIt()));
 getIt.registerFactory(
         () => SpeakingBloc(speakingRepository: getIt()));
 getIt.registerFactory(
         () => SpeakingLessonBloc(speakingRepository: getIt()));
 getIt.registerFactory(() => ReadingBloc(readingRepository: getIt()));
 getIt.registerFactory(
         () => ReadingAttemptBloc(readingRepository: getIt()));
 getIt.registerFactory(
         () => VocabularyBloc(userVocabRepository: getIt()));
 getIt.registerFactory(
         () => ReviewBloc(userVocabRepository: getIt()));
 getIt.registerFactory(
         () => ProgressBloc(progressRepository: getIt()));
 getIt.registerLazySingleton<AiChatBloc>(
      () => AiChatBloc(aiChatRepository: getIt()),
 );
 getIt.registerFactory(() => AdminBloc(adminRepository: getIt()));
 getIt.registerFactory(() => AdminReadingBloc(getIt<ReadingRepository>()));
 getIt.registerFactory(() => AdminListeningBloc(getIt<ListeningRepository>()));
 getIt.registerFactory(() => AdminSpeakingBloc(getIt<SpeakingRepository>()));
}