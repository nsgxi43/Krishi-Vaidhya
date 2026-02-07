import 'package:flutter_tflite/flutter_tflite.dart';

class AiService {
  
  // 1. Load the Model (Brain)
  static Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/model/model.tflite",
        labels: "assets/model/labels.txt",
        numThreads: 1, // Uses 1 CPU thread
        isAsset: true,
        useGpuDelegate: false,
      );
      print("Model Loaded: $res");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  // 2. Run Analysis on Image
  static Future<List<dynamic>?> classifyImage(String imagePath) async {
    try {
      var recognitions = await Tflite.runModelOnImage(
        path: imagePath,
        imageMean: 0.0,   // Defaults for standard models
        imageStd: 255.0,  // Defaults for standard models
        numResults: 2,    // Return top 2 results
        threshold: 0.2,   // Confidence threshold (20%)
        asynch: true,
      );
      return recognitions;
    } catch (e) {
      print("Error analyzing image: $e");
      return null;
    }
  }

  // 3. Clean up memory
  static void dispose() {
    Tflite.close();
  }
}