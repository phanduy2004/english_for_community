import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:recognize_face/main.dart';
import 'package:recognize_face/screens/common/face_painter.dart';
import 'package:recognize_face/services/liveness_service/liveness_service.dart';
import 'package:recognize_face/utils/simple_settings.dart';

class IsolateContext {
  final SendPort mainSendPort;
  final Uint8List modelBytes;
  final RootIsolateToken rootIsolateToken;
  IsolateContext(this.mainSendPort, this.modelBytes, this.rootIsolateToken);
}

class IsolateRequest {
  final CameraImage cameraImage;
  final InputImageRotation imageRotation;
  IsolateRequest(this.cameraImage, this.imageRotation);
}

class IsolateResponse {
  final List<Face> faces;
  final Map<String, Map<String, dynamic>> results;
  final Uint8List? preview;

  IsolateResponse(this.faces, this.results, {this.preview});
}

void isolateEntry(IsolateContext isolateContext) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(
      isolateContext.rootIsolateToken);
  DartPluginRegistrant.ensureInitialized();

  final isolateReceivePort = ReceivePort();
  isolateContext.mainSendPort.send(isolateReceivePort.sendPort);

  final faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  final livenessService = LivenessService();
  await livenessService.loadModelFromBytes(isolateContext.modelBytes);

  await for (final message in isolateReceivePort) {
    if (message == null) break;

    if (message is ReloadModelRequest) {
      final bytes = message.tfliteBytes.materialize().asUint8List();
      await livenessService.loadModelFromBytes(bytes);
      continue;
    }

    // Xử lý frame bình thường
    if (message is IsolateRequest) {
      final inputImage = livenessService.inputImageFromCameraImage(
        message.cameraImage,
        message.imageRotation,
      );
      if (inputImage == null) {
        continue;
      }

      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        isolateContext.mainSendPort.send(IsolateResponse([], {}));
        continue;
      }

      final validFaces = faces
          .where((f) => f.boundingBox.width >= 80 && f.boundingBox.height >= 80)
          .toList();
      if (validFaces.isEmpty) {
        isolateContext.mainSendPort.send(IsolateResponse([], {}));
        continue;
      }

      final largestFace = validFaces.reduce((a, b) =>
          a.boundingBox.width * a.boundingBox.height >
                  b.boundingBox.width * b.boundingBox.height
              ? a
              : b);

      final score =
          await livenessService.predict(message.cameraImage, largestFace);
      final threshold = SimpleSettings.livenessThreshold; // 👈 lấy từ settings
      final label = score >= threshold ? "Real" : "Fake";
      final faceKey = largestFace.boundingBox.toString();

      final previewBytes = livenessService.cropFaceAsBytes(
        message.cameraImage,
        largestFace,
        rotation: message.imageRotation,
      );

      isolateContext.mainSendPort.send(
        IsolateResponse(
          [largestFace],
          {
            faceKey: {"label": label, "score": score}
          },
          preview: previewBytes,
        ),
      );
    }
  }
}

class ReloadModelRequest {
  final TransferableTypedData
      tfliteBytes; // dùng TransferableTypedData để gửi nhanh/không copy
  ReloadModelRequest(Uint8List bytes)
      : tfliteBytes = TransferableTypedData.fromList([bytes]);
}

