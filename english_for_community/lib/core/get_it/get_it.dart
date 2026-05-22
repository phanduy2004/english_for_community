import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/feature/listening/list_listening/bloc/listening_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../feature/admin/content_management/listening/bloc/admin_listening_bloc.dart';
import '../../feature/admin/content_management/listening_comp/bloc/admin_listening_comp_bloc.dart';
import '../../feature/admin/content_management/reading/bloc/admin_reading_bloc.dart';
import '../../feature/admin/content_management/speaking/bloc/admin_speaking_bloc.dart';
import '../../feature/admin/content_management/writing/bloc/admin_writing_bloc.dart';
import '../../feature/admin/dashboard_home/bloc/admin_bloc.dart';
import '../../feature/admin/release_management/bloc/release_management_bloc.dart';
import '../../feature/admin/submission_managerment/bloc/history_bloc.dart';
import '../../feature/home/bloc_ai/ai_chat_bloc.dart';
import '../../feature/home/bloc_noti/notification_bloc.dart';
import '../../feature/app_update/bloc/app_update_bloc.dart';
import '../../feature/listening/listening_skill/bloc/cue_bloc.dart';
import '../../feature/listening_comp/bloc/listening_comp_bloc.dart';
import '../../feature/listening_comp/bloc_list/listening_comp_list_bloc.dart';
import '../../feature/profile/my_exercise_history/my_exercise_history_bloc.dart';
import '../../feature/progress/bloc/progress_bloc.dart';
import '../../feature/progress/bloc_report/report_bloc.dart';
import '../../feature/reading/bloc/reading_bloc.dart';
import '../../feature/reading/reading_attempt_bloc/reading_attempt_bloc.dart';
import '../../feature/speaking/bloc/speaking_bloc.dart';
import '../../feature/speaking/speaking_lesson_bloc/speaking_lesson_bloc.dart';
import '../../feature/vocabulary/bloc_review/review_bloc.dart';
import '../api/api_client.dart';
import '../datasource/admin_remote_datasource.dart';
import '../datasource/ai_chat_remote_datasource.dart';
import '../datasource/app_update_remote_datasource.dart';
import '../datasource/app_release_admin_remote_datasource.dart';
import '../datasource/teacher_exam_remote_datasource.dart';
import '../datasource/admin_teacher_application_remote_datasource.dart';
import '../datasource/dictionary_local_datasource.dart';
import '../datasource/history_remote_datasource.dart';
import '../datasource/listening_comp_remote_datasource.dart';
import '../datasource/listening_remote_datasource.dart';
import '../datasource/notification_remote_datasource.dart';
import '../datasource/progress_remote_datasource.dart';
import '../datasource/reading_remote_datasource.dart';
import '../datasource/report_remote_datasource.dart';
import '../datasource/speaking_remote_datasource.dart';
import '../datasource/user_remote_datasource.dart';
import '../datasource/auth_remote_datasource.dart';
import '../datasource/user_vocab_remote_datasource.dart';
import '../datasource/writing_remote_datasource.dart';
import '../repository/admin_repository.dart';
import '../repository/ai_chat_repository.dart';
import '../repository/auth_repository.dart';
import '../repository/app_update_repository.dart';
import '../repository/app_release_repository.dart';
import '../repository/teacher_exam_repository.dart';
import '../repository/admin_teacher_application_repository.dart';
import '../repository/dictionary_repository.dart';
import '../repository/history_repository.dart';
import '../repository/listening_comp_repository.dart';
import '../repository/listening_repository.dart';
import '../repository/notification_repository.dart';
import '../repository/progress_repository.dart';
import '../repository/reading_repository.dart';
import '../repository/report_repository.dart';
import '../repository/speaking_repository.dart';
import '../repository/user_repository.dart';
import '../repository/user_vocab_repository.dart';
import '../repository_impl/admin_repository_impl.dart';
import '../repository_impl/ai_chat_repository_impl.dart';
import '../repository_impl/app_update_repository_impl.dart';
import '../repository_impl/app_release_repository_impl.dart';
import '../repository_impl/teacher_exam_repository_impl.dart';
import '../repository_impl/admin_teacher_application_repository_impl.dart';
import '../repository_impl/auth_repository_impl.dart';
import '../repository_impl/dictionary_repository_impl.dart';
import '../repository_impl/history_repository_impl.dart';
import '../repository_impl/listening_comp_repository_impl.dart';
import '../repository_impl/listening_repository_impl.dart';
import '../repository_impl/notification_repository_impl.dart';
import '../repository_impl/progress_repository_impl.dart';
import '../repository_impl/reading_repository_impl.dart';
import '../repository_impl/report_repository_impl.dart';
import '../repository_impl/speaking_repository_impl.dart';
import '../repository_impl/user_repository_impl.dart';
import '../../feature/auth/bloc/user_bloc.dart';
import '../repository_impl/user_vocab_repository_impl.dart';
import '../repository_impl/writing_repository_impl.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_bloc.dart';
import '../../feature/student/bloc/classes_hub/student_classes_hub_bloc.dart';
import '../../feature/student/bloc/classroom_detail/student_classroom_detail_bloc.dart';
import '../../feature/teacher/bloc/analytics/teacher_analytics_bloc.dart';
import '../../feature/teacher/bloc/live_monitor/teacher_live_monitor_bloc.dart';
import '../../feature/teacher/bloc/apply/teacher_apply_bloc.dart';
import '../../feature/teacher/bloc/classroom/teacher_classroom_bloc.dart';
import '../../feature/teacher/bloc/dashboard/teacher_dashboard_bloc.dart';
import '../../feature/teacher/bloc/exams_list/teacher_exams_list_bloc.dart';
import '../../feature/teacher/bloc/grading_hub/teacher_grading_hub_bloc.dart';
import '../socket/socket_service.dart';
import '../locale/app_locale_controller.dart';

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
  getIt.registerSingleton<AppLocaleController>(AppLocaleController());
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
  getIt.registerSingleton<ReportRemoteDatasource>(
    ReportRemoteDatasource(dio: dioAuth),
  );
  getIt.registerSingleton<NotificationRemoteDataSource>(
    NotificationRemoteDataSource(dio: dioAuth),
  );
  getIt.registerSingleton<AppUpdateRemoteDatasource>(
    AppUpdateRemoteDatasource(dio: dioPublic),
  );
  getIt.registerSingleton<AppReleaseAdminRemoteDatasource>(
    AppReleaseAdminRemoteDatasource(dio: dioAuth),
  );
  getIt.registerSingleton<TeacherExamRemoteDatasource>(
    TeacherExamRemoteDatasource(dio: dioAuth),
  );
  getIt.registerSingleton<AdminTeacherApplicationRemoteDatasource>(
    AdminTeacherApplicationRemoteDatasource(dio: dioAuth),
  );
  getIt.registerLazySingleton<HistoryRemoteDatasource>(
      () => HistoryRemoteDatasource(dio: dioAuth));
  getIt.registerSingleton<ListeningCompRemoteDatasource>(
    ListeningCompRemoteDatasource(dio: dioAuth),
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
    AdminRepositoryImpl(
        adminRemoteDatasource: getIt(), reportRemoteDatasource: getIt()),
  );
  getIt.registerSingleton<ReportRepository>(
    ReportRepositoryImpl(reportRemoteDatasource: getIt()),
  );
  getIt.registerSingleton<NotificationRepository>(
    NotificationRepositoryImpl(dataSource: getIt()),
  );
  getIt.registerSingleton<AppUpdateRepository>(
    AppUpdateRepositoryImpl(remoteDatasource: getIt()),
  );
  getIt.registerSingleton<AppReleaseRepository>(
    AppReleaseRepositoryImpl(datasource: getIt()),
  );
  getIt.registerSingleton<TeacherExamRepository>(
    TeacherExamRepositoryImpl(remote: getIt()),
  );
  getIt.registerSingleton<AdminTeacherApplicationRepository>(
    AdminTeacherApplicationRepositoryImpl(remote: getIt()),
  );
  getIt.registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(historyRemoteDatasource: getIt()));
  getIt.registerSingleton<ListeningCompRepository>(
    ListeningCompRepositoryImpl(datasource: getIt()),
  );
}

