import 'package:flutter/material.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final EnvironmentSensors _sensors = EnvironmentSensors();
  
  // Sensor Values
  double _temp = 0.0;
  double _humidity = 0.0;
  double _light = 0.0;
  bool _hasSensors = false;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() async {
    // Check if hardware is present
    bool tempAvailable = await _sensors.getSensorAvailable(SensorType.AmbientTemperature);
    bool humidAvailable = await _sensors.getSensorAvailable(SensorType.Humidity);
    bool lightAvailable = await _sensors.getSensorAvailable(SensorType.Light);

    if (mounted) {
      setState(() {
        _hasSensors = tempAvailable || humidAvailable || lightAvailable;
      });
    }

    // Listen to Streams (Live Data)
    if (tempAvailable) {
      _sensors.temperature.listen((temp) => setState(() => _temp = temp));
    }
    if (humidAvailable) {
      _sensors.humidity.listen((humid) => setState(() => _humidity = humid));
    }
    if (lightAvailable) {
      _sensors.light.listen((lux) => setState(() => _light = lux));
    }
  }

  // --- LOGIC: Predict Disease using SENSORS ---
  String _analyzeRisk() {
    // 1. Fallback if no sensors (Mock Logic for testing)
    if (!_hasSensors && _temp == 0) return 'risk_low'; 

    // 2. Real Logic
    // High Humidity (>80%) is the biggest risk for Blight
    if (_humidity > 80) return 'risk_high';

    // Low Light (< 5000 Lux means Cloudy/Overcast) + Warmth = Risk
    // Direct Sunlight is usually > 10,000 Lux
    if (_light < 5000 && _temp > 25) {
      return 'risk_high'; // "Cloudy & Warm" warning
    }

    if (_temp < 5 && _temp != 0) return 'alert_frost'; // Frost

    return 'risk_low';
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final riskKey = _analyzeRisk();
    final bool isHighRisk = riskKey == 'risk_high' || riskKey == 'alert_frost';

    // Card Colors
    final Color bg1 = isHighRisk ? Colors.red.shade400 : const Color(0xFF90CAF9);
    final Color bg2 = isHighRisk ? Colors.red.shade700 : const Color(0xFF1976D2);

    return Container(
      height: 140, // Taller for sensor stats
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bg1, bg2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: bg2.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row 1: Live Sensor Readings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSensorItem(Icons.thermostat, "${_temp.toStringAsFixed(1)}°C"),
              _buildSensorItem(Icons.water_drop, "${_humidity.toStringAsFixed(0)}%"),
              _buildSensorItem(Icons.wb_sunny, "${_light.toStringAsFixed(0)} Lx"),
            ],
          ),
          
          const SizedBox(height: 12),

          // Row 2: The Prediction Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5))
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isHighRisk ? Icons.warning : Icons.check_circle, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.getText(langCode, riskKey),
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          if (!_hasSensors)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                "(Sensors not found on device)",
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}