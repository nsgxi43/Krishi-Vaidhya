import 'dart:convert';
import 'dart:io' as io; // Use prefix to avoid conflicts and accidental usage
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/diagnosis_response.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:5001/api";
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator uses 10.0.2.2 for host
      return "http://10.0.2.2:5001/api";
    }
    
    // Default/iOS
    return "http://127.0.0.1:5001/api";
  }

  // --- AUTH ---
  static Future<Map<String, dynamic>?> login(String phone, String name, String language, List<String> crops) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phone,
          "name": name,
          "language": language,
          "crops": crops,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Login failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // --- DIAGNOSIS ---
  // --- DIAGNOSIS ---
  static Future<DiagnosisResponse?> uploadImage(String imagePath, String userId, double lat, double lng) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/diagnosis'));
      
      request.fields['userId'] = userId;
      request.fields['lat'] = lat.toString();
      request.fields['lng'] = lng.toString();
      
      if (kIsWeb) {
        // Web: Read bytes from blob/url
        final res = await http.get(Uri.parse(imagePath));
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            res.bodyBytes,
            filename: 'upload.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        // Mobile/Desktop: Use file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return DiagnosisResponse.fromJson(data);
      } else {
        print("Upload failed: ${response.statusCode} - ${response.body}");
        
        // Try to parse error message from response
        String errorMessage = 'Upload failed';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Upload failed';
        } catch (parseError) {
          // If JSON parsing fails, use the raw response body
          errorMessage = response.body.isNotEmpty ? response.body : 'Upload failed with status ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print("Upload error: $e");
      rethrow; // Re-throw to let caller handle it
    }
  }

  // --- CALENDAR ---
  static Future<Map<String, dynamic>?> generateCalendar(String userId, String crop, String sowingDate, double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calendar/generate'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "crop": crop,
          "sowingDate": sowingDate,
          "lat": lat,
          "lng": lng,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Calendar generation failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Calendar error: $e");
      return null;
    }
  }

  // --- STORES ---
  static Future<List<NearbyStore>> fetchNearbyStores(double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stores'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lat": lat,
          "lng": lng,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NearbyStore.fromJson(json)).toList();
      } else {
        print("Store fetch failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Store fetch error: $e");
      return [];
    }
  }

  // --- WEATHER ---
  static Future<Map<String, dynamic>?> fetchWeather(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather/current?lat=$lat&lng=$lng'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Weather fetch failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Weather fetch error: $e");
      return null;
    }
  }
}
