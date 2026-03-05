import 'dart:io' as io;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../utils/translations.dart';
import '../services/api_service.dart'; // Import API Service
import '../services/offline_service.dart';
import 'result_screen.dart'; // Import Result Screen

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  // LOGIC: Analyze the image using Backend (Gemini/CNN)
  Future<void> _analyzeImage(BuildContext context) async {
    // ── Check connectivity first ──────────────────────────────────────────
    final online = await OfflineService.isOnline();

    if (!online) {
      await _analyzeImageOffline(context);
      return;
    }

    // ── Online flow (unchanged) ───────────────────────────────────────────
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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.phone.isNotEmpty ? userProvider.phone : "guest_user";

      final response = await ApiService.uploadImage(
        imagePath,
        userId,
        12.9716,
        77.5946,
      );

      // 3. Close Loading Dialog
      if (context.mounted) Navigator.pop(context);

      if (response != null) {
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
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        String errorMessage = "Analysis failed. Please try again.";
        bool isNotPlantError = false;

        if (e.toString().contains("Not a Plant Image") ||
            e.toString().contains("not appear to be")) {
          isNotPlantError = true;
          errorMessage =
              "The uploaded image does not appear to be a clear plant/crop image.";
        } else if (e.toString().contains("Exception:")) {
          errorMessage = e.toString().replaceFirst("Exception: ", "");
        }

        if (isNotPlantError) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text("Not a Plant Image"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMessage, style: TextStyle(fontSize: 16)),
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
                            Icon(Icons.lightbulb_outline,
                                color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text("Tips for best results:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800)),
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
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child:
                      Text("Retake Photo", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        } else {
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

  // ── Offline diagnosis ─────────────────────────────────────────────────────
  static const List<String> _offlineCrops = [
    'Tomato',
    'Potato',
    'Corn',
    'Wheat',
    'Rice',
  ];

  Future<void> _analyzeImageOffline(BuildContext context) async {
    // Step 1: Let user pick the crop
    final String? selectedCrop = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Color(0xFFF57F17), size: 22),
            SizedBox(width: 8),
            Text('Offline Mode', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "No internet connection. Select your crop to get pre-loaded disease information:",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ..._offlineCrops.map(
              (crop) => ListTile(
                dense: true,
                leading:
                    const Icon(Icons.eco, color: Colors.green, size: 20),
                title: Text(crop,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, crop),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedCrop == null || !context.mounted) return;

    // Step 2: Show disease picker for the selected crop
    final diseases =
        await OfflineService.getDiseasesForCrop(selectedCrop);
    if (diseases.isEmpty || !context.mounted) return;

    final Map<String, dynamic>? selectedDisease =
        await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Select symptom — $selectedCrop',
            style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: diseases
              .map(
                (d) => ListTile(
                  dense: true,
                  leading: Icon(
                    (d['isHealthy'] as bool? ?? false)
                        ? Icons.check_circle_outline
                        : Icons.bug_report_outlined,
                    color: (d['isHealthy'] as bool? ?? false)
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  title: Text(d['displayLabel'] ?? d['diseaseName'],
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(ctx, d),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedDisease == null || !context.mounted) return;

    // Step 3: Build offline DiagnosisResponse and navigate to ResultScreen
    final response = OfflineService.buildOfflineDiagnosisResponse(
        selectedDisease, selectedCrop);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imagePath: imagePath,
            response: response,
            isOffline: true,
          ),
        ),
      );
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