void registerBloc() {
  getIt.registerLazySingleton<UserBloc>(() => UserBloc(
        authRepository: getIt(),
        userRepository: getIt(),
      ));
  getIt.registerFactory(() => ListeningBloc(listeningRepository: getIt()));
  getIt.registerFactory(() => CueBloc(listeningRepository: getIt()));
  getIt.registerFactory(() => WritingBloc(writingRepository: getIt()));
  getIt.registerFactory(() => SpeakingBloc(speakingRepository: getIt()));
  getIt.registerFactory(() => SpeakingLessonBloc(speakingRepository: getIt()));
  getIt.registerFactory(() => ReadingBloc(readingRepository: getIt()));
  getIt.registerFactory(() => ReadingAttemptBloc(readingRepository: getIt()));
  getIt.registerFactory(() => VocabularyBloc(userVocabRepository: getIt()));
  getIt.registerFactory(() => ReviewBloc(userVocabRepository: getIt()));
  getIt.registerFactory(() => ProgressBloc(progressRepository: getIt()));
  getIt.registerLazySingleton<AiChatBloc>(
    () => AiChatBloc(aiChatRepository: getIt()),
  );
  getIt.registerFactory(() => AdminBloc(adminRepository: getIt()));
  getIt.registerFactory(() => AdminReadingBloc(getIt<ReadingRepository>()));
  getIt.registerFactory(() => AdminListeningBloc(getIt<ListeningRepository>()));
  getIt.registerFactory(() => AdminSpeakingBloc(getIt<SpeakingRepository>()));
  getIt.registerFactory(() => ReportBloc(reportRepository: getIt()));
  getIt.registerFactory(() => AdminWritingBloc(getIt<WritingRepository>()));
  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(repository: getIt()),
  );
  getIt.registerLazySingleton<AppUpdateBloc>(
    () => AppUpdateBloc(repository: getIt()),
  );
  getIt.registerFactory(
    () => ReleaseManagementBloc(repository: getIt()),
  );
  getIt.registerFactory(() => HistoryBloc(historyRepository: getIt()));
  getIt
      .registerFactory(() => MyExerciseHistoryBloc(historyRepository: getIt()));
  getIt.registerFactory(() => ListeningCompListBloc(repository: getIt()));
  getIt.registerFactory(() => ListeningCompBloc(repo: getIt()));
  getIt.registerFactory(() => AdminListeningCompBloc(repository: getIt()));
  getIt.registerFactory(() => TeacherDashboardBloc(repository: getIt()));
  getIt.registerFactory(() => TeacherExamsListBloc(repository: getIt()));
  getIt.registerFactory(() => TeacherApplyBloc(repository: getIt()));
  getIt.registerFactory(() => TeacherAnalyticsBloc(repository: getIt()));
  getIt.registerFactoryParam<TeacherClassroomBloc, String, void>(
    (classroomId, _) => TeacherClassroomBloc(
      repository: getIt(),
      classroomId: classroomId,
    ),
  );
  getIt.registerFactoryParam<TeacherGradingHubBloc, String, void>(
    (assignmentId, _) => TeacherGradingHubBloc(
      repository: getIt(),
      assignmentId: assignmentId,
    ),
  );
  getIt.registerFactoryParam<TeacherLiveMonitorBloc, String, void>(
    (sessionId, _) => TeacherLiveMonitorBloc(
      repository: getIt(),
      socketService: getIt(),
      sessionId: sessionId,
    ),
  );
  getIt.registerFactory(() => StudentClassesHubBloc(repository: getIt()));
  getIt.registerFactoryParam<StudentClassroomDetailBloc, String, void>(
    (classroomId, _) => StudentClassroomDetailBloc(
      repository: getIt(),
      classroomId: classroomId,
    ),
  );
}
