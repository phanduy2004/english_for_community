import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import 'core/get_it/get_it.dart';
import 'core/locale/app_locale_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/notification/local_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/sqflite/notification_service.dart';
import 'core/theme/app_theme.dart';

// 1. Import Widget quản lý vòng đời Socket
import 'core/socket/socket_lifecycle_manager.dart';

import 'feature/auth/bloc/user_bloc.dart';
import 'feature/auth/bloc/user_event.dart';
import 'feature/app_update/bloc/app_update_bloc.dart';
import 'feature/app_update/app_update_guard.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.I.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setup(); // Khởi tạo Dependency Injection (GetIt)
  //await DictDb.I.db;
  //NotificationService.I.scheduleDaily9AMNotification();
  await LocalNotificationService().init();
  await getIt<AppLocaleController>().load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = getIt<AppLocaleController>();
    return ListenableBuilder(
      listenable: localeCtrl,
      builder: (context, _) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              // ✅ Báo cho BLoC kiểm tra auth ngay khi app khởi động
              // UserBloc sẽ phát ra state, và SocketLifecycleManager sẽ lắng nghe state này
              value: getIt<UserBloc>()..add(CheckAuthStatusEvent()),
            ),
            BlocProvider.value(value: getIt<AppUpdateBloc>()),
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'LearnLingo',
            theme: AppTheme.getTheme(),
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.router,

            locale: localeCtrl.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...FLocalizations.localizationsDelegates,
            ],

            // 🔥 QUAN TRỌNG: Tích hợp SocketLifecycleManager vào Builder 🔥
            builder: (context, child) {
              final brightness = MediaQuery.platformBrightnessOf(context);
              final fTheme = (brightness == Brightness.dark)
                  ? FThemes.zinc.dark
                  : FThemes.zinc.light;

              // Bọc App bằng SocketLifecycleManager để nó tồn tại xuyên suốt
              // Nó sẽ tự động connect/disconnect socket dựa trên UserBloc
              // Và lắng nghe sự kiện "Force Logout" toàn cục
              return AppUpdateGuard(
                child: SocketLifecycleManager(
                  child: FAnimatedTheme(
                    data: fTheme,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
