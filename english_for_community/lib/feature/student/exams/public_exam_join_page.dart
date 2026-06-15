import 'package:english_for_community/feature/student/classes/my_classes_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy route — unified join lives on [MyClassesHubPage].
class PublicExamJoinPage extends StatelessWidget {
  const PublicExamJoinPage({super.key});

  static const String routePath = '/student/exams/join';
  static const String routeName = 'PublicExamJoinPage';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(MyClassesHubPage.routePath);
    });
    return const Scaffold(body: SizedBox.shrink());
  }
}
