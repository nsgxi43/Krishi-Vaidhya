import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/crop_item.dart';

class OfflineService {
  
  // LOGIC: Task 2.2.2 - Simulate downloading data for specific crops
  static Future<void> downloadCropData(List<CropItem> selectedCrops) async {
    // Artificial delay to mimic network request (e.g., fetching from Cloud)
    await Future.delayed(const Duration(seconds: 2));

    for (var crop in selectedCrops) {
      if (crop.isSelected) {
        // In a real app, this data would come from an API based on crop.id
        await _saveFakeDataForCrop(crop.nameKey);
      }
    }
  }

  // LOGIC: Task 2.2.3 - Store data locally on device
  static Future<void> _saveFakeDataForCrop(String cropName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$cropName.json');

    // MOCK DATA: We are saving this JSON to the phone's storage
    Map<String, dynamic> mockData = {
      "crop": cropName,
      "lastUpdated": DateTime.now().toIso8601String(),
      "diseases": [
        {
          "diseaseName": "$cropName Blight",
          "symptoms": "Brown spots on leaves, yellowing edges.",
          "treatment": "Use Copper Fungicide and avoid overhead watering.",
          "imagePath": "assets/images/blight.png" 
        },
        {
          "diseaseName": "$cropName Rot",
          "symptoms": "Soft, watery decay near the stem.",
          "treatment": "Improve drainage and remove infected plants.",
          "imagePath": "assets/images/rot.png"
        }
      ]
    };

    await file.writeAsString(jsonEncode(mockData));
    print("Saved offline data to: ${file.path}"); // Debugging log
  }

  // LOGIC: Retrieve data when needed (e.g., for Diagnosis later)
  static Future<Map<String, dynamic>?> getOfflineData(String cropName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$cropName.json');

      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
    } catch (e) {
      print("Error reading offline data: $e");
    }
    return null;
  }
}