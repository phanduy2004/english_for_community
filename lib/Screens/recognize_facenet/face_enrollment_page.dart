// lib/pages/simple_face_enrollment_page.dart
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

class FaceEnrollmentPage extends StatefulWidget {
  const FaceEnrollmentPage({super.key});
  @override
  State<FaceEnrollmentPage> createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends State<FaceEnrollmentPage> {
  // Core
  CameraController? _cam;
  late final FaceDetector _detector;
  final _repo = FaceDatasetRepositorySqlite();

  // State
  bool _inited = false;      // camera + detector + facenet ready
  bool _session = false;     // đang enroll
  bool _paused = false;      // tạm dừng vì người khác
  bool _running = false;     // guard chống xử lý chồng

  // Tracking / UI
  Face? _face;
  Rect? _previewRect;
  int? _trackId;
  int _good = 0;             // khung tốt liên tiếp
  int _lastMs = 0;           // throttle

  // Rotation cache
  InputImageRotation? _cachedRotation;
  int _degCached = 0;        // 0/90/180/270

  // Enrollment data
  String _name = '';
  final List<List<double>> _embs = [];
  List<double>? _anchorEmb;  // embedding anchor (mẫu đầu)
  static const int _target = 5;
  static const double _samePersonFactor = 1.2; // chặt/lỏng hơn threshold

  // ===== lifecycle =====
  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _stopStream();
    _cam?.dispose();
    if (_inited) _detector.close();
    disposeFaceNet();
    super.dispose();
  }

  // ===== init =====
  Future<void> _boot() async {
    try {
      await initFaceNet();

      final cams = await availableCameras();
      final front = cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      _cam = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await _cam!.initialize();
      await _cam!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      // cache rotation theo sensor
      final deg = _cam!.description.sensorOrientation % 360;
      _cachedRotation =
          InputImageRotationValue.fromRawValue(deg) ?? InputImageRotation.rotation0deg;
      _degCached = _degFromRotation(_cachedRotation!);

      _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableTracking: true,
          minFaceSize: 0.25,
          enableClassification: false,
          enableLandmarks: false,
        ),
      );

