import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../services/ai_service.dart'; // Import AI Service
import 'result_screen.dart'; // Import Result Screen

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  // LOGIC: Analyze the image using TFLite
  Future<void> _analyzeImage(BuildContext context) async {
    // 1. Show Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot click outside to close
      builder: (ctx) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text("Analyzing...", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // 2. Ensure Model is Loaded
      await AiService.loadModel();

      // 3. Run Prediction
      final predictions = await AiService.classifyImage(imagePath);

      // 4. Close Loading Dialog
      if (context.mounted) Navigator.pop(context);

      if (predictions != null && predictions.isNotEmpty) {
        // 5. Success! Go to Result Screen
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ResultScreen(imagePath: imagePath, predictions: predictions),
            ),
          );
        }
      } else {
        // AI returned nothing (Model might be missing or image is invalid)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not identify disease. Try a clearer photo."),
            ),
          );
        }
      }
    } catch (e) {
      // Handle crashes/errors
      if (context.mounted) {
        Navigator.pop(context); // Close dialog if open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppTranslations.getText(langCode, 'preview_image'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // 1. The Image Preview
          Expanded(child: Image.file(File(imagePath), fit: BoxFit.contain)),

          // 2. Validation Area (White Box)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppTranslations.getText(langCode, 'is_image_clear'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // --- Retake Button ---
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Go back to Camera
                        },
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        label: Text(
                          AppTranslations.getText(langCode, 'retake'),
                          style: const TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // --- Analyze Button ---
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _analyzeImage(context), // Logic trigger
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          AppTranslations.getText(langCode, 'analyze'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
