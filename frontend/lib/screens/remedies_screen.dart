import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diagnosis_response.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import 'agri_store_screen.dart';

class RemediesScreen extends StatelessWidget {
  final DiagnosisResponse response;

  const RemediesScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final bool isHealthy = response.isHealthy;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText(langCode, 'treatment_header')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHealthy
                  ? AppTranslations.getText(langCode, 'healthy_crop')
                  : AppTranslations.getText(langCode, 'treatment_header'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isHealthy)
              _buildHealthyCard(langCode)
            else
              _buildRemediesList(langCode),
            const SizedBox(height: 40),
            
            // Next Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgriStoreScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_basket, color: Colors.white),
                label: const Text(
                  "Find Stores Nearby",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthyCard(String langCode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppTranslations.getText(langCode, 'healthy_msg'),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemediesList(String langCode) {
    return Column(
      children: [
        if (response.llm != null && response.llm!.chemicalTreatments.isNotEmpty)
          _buildCategoryCard(
            title: AppTranslations.getText(langCode, 'chemical_control'),
            icon: Icons.science,
            color: Colors.red,
            items: response.llm!.chemicalTreatments,
          ),
        const SizedBox(height: 16),
        if (response.llm != null && response.llm!.organicTreatments.isNotEmpty)
          _buildCategoryCard(
            title: "Organic Control",
            icon: Icons.eco,
            color: Colors.green,
            items: response.llm!.organicTreatments,
          ),
        if (response.llm == null)
          _buildCategoryCard(
            title: AppTranslations.getText(langCode, 'remedy'),
            icon: Icons.medical_services,
            color: Colors.orange,
            items: [AppTranslations.getText(langCode, 'treat_${response.predictedDisease}')],
          ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
              ),
            ],
          ),
          const Divider(height: 24),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 15))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
