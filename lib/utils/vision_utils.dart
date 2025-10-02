import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/rendering.dart' show applyBoxFit, BoxFit;

class VisionUtils {
  const VisionUtils._();

  // Cache để tối ưu performance
  static final Map<String, img.Image> _imageCache = {};
  static int _cacheSize = 0;
  static const int _maxCacheSize = 3; // Giới hạn cache

  /// Tạo InputImage từ frame camera với tối ưu
  static InputImage? inputFromFrame(CameraImage f, InputImageRotation rot) {
    if (Platform.isIOS) {
      if (f.format.group != ImageFormatGroup.bgra8888 || f.planes.isEmpty) return null;
      final p = f.planes.first;
      if (p.bytes.isEmpty) return null;
      return InputImage.fromBytes(
        bytes: p.bytes,
        metadata: InputImageMetadata(
          size: Size(f.width.toDouble(), f.height.toDouble()),
          rotation: rot,
          format: InputImageFormat.bgra8888,
          bytesPerRow: p.bytesPerRow,
        ),
      );
    } else {
      if (f.format.group != ImageFormatGroup.yuv420 || f.planes.length < 3) return null;
      final wb = WriteBuffer();
      for (final p in f.planes) {
        if (p.bytes.isEmpty) return null;
        wb.putUint8List(p.bytes);
      }
      return InputImage.fromBytes(
        bytes: wb.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size: Size(f.width.toDouble(), f.height.toDouble()),
          rotation: rot,
          format: InputImageFormat.nv21,
          bytesPerRow: f.planes[0].bytesPerRow,
        ),
      );
    }
  }

  /// Chuyển frame camera → ảnh RGB với tối ưu
  static Future<img.Image> rgbFromFrame(CameraImage f) async {
    final w = f.width, h = f.height;
    final cacheKey = '${w}x${h}_${f.format.group}';

    if (Platform.isIOS && f.format.group == ImageFormatGroup.bgra8888) {
      final p = f.planes.first;
      final data = p.bytes;
      final out = img.Image(width: w, height: h);

      // Tối ưu loop với buffer access pattern tốt hơn
      for (int y = 0; y < h; y++) {
        final rowOffset = y * w * 4;
        for (int x = 0; x < w; x++) {
          final pixelOffset = rowOffset + (x * 4);
          final b = data[pixelOffset + 0];
          final g = data[pixelOffset + 1];
          final r = data[pixelOffset + 2];
          out.setPixelRgb(x, y, r, g, b);
        }
      }
      return out;
    }

    // Android NV21 -> RGB optimized
    return _convertNV21ToRGB(f);
  }

  /// Tối ưu conversion NV21 -> RGB
  static img.Image _convertNV21ToRGB(CameraImage frame) {
    final w = frame.width, h = frame.height;
    final yPlane = frame.planes[0].bytes;
    final uPlane = frame.planes[1].bytes;
    final vPlane = frame.planes[2].bytes;
    final uvRowStride = frame.planes[1].bytesPerRow;
    final uvPixelStride = frame.planes[1].bytesPerPixel ?? 1;

    final out = img.Image(width: w, height: h);

    // Pre-compute constants
    const double cr = 1.402;
    const double cg1 = 0.344136;
    const double cg2 = 0.714136;
    const double cb = 1.772;

    for (int y = 0; y < h; y++) {
      final yRow = y * w;
      final uvRow = (y >> 1) * uvRowStride; // Bit shift thay vì chia

      for (int x = 0; x < w; x++) {
        final yy = yPlane[yRow + x];
        final uvIndex = uvRow + ((x >> 1) * uvPixelStride);
        final u = uPlane[uvIndex] - 128;
        final v = vPlane[uvIndex] - 128;

        // Optimized YUV to RGB conversion
        final r = (yy + cr * v).round().clamp(0, 255);
        final g = (yy - cg1 * u - cg2 * v).round().clamp(0, 255);
        final b = (yy + cb * u).round().clamp(0, 255);

        out.setPixelRgb(x, y, r, g, b);
      }
    }
    return out;
  }

  /// Crop + resize với tối ưu performance
  static img.Image standardize(
      img.Image src,
      Rect box, {
        double margin = .08,
        required int targetW,
        required int targetH,
      }) {
    // Pre-calculate values
    final boxW = box.width;
    final boxH = box.height;
    final ex = boxW * margin;
    final ey = boxH * margin;

    // Clamp coordinates
    final x0 = (box.left - ex).floor().clamp(0, src.width - 1);
    final y0 = (box.top - ey).floor().clamp(0, src.height - 1);
    final x1 = (box.right + ex).ceil().clamp(x0 + 1, src.width);
    final y1 = (box.bottom + ey).ceil().clamp(y0 + 1, src.height);

    // Crop với bounds checking
    final cropW = x1 - x0;
    final cropH = y1 - y0;
    if (cropW <= 0 || cropH <= 0) {
      return img.Image(width: targetW, height: targetH); // Return empty image
    }

    final face = img.copyCrop(src, x: x0, y: y0, width: cropW, height: cropH);

    // Resize với interpolation tối ưu
    return img.copyResize(
        face,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.linear
    );
  }

  /// Map bbox với tối ưu calculations
  static Rect? mapRectToPreview(Rect? r, Size srcSize, Size previewSize, bool mirror) {
    if (r == null) return null;

    // Pre-calculate fit once
    final fit = applyBoxFit(BoxFit.cover, srcSize, previewSize);
    final scaleX = fit.destination.width / fit.source.width;
    final scaleY = fit.destination.height / fit.source.height;
    final offsetX = (previewSize.width - fit.destination.width) * 0.5;
    final offsetY = (previewSize.height - fit.destination.height) * 0.5;

    // Apply transformations
    double left = r.left * scaleX + offsetX;
    double top = r.top * scaleY + offsetY;
    double right = r.right * scaleX + offsetX;
    double bottom = r.bottom * scaleY + offsetY;

    // Mirror logic optimized
    if (mirror) {
      final temp = previewSize.width - right;
      right = previewSize.width - left;
      left = temp;
    }

    // Clamp once at the end
    return Rect.fromLTRB(
      left.clamp(0.0, previewSize.width),
      top.clamp(0.0, previewSize.height),
      right.clamp(0.0, previewSize.width),
      bottom.clamp(0.0, previewSize.height),
    );
  }

  /// Optimized face selection
  static Face? pickBest(
      List<Face> faces, {
        required double minBox,
        required double maxAbsYaw,
        required double maxAbsRoll,
      }) {
    if (faces.isEmpty) return null;

    // Pre-filter and sort in one pass
    Face? bestFace;
    double bestArea = 0;
    bool hasgoodFace = false;

    for (final face in faces) {
      final yaw = (face.headEulerAngleY?.abs() ?? 0);
      final roll = (face.headEulerAngleZ?.abs() ?? 0);
      final box = face.boundingBox;
      final area = box.width * box.height;

      final isGood = yaw <= maxAbsYaw &&
          roll <= maxAbsRoll &&
          box.width >= minBox &&
          box.height >= minBox;

      // Priority: good face with larger area, or any face with larger area if no good faces
      if (isGood && !hasgoodFace) {
        // First good face found
        bestFace = face;
        bestArea = area;
        hasgoodFace = true;
      } else if (isGood && hasgoodFace && area > bestArea) {
        // Better good face
        bestFace = face;
        bestArea = area;
      } else if (!hasgoodFace && area > bestArea) {
        // Better face when no good faces available
        bestFace = face;
        bestArea = area;
      }
    }

    return bestFace;
  }

  /// Quick face quality check
  static bool isGood(
      Face f, {
        required double minBox,
        required double maxAbsYaw,
        required double maxAbsRoll,
      }) {
    final box = f.boundingBox;
    return (f.headEulerAngleY?.abs() ?? 0) <= maxAbsYaw &&
        (f.headEulerAngleZ?.abs() ?? 0) <= maxAbsRoll &&
        box.width >= minBox &&
        box.height >= minBox;
  }

  /// Clear caches to free memory
  static void clearCaches() {
    _imageCache.clear();
    _cacheSize = 0;
  }
}