// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/get_it/get_it.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'feature/auth/bloc/user_bloc.dart';
import 'feature/auth/bloc/user_state.dart';
import 'feature/auth/login_page.dart';

// ⬇ forui 0.16.x
import 'package:forui/forui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setup();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => getIt<UserBloc>())],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'LearnLingo',
        theme: AppTheme.getTheme(),
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,

        // ✅ forui: locales & delegates (khuyến nghị thêm)
        supportedLocales: FLocalizations.supportedLocales,
        localizationsDelegates: const [...FLocalizations.localizationsDelegates],

        // ✅ Bọc FAnimatedTheme ngay trong builder
        builder: (context, child) {
          // Chọn theme forui theo hệ thống
          final brightness = MediaQuery.platformBrightnessOf(context);
          final fTheme = (brightness == Brightness.dark)
              ? FThemes.zinc.dark
              : FThemes.zinc.light;

          return FAnimatedTheme(
            data: fTheme,
            child: BlocListener<UserBloc, UserState>(
              listener: (context, state) {
                if (state.status == UserStatus.error ||
                    state.status == UserStatus.logout) {
                  AppRouter.router.goNamed(LoginPage.routeName);
                }
              },
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
