// feature/speaking/vapi/real_vapi_service.dart

import 'dart:async';
import 'package:vapi/vapi.dart' as vapi_sdk;
import 'vapi_service.dart';

class RealVapiService implements VapiService {
  final String publicKey = "16a74697-fbd2-4ae9-8f3e-aa84e7f23e64";
  final String assistantId = "3e7ab5e0-eeb9-4d1c-a0f5-18a601319d25";

  late final vapi_sdk.VapiClient _client;
  vapi_sdk.VapiCall? _currentCall;
  final _controller = StreamController<VapiEvent>.broadcast();

  RealVapiService() {
    _client = vapi_sdk.VapiClient(publicKey);
  }

  @override
  List<VapiVoice> getAvailableVoices() {
    return const [
      VapiVoice(id: "", name: "Default (Assistant)", gender: "AI", accent: "Default"),
      VapiVoice(id: "21m00Tcm4TlvDq8ikWAM", name: "Rachel", gender: "Female", accent: "US"),
      VapiVoice(id: "29vD33N1CtxCmqQRPOHJ", name: "Drew", gender: "Male", accent: "US"),
      VapiVoice(id: "AZnzlk1XvdvUeBnXmlld", name: "Domi", gender: "Female", accent: "US"),
      VapiVoice(id: "ErXwobaYiN019PkySvjV", name: "Antoni", gender: "Male", accent: "US"),
      VapiVoice(id: "TxGEqnHWrfWFTfGW9XjX", name: "Josh", gender: "Male", accent: "US"),
      VapiVoice(id: "EXAVITQu4vr4xnSDxMaL", name: "Bella", gender: "Female", accent: "US"),
    ];
  }

  @override
  Stream<VapiEvent> get onEvent => _controller.stream;

  @override
  Future<void> start({String? voiceId}) async {
    _emit(type: 'status', value: VapiCallStatus.connecting);
    try {
      // ⭐️ FIX: Khởi tạo là Map rỗng {} (Không dùng null)
      Map<String, dynamic> overrides = {};

      // 1. CHỈ thêm cấu hình Voice nếu có ID hợp lệ
      if (voiceId != null && voiceId.isNotEmpty && voiceId != "default") {
        print("🔹 Changing Voice to: $voiceId");
        overrides = {
          "voice": {
            "provider": "11labs",
            "voiceId": voiceId,
          }
        };
      } else {
        print("🔹 Using Default Assistant Voice");
      }

      print("Vapi Config Payload: $overrides");

      // 2. Bắt đầu cuộc gọi
      _currentCall = await _client.start(
        assistantId: assistantId,
        assistantOverrides: overrides, // Bây giờ biến này là non-nullable Map
      );

      _currentCall?.setMuted(false);

      // ... (Phần lắng nghe sự kiện giữ nguyên như cũ)
      _currentCall?.onEvent.listen((vapi_sdk.VapiEvent event) {
        final label = event.label;
        final value = event.value;
        if (label == "call-start") {
          _emit(type: 'status', value: VapiCallStatus.active);
        } else if (label == "call-end") {
          _emit(type: 'status', value: VapiCallStatus.ended);
          _currentCall = null;
        } else if (label == "message") {
          _handleMessage(value);
        }
      });

    } catch (e) {
      print("🔴 Error Vapi Start: $e");
      _emit(type: 'status', value: VapiCallStatus.disconnected);
    }
  }

  @override
  Future<void> sendMessage(String text) async {
    if (_currentCall == null) return;
    try {
      _currentCall!.send({
        "type": "add-message",
        "message": {"role": "user", "content": text}
      });
      // Tự hiển thị tin nhắn người dùng lên UI
      _emit(type: 'transcript', data: {'text': text, 'role': 'user', 'isFinal': true});
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void _handleMessage(dynamic message) {
    if (message is! Map) return;
    final type = message['type'];

    if (type == 'transcript') {
      _emit(type: 'transcript', data: {
        'text': message['transcript'],
        'role': message['role'] ?? 'ai',
        'isFinal': message['transcriptType'] == 'final',
      });
    } else if (type == 'speech-update') {
      final status = message['status'];
      final role = message['role'] ?? 'ai';
      if (status == 'started') _emit(type: 'speech_start', data: {'role': role});
      else if (status == 'stopped') _emit(type: 'speech_end', data: {'role': role});
    }
  }

  @override
  Future<void> stop() async {
    await _currentCall?.stop();
    _currentCall = null;
    _emit(type: 'status', value: VapiCallStatus.ended);
  }

  @override
  void dispose() {
    stop();
    _client.dispose();
    _controller.close();
  }

  void _emit({required String type, dynamic value, Map<String, dynamic>? data}) {
    if (!_controller.isClosed) {
      _controller.add(VapiEvent(type: type, value: value, data: data));
    }
  }
}