import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:rive/rive.dart' as rive;

import 'core/api/api_config.dart';
import 'core/debug/app_bloc_observer.dart';
import 'core/debug/app_global_error_hooks.dart';
import 'core/get_it/get_it.dart';
import 'core/locale/app_locale_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/notification/local_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/router/configure_web_url_strategy.dart';
import 'core/sqflite/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/e4c_scroll_behavior.dart';
import 'core/ui/motion/app_lottie_cache.dart';

// 1. Import Widget quản lý vòng đời Socket
import 'core/notification/app_notification_listener.dart';
import 'core/socket/socket_lifecycle_manager.dart';

import 'feature/auth/bloc/user_bloc.dart';
import 'feature/auth/bloc/user_event.dart';
import 'feature/app_update/bloc/app_update_bloc.dart';
import 'feature/app_update/app_update_guard.dart';
import 'firebase_options.dart';

/// Handler chạy ở ISOLATE NỀN khi app ở background/bị kill (bắt buộc top-level +
/// vm:entry-point). Với message có sẵn khối `notification`, Android tự hiển thị ở
/// khay nên không cần làm gì thêm; nếu sau này gửi data-only thì hiển thị thủ công tại đây.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 [FCM BG] ${message.messageId} type=${message.data['type']}');
}

Future<void> main() async {
  await runAppWithErrorZone(() async {
    WidgetsFlutterBinding.ensureInitialized();
    installAppGlobalErrorHooks();
    Bloc.observer = AppBlocObserver();
    await rive.RiveNative.init();
    configureWebUrlStrategy();
    await NotificationService.I.init();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Đăng ký handler nền NGAY sau khi init Firebase (trước runApp).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await ApiConfig.init();
    if (kDebugMode) {
      debugPrint('[ApiConfig] API base: ${ApiConfig.Base_URL}');
    }
    setup(); // Khởi tạo Dependency Injection (GetIt)
    //await DictDb.I.db;
    //NotificationService.I.scheduleDaily9AMNotification();
    await LocalNotificationService().init();
    await getIt<AppLocaleController>().load();
    runApp(MyApp());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLottieCache.warmUp();
    });
  });
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
            title: 'E4C',
            theme: AppTheme.getTheme(),
            scrollBehavior: kIsWeb
                ? const E4cNoScrollbarScrollBehavior()
                : const E4cScrollBehavior(),
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
                  child: AppNotificationListener(
                    child: FAnimatedTheme(
                      data: fTheme,
                      child: child ?? const SizedBox.shrink(),
                    ),
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
