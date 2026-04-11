// feature/speaking/vapi/real_vapi_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vapi/vapi.dart' as vapi_sdk;
import 'vapi_service.dart';

class RealVapiService implements VapiService {
  /// [vapiAssistantId] = ID assistant trên dashboard Vapi (không trùng tên với [VapiEnvConfig.assistantId] để tránh nhầm khi analyze).
  RealVapiService({
    required String publicKey,
    required String vapiAssistantId,
  })  : _publicKey = publicKey.trim(),
        _assistantId = vapiAssistantId.trim();

  final String _publicKey;
  final String _assistantId;

  vapi_sdk.VapiClient? _client;
  vapi_sdk.VapiCall? _currentCall;
  final _controller = StreamController<VapiEvent>.broadcast();

  bool get isConfigured =>
      _publicKey.isNotEmpty && _assistantId.isNotEmpty;

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
    if (!isConfigured) {
      _emit(
        type: 'error',
        data: {
          'code': 'missing_config',
          'message': 'Missing Vapi configuration.',
        },
      );
      _emit(type: 'status', value: VapiCallStatus.disconnected);
      return;
    }

    _emit(type: 'status', value: VapiCallStatus.connecting);
    try {
      _client ??= vapi_sdk.VapiClient(_publicKey);

      Map<String, dynamic> overrides = {};
      if (voiceId != null && voiceId.isNotEmpty && voiceId != "default") {
        overrides = {
          "voice": {
            "provider": "11labs",
            "voiceId": voiceId,
          }
        };
      }

      final call = _client!;
      _currentCall = await call.start(
        assistantId: _assistantId,
        assistantOverrides: overrides,
      );

      _currentCall?.setMuted(false);

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
    } catch (e, st) {
      debugPrint('Vapi start error: $e\n$st');
      _emit(
        type: 'error',
        data: {
          'code': 'start_failed',
          'message': e.toString(),
        },
      );
      _emit(type: 'status', value: VapiCallStatus.disconnected);
    }
  }

  @override
  Future<void> sendMessage(String text) async {
    if (_currentCall == null) {
      _emit(
        type: 'error',
        data: {
          'code': 'not_connected',
          'message': 'No active call.',
        },
      );
      return;
    }
    try {
      _currentCall!.send({
        "type": "add-message",
        "message": {"role": "user", "content": text}
      });
      _emit(type: 'transcript', data: {'text': text, 'role': 'user', 'isFinal': true});
    } catch (e) {
      _emit(
        type: 'error',
        data: {
          'code': 'send_failed',
          'message': e.toString(),
        },
      );
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
    _client?.dispose();
    _controller.close();
  }

  void _emit({required String type, dynamic value, Map<String, dynamic>? data}) {
    if (!_controller.isClosed) {
      _controller.add(VapiEvent(type: type, value: value, data: data));
    }
  }
}
