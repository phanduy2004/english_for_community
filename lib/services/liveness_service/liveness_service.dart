import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:yuv_converter/yuv_converter.dart';

class LivenessService {
  Interpreter? _interpreter;
  static const int inputSize = 160;

  Future<void> loadModelFromBytes(Uint8List modelBytes) async {
    _interpreter?.close();
    try {
      _interpreter = Interpreter.fromBuffer(modelBytes);
      debugPrint("✅ Load model success");
    } catch (e) {
      debugPrint("❌ Load model error: $e");
    }
  }

  Future<void> reloadModel(String path) async {
    final byteData = await rootBundle.load(path);
    final modelBytes = byteData.buffer.asUint8List();
    await loadModelFromBytes(modelBytes);
  }

  // === FEED cho ML Kit ===
  InputImage? inputImageFromCameraImage(
    CameraImage image,
    InputImageRotation rotation,
  ) {
    if (!Platform.isAndroid) {
      // iOS: BGRA
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    // Android
    final raw = image.format.raw; // 17=NV21, 35=YUV_420_888
    Uint8List? nv21;

    if (raw == 17 && image.planes.length == 1) {
      // NV21 contiguous
      nv21 = image.planes[0].bytes;
    } else if (raw == 35 && image.planes.length == 3) {
      // Convert YUV_420_888 -> NV21
      nv21 = _yuv420ToNv21(image);
    } else {
      return null;
    }

    if (nv21 == null) return null;

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21, // feed NV21
        bytesPerRow: image.planes[0].bytesPerRow, // stride của Y
      ),
    );
  }

  // === PREDICT cho model TFLite ===
  Future<double> predict(CameraImage cameraImage, Face face) async {
    if (_interpreter == null) return -1;

    try {
      // Luôn chuẩn hoá về NV21 (đồng bộ với ML Kit)
      final nv21 =
          (cameraImage.format.raw == 17 && cameraImage.planes.length == 1)
              ? cameraImage.planes[0].bytes
              : _yuv420ToNv21(cameraImage);

      if (nv21 == null) {
        return -1;
      }

      // NV21 -> RGBA (thư viện yuv_converter)
      final Uint8List rgbaBytes = YuvConverter.yuv420NV21ToRgba8888(
        nv21,
        cameraImage.width,
        cameraImage.height,
      );

      // RGBA -> image
      final rgbImage = img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: rgbaBytes.buffer,
        order: img.ChannelOrder.rgba,
      );

      // Crop theo bounding box
      final rect = face.boundingBox;
      final x = rect.left.toInt().clamp(0, rgbImage.width - 1);
      final y = rect.top.toInt().clamp(0, rgbImage.height - 1);
      final w = rect.width.toInt().clamp(1, rgbImage.width - x);
      final h = rect.height.toInt().clamp(1, rgbImage.height - y);

      final cropped = img.copyCrop(rgbImage, x: x, y: y, width: w, height: h);
      final resized =
          img.copyResize(cropped, width: inputSize, height: inputSize);

      final input = _preProcess(resized);
      final output = List.filled(1, 0.0).reshape([1, 1]);

      _interpreter!.run(input, output);
      final score = output[0][0] as double;

      debugPrint("🔎 Liveness score = $score, bbox=$rect");
      return score;
    } catch (e) {
      debugPrint("❌ Error predicting: $e");
      return -1;
    }
  }

  // Chuẩn hoá input [-1,1]
  List<List<List<List<double>>>> _preProcess(img.Image image) {
    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(inputSize, (_) => List.filled(3, 0.0)),
      ),
    );
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = image.getPixel(x, y);
        input[0][y][x][0] = (p.r - 127.5) / 127.5;
        input[0][y][x][1] = (p.g - 127.5) / 127.5;
        input[0][y][x][2] = (p.b - 127.5) / 127.5;
      }
    }
    return input;
  }

  // === Converter: YUV_420_888 -> NV21 (VU interleave) ===
  Uint8List? _yuv420ToNv21(CameraImage img) {
    try {
      final width = img.width;
      final height = img.height;

      final yPlane = img.planes[0];
      final uPlane = img.planes[1];
      final vPlane = img.planes[2];

      final int ySize = width * height;
      final int uvSize = width * height ~/ 2;
      final out = Uint8List(ySize + uvSize);

      // Copy Y (từng dòng để bỏ padding theo rowStride)
      int dst = 0;
      for (int r = 0; r < height; r++) {
        final src = r * yPlane.bytesPerRow;
        out.setRange(dst, dst + width, yPlane.bytes.sublist(src, src + width));
        dst += width;
      }

      // Copy VU (NV21) từ U/V planes (pixelStride có thể là 1 hoặc 2)
      final uvWidth = width ~/ 2;
      final uvHeight = height ~/ 2;
      final uRowStride = uPlane.bytesPerRow;
      final vRowStride = vPlane.bytesPerRow;
      final uPixelStride = uPlane.bytesPerPixel ?? 1;
      final vPixelStride = vPlane.bytesPerPixel ?? 1;

      int uvDst = ySize;
      for (int r = 0; r < uvHeight; r++) {
        int uSrc = r * uRowStride;
        int vSrc = r * vRowStride;
        for (int c = 0; c < uvWidth; c++) {
          final v = vPlane.bytes[vSrc];
          final u = uPlane.bytes[uSrc];
          out[uvDst++] = v; // V trước
          out[uvDst++] = u; // U sau  => NV21 (VU)
          uSrc += uPixelStride;
          vSrc += vPixelStride;
        }
      }
      return out;
    } catch (e) {
      debugPrint("_yuv420ToNv21 failed: $e");
      return null;
    }
  }

  Uint8List? cropFaceAsBytes(CameraImage cameraImage, Face face,
      {InputImageRotation? rotation}) {
    try {
      final Uint8List? nv21 =
          (cameraImage.format.raw == 17 && cameraImage.planes.length == 1)
              ? cameraImage.planes[0].bytes
              : _yuv420ToNv21(cameraImage);

      if (nv21 == null) return null;

      final Uint8List rgbaBytes = YuvConverter.yuv420NV21ToRgba8888(
        nv21,
        cameraImage.width,
        cameraImage.height,
      );

      img.Image rgbImage = img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: rgbaBytes.buffer,
        order: img.ChannelOrder.rgba,
      );

      // 👉 Xoay ảnh theo rotation (nếu có)
      if (rotation != null) {
        switch (rotation) {
          case InputImageRotation.rotation90deg:
            rgbImage = img.copyRotate(rgbImage, angle: 90);
            break;
          case InputImageRotation.rotation180deg:
            rgbImage = img.copyRotate(rgbImage, angle: 180);
            break;
          case InputImageRotation.rotation270deg:
            rgbImage = img.copyRotate(rgbImage, angle: 270);
            break;
          default:
            break;
        }
      }

      // Crop theo bounding box
      final rect = face.boundingBox;
      final x = rect.left.toInt().clamp(0, rgbImage.width - 1);
      final y = rect.top.toInt().clamp(0, rgbImage.height - 1);
      final w = rect.width.toInt().clamp(1, rgbImage.width - x);
      final h = rect.height.toInt().clamp(1, rgbImage.height - y);

      final cropped = img.copyCrop(rgbImage, x: x, y: y, width: w, height: h);

      return Uint8List.fromList(img.encodeJpg(cropped));
    } catch (e) {
      debugPrint("cropFaceAsBytes error: $e");
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
