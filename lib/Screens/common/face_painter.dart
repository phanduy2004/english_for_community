import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  final Size imageSize;
  final InputImageRotation imageRotation;
  final List<Face> faces;
  final Map<String, Map<String, dynamic>> results;
  final CameraLensDirection cameraLensDirection;

  FacePainter({
    required this.imageSize,
    required this.imageRotation,
    required this.faces,
    required this.results,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint realPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.green;

    final Paint spoofPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    // scale map trực tiếp ảnh gốc -> khung hiển thị
    double scaleX, scaleY;

    if (imageRotation == InputImageRotation.rotation90deg ||
        imageRotation == InputImageRotation.rotation270deg) {
      // khi camera stream xoay 90/270 -> đảo width/height
      scaleX = size.width / imageSize.height;
      scaleY = size.height / imageSize.width;
    } else {
      scaleX = size.width / imageSize.width;
      scaleY = size.height / imageSize.height;
    }

    for (final face in faces) {
      final r = face.boundingBox;

      double left = r.left * scaleX;
      double top = r.top * scaleY;
      double right = r.right * scaleX;
      double bottom = r.bottom * scaleY;

      // lật gương nếu camera trước
      if (cameraLensDirection == CameraLensDirection.front) {
        final tmpLeft = left;
        left = size.width - right;
        right = size.width - tmpLeft;
      }

      final box = Rect.fromLTRB(left, top, right, bottom);

      final key = face.boundingBox.toString();
      final res = results[key] ?? {"label": "...", "score": 0.0};
      final label = (res["label"] as String?) ?? "...";
      final score = (res["score"] as double?) ?? 0.0;
      final paint = label == "Real" ? realPaint : spoofPaint;

      canvas.drawRect(box, paint);

      // label text
      final tp = TextPainter(
        text: TextSpan(
          text: "$label (${score.toStringAsFixed(2)})",
          style: TextStyle(
            color: paint.color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black.withOpacity(0.55),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(box.left, box.top - 22));
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.faces != faces ||
        oldDelegate.imageRotation != imageRotation ||
        oldDelegate.results != results;
  }
}
