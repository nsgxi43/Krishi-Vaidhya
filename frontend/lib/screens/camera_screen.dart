import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <--- Import Image Picker
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import 'image_preview_screen.dart'; // <--- Import Preview Screen

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker(); // Instance of Image Picker

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use high resolution for better AI detection
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller!.initialize();

    if (mounted) setState(() => _isCameraInitialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // LOGIC: Take Photo from Camera
  Future<void> _takePicture() async {
    if (!_isCameraInitialized) return;
    try {
      final image = await _controller!.takePicture();
      if (mounted) _goToPreview(image.path);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // LOGIC: Pick Photo from Gallery (Story 3.1)
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      _goToPreview(image.path);
    }
  }

  // Helper to navigate to Validation Screen
  void _goToPreview(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(imagePath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          Center(child: CameraPreview(_controller!)),

          // 2. Guide Overlay (Visual aid for focus)
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white54,
                size: 40,
              ), // Center focus point
            ),
          ),

          // 3. Controls Area
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Gallery Button
                  IconButton(
                    onPressed: _pickFromGallery,
                    icon: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 30,
                    ),
                    tooltip: AppTranslations.getText(langCode, 'gallery'),
                  ),

                  // Capture Button
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 4),
                      ),
                    ),
                  ),

                  // Flash Button (Placeholder logic)
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
