// lib/services/facenet_service.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:recognize_face/services/facenet_service/face_dataset_repository_v2.dart';
import 'package:recognize_face/utils/vision_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../utils/values.dart';
import 'package:flutter/material.dart'; // để dùng Rect

// ======= Global State =======
SendPort? _workerPort;
bool _isInitialized = false;
Map<String, List<List<double>>> _embeddings = {};
FaceDatasetRepositorySqlite repositorySqlite = FaceDatasetRepositorySqlite();

// ======= Public API =======

Future<void> initFaceNet() async {
  if (_isInitialized) return;

  debugPrint('🔄 Initializing FaceNet...');
  await loadEmbeddings();

  // Start worker isolate
  _workerPort = await _startWorker();

  // Initialize model in worker
  await _workerInit(_workerPort!, 'assets/models/facenet_david.tflite');

  _isInitialized = true;
  debugPrint('✅ FaceNet initialized');
}

Future<void> loadEmbeddings() async {
  try {
    final db = <String, List<List<double>>>{};
    final users = await repositorySqlite.listUsers();
    for (final u in users) {
      final name = (u['name'] ?? '').toString();
      if (name.isEmpty) continue;
      final embs = await repositorySqlite.getEmbeddingsByName(name);
      if (embs.isNotEmpty) db[name] = embs;
    }
    _embeddings = _deepCopy(db);
    debugPrint('✅ Embeddings loaded: ${db.length} users');
  } catch (e) {
    debugPrint('❌ Error loading embeddings from sqlite: $e');
    _embeddings = {};
  }
}

Map<String, List<List<double>>> _deepCopy(Map<String, List<List<double>>> g) => {
  for (final e in g.entries) e.key: [for (final emb in e.value) List<double>.from(emb)],
};

/// NEW: Chạy toàn bộ pipeline trong worker từ RGBA thô + bbox đã xoay.
/// Trả về: success, name?, distance, previewPng (224x224) để UI hiển thị.
Future<({
bool success,
String? name,
double distance,
Uint8List? previewPng,
List<double>? embedded, // <= thêm
String? error,
})> preprocessRecognizeFromRgba({
  required Uint8List rgbaBytes,
  required int width,
  required int height,
  required int rotationDeg,
  required Rect bboxRotated,
  double margin = 0.06,
}) async {
  if (!_isInitialized || _workerPort == null) {
    return (success:false, name:null, distance:double.infinity, previewPng:null, embedded:null, error:'Not initialized');
  }
  try {
    final rp = ReceivePort();
    _workerPort!.send({
      'type': 'preproc_recognize_rgba',
      'reply': rp.sendPort,
      'rgba': rgbaBytes,
      'w': width,                 // ✅ width thật
      'h': height,                // ✅ height thật
      'deg': rotationDeg,
      'bbox': {
        'l': bboxRotated.left,
        't': bboxRotated.top,
        'w': bboxRotated.width,
        'h': bboxRotated.height,
      },
      'margin': margin,
      'gallery': _embeddings,
      'threshold': threshold,
      'targetW': widthImage,
      'targetH': heightImage,
      'wantPreview': true,
    });

    final res = await rp.first.timeout(const Duration(seconds: 5));
    if (res is Map && res['success'] == true) {
      return (
      success: true,
      name: res['name'] as String?,
      distance: (res['distance'] as num).toDouble(),
      previewPng: res['preview'] as Uint8List?,
      embedded: (res['embedded'] as List).cast<double>(),
      error: null
      );
    }
    return (success:false, name:null, distance:double.infinity, previewPng:null, embedded:null, error:(res as Map?)?['error']?.toString());
  } catch (e) {
    return (success:false, name:null, distance:double.infinity, previewPng:null, embedded:null, error:e.toString());
  }
}


void disposeFaceNet() {
  if (_workerPort != null) {
    _workerDispose(_workerPort!).catchError((e) => debugPrint('Dispose error: $e'));
    _workerPort = null;
  }
  _isInitialized = false;
}

// ======= Worker Communication =======

Future<SendPort> _startWorker() async {
  final completer = Completer<SendPort>();
  final receivePort = ReceivePort();
  await Isolate.spawn(_workerEntry, receivePort.sendPort);
  receivePort.listen((message) {
    if (message is SendPort && !completer.isCompleted) {
      completer.complete(message);
    }
  });
  return completer.future;
}

Future<void> _workerInit(SendPort worker, String modelPath) async {
  final modelBytes = await rootBundle.load(modelPath);
  final modelData = modelBytes.buffer.asUint8List();

  final receivePort = ReceivePort();
  worker.send({
    'type': 'init',
    'reply': receivePort.sendPort,
    'modelBytes': modelData,
  });

  final response = await receivePort.first.timeout(const Duration(seconds: 10));
  if (response is Map && response['success'] != true) {
    throw Exception(response['error'] ?? 'Init failed');
  }
}

Future<void> _workerDispose(SendPort worker) async {
  final receivePort = ReceivePort();
  worker.send({
    'type': 'dispose',
    'reply': receivePort.sendPort,
  });
  await receivePort.first.timeout(const Duration(seconds: 3));
}

