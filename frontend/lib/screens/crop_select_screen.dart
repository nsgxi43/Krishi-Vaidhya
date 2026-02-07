import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crop_item.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';

class CropSelectScreen extends StatefulWidget {
  final List<CropItem> initialCrops;
  const CropSelectScreen({super.key, required this.initialCrops});

  @override
  State<CropSelectScreen> createState() => _CropSelectScreenState();
}

class _CropSelectScreenState extends State<CropSelectScreen> {
  // Master list of crops ordered by Priority
  final List<CropItem> _allCrops = [
    // --- PRIORITY GROUP ---
    CropItem(nameKey: 'Apple', imagePath: 'assets/images/apple.png', color: Colors.red.shade50),
    CropItem(nameKey: 'Corn', imagePath: 'assets/images/corn.png', color: Colors.yellow.shade50),
    CropItem(nameKey: 'Potato', imagePath: 'assets/images/potato.png', color: Colors.brown.shade50),
    CropItem(nameKey: 'Soyabean', imagePath: 'assets/images/soyabean.png', color: Colors.green.shade50),
    CropItem(nameKey: 'Tomato', imagePath: 'assets/images/tomato.png', color: Colors.red.shade50),
    CropItem(nameKey: 'Blueberry', imagePath: 'assets/images/blueberry.png', color: Colors.purple.shade50),
    CropItem(nameKey: 'Cherry', imagePath: 'assets/images/cherry.png', color: Colors.red.shade100),
    CropItem(nameKey: 'Grape', imagePath: 'assets/images/grape.png', color: Colors.purple.shade100),
    CropItem(nameKey: 'Peach', imagePath: 'assets/images/peach.png', color: Colors.orange.shade50),
    CropItem(nameKey: 'Raspberry', imagePath: 'assets/images/raspberry.png', color: Colors.red.shade200),
    CropItem(nameKey: 'Strawberry', imagePath: 'assets/images/strawberry.png', color: Colors.red.shade300),

    // --- REMAINING CROPS ---
    CropItem(nameKey: 'Cotton', imagePath: 'assets/images/cotton.png', color: Colors.blue.shade50),
    CropItem(nameKey: 'Sugarcane', imagePath: 'assets/images/sugarcane.jpg', color: Colors.lightGreen.shade50),
    CropItem(nameKey: 'Chilli', imagePath: 'assets/images/chilli.png', color: Colors.red.shade100),
    CropItem(nameKey: 'Onion', imagePath: 'assets/images/onion.png', color: Colors.purple.shade50),
    CropItem(nameKey: 'Coconut', imagePath: 'assets/images/coconut.png', color: Colors.green.shade100),
    CropItem(nameKey: 'Banana', imagePath: 'assets/images/banana.png', color: Colors.yellow.shade100),
    CropItem(nameKey: 'Turmeric', imagePath: 'assets/images/turmeric.png', color: Colors.orange.shade100),
    CropItem(nameKey: 'Brinjal', imagePath: 'assets/images/brinjal.png', color: Colors.purple.shade100),
    CropItem(nameKey: 'Groundnut', imagePath: 'assets/images/groundnut.png', color: Colors.brown.shade100),
    CropItem(nameKey: 'Okra', imagePath: 'assets/images/okra.jpg', color: Colors.green.shade50),
    CropItem(nameKey: 'Mango', imagePath: 'assets/images/mango.png', color: Colors.yellow.shade200),
    CropItem(nameKey: 'Papaya', imagePath: 'assets/images/papaya.png', color: Colors.orange.shade200),
    CropItem(nameKey: 'Lemon', imagePath: 'assets/images/lemon.png', color: Colors.yellow.shade100),
    CropItem(nameKey: 'Pomegranate', imagePath: 'assets/images/pomegranate.png', color: Colors.red.shade100),
    CropItem(nameKey: 'Ginger', imagePath: 'assets/images/ginger.png', color: Colors.brown.shade200),
    CropItem(nameKey: 'Spinach', imagePath: 'assets/images/spinach.png', color: Colors.green.shade200),
    CropItem(nameKey: 'Wheat', imagePath: 'assets/images/wheat.png', color: Colors.orange.shade50),
    CropItem(nameKey: 'Rice', imagePath: 'assets/images/rice.png', color: Colors.green.shade50),
  ];

  @override
  void initState() {
    super.initState();
    for (var crop in _allCrops) {
      crop.isSelected = widget.initialCrops.any((c) => c.nameKey == crop.nameKey);
    }
  }

  void _saveSelection() {
    Navigator.pop(context, _allCrops.where((c) => c.isSelected).toList());
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppTranslations.getText(langCode, 'selected_crops'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Tap to select crops:",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24), // Increased padding around grid
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                childAspectRatio: 0.85, // Adjusted to make items slightly smaller
                crossAxisSpacing: 20, 
                mainAxisSpacing: 24,
              ),
              itemCount: _allCrops.length,
              itemBuilder: (context, index) {
                final crop = _allCrops[index];
                return GestureDetector(
                  onTap: () => setState(() => crop.isSelected = !crop.isSelected),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Selection Ring
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200), // Smooth transition duration
                          curve: Curves.easeInOut,
                          // Padding creates the gap between the image and the selection ring
                          padding: EdgeInsets.all(crop.isSelected ? 5.0 : 0.0), 
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              // Ring is transparent when not selected, Green when selected
                              color: crop.isSelected ? Colors.green : Colors.transparent, 
                              width: 3.0,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // Optional: Subtle shadow only when selected
                              boxShadow: crop.isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.2),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : [],
                            ),
                            child: ClipOval(
                              child: Stack(
                                children: [
                                  // Background color fallback
                                  Container(color: crop.color),
                                  // The Image
                                  Positioned.fill(
                                    child: Image.asset(
                                      crop.imagePath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.getText(langCode, crop.nameKey.toLowerCase()),
                        style: TextStyle(
                          fontWeight: crop.isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13, 
                          color: crop.isSelected ? Colors.green.shade800 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity, 
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  AppTranslations.getText(langCode, 'save'), 
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}