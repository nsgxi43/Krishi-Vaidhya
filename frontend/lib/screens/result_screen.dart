import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  final List<dynamic> predictions;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.predictions,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    // 1. Parse AI Output
    final topResult = predictions.isNotEmpty ? predictions[0] : null;
    final String rawLabel = topResult != null ? topResult['label'] : "Unknown";

    // Format Label (e.g., "Tomato___Early_blight" -> "Tomato Early Blight")
    final String displayLabel = rawLabel.replaceAll('_', ' ');

    final String confidence = topResult != null
        ? (topResult['confidence'] * 100).toStringAsFixed(1)
        : "0";

    // 2. Determine Health Status
    final bool isHealthy = rawLabel.toLowerCase().contains("healthy");
    final Color statusColor = isHealthy ? Colors.green : Colors.red;

    // 3. Fetch Remedy Logic
    // We construct a key like 'treat_Tomato___Early_blight' to look up the dictionary
    String remedyKey = 'treat_$rawLabel';
    String remedyText = AppTranslations.getText(langCode, remedyKey);

    // If exact remedy isn't found in dictionary, show generic message
    if (remedyText == remedyKey) {
      remedyText = AppTranslations.getText(langCode, 'treat_unknown');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText(langCode, 'diagnosis_report')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image Section ---
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black12,
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // --- Diagnosis Section ---
            Container(
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label & Confidence
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getText(
                                langCode,
                                'detected_issue',
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayLabel,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$confidence%",
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              AppTranslations.getText(langCode, 'confidence'),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // --- Remedy Section ---
                  Text(
                    isHealthy
                        ? AppTranslations.getText(langCode, 'healthy_crop')
                        : AppTranslations.getText(langCode, 'treatment_header'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (isHealthy)
                    // Healthy Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppTranslations.getText(langCode, 'healthy_msg'),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Disease Treatment Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.medical_services,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.getText(
                                  langCode,
                                  'chemical_control',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            remedyText, // <--- The dynamic translated remedy
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppTranslations.getText(langCode, 'consult_expert'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // --- Action Buttons ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Reset everything and go Home
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppTranslations.getText(langCode, 'home'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
