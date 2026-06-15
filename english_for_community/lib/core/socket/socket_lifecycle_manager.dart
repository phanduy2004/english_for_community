import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_state.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../../feature/classroom_chat/dock/classroom_chat_dock_controller.dart';
import '../utils/global_keys.dart';
import '../../l10n/generated/app_localizations.dart';

class SocketLifecycleManager extends StatefulWidget {
  final Widget child;
  const SocketLifecycleManager({super.key, required this.child});

  @override
  State<SocketLifecycleManager> createState() => _SocketLifecycleManagerState();
}

class _SocketLifecycleManagerState extends State<SocketLifecycleManager> {

  // Logic to handle forced logout (Ban)
  void _setupForceLogoutListener() {
    GetIt.I<SocketService>().listenToForceLogout((reason) {
      print("🚨 [Global Socket] Received Ban Signal: $reason");

      // 1. Disconnect Socket immediately to stop receiving messages
      GetIt.I<SocketService>().disconnect();

      // 2. 🔥 CLEAR TOKEN IMMEDIATELY (IMPORTANT) 🔥
      // If the user reloads the app now, they will be sent to Login because the token is gone.
      // But DO NOT navigate yet, keep the Dialog visible.
      GetIt.I<UserBloc>().add(ClearUserDataEvent());

      // 3. Show Alert Dialog
      final context = rootNavigatorKey.currentContext;

      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (ctx) {
            final t = AppLocalizations.of(ctx)!;
            return PopScope(
            canPop: false, // Prevent Android Back button
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  const Icon(Icons.block_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t.accountSuspendedTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.accountSessionTerminated, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2), // Red-50
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)), // Red-200
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.suspensionReasonLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                        const SizedBox(height: 4),
                        Text(reason, style: const TextStyle(fontSize: 14, color: Color(0xFF7F1D1D))),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // 4. 🔥 ONLY NAVIGATE WHEN USER CLICKS BUTTON 🔥
                      Navigator.of(ctx).pop(); // Close Dialog

                      // Trigger Sign Out (Updates state -> GoRouter redirects to Login)
                      GetIt.I<UserBloc>().add(SignOutEvent());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(t.agreeAndLogout, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
          },
        );
      } else {
        // Fallback: If context is unavailable (rare), force logout immediately
        GetIt.I<UserBloc>().add(SignOutEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to User state to manage Socket connection
    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        // On Login Success
        if (state.status == UserStatus.success && state.userEntity != null) {
          print("🌐 [Global Socket] User Authenticated");
          GetIt.I<SocketService>().userLogin(state.userEntity!.id);

          registerClassroomChatDockController();
          final dock = GetIt.I<ClassroomChatDockController>();
          dock.detachInboxSocket();
          dock.attachInboxSocket();
          dock.refreshInboxBadge();

          // Setup Ban listener
          _setupForceLogoutListener();
        }
        // On Logout
        else if (state.status == UserStatus.unauthenticated) {
          print("🔌 [Global Socket] User Logout -> Disconnect");
          registerClassroomChatDockController();
          GetIt.I<ClassroomChatDockController>().detachInboxSocket();
          GetIt.I<SocketService>().disconnect();
        }
      },
      child: widget.child,
    );
  }
}