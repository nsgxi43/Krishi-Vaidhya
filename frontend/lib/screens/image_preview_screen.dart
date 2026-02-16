import 'dart:io' as io;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../services/api_service.dart'; // Import API Service
import 'result_screen.dart'; // Import Result Screen

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  // LOGIC: Analyze the image using Backend (Gemini/CNN)
  Future<void> _analyzeImage(BuildContext context) async {
    // 1. Show Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text("Analyzing crop...", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // 2. Upload to Backend
      // TODO: Get actual user location if available. Using default for now.
      final response = await ApiService.uploadImage(
        imagePath, 
        "user_123", // Replace with real user ID from Provider if available
        12.9716, // Default Lat (Bangalore)
        77.5946  // Default Lng (Bangalore)
      );

      // 3. Close Loading Dialog
      if (context.mounted) Navigator.pop(context);

      if (response != null) {
        // 4. Success! Go to Result Screen
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ResultScreen(imagePath: imagePath, response: response),
            ),
          );
        }
      } else {
        // AI returned nothing (Model might be missing or image is invalid)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Analysis failed. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle crashes/errors
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Extract user-friendly error message
        String errorMessage = "Analysis failed. Please try again.";
        bool isNotPlantError = false;
        
        if (e.toString().contains("Not a Plant Image") || e.toString().contains("not appear to be")) {
          isNotPlantError = true;
          errorMessage = "The uploaded image does not appear to be a clear plant/crop image.";
        } else if (e.toString().contains("Exception:")) {
          // Extract message after "Exception: "
          errorMessage = e.toString().replaceFirst("Exception: ", "");
        }
        
        // Show prominent dialog for non-plant images
        if (isNotPlantError) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text("Not a Plant Image"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Tips for best results:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text("• Take a clear photo of plant leaves"),
                        Text("• Show affected/diseased areas"),
                        Text("• Ensure good lighting"),
                        Text("• Avoid blurry images"),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Go back to camera
                  },
                  child: Text("Retake Photo", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        } else {
          // Show SnackBar for other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
          Expanded(
            child: kIsWeb
                ? Image.network(imagePath, fit: BoxFit.contain)
                : Image.file(io.File(imagePath), fit: BoxFit.contain),
          ),

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