class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key});
  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _isolateSendPort;

  List<Face> _faces = [];
  Map<String, Map<String, dynamic>> _livenessResults = {};
  bool _isProcessing = false;
  Size? _imageSize;
  InputImageRotation? _imageRotation;

  int _frameCount = 0;
  Uint8List? _facePreview;

  String _currentModelPath = "assets/models/liveness_ResNet50.tflite";
  String get _currentModelName {
    if (_currentModelPath.contains("ResNet")) return "ResNet50";
    if (_currentModelPath.contains("MobileNetV2")) return "MobileNetV2";
    if (_currentModelPath.contains("MobileNetV3Large")) {
      return "MobileNetV3Large";
    }
    if (_currentModelPath.contains("MiniFASNet")) return "MiniFASNet";
    if (_currentModelPath.contains("EfficientNetB0")) return "EfficientNetB0";
    if (_currentModelPath.contains("EfficientNetB5")) return "EfficientNetB5";
    return "Unknown";
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final modelBytes = await _loadModelBytes();
    if (modelBytes == null) {
      debugPrint("Cannot load MODEL, Stop!!!");
      return;
    }
    _startIsolate(modelBytes);
    await _initializeCamera();
  }

  Future<Uint8List?> _loadModelBytes() async {
    try {
      final byteData =
          await rootBundle.load('assets/models/liveness_ResNet50.tflite');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error load MODEL: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _stopIsolate();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startIsolate(Uint8List modelBytes) async {
    _receivePort = ReceivePort();
    final rootIsolateToken = RootIsolateToken.instance!;
    final context =
        IsolateContext(_receivePort!.sendPort, modelBytes, rootIsolateToken);
    _isolate = await Isolate.spawn(isolateEntry, context);

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _isolateSendPort = message;
      } else if (message is IsolateResponse) {
        if (mounted) {
          setState(() {
            _faces = message.faces;
            _livenessResults = message.results;
            _facePreview = message.preview;
            _isProcessing = false;
          });
        }
      }
    });
  }

  void _stopIsolate() {
    _isolateSendPort?.send(null);
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  Future<void> _initializeCamera() async {
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      // Để mặc định YUV_420_888 (ổn định trên nhiều thiết bị)
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
    _cameraController!.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) {
    if (_isProcessing || _isolateSendPort == null || !mounted) return;

    // throttle: xử lý mỗi 3 frame
    _frameCount = (_frameCount + 1) % 3;
    if (_frameCount != 0) return;

    _isProcessing = true;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation imageRotation = InputImageRotation.rotation0deg;

    if (Platform.isAndroid) {
      // portraitUp giả định
      final newRotation = sensorOrientation % 360;
      imageRotation = InputImageRotationValue.fromRawValue(newRotation)!;
    } else if (Platform.isIOS) {
      imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation)!;
    }

    setState(() {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _imageRotation = imageRotation;
    });

    _isolateSendPort?.send(IsolateRequest(image, imageRotation));
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.model_training),
                title: const Text("Model: ResNet50"),
                onTap: () {
                  Navigator.pop(context);
                  _reloadModel("assets/models/liveness_ResNet50.tflite");
                },
              ),
              ListTile(
                leading: const Icon(Icons.model_training),
                title: const Text("Model: MobileNetV2"),
                onTap: () {
                  Navigator.pop(context);
                  _reloadModel("assets/models/liveness_MobileNetV2.tflite");
                },
              ),
              ListTile(
                leading: const Icon(Icons.model_training),
                title: const Text("Model: MobileNetV3Large"),
                onTap: () {
                  Navigator.pop(context);
                  _reloadModel(
                      "assets/models/liveness_MobileNetV3Large.tflite");
                },
              ),
              ListTile(
                leading: const Icon(Icons.model_training),
                title: const Text("Model: MiniFASNet"),
                onTap: () {
                  Navigator.pop(context);
                  _reloadModel("assets/models/liveness_MiniFASNet.tflite");
                },
              ),
              ListTile(
                leading: const Icon(Icons.model_training),
                title: const Text("Model: EfficientNetB0"),
                onTap: () {
                  Navigator.pop(context);
                  _reloadModel("assets/models/liveness_EfficientNetB0.tflite");
                },
              ),
              ListTile(
                leading: const Icon(Icons.model_training),
                title: const Text("Model: EfficientNetB5"),
                onTap: () {
                  Navigator.pop(context);
                  _reloadModel("assets/models/liveness_EfficientNetB5.tflite");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reloadModel(String modelPath) async {
    debugPrint("Reloading model: $modelPath");

    try {
      final byteData = await rootBundle.load(modelPath);
      final modelBytes = byteData.buffer.asUint8List();
      _isolateSendPort?.send(ReloadModelRequest(modelBytes));

      setState(() {
        _currentModelPath = modelPath;
        _faces = [];
        _livenessResults = {};
        _facePreview = null;
      });
    } catch (e) {
      debugPrint("Error reload model: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Passive Liveness"),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              _openSettings(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraController!.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          if (_imageSize != null && _imageRotation != null)
                            CustomPaint(
                              painter: FacePainter(
                                imageSize: _imageSize!,
                                imageRotation: _imageRotation!,
                                faces: _faces,
                                results: _livenessResults,
                                cameraLensDirection: _cameraController!
                                    .description.lensDirection,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Thông số và preview nhỏ
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.15,
            width: double.infinity,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),

                        // Hiển thị model đang dùng
                        Text("Model: $_currentModelName",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.blue)),

                        const SizedBox(height: 6),

                        // Hiển thị chỉ số liveness
                        if (_livenessResults.isNotEmpty)
                          Text(
                            "Liveness Score: ${_livenessResults.values.first["score"]?.toStringAsFixed(3)}",
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          )
                        else
                          const Text("Liveness Score: ---"),

                        const SizedBox(height: 8),

                        // List chi tiết label/score
                        if (_livenessResults.isNotEmpty)
                          Expanded(
                            child: ListView(
                              children: _livenessResults.entries.map((entry) {
                                final label = entry.value["label"];
                                //final score = entry.value["score"];
                                return Text("$label");
                                //return Text("$label (${score.toStringAsFixed(2)})");
                              }).toList(),
                            ),
                          )
                        else
                          const Text("Chưa có dữ liệu..."),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: _facePreview != null
                        ? Image.memory(_facePreview!, fit: BoxFit.cover)
                        : const Text("No face"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
