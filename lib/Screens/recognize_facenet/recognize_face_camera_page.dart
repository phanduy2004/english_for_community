// lib/pages/recognize_face_camera_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../../services/facenet_service/face_dataset_repository_v2.dart';
import '../../services/facenet_service/improve_facenet_service.dart';
import '../../utils/values.dart';
import '../../utils/vision_utils.dart';
import '../common/face_box_painter.dart';

class RecognizeFaceCameraPage extends StatefulWidget {
  const RecognizeFaceCameraPage({super.key});
  @override
  State<RecognizeFaceCameraPage> createState() => _RecognizeFaceCameraPageState();
}

class _RecognizeFaceCameraPageState extends State<RecognizeFaceCameraPage> {
  CameraController? _camera;
  late final FaceDetector _detector;
  final _repo = FaceDatasetRepositorySqlite();

  // State
  bool _ready = false;
  Face? _face; // (rotated space) for overlay
  Rect? _previewRect;
  String? _bestName;
  bool _isMatch = false;
  double? _bestDist;
  bool _recogBusy = false;

  int _lastTick = 0;

  // ValueNotifiers để tránh rebuild toàn trang
  final _status = ValueNotifier<String>('Initializing...');
  final _overlay = ValueNotifier<({Rect? rect, String? label, bool matched})>(
    (rect: null, label: null, matched: false),
  );

