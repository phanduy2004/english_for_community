/*
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../services/facenet_service/improve_face_detect_service.dart';
import '../../services/facenet_service/improve_facenet_service.dart';
import '../../utils/values.dart';
import 'face_enrollment_page.dart';

class RecognizeFacePicturePage extends StatefulWidget {
  const RecognizeFacePicturePage({super.key});

  @override
  State<RecognizeFacePicturePage> createState() =>
      _RecognizeFacePicturePageState();
}

class _RecognizeFacePicturePageState extends State<RecognizeFacePicturePage> {
  final _picker = ImagePicker();
  final _faceNetService = ImprovedFaceNetService();
  final _faceDetectionService = ImprovedFaceDetectionService();

  File? _image;
  List<img.Image> _croppedFaces = [];
  Map<String, dynamic>? _recognition;
  bool _loading = false;
  bool _isPickingImage = false;

  // ---------- UI helpers ----------
  void _toast(String msg, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _buildBestMatch() {
    final name = _recognition?['name'] as String?;
    final distance = (_recognition?['distance'] as double?) ?? double.infinity;

    if (name == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Best match: ${name.isNotEmpty ? name : "Unknown"}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Distance: ${distance.isFinite ? distance.toStringAsFixed(4) : "N/A"}',
          style: TextStyle(
            color: distance < threshold ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------- Image helpers ----------
  Future<File> _ensureJpeg(XFile picked) async {
    try {
      final bytes = await picked.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Không decode được ảnh');
      final jpg = img.encodeJpg(decoded, quality: 95);
      final path =
          '${Directory.systemTemp.path}/converted_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final f = File(path);
      await f.writeAsBytes(jpg);
      return f;
    } catch (_) {
      // fallback: dùng file gốc
      return File(picked.path);
    }
  }

  Future<void> _pickAndRecognizeImage() async {
    if (_isPickingImage) return; // Prevent multiple simultaneous calls

    setState(() => _isPickingImage = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null) return;

      setState(() {
        _loading = true;
        _image = null;
        _croppedFaces = [];
        _recognition = null;
      });

      try {
        final imageFile = await _ensureJpeg(picked);

        // detect & crop
        final faces = await _faceDetectionService.cropAllFaces(imageFile);
        if (faces.isEmpty) {
          setState(() {
            _image = imageFile;
            _recognition = {'name': 'No face detected', 'confidence': 0.0};
          });
          return;
        }

        // recognize face đầu tiên
        final result = await _faceNetService.recognizeFace(faces.first);
        setState(() {
          _image = imageFile;
          _croppedFaces = faces;
          _recognition = result ?? {'name': 'Unknown', 'confidence': 0.0};
        });
      } catch (e) {
        setState(() {
          _recognition = {'name': 'Error', 'confidence': 0.0};
        });
        _toast('Lỗi xử lý ảnh: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Advanced Face Recognition"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Enroll khuôn mặt',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FaceEnrollmentPage()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Ảnh gốc
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border.all(color: Colors.black12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.cover)
                  : const Center(child: Text("No image")),
            ),
            const SizedBox(height: 16),

            // Khuôn mặt detect
            if (_croppedFaces.isNotEmpty) ...[
              const Text(
                "Detected faces:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _croppedFaces.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      Uint8List.fromList(img.encodeJpg(_croppedFaces[i])),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nút chọn ảnh
            ElevatedButton(
              onPressed:
                  (_loading || _isPickingImage) ? null : _pickAndRecognizeImage,
              child: (_loading || _isPickingImage)
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Pick & Recognize"),
            ),
            const SizedBox(height: 16),

            // Kết quả
            _buildBestMatch(),
          ],
        ),
      ),
    );
  }
}
*/