// ======= Worker Isolate =======

void _workerEntry(SendPort mainPort) async {
  final receivePort = ReceivePort();
  mainPort.send(receivePort.sendPort);

  Interpreter? interpreter;

  await for (final message in receivePort) {
    if (message is! Map) continue;

    final SendPort reply = message['reply'] as SendPort;
    final String type = message['type'] as String;

    try {
      switch (type) {
        case 'init': {
          final modelBytes = message['modelBytes'] as Uint8List;
          interpreter = Interpreter.fromBuffer(modelBytes);
          interpreter!.allocateTensors();
          reply.send({'success': true});
          break;
        }
        case 'preproc_recognize_rgba': {
          if (interpreter == null) throw StateError('Not initialized');
          final Uint8List rgba = message['rgba'] as Uint8List;
          final int w = message['w'] as int;          // ✅ width thật
          final int h = message['h'] as int;          // ✅ height thật
          final int deg = message['deg'] as int;
          final Map bbox = message['bbox'] as Map;

          final double margin = (message['margin'] as num?)?.toDouble() ?? 0.06;
          final int targetW = (message['targetW'] as num?)?.toInt() ?? widthImage;
          final int targetH = (message['targetH'] as num?)?.toInt() ?? heightImage;
          final bool wantPreview = message['wantPreview'] == true;

          final gallery = (message['gallery'] as Map).cast<String, List<List<double>>>();
          final double thr = (message['threshold'] as num?)?.toDouble() ?? threshold;

          img.Image im = img.Image.fromBytes(
            width: w, height: h,
            bytes: rgba.buffer,
            numChannels: 4,
            order: img.ChannelOrder.rgba,
          );

          if (deg == 90)       im = img.copyRotate(im, angle: 90);
          else if (deg == 180) im = img.copyRotate(im, angle: 180);
          else if (deg == 270) im = img.copyRotate(im, angle: 270);

          final Rect box = Rect.fromLTWH(
            (bbox['l'] as num).toDouble(),
            (bbox['t'] as num).toDouble(),
            (bbox['w'] as num).toDouble(),
            (bbox['h'] as num).toDouble(),
          );

          // Dùng helper thuần package:image (không gọi VisionUtils trong isolate)
          final img.Image standardized = VisionUtils.standardize(
            im, box, margin: margin, targetW: targetW, targetH: targetH,
          );

          final emb = _runEmbeddingFromImage(interpreter!, standardized);
          final best = _findBestMatch(emb, gallery, thr);

          Uint8List? preview;
          if (wantPreview) {
            final small = img.copyResize(standardized, width: 224, height: 224, interpolation: img.Interpolation.linear);
            preview = Uint8List.fromList(img.encodeJpg(small, quality: 85));
          }

          reply.send({
            'success': true,
            'name': best.name,
            'distance': best.distance,
            'preview': preview,
            'embedded': emb,      // ✅ gửi luôn embedding
          });
          break;
        }


        case 'dispose': {
          interpreter?.close();
          interpreter = null;
          reply.send({'success': true});
          break;
        }

        default:
          reply.send({'success': false, 'error': 'Unknown type: $type'});
          break;
      }
    } catch (e) {
      reply.send({'success': false, 'error': e.toString()});
    }
  }
}
// ======= Worker Helper Functions =======
List<double> _runEmbeddingFromImage(Interpreter interpreter, img.Image image) {
  final input = Float32List(widthImage * heightImage * 3);
  int i = 0;
  for (int y = 0; y < heightImage; y++) {
    for (int x = 0; x < widthImage; x++) {
      final p = image.getPixel(x, y);
      input[i++] = (p.r - 128.0) / 128.0;
      input[i++] = (p.g - 128.0) / 128.0;
      input[i++] = (p.b - 128.0) / 128.0;
    }
  }
  final inputTensor = input.reshape([1, heightImage, widthImage, 3]);
  final outTensor = interpreter.getOutputTensor(0);
  final outSize = outTensor.shape.reduce((a, b) => a * b);
  final out = Float32List(outSize).reshape([1, outSize]);
  interpreter.run(inputTensor, out);
  return List<double>.from(out[0]);
}

({String? name, double distance}) _findBestMatch(
    List<double> probe,
    Map<String, List<List<double>>> gallery,
    double threshold,
    ) {
  if (gallery.isEmpty) {
    return (name: null, distance: double.infinity);
  }

  String? bestName;
  double bestDistance = double.infinity;

  for (final entry in gallery.entries) {
    final personName = entry.key;
    final embeddings = entry.value;

    for (final embedding in embeddings) {
      final distance = euclideanDistance(probe, embedding);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestName = personName;
      }
    }
  }

  final isMatch = bestDistance <= threshold;
  return (name: isMatch ? bestName : null, distance: bestDistance);
}

double euclideanDistance(List<double> a, List<double> b) {
  if (a.length != b.length) return double.infinity;
  double sum = 0.0;
  for (int i = 0; i < a.length; i++) {
    final diff = a[i] - b[i];
    sum += diff * diff;
  }
  return sum; // squared distance cho nhanh
}
