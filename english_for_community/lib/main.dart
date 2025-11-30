import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import 'core/get_it/get_it.dart';
import 'core/notification/local_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/sqflite/notification_service.dart';
import 'core/theme/app_theme.dart';

// 1. Import Widget quản lý vòng đời Socket
import 'core/socket/socket_lifecycle_manager.dart';

import 'feature/auth/bloc/user_bloc.dart';
import 'feature/auth/bloc/user_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.I.init();

  setup(); // Khởi tạo Dependency Injection (GetIt)

  //NotificationService.I.scheduleDaily9AMNotification();
  await LocalNotificationService().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          // ✅ Báo cho BLoC kiểm tra auth ngay khi app khởi động
          // UserBloc sẽ phát ra state, và SocketLifecycleManager sẽ lắng nghe state này
          value: getIt<UserBloc>()..add(CheckAuthStatusEvent()),
        )
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'LearnLingo',
        theme: AppTheme.getTheme(),
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,

        supportedLocales: FLocalizations.supportedLocales,
        localizationsDelegates: const [...FLocalizations.localizationsDelegates],

        // 🔥 QUAN TRỌNG: Tích hợp SocketLifecycleManager vào Builder 🔥
        builder: (context, child) {
          final brightness = MediaQuery.platformBrightnessOf(context);
          final fTheme = (brightness == Brightness.dark)
              ? FThemes.zinc.dark
              : FThemes.zinc.light;

          // Bọc App bằng SocketLifecycleManager để nó tồn tại xuyên suốt
          // Nó sẽ tự động connect/disconnect socket dựa trên UserBloc
          // Và lắng nghe sự kiện "Force Logout" toàn cục
          return SocketLifecycleManager(
            child: FAnimatedTheme(
              data: fTheme,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}