      if (!mounted) return;
      _inited = true;
      setState(() {});
      _startStream();
    } catch (e) {
      debugPrint('Init failed: $e');
      if (mounted) {
        _inited = true;
        setState(() {});
      }
    }
  }

  Future<void> _startStream() async {
    final cam = _cam;
    if (cam != null && !cam.value.isStreamingImages) {
      await cam.startImageStream(_onFrame);
    }
  }

  Future<void> _stopStream() async {
    final cam = _cam;
    if (cam != null && cam.value.isStreamingImages) {
      await cam.stopImageStream();
    }
  }

  // ===== utils =====
  bool _isGoodFace(Face f) =>
      VisionUtils.isGood(f, minBox: 120, maxAbsYaw: 20, maxAbsRoll: 20);

  void _updatePreview(CameraImage frame, Face? face, InputImageRotation rot) {
    if (face == null) {
      if (_previewRect != null) {
        _previewRect = null;
        setState(() {});
      }
      return;
    }
    final rotSwap = rot == InputImageRotation.rotation90deg ||
        rot == InputImageRotation.rotation270deg;

    final imageSize = rotSwap
        ? Size(frame.height.toDouble(), frame.width.toDouble())
        : Size(frame.width.toDouble(), frame.height.toDouble());

    final pv = _cam!.value.previewSize!;
    final previewSize = Size(pv.height, pv.width);

    final mapped = VisionUtils.mapRectToPreview(
      face.boundingBox, imageSize, previewSize, true,
    );

    if (_previewRect != mapped) {
      _previewRect = mapped;
      setState(() {});
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
    final img.Image rgb = await VisionUtils.rgbFromFrame(frame);
    final Uint8List raw = Uint8List.fromList(
      rgb.getBytes(order: img.ChannelOrder.rgba),
    );
    return (bytes: raw, w: rgb.width, h: rgb.height);
  }

  // ===== same-person check =====
  bool _isSamePerson(List<double> emb) {
    if (_anchorEmb == null) return true;
    final d = euclideanDistance(_anchorEmb!, emb);
    return d <= threshold * _samePersonFactor;
  }

  // ===== pipeline =====
  Future<void> _onFrame(CameraImage frame) async {
    if (!_session || _running) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMs < tickMsEnroll) return; // throttle
    _lastMs = now;

    try {
      final rot = _cachedRotation ?? InputImageRotation.rotation0deg;
      final input = VisionUtils.inputFromFrame(frame, rot);
      if (input == null) return;

      final faces = await _detector.processImage(input);
      final best = VisionUtils.pickBest(
        faces, minBox: 120, maxAbsYaw: 20, maxAbsRoll: 20,
      );

      _face = best;
      _updatePreview(frame, best, rot);

      // trackingId gợi ý đổi người -> xác minh bằng embedding sau
      if (best?.trackingId != null) {
        final tid = best!.trackingId!;
        if (_trackId == null) {
          _trackId = tid;
        } else if (_trackId != tid && _anchorEmb != null) {
          // có thể là người khác
        }
      }

      if (best == null || !_isGoodFace(best)) {
        _good = 0;
        return;
      }

      // yêu cầu 3 khung ổn định
      _good++;
      if (_good < 3) return;
      _good = 0;

      // ----- guard để không xử lý chồng -----
      _running = true;

      // Lấy embedding chuẩn từ worker (rotate+crop+resize bên worker)
      final data = await _rgbaFromFrame(frame);
      final res = await preprocessRecognizeFromRgba(
        rgbaBytes: data.bytes,
        width: data.w,
        height: data.h,
        rotationDeg: _degCached,
        bboxRotated: best.boundingBox,
        margin: 0.08,
      );
      final emb = res.embedded;
      if (emb == null) return;

      if (_anchorEmb == null) {
        // mẫu đầu tiên -> đặt anchor
        _anchorEmb = emb;
        _trackId = best.trackingId ?? _trackId;
        if (!_paused) {
          _embs.add(emb);
          if (_embs.length >= _target) {
            await _finalSaveAndExit();
            return;
          }
        }
        return;
      }

      // đã có anchor
      final same = _isSamePerson(emb);

      if (_paused) {
        // chỉ nhận khi cùng anchor
        if (same) {
          _paused = false;
          _trackId = best.trackingId ?? _trackId;
          _embs.add(emb);
          if (_embs.length >= _target) {
            await _finalSaveAndExit();
            return;
          }
        }
      } else {
        if (!same) {
          _paused = true; // không lưu, chờ anchor quay lại
        } else {
          _embs.add(emb);
          if (_embs.length >= _target) {
            await _finalSaveAndExit();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('onFrame error: $e');
    } finally {
      _running = false;
      if (mounted) setState(() {}); // cập nhật status/khung
    }
  }

  // Lưu 1 lần khi đủ mẫu và thoát
  Future<void> _finalSaveAndExit() async {
    try {
      if (_embs.isNotEmpty) {
        await _repo.addEmbeddings(
          personName: _name,
          embeddings: List<List<double>>.from(_embs),
          avatarBytes: null,
        );
        await loadEmbeddings();
      }
    } catch (e) {
      debugPrint('final save failed: $e');
      await _stopStream();
      if (!mounted) return;
      Navigator.of(context).pop(<String, dynamic>{
        'success': false,
        'error': e.toString(),
      });
      return;
    }

    // Kết thúc phiên
    _session = false;
    _paused = false;
    _trackId = null;
    _face = null;
    await _stopStream();
    if (!mounted) return;
    Navigator.of(context).pop(<String, dynamic>{
      'success': true,
      'name': _name,
      'samples': _embs.length,
    });
  }

  // ===== UI helpers =====
  String get _status {
    if (!_session) return 'Nhấn START để bắt đầu enroll';
    if (_paused) return 'Người khác vào khung — tạm dừng, chờ $_name quay lại';
    if (_face == null) return 'Đưa mặt vào khung';
    return _isGoodFace(_face!) ? 'Giữ ổn định...' : 'Nhìn thẳng vào camera';
  }

  Color get _statusColor {
    if (!_session) return Colors.grey;
    if (_paused) return Colors.amber;
    if (_face == null) return Colors.red;
    return _isGoodFace(_face!) ? Colors.green : Colors.amber;
  }

  Future<void> _start() async {
    final name = await _askName();
    if (name == null || name.trim().isEmpty) return;
    _name = name.trim();
    _session = true;
    _paused = false;
    _trackId = null;
    _good = 0;
    _face = null;
    _embs.clear();
    _anchorEmb = null; // reset anchor
    setState(() {});
  }

  void _stop() {
    _session = false;
    _paused = false;
    _trackId = null;
    _good = 0;
    _face = null;
    _embs.clear();
    _anchorEmb = null;
    setState(() {});
  }

  Future<String?> _askName() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Tên người dùng'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: John Doe',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    if (!_inited) {
      return const Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Đang khởi tạo...'),
          ]),
        ),
      );
    }

    final pv = _cam!.value.previewSize!;
    final w = pv.height;
    final h = pv.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Face Enrollment'), centerTitle: true),
      body: Column(
        children: [
          // Preview
          Expanded(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    CameraPreview(_cam!),
                    if (_session && _previewRect != null)
                      CustomPaint(
                        painter: FaceBoxPainter(
                          rect: _previewRect!,
                          color: _statusColor,
                        ),
                      ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _session ? 'Enrolling: $_name' : 'Sẵn sàng enroll',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: _session ? _stop : _start,
                  child: Text(_session ? 'Stop' : 'Start'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
