import 'dart:math';

class WeatherService {
  
  // 1. Simulate fetching live weather (Temp, Humidity)
  static Future<Map<String, dynamic>> getCurrentWeather() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Mimic API delay
    
    // SIMULATION: We return "High Humidity" to test the Alert feature
    return {
      'temp': 28.0,       // Degrees Celsius
      'humidity': 85.0,   // % (Very High -> Fungal Risk)
      'condition': 'Cloudy'
    };
  }

  // 2. The "Smart" Logic: Predict Disease based on Weather
  static String analyzeRisk(double temp, double humidity) {
    if (humidity > 80 && temp > 20) {
      return 'risk_high'; // Key for Translation
    } else if (temp < 5) {
      return 'alert_frost'; // Frost Risk
    } else {
      return 'risk_low'; // Safe
    }
  }
}