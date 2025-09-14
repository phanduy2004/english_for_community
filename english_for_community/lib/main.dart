// main.dart
import 'package:english_for_community/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/get_it/get_it.dart';
import 'core/theme/app_theme.dart';
import 'feature/auth/bloc/user_bloc.dart';
import 'feature/auth/bloc/user_state.dart';
import 'feature/auth/login_page.dart';

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
        providers: [
          // 👇 CẤP UserBloc CHO TOÀN APP (root)
          BlocProvider(create: (_) => getIt<UserBloc>()),
        ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        builder: (context, widget) {
          return BlocListener<UserBloc, UserState>(
            listener: (context, state) {
              if (state.status == UserStatus.error ||
                  state.status == UserStatus.logout) {
                AppRouter.router.goNamed(LoginPage.routeName);
              }
            },
            child: Center(child: widget),
          );
        },
        title: 'LearnLingo',
        theme: AppTheme.getTheme(),   // dùng theme chung của bạn
        routerConfig: AppRouter.router,
      ),
    );
  }
}
