import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diagnosis_response.dart';

class OfflineService {
  static const String _calendarCachePrefix = 'offline_calendar_';
  static const String _lastDiagnosisKey = 'offline_last_diagnosis';
  static const String _assetPath = 'assets/offline_data/crop_diseases.json';

  // ─── Connectivity ────────────────────────────────────────────────────────

  /// Returns true if the backend is reachable (which implies internet is also up,
  /// because the backend itself calls external APIs like Gemini & Weather).
  static Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:5001/'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Offline Diagnosis ───────────────────────────────────────────────────

  /// Loads the full disease database from the bundled asset.
  static Future<Map<String, dynamic>> _loadDiseaseAsset() async {
    final jsonStr = await rootBundle.loadString(_assetPath);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  /// Returns the list of disease maps for [cropName], or empty list if not found.
  static Future<List<Map<String, dynamic>>> getDiseasesForCrop(
      String cropName) async {
    final data = await _loadDiseaseAsset();
    final List<dynamic>? diseases = data[cropName];
    if (diseases == null) return [];
    return diseases.cast<Map<String, dynamic>>();
  }

  /// Builds a [DiagnosisResponse] from a locally stored disease map.
  static DiagnosisResponse buildOfflineDiagnosisResponse(
      Map<String, dynamic> diseaseMap, String crop) {
    final llm = DiagnosisLLM(
      diseaseOverview: diseaseMap['diseaseOverview'] ?? '',
      whyThisPrediction: diseaseMap['whyThisPrediction'] ?? '',
      chemicalTreatments:
          List<String>.from(diseaseMap['chemicalTreatments'] ?? []),
      organicTreatments:
          List<String>.from(diseaseMap['organicTreatments'] ?? []),
      preventionTips: List<String>.from(diseaseMap['preventionTips'] ?? []),
    );

    return DiagnosisResponse(
      diagnosisId: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      crop: crop,
      predictedDisease: diseaseMap['diseaseName'] ?? 'Unknown',
      confidence: 0.0, // not available offline
      displayLabel: diseaseMap['displayLabel'] ?? diseaseMap['diseaseName'] ?? 'Unknown',
      isHealthy: diseaseMap['isHealthy'] ?? false,
      llm: llm,
      nearbyStores: [],
    );
  }

  // ─── Calendar Cache ──────────────────────────────────────────────────────

  /// Saves a successfully-generated calendar to local storage.
  static Future<void> cacheCalendar(
      String cropName, Map<String, dynamic> calendarData) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'data': calendarData,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(
        '$_calendarCachePrefix$cropName', jsonEncode(payload));
  }

  /// Returns cached calendar payload {data, cachedAt}, or null if none exists.
  static Future<Map<String, dynamic>?> getCachedCalendar(
      String cropName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_calendarCachePrefix$cropName');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ─── Last Diagnosis Cache ────────────────────────────────────────────────

  /// Caches the most recent successful online diagnosis result as raw JSON map.
  static Future<void> cacheLastDiagnosis(
      Map<String, dynamic> diagnosisJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDiagnosisKey, jsonEncode(diagnosisJson));
  }

  /// Returns the last cached diagnosis JSON map, or null.
  static Future<Map<String, dynamic>?> getLastCachedDiagnosis() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastDiagnosisKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}