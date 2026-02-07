import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';

class CameraActionSection extends StatelessWidget {
  final VoidCallback onTakePicture;
  const CameraActionSection({super.key, required this.onTakePicture});

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToggleIcon(Icons.camera_alt, true),
              _buildToggleIcon(Icons.description, false),
              _buildToggleIcon(Icons.local_florist, false),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onTakePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                AppTranslations.getText(langCode, 'take_picture'), // Translated!
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleIcon(IconData icon, bool isSelected) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(height: 3, width: 30, color: isSelected ? Colors.black : Colors.transparent)
      ],
    );
  }
}