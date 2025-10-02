import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;


class FaceToProcess{
  final img.Image image;
  final List<double> emb;
  final SendPort replyPort;
  final String modelFilePath;
  FaceToProcess( this.image, this.emb, this.replyPort, this.modelFilePath);
}

class CroppedImageToProcess {
  final Uint8List imageBytes;
  final String modelPath;
  CroppedImageToProcess( this.imageBytes, this.modelPath);
}

class CropParams {
  final Uint8List imageBytes;
  final Rect boundingBox;

  CropParams(this.imageBytes, this.boundingBox);
}

class CropAndRotate{
  final String imagePath;
  final int angle;

  CropAndRotate(this.imagePath, this.angle);
}

