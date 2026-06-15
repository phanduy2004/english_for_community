import 'package:english_for_community/core/get_it/get_it.dart' as di;

import 'package:english_for_community/core/repository/classroom_chat_repository.dart';

import 'package:english_for_community/core/socket/socket_service.dart';

import 'package:english_for_community/core/theme/app_color.dart';

import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_bloc.dart';

import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_event.dart';
import 'package:english_for_community/feature/classroom_chat/bloc/classroom_chat_state.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_settings_menu.dart';

import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_app_bar.dart';

import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_body.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';



class ClassroomChatPage extends StatelessWidget {

  const ClassroomChatPage({

    super.key,

    required this.classroomId,

    required this.classroomName,

    required this.currentUserId,

    this.coverImageUrl,

  });



  final String classroomId;

  final String classroomName;

  final String currentUserId;

  final String? coverImageUrl;



  static const routePath = '/classroom-chat';

  static const routeName = 'ClassroomChatPage';



  static String routePathFor(String classroomId) =>

      '/teacher/classroom/$classroomId/chat';

  static String studentRoutePath(String classroomId) =>
      '/student/classroom/$classroomId/chat';

  static const studentRouteName = 'StudentClassroomChatPage';



  @override

  Widget build(BuildContext context) {

    if (!di.getIt.isRegistered<ClassroomChatRepository>()) {

      return Scaffold(

        backgroundColor: AppColors.surface,

        appBar: AppBar(title: Text(classroomName)),

        body: const Center(

          child: Padding(

            padding: EdgeInsets.all(24),

            child: Text(

              'Chat chưa sẵn sàng. Hãy dừng app và chạy lại (Stop → Run), không chỉ hot reload.',

              textAlign: TextAlign.center,

            ),

          ),

        ),

      );

    }



    return BlocProvider(

      create: (_) => ClassroomChatBloc(
        classroomId: classroomId,
        currentUserId: currentUserId,
        repo: di.getIt<ClassroomChatRepository>(),
        socket: di.getIt<SocketService>(),
        initialCoverImageUrl: coverImageUrl,
        initialGroupName: classroomName,
      )..add(const ClassroomChatLoaded()),

      child: _ClassroomChatScaffold(

        classroomId: classroomId,

        classroomName: classroomName,

        currentUserId: currentUserId,

      ),

    );

  }

}



class _ClassroomChatScaffold extends StatefulWidget {

  const _ClassroomChatScaffold({

    required this.classroomId,

    required this.classroomName,

    required this.currentUserId,

  });



  final String classroomId;

  final String classroomName;

  final String currentUserId;



  @override

  State<_ClassroomChatScaffold> createState() => _ClassroomChatScaffoldState();

}



class _ClassroomChatScaffoldState extends State<_ClassroomChatScaffold> {

  bool _settingsOpen = false;



  Future<void> _openSettings(BuildContext context) async {

    final members = context.read<ClassroomChatBloc>().state.members;

    setState(() => _settingsOpen = true);

    await ChatSettingsSheet.show(

      context,

      members: members,

      classroomName: widget.classroomName,

      currentUserId: widget.currentUserId,

    );

    if (mounted) setState(() => _settingsOpen = false);

  }



  @override

  Widget build(BuildContext context) {

    return BlocListener<ClassroomChatBloc, ClassroomChatState>(
      listenWhen: (p, c) => p.isUpdatingSettings && !c.isUpdatingSettings,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppCornerToast.show(context, state.errorMessage!, error: true);
        } else {
          AppCornerToast.show(context, 'Đã lưu cài đặt nhóm');
        }
      },
      child: Scaffold(

      resizeToAvoidBottomInset: true,

      backgroundColor: AppColors.surface,

      body: SafeArea(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            BlocBuilder<ClassroomChatBloc, ClassroomChatState>(

              buildWhen: (p, c) =>
                  p.members.length != c.members.length ||
                  p.groupName != c.groupName ||
                  p.coverImageUrl != c.coverImageUrl ||
                  p.isUpdatingSettings != c.isUpdatingSettings,

              builder: (context, state) {

                final count = state.members.length;

                final subtitle = count > 0 ? '$count thành viên · Nhóm lớp học' : 'Nhóm lớp học';
                final isOwner = state.isClassOwner(widget.currentUserId);

                return ClassroomChatHeader(

                  title: state.displayName(widget.classroomName),

                  subtitle: subtitle,

                  coverImageUrl: state.coverImageUrl,

                  settingsOpen: _settingsOpen,

                  leading: const BackButton(),

                  onTitleTap: () => _openSettings(context),

                  onCoverTap: isOwner
                      ? () => ChatGroupAvatarPicker.pickAndUpload(context)
                      : null,

                  coverUploading: state.isUpdatingSettings,

                );

              },

            ),

            Expanded(

              child: ClipRect(

                child: ClassroomChatBody(
                  classroomId: widget.classroomId,
                  classroomName: widget.classroomName,
                  currentUserId: widget.currentUserId,
                  highlightTeacherMessages: true,
                ),

              ),

            ),

          ],

        ),

      ),

      ),
    );

  }

}


