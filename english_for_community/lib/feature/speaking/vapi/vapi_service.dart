// feature/speaking/vapi/vapi_service.dart

import 'dart:async';

enum VapiCallStatus { disconnected, connecting, active, ended }

class VapiEvent {
  final String type;
  final dynamic value;
  final Map<String, dynamic>? data;

  VapiEvent({required this.type, this.value, this.data});
}

class VapiVoice {
  final String id;
  final String name;
  final String gender;
  final String provider;
  final String accent;

  const VapiVoice({
    required this.id,
    required this.name,
    required this.gender,
    this.provider = '11labs',
    this.accent = 'US',
  });
}

abstract class VapiService {
  Stream<VapiEvent> get onEvent;
  List<VapiVoice> getAvailableVoices();
  Future<void> start({String? voiceId}); // start nhận voiceId
  Future<void> stop();
  Future<void> sendMessage(String text);
  void dispose();
}