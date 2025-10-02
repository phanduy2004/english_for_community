import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../object/face_to_process.dart';

Future<img.Image?> cropImage(String imagePath) async {
  //final newFilePath = await rotateImage180ToTemp(imagePath, input.angle);
  // if (newFilePath == null) {
  //   return null;
  // }
  final InputImage inputImage = InputImage.fromFilePath(imagePath); //to detect
  final file = File(imagePath);
  final Uint8List imageBytes = await file.readAsBytes(); //image to crop
  final options =
  FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
  final faceDetector = FaceDetector(options: options);
  final List<Face> faces = await faceDetector.processImage(inputImage);
  if (faces.isNotEmpty) {
    Face largestFace = faces.reduce((a, b) =>
    a.boundingBox.width * a.boundingBox.height >
        b.boundingBox.width * b.boundingBox.height
        ? a
        : b);

    final box = largestFace.boundingBox;
    final croppedBytes = await compute(
      cropImageInIsolate,
      CropParams(imageBytes, box),
    );

    return img.decodeImage(croppedBytes);
  } else {
    print("face is empty &&&&&&&&&&&&&&&&&");
  }
  print("return null");
  return null;
}

// Future<String?> rotateImage180ToTemp(String inputFilePath, int angle) async {
//   try {
//     final inputFile = File(inputFilePath);
//     final bytes = await inputFile.readAsBytes();
//     final image = img.decodeImage(bytes);
//     if (image == null) return null;
//     final rotated = img.copyRotate(image, angle: angle);
//     final tempDir = await getTemporaryDirectory();
//     final newPath = path.join(
//       tempDir.path,
//       'rotated_${path.basename(inputFile.path)}',
//     );
//     final rotatedFile = File(newPath);
//     await rotatedFile.writeAsBytes(img.encodeJpg(rotated));
//     return newPath;
//   } catch (e) {
//     print('Lỗi khi xoay ảnh: $e');
//     return null;
//   }
// }

Future<Uint8List> cropImageInIsolate(CropParams params) async {
  final image = img.decodeImage(params.imageBytes);
  if (image == null) throw Exception("Decode image failed");

  const padding = 0.1; // Tăng thêm 30% lề
  final verticalPadding = params.boundingBox.height * padding;
  final horizontalPadding = params.boundingBox.width * padding;

  // BƯỚC 2: Tính toán lại tọa độ và kích thước mới
// Dịch toạ độ gốc sang trái và lên trên
  final newX = params.boundingBox.left - horizontalPadding;
  final newY = params.boundingBox.top - verticalPadding;

  // Tăng chiều rộng và chiều cao (padding * 2 vì có cả 2 bên)
  final newW = params.boundingBox.width + (horizontalPadding * 2);
  final newH = params.boundingBox.height + (verticalPadding * 2);

  final x = newX.clamp(0, image.width - 1).toInt();
  final y = newY.clamp(0, image.height - 1).toInt();
  final w = newW.clamp(1, image.width - x).toInt();
  final h = newH.clamp(1, image.height - y).toInt();

  final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
  return Uint8List.fromList(img.encodeJpg(cropped));
}

// Future<img.Image?> cropImageFromFile(File faceImage, Rect box) async {
//   final imageBytes = faceImage.readAsBytesSync(); //image to crop
//   img.Image originalImage = img.decodeImage(imageBytes)!;
//   final x = box.left.clamp(0, originalImage.width - 1).toInt();
//   final y = box.top.clamp(0, originalImage.height - 1).toInt();
//   final w = box.width.clamp(1, originalImage.width - x).toInt();
//   final h = box.height.clamp(1, originalImage.height - y).toInt();
//   img.Image cropped =
//       img.copyCrop(originalImage, x: x, y: y, width: w, height: h);
//   return cropped;
// }

// Future<String> saveImage(File imageFile) async {
//   final dir = await getApplicationDocumentsDirectory();
//   final path = '${dir.path}/imageFile.jpg';
//   final file = File(path);
//
//   final bytes = await imageFile.readAsBytes();
//   await file.writeAsBytes(bytes);
//   return path;
// }
