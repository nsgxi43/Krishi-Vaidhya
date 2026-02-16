import 'dart:io' as io;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../models/diagnosis_response.dart';
import 'home_screen.dart';
import 'agri_store_screen.dart';
import '../services/community_service.dart';
import '../providers/user_provider.dart';
import 'remedies_screen.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  final DiagnosisResponse response;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final bool isHealthy = response.isHealthy;
    final Color statusColor = isHealthy ? Colors.green : Colors.red;

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
                  image: kIsWeb
                      ? NetworkImage(imagePath)
                      : FileImage(io.File(imagePath)) as ImageProvider,
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
                              AppTranslations.getText(langCode, 'detected_issue'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              response.displayLabel,
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
                              "${(response.confidence * 100).toStringAsFixed(1)}%",
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

                  // --- AI Explanation (LLM) ---
                  if (response.llm != null) ...[
                    Text(
                      "AI Analysis",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Analysis", Icons.analytics),
                          Text(response.llm!.whyThisPrediction),
                          const SizedBox(height: 12),
                          _buildSectionTitle("Overview", Icons.info),
                          Text(response.llm!.diseaseOverview),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Remedy summary removed - points to RemediesScreen
                  const SizedBox(height: 12),

                  const SizedBox(height: 24),

                  // --- Nearby Stores (NEW) ---
                  if (response.nearbyStores.isNotEmpty) ...[
                    Text(
                      "Nearby Agri Stores",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: response.nearbyStores.length,
                        itemBuilder: (context, index) {
                          final store = response.nearbyStores[index];
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${store.distanceKm} km away",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.green),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  store.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: () => _launchMaps(store.mapsUrl),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: EdgeInsets.zero),
                                    child: const Text("Get Directions",
                                        style: TextStyle(fontSize: 10)),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                      // Next: View Remedies Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RemediesScreen(response: response),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          label: const Text(
                            "Next: View Remedies",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Share to Community
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _showShareDialog(context, langCode),
                          icon: const Icon(Icons.share, color: Colors.teal),
                          label: Text(
                            AppTranslations.getText(langCode, 'share_community'),
                            style: const TextStyle(color: Colors.teal, fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Back to Home
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: Text(
                            AppTranslations.getText(langCode, 'home'),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
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

  Widget _buildSectionTitle(String title, IconData icon, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, String langCode) {
    final TextEditingController controller = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.getText(langCode, 'share_community')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${AppTranslations.getText(langCode, 'sharing_result')}: ${response.displayLabel}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: AppTranslations.getText(langCode, 'write_something'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.getText(langCode, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = controller.text.isEmpty
                  ? "Check out my ${response.crop} diagnosis!"
                  : controller.text;

              final success = await CommunityService.createPost(
                userProvider.phone,
                content,
                0.0, // Should use real location if available
                0.0,
                imagePath: imagePath,
                analysisData: {
                  'crop': response.crop,
                  'disease': response.predictedDisease,
                  'confidence': response.confidence,
                  'label': response.displayLabel,
                },
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppTranslations.getText(langCode, 'share_success'))),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppTranslations.getText(langCode, 'share_failed'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text(
              AppTranslations.getText(langCode, 'post_btn'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getFallbackRemedy(String label, String langCode) {
    String remedyKey = 'treat_$label';
    String remedyText = AppTranslations.getText(langCode, remedyKey);
    if (remedyText == remedyKey) {
      return AppTranslations.getText(langCode, 'treat_unknown');
    }
    return remedyText;
  }
}
