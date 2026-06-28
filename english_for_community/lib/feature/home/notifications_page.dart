import 'package:english_for_community/feature/home/notification_dialog.dart';
import 'package:english_for_community/feature/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Deeplink target for `/notifications` — opens the shared dialog, then returns home.
class NotificationsPage extends StatefulWidget {
  static const String routeName = 'NotificationsPage';
  static const String routePath = '/notifications';

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAppNotificationsDialog(context);
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(HomePage.routePath);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
