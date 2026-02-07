import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppTranslations.getText(langCode, 'help_support'), style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic, size: 40, color: Colors.green),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppTranslations.getText(langCode, 'contact_us'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text("support@krishivaidhya.com", style: TextStyle(color: Colors.grey)),
                        const Text("+91 1800-123-4567", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            Text(AppTranslations.getText(langCode, 'faq'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),

            // FAQs
            _buildFaqItem(langCode, 'faq_1_q', 'faq_1_a'),
            _buildFaqItem(langCode, 'faq_2_q', 'faq_2_a'),
            
            // Static FAQ Example (General)
            _buildStaticFaq("How do I change language?", "Go to Profile > Select Language."),
            _buildStaticFaq("My app is slow?", "Try clearing cache or restarting your phone."),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String langCode, String qKey, String aKey) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          AppTranslations.getText(langCode, qKey),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              AppTranslations.getText(langCode, aKey),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildStaticFaq(String q, String a) {
     return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(a, style: TextStyle(color: Colors.grey.shade700)),
          )
        ],
      ),
    );
  }
}