  // Cache
  InputImageRotation? _cachedRotation;
  CameraImage? _lastValidFrame;
  Face? _lastValidFace; // (rotated space)
  Uint8List? _lastPreviewPng; // preview nhỏ nhận từ worker (tùy chọn)

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _status.dispose();
    _overlay.dispose();
    _stopStream();
    _camera?.dispose();
    if (_ready) _detector.close();
    disposeFaceNet();
    super.dispose();
  }

  void _setStatus(String s) {
    if (_status.value != s) _status.value = s;
  }

  void _updateOverlay(Rect? r, String? label, bool matched) {
    final v = _overlay.value;
    if (v.rect != r || v.label != label || v.matched != matched) {
      _overlay.value = (rect: r, label: label, matched: matched);
    }
  }

  Future<void> _init() async {
    // init facenet + camera song song
    await Future.wait([initFaceNet(), _initCamera()]);
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: true,
        minFaceSize: 0.12,
        enableClassification: false,
        enableLandmarks: false,
      ),
    );
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
    _setStatus('No face detected');
    await _startStream();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );

    await _camera?.dispose();
    _camera = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    await _camera!.initialize();
    await _camera!.lockCaptureOrientation(DeviceOrientation.portraitUp);

    final deg = _camera!.description.sensorOrientation % 360;
    _cachedRotation = InputImageRotationValue.fromRawValue(deg)!;

    await _camera!.setFlashMode(FlashMode.off);
    if (_camera!.value.exposureMode != ExposureMode.auto) {
      await _camera!.setExposureMode(ExposureMode.auto);
    }
    if (_camera!.value.focusMode != FocusMode.auto) {
      await _camera!.setFocusMode(FocusMode.auto);
    }
  }

  Future<void> _startStream() async {
    final cam = _camera;
    if (cam == null) return;
    if (!cam.value.isInitialized) return;
    if (cam.value.isStreamingImages) return;
    await cam.startImageStream(_onStream);
    if (mounted) setState(() {});
  }

  Future<void> _stopStream() async {
    final cam = _camera;
    if (cam?.value.isStreamingImages == true) {
      await cam!.stopImageStream();
    }
  }

  bool _goodFace(Face f) =>
      VisionUtils.isGood(f, minBox: 100, maxAbsYaw: 25, maxAbsRoll: 25);

  Future<void> _onStream(CameraImage frame) async {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTick < 300) return; // throttle
    _lastTick = now;

    try {
      final desc = _camera!.description;
      final isFront = desc.lensDirection == CameraLensDirection.front;

      final input = VisionUtils.inputFromFrame(frame, _cachedRotation!);
      if (input == null) return;

      final faces = await _detector.processImage(input);
      final best = VisionUtils.pickBest(
        faces,
        minBox: 100,
        maxAbsYaw: 30,
        maxAbsRoll: 30,
      );

      if (best != null && _goodFace(best)) {
        _lastValidFrame = frame;
        _lastValidFace = best;
        unawaited(_recognizeAsync()); // nhận diện nền
      } else {
        _isMatch = false;
        _bestName = null;
        _bestDist = null;
        _lastValidFrame = null;
        _lastValidFace = null;
      }

      _face = best;
      _updatePreviewRect(frame, best?.boundingBox, _cachedRotation!, isFront);
      _updateStatus();
      _updateUiOverlay();
    } catch (_) {
      // ignore minor errors
    }
  }

  void _updatePreviewRect(
      CameraImage frame,
      Rect? bboxRot,
      InputImageRotation rot,
      bool isFront,
      ) {
    if (bboxRot == null) {
      _previewRect = null;
      return;
    }

    final bool swap = rot == InputImageRotation.rotation90deg ||
        rot == InputImageRotation.rotation270deg;
    final Size imageSizeRotated = swap
        ? Size(frame.height.toDouble(), frame.width.toDouble())
        : Size(frame.width.toDouble(), frame.height.toDouble());

    final pv = _camera!.value.previewSize!;
    final Size previewSize = Size(pv.height, pv.width);
    final bool mirror = isFront;

    _previewRect = VisionUtils.mapRectToPreview(
      bboxRot,
      imageSizeRotated,
      previewSize,
      mirror,
    );
  }

  void _updateUiOverlay() {
    final String labelStr = _isMatch && _bestName != null
        ? '${_bestName!}${_bestDist != null ? ' · d=${_bestDist!.toStringAsFixed(3)}' : ''}'
        : 'Unknow';
    _updateOverlay(_previewRect, labelStr, _isMatch);
  }

  void _updateStatus() {
    if (_isMatch) {
      _setStatus('Face recognized!');
    } else if (_face == null) {
      _setStatus('No face detected');
    } else {
      _setStatus('Face detected');
    }
  }

  int _degFromRotation(InputImageRotation r) {
    switch (r) {
      case InputImageRotation.rotation90deg: return 90;
      case InputImageRotation.rotation180deg: return 180;
      case InputImageRotation.rotation270deg: return 270;
      case InputImageRotation.rotation0deg:
      default: return 0;
    }
  }

  Future<({Uint8List bytes, int w, int h})> _rgbaFromFrame(CameraImage frame) async {
    // VisionUtils.rgbFromFrame trả về img.Image RGB
    final img.Image rgb = await VisionUtils.rgbFromFrame(frame);
    final Uint8List raw = Uint8List.fromList(rgb.getBytes(order: img.ChannelOrder.rgba));
    return (bytes: raw, w: rgb.width, h: rgb.height);
  }

  Future<void> _recognizeAsync() async {
    if (_lastValidFrame == null || _lastValidFace == null) return;
    _updateStatus();
    _updateUiOverlay();
    try {
      final data = await _rgbaFromFrame(_lastValidFrame!);
      final int deg = _degFromRotation(_cachedRotation!);
      final Rect boxRot = _lastValidFace!.boundingBox;

      final res = await preprocessRecognizeFromRgba(
        rgbaBytes: data.bytes,
        width: data.w,
        height: data.h,
        rotationDeg: deg,
        bboxRotated: boxRot,
        margin: 0.06,
      );

      if (res.success) {
        _isMatch = res.name != null;
        _bestName = res.name;
        _bestDist = res.distance.isFinite ? res.distance : null;
        _lastPreviewPng = res.previewPng;
      } else {
        _isMatch = false;
        _bestName = null;
        _bestDist = null;
      }
    } catch (_) {
      _isMatch = false;
      _bestName = null;
      _bestDist = null;
    } finally {
      _updateStatus();
      _updateUiOverlay();
    }
  }

  // ===================== CAPTURE =====================
  Future<void> _captureAndSave() async {
    if (_lastValidFrame == null || _lastValidFace == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No good face to capture')),
      );
      return;
    }

    try {
      // 1) Lấy RGBA từ frame cache
      final data = await _rgbaFromFrame(_lastValidFrame!);
      final int deg = _degFromRotation(_cachedRotation!);

      // 2) Nhờ worker chuẩn hoá + trả preview + embedding
      final res = await preprocessRecognizeFromRgba(
        rgbaBytes: data.bytes,
        width: data.w,
        height: data.h,
        rotationDeg: deg,
        bboxRotated: _lastValidFace!.boundingBox,
        margin: 0.08,
      );
      if (!res.success || res.previewPng == null || res.embedded == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: ${res.error ?? 'unknown'}')),
        );
        return;
      }

      // 3) Gợi ý tên từ nhận diện
      final initialName = (_isMatch && _bestName != null)
          ? _bestName!.split(':').first.trim()
          : (res.name ?? '');

      // 4) Hỏi tên kèm preview
      final String? name = await _askName(res.previewPng!, initialText: initialName);
      if (name == null || name.trim().isEmpty) return;

      // 5) Lưu embedding + avatar (dùng preview làm avatar)
      await _repo.addEmbeddings(
        personName: name.trim(),
        embeddings: [res.embedded!],
        avatarBytes: res.previewPng!,
      );
      await loadEmbeddings();
      _isMatch = false;
      _bestName = null;
      _bestDist = null;
      _setStatus('Saved · Updated');
      _updateUiOverlay();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sample saved for ${name.trim()} · Reloaded')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  Future<String?> _askName(Uint8List preview, {String initialText = ''}) async {
    final controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preview.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  preview,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter name'),
              onSubmitted: (_) => Navigator.pop(context, controller.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pv = _camera!.value.previewSize!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await loadEmbeddings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Embeddings reloaded')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: pv.height,
                height: pv.width,
                child: Stack(
                  children: [
                    CameraPreview(_camera!),
                    // Overlay chỉ redraw khi overlay thay đổi
                    Positioned.fill(
                      child: ValueListenableBuilder<({Rect? rect, String? label, bool matched})>(
                        valueListenable: _overlay,
                        builder: (_, v, __) => CustomPaint(
                          foregroundPainter: FaceBoxPainter(
                            rect: v.rect,
                            color: v.matched ? Colors.green : Colors.orange,
                            label: v.label,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: ValueListenableBuilder<String>(
              valueListenable: _status,
              builder: (_, s, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: _captureAndSave,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }
}
