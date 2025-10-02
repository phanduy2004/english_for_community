// lib/pages/active_liveness_page.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

// =========================================================================
// HÀM TIỆN ÍCH CHO XỬ LÝ HÌNH ẢNH
// =========================================================================

InputImageRotation rotationIntToImageRotation(int rotation) {
  final map = {
    0: InputImageRotation.rotation0deg,
    90: InputImageRotation.rotation90deg,
    180: InputImageRotation.rotation180deg,
    270: InputImageRotation.rotation270deg,
  };
  return map[rotation] ?? InputImageRotation.rotation0deg;
}

InputImage? inputFromFrame(CameraImage frame, CameraDescription description) {
  final InputImageRotation rotation =
  rotationIntToImageRotation(description.sensorOrientation);
  final formatGroup = frame.format.group;

  if (Platform.isAndroid && formatGroup == ImageFormatGroup.yuv420) {
    final imageWidth = frame.width;
    final imageHeight = frame.height;
    final planes = frame.planes;
    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];
    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    final int ySize = yBuffer.length;
    final int uvSize = uBuffer.length;
    final int totalSize = ySize + uvSize * 2;
    final Uint8List nv21Bytes = Uint8List(totalSize);

    nv21Bytes.setAll(0, yBuffer);

    int uvIndex = ySize;
    for (int i = 0; i < uvSize; i++) {
      nv21Bytes[uvIndex++] = vBuffer[i];
      nv21Bytes[uvIndex++] = uBuffer[i];
    }

    return InputImage.fromBytes(
      bytes: nv21Bytes,
      metadata: InputImageMetadata(
        size: Size(imageWidth.toDouble(), imageHeight.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: imageWidth,
      ),
    );
  } else if (Platform.isIOS && formatGroup == ImageFormatGroup.bgra8888) {
    final plane = frame.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
  return null;
}

List<CameraDescription> cameras = [];

// THAY ĐỔI: Thêm các hành động mới
enum LivenessAction { turnRight, turnLeft, lookUp, lookDown, smile, blink }

class ActiveLivenessDetection2 extends StatefulWidget {
  @override
  _ActiveLivenessDetection2State createState() => _ActiveLivenessDetection2State();
}

class _ActiveLivenessDetection2State extends State<ActiveLivenessDetection2> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.7,
    ),
  );

  int _currentPage = 0;
  final List<LivenessAction> _actions = LivenessAction.values.toList();
  // THAY ĐỔI: Cập nhật danh sách mô tả hành động
  final Map<LivenessAction, String> _actionDescriptions = {
    LivenessAction.turnRight: 'Quay mặt sang phải',
    LivenessAction.turnLeft: 'Quay mặt sang trái',
    LivenessAction.lookUp: 'Ngẩn mặt lên',
    LivenessAction.lookDown: 'Cúi mặt xuống',
    LivenessAction.smile: 'Mỉm cười',
    LivenessAction.blink: 'Chớp mắt',
  };
  // THAY ĐỔI: Cập nhật danh sách trạng thái hoàn thành
  final List<bool> _actionCompleted = List.filled(LivenessAction.values.length, false);
  bool _isProcessing = false;

  String _statusMessage = 'Hãy đưa khuôn mặt vào khung hình';
  bool _isFaceDetected = false;

  final int _needValidFrames = 10;
  Map<LivenessAction, int> _frameCounts = {};

  @override
  void initState() {
    super.initState();
    _actions.shuffle(Random());
    _frameCounts = Map.fromIterable(_actions, key: (action) => action, value: (action) => 0);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // var status = await Permission.camera.request();
    // if (status.isDenied || status.isPermanentlyDenied) {
    //   setState(() {
    //     _statusMessage = 'Quyền truy cập camera bị từ chối. Vui lòng cấp quyền trong cài đặt.';
    //   });
    //   if (status.isPermanentlyDenied) {
    //     await openAppSettings();
    //   }
    //   return;
    // }

    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      final front = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () {
          setState(() {
            _statusMessage = 'Không tìm thấy camera trước, sử dụng camera mặc định.';
          });
          return cameras.first;
        },
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {});
        print('Camera khởi tạo thành công.');
        _startImageStream();
      } catch (e) {
        print('Lỗi khi khởi tạo camera: $e');
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Lỗi khởi tạo camera, vui lòng kiểm tra quyền truy cập.';
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Không tìm thấy camera trên thiết bị.';
      });
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _statusMessage = 'Camera chưa được khởi tạo đúng cách.';
      });
      return;
    }

    if (!_cameraController!.value.isStreamingImages) {
      try {
        _cameraController!.startImageStream((CameraImage image) async {
          if (_isProcessing) return;
          _isProcessing = true;
          await _processImage(image);
          _isProcessing = false;
        });
        print('Image stream started successfully');
      } on CameraException catch (e) {
        setState(() {
          _statusMessage = 'Lỗi khi bắt đầu stream camera: $e';
        });
      }
    }
  }

  // Future<void> _processImage(CameraImage cameraImage) async {
  //   if (_actionCompleted.every((c) => c)) {
  //     if (_cameraController!.value.isStreamingImages) {
  //       _cameraController!.stopImageStream();
  //     }
  //     return;
  //   }
  //
  //   final inputImage = inputFromFrame(cameraImage, _cameraController!.description);
  //   if (inputImage == null) {
  //     return;
  //   }
  //
  //   try {
  //     final List<Face> faces = await _faceDetector.processImage(inputImage);
  //     if (!mounted) return;
  //
  //     if (faces.isNotEmpty) {
  //       final face = faces.first;
  //
  //       final box = face.boundingBox;
  //       final faceCenter = Offset(
  //         box.left + box.width / 2,
  //         box.top + box.height / 2,
  //       );
  //
  //       final screenSize = MediaQuery.of(context).size;
  //       final circleCenter = Offset(screenSize.width / 2, screenSize.height / 2);
  //       final circleRadius = screenSize.width / 2; // giống như bạn vẽ
  //
  //       // Tính khoảng cách từ tâm mặt tới tâm vòng tròn
  //       final distance = (faceCenter - circleCenter).distance;
  //
  //       final isInsideCircle = distance + (box.width / 2) < circleRadius;
  //
  //       if (isInsideCircle) {
  //         setState(() {
  //           _isFaceDetected = true;
  //           _checkLiveness(face); // chỉ chạy khi mặt nằm trong khung
  //         });
  //       } else {
  //         setState(() {
  //           _isFaceDetected = false;
  //           _statusMessage = 'Hãy đưa toàn bộ khuôn mặt vào trong khung tròn';
  //         });
  //       }
  //     } else {
  //       setState(() {
  //         _isFaceDetected = false;
  //         _statusMessage = 'Không tìm thấy khuôn mặt, vui lòng đưa khuôn mặt vào khung hình.';
  //       });
  //     }
  //
  //
  //     // if (faces.isNotEmpty) {
  //     //   final face = faces.first;
  //     //   setState(() {
  //     //     _isFaceDetected = true;
  //     //     _checkLiveness(face);
  //     //   });
  //     // } else {
  //     //   setState(() {
  //     //     _isFaceDetected = false;
  //     //     _statusMessage = 'Không tìm thấy khuôn mặt, vui lòng đưa khuôn mặt vào khung hình.';
  //     //   });
  //     // }
  //   } catch (e) {
  //     print('Lỗi khi xử lý ảnh với ML Kit: $e');
  //     if (!mounted) return;
  //     setState(() {
  //       _statusMessage = 'Lỗi xử lý hình ảnh: $e';
  //     });
  //   }
  // }

  Future<void> _processImage(CameraImage cameraImage) async {
    if (_actionCompleted.every((c) => c)) {
      if (_cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
      return;
    }

    final inputImage = inputFromFrame(cameraImage, _cameraController!.description);
    if (inputImage == null) {
      return;
    }

    try {
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      if (faces.isNotEmpty) {
        final face = faces.first;
        final box = face.boundingBox;

        // Kích thước ảnh gốc từ camera
        final imageWidth = _cameraController!.value.previewSize!.height;
        final imageHeight = _cameraController!.value.previewSize!.width;

        // Kích thước widget hiển thị
        final screenSize = MediaQuery.of(context).size;
        final widgetWidth = screenSize.width;
        final widgetHeight = screenSize.height;

        // Scale từ ảnh camera → widget
        final scaleX = widgetWidth / imageWidth;
        final scaleY = widgetHeight / imageHeight;

        // Chuyển boundingBox về hệ toạ độ widget
        final scaledBox = Rect.fromLTRB(
          box.left * scaleX,
          box.top * scaleY,
          box.right * scaleX,
          box.bottom * scaleY,
        );

        // Tọa độ trung tâm khuôn mặt
        final faceCenter = Offset(
          scaledBox.left + scaledBox.width / 2,
          scaledBox.top + scaledBox.height / 2,
        );

        // Vòng tròn bạn vẽ (dựa theo UI)
        final circleCenter = Offset(widgetWidth / 2, widgetHeight / 2);
        final circleRadius = widgetWidth / 2; // giống FaceCirclePainter

        // Kiểm tra: tâm khuôn mặt + nửa chiều rộng < bán kính vòng tròn
        final distance = (faceCenter - circleCenter).distance;
        final isInsideCircle = distance + (scaledBox.width / 2) < circleRadius;

        if (isInsideCircle) {
          setState(() {
            _isFaceDetected = true;
            _checkLiveness(face); // chỉ chạy khi mặt nằm trong khung
          });
        } else {
          setState(() {
            _isFaceDetected = false;
            _statusMessage = 'Hãy đưa toàn bộ khuôn mặt vào trong khung tròn';
          });
        }
      } else {
        setState(() {
          _isFaceDetected = false;
          _statusMessage =
          'Không tìm thấy khuôn mặt, vui lòng đưa khuôn mặt vào khung hình.';
        });
      }
    } catch (e) {
      print('Lỗi khi xử lý ảnh với ML Kit: $e');
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Lỗi xử lý hình ảnh: $e';
      });
    }
  }


  void _checkLiveness(Face face) {
    if (_actionCompleted.every((c) => c)) {
      _finishLivenessCheck();
      return;
    }

    final LivenessAction currentAction = _actions[_currentPage];

    // THAY ĐỔI: Cập nhật ngưỡng cho các hành động
    const double headYawThreshold = 20; // Quay trái/phải
    const double headPitchThreshold = 20; // Nhìn lên/xuống
    const double eyeBlinkThreshold = 0.1;
    const double smileThreshold = 0.05;
    const double headResetThreshold = 50;

    String currentStatus = 'Vui lòng thực hiện: ${_actionDescriptions[currentAction]}';
    bool isActionCorrect = false;

    switch (currentAction) {
      case LivenessAction.turnRight:
        if (face.headEulerAngleY != null && face.headEulerAngleY! < -headYawThreshold) {
          isActionCorrect = true;
          _frameCounts[currentAction] = _frameCounts[currentAction]! + 1;
          currentStatus = '✅ Quay mặt sang phải... ${((_frameCounts[currentAction]! / _needValidFrames) * 100).toInt()}%';
        } else if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() < headResetThreshold) {
          _frameCounts[currentAction] = 0;
          currentStatus = '❌ Vui lòng quay mặt sang phải!';
        }
        break;
      case LivenessAction.turnLeft:
        if (face.headEulerAngleY != null && face.headEulerAngleY! > headYawThreshold) {
          isActionCorrect = true;
          _frameCounts[currentAction] = _frameCounts[currentAction]! + 1;
          currentStatus = '✅ Quay mặt sang trái... ${((_frameCounts[currentAction]! / _needValidFrames) * 100).toInt()}%';
        } else if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() < headResetThreshold) {
          _frameCounts[currentAction] = 0;
          currentStatus = '❌ Vui lòng quay mặt sang trái!';
        }
        break;
    // THAY ĐỔI: Thêm logic cho hành động nhìn lên
      case LivenessAction.lookUp:
      //if (face.headEulerAngleX != null && face.headEulerAngleX! < -headPitchThreshold)
        if (face.headEulerAngleX != null && face.headEulerAngleX! > headPitchThreshold){
          isActionCorrect = true;
          _frameCounts[currentAction] = _frameCounts[currentAction]! + 1;
          currentStatus = '✅ Ngẩn mặt lên... ${((_frameCounts[currentAction]! / _needValidFrames) * 100).toInt()}%';
        } else if (face.headEulerAngleX != null && face.headEulerAngleX!.abs() < headResetThreshold) {
          _frameCounts[currentAction] = 0;
          currentStatus = '❌ Vui lòng ngẩn mặt lên!';
        }
        break;
    // THAY ĐỔI: Thêm logic cho hành động nhìn xuống
      case LivenessAction.lookDown:
      //if (face.headEulerAngleX != null && face.headEulerAngleX! > headPitchThreshold)
        if (face.headEulerAngleX != null && face.headEulerAngleX! < -headPitchThreshold){
          isActionCorrect = true;
          _frameCounts[currentAction] = _frameCounts[currentAction]! + 1;
          currentStatus = '✅ Cúi mặt xuống... ${((_frameCounts[currentAction]! / _needValidFrames) * 100).toInt()}%';
        } else if (face.headEulerAngleX != null && face.headEulerAngleX!.abs() < headResetThreshold) {
          _frameCounts[currentAction] = 0;
          currentStatus = '❌ Vui lòng cúi mặt xuống!';
        }
        break;
      case LivenessAction.smile:
        if (face.smilingProbability != null && face.smilingProbability! > smileThreshold) {
          isActionCorrect = true;
          _frameCounts[currentAction] = _frameCounts[currentAction]! + 1;
          currentStatus = '✅ Mỉm cười... ${((_frameCounts[currentAction]! / _needValidFrames) * 100).toInt()}%';
        } else {
          _frameCounts[currentAction] = 0;
          currentStatus = '❌ Vui lòng mỉm cười!';
        }
        break;
      case LivenessAction.blink:
        final isBlinking = face.rightEyeOpenProbability != null &&
            face.leftEyeOpenProbability != null &&
            face.rightEyeOpenProbability! < eyeBlinkThreshold &&
            face.leftEyeOpenProbability! < eyeBlinkThreshold;

        if (isBlinking) {
          _completeAction();
          currentStatus = '✅ Chớp mắt đã hoàn thành!';
        } else {
          currentStatus = '❌ Vui lòng chớp mắt!';
        }
        break;
    }



    if (currentAction != LivenessAction.blink && isActionCorrect && _frameCounts[currentAction]! >= _needValidFrames) {
      _completeAction();
      if (_actionCompleted.every((c) => c)) {
        _finishLivenessCheck();
        return;
      }
      currentStatus = '✅ Đã hoàn thành, chuyển sang bước tiếp theo';
    }

    setState(() {
      _statusMessage = currentStatus;
    });
  }

  void _completeAction() {
    if (_currentPage < _actions.length && !_actionCompleted[_currentPage]) {
      setState(() {
        _actionCompleted[_currentPage] = true;
        if (_currentPage < _actions.length - 1) {
          _currentPage++;
        }
      });
    }
  }

  void _finishLivenessCheck() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xác thực thành công!')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final cameraRatio = _cameraController!.value.aspectRatio;
    final screenRatio = size.width / size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Camera Preview
            Positioned.fill(
              // child: AspectRatio(
              //   aspectRatio: cameraRatio,
              //   child: CameraPreview(_cameraController!),
              // ),
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),

            // Lớp phủ gradient để làm mờ viền
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.5)],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

            // Khung tròn và mặt nạ
            Center(
              child: CustomPaint(
                size: Size(size.width * 0.8, size.width * 0.8),
                painter: FaceCirclePainter(isFaceDetected: _isFaceDetected),
              ),
            ),

            // Thanh tiến trình
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              // THAY ĐỔI: Sử dụng LivenessProgressIndicator mới
              child: LivenessProgressIndicator(
                actions: _actions.map((e) => _actionDescriptions[e]!).toList(),
                completedActions: _actionCompleted,
              ),
            ),

            // Hiển thị trạng thái
            Positioned(
              bottom: size.height * 0.1,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _isFaceDetected ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_actionCompleted[_currentPage])
                    Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 60,
                    )
                  else
                    Icon(
                      Icons.motion_photos_on,
                      color: Colors.white,
                      size: 60,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET MỚI CHO GIAO DIỆN
// =========================================================================

class FaceCirclePainter extends CustomPainter {
  final bool isFaceDetected;

  FaceCirclePainter({required this.isFaceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isFaceDetected ? Colors.greenAccent : Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Vẽ khung tròn
    canvas.drawCircle(center, radius, paint);

    // Tạo mặt nạ để chỉ hiển thị camera bên trong vòng tròn
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, maskPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is FaceCirclePainter) {
      return oldDelegate.isFaceDetected != isFaceDetected;
    }
    return true;
  }
}

// THAY ĐỔI: Sử dụng Wrap để hiển thị các hành động
class LivenessProgressIndicator extends StatelessWidget {
  final List<String> actions;
  final List<bool> completedActions;

  LivenessProgressIndicator({
    required this.actions,
    required this.completedActions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16.0, // Khoảng cách ngang giữa các item
        runSpacing: 12.0, // Khoảng cách dọc giữa các dòng
        children: List.generate(actions.length, (index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completedActions[index]
                      ? Colors.green
                      : (!completedActions.sublist(0, index).contains(false) && !completedActions[index]
                      ? Colors.blue
                      : Colors.grey),
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
                child: completedActions[index]
                    ? Icon(Icons.check, color: Colors.white)
                    : Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                actions[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: completedActions[index] ? Colors.white : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}