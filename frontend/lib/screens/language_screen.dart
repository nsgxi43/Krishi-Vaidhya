import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'login_screen.dart';

class LanguageScreen extends StatelessWidget {
  final bool fromSettings;

  const LanguageScreen({
    super.key, 
    this.fromSettings = false // false = First time app open, true = from Settings
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    // Helper to handle navigation logic
    void onContinue() {
      if (fromSettings) {
        // Case 1: Accessed from Settings -> Go back to Settings
        Navigator.pop(context);
      } else {
        // Case 2: First App Launch -> Go to Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Language", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        // Hide back button if it's the first launch (force selection)
        automaticallyImplyLeading: fromSettings,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Choose your preferred language",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: ListView(
                children: [
                  _buildLanguageCard(context, "English", "en", languageProvider),
                  const SizedBox(height: 12),
                  _buildLanguageCard(context, "हिंदी (Hindi)", "hi", languageProvider),
                  const SizedBox(height: 12),
                  _buildLanguageCard(context, "தமிழ் (Tamil)", "ta", languageProvider),
                  const SizedBox(height: 12),
                  _buildLanguageCard(context, "తెలుగు (Telugu)", "te", languageProvider),
                ],
              ),
            ),

            // Continue / Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  fromSettings ? "Save & Go Back" : "Continue",
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, String name, String code, LanguageProvider provider) {
    bool isSelected = provider.currentLocale == code;
    return GestureDetector(
      onTap: () {
        provider.setLanguage(code); // Updates the app language immediately
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green.shade800 : Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}