import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../feature/auth/bloc/user_bloc.dart';
import '../../feature/auth/bloc/user_state.dart';
import '../../feature/auth/bloc/user_event.dart';
import '../utils/global_keys.dart';

class SocketLifecycleManager extends StatefulWidget {
  final Widget child;
  const SocketLifecycleManager({super.key, required this.child});

  @override
  State<SocketLifecycleManager> createState() => _SocketLifecycleManagerState();
}

class _SocketLifecycleManagerState extends State<SocketLifecycleManager> {

  // Hàm xử lý logic khi bị Ban
  void _setupForceLogoutListener() {
    GetIt.I<SocketService>().listenToForceLogout((reason) {
      print("🚨 [Global Socket] Received Ban Signal: $reason");

      // 1. Ngắt kết nối Socket ngay lập tức để không nhận tin nữa
      GetIt.I<SocketService>().disconnect();

      // 2. 🔥 XÓA TOKEN NGAY LẬP TỨC (QUAN TRỌNG) 🔥
      // Nếu người dùng reload app ngay lúc này, họ sẽ bị đá ra Login vì token đã mất.
      // Nhưng KHÔNG chuyển trang ngay để còn hiện Dialog.
      GetIt.I<UserBloc>().add(ClearUserDataEvent());

      // 3. Hiện Dialog thông báo
      final context = rootNavigatorKey.currentContext;

      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false, // Chặn không cho bấm ra ngoài
          builder: (ctx) => PopScope(
            canPop: false, // Chặn nút Back của Android
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: const [
                  Icon(Icons.block_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text('Tài khoản bị khóa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Phiên đăng nhập của bạn đã bị chấm dứt.", style: TextStyle(fontWeight: FontWeight.w500)),
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
                        const Text("Lý do:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
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
                      // 4. 🔥 KHI NGƯỜI DÙNG BẤM NÚT -> MỚI CHUYỂN TRANG 🔥
                      Navigator.of(ctx).pop(); // Đóng Dialog

                      // Gọi lệnh đăng xuất (Chuyển state -> GoRouter tự chuyển về Login)
                      GetIt.I<UserBloc>().add(SignOutEvent());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Đồng ý & Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      } else {
        // Fallback: Nếu không lấy được context (hiếm gặp), thì đành logout luôn
        GetIt.I<UserBloc>().add(SignOutEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái User để quản lý kết nối Socket
    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        // Khi đăng nhập thành công
        if (state.status == UserStatus.success && state.userEntity != null) {
          print("🌐 [Global Socket] User Authenticated");
          GetIt.I<SocketService>().userLogin(state.userEntity!.id);

          // Đăng ký lắng nghe sự kiện Ban
          _setupForceLogoutListener();
        }
        // Khi đăng xuất
        else if (state.status == UserStatus.unauthenticated) {
          print("🔌 [Global Socket] User Logout -> Disconnect");
          GetIt.I<SocketService>().disconnect();
        }
      },
      child: widget.child,
    );
  }
}