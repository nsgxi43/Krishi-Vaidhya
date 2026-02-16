import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CalendarService {
  static String get baseUrl => ApiService.baseUrl;

  static Future<Map<String, dynamic>?> generateCalendar({
    required String userId,
    required String crop,
    required String sowingDate,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calendar/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'crop': crop,
          'sowingDate': sowingDate,
          'lat': lat,
          'lng': lng,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to generate calendar: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating calendar: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCalendar(String calendarId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/calendar/$calendarId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to fetch calendar: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching calendar: $e');
      return null;
    }
  }
}
