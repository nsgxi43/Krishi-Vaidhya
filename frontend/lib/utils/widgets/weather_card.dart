
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../services/api_service.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  bool _isLoading = true;
  String? _error;
  
  // Weather Data
  double _temp = 0.0;
  double _humidity = 0.0;
  double _wind = 0.0;
  String _condition = "Unknown";
  String _locationName = "Loading...";
  String _iconUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Position? position;
      try {
        position = await _determinePosition();
      } catch (e) {
        print("Location error: $e");
        // Fallback to Bangalore if location fails
        position = Position(
            longitude: 77.5946,
            latitude: 12.9716,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0);
      }

      final data = await ApiService.fetchWeather(position.latitude, position.longitude);
      
      if (mounted) {
        if (data != null) {
          setState(() {
            _temp = (data['temp_c'] as num?)?.toDouble() ?? 0.0;
            _humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;
            _wind = (data['wind_kph'] as num?)?.toDouble() ?? 0.0;
            _condition = data['condition'] ?? "Unknown";
            _locationName = data['location'] ?? "Unknown Location";
            String rawIcon = data['icon'] ?? "";
            if (rawIcon.startsWith("//")) {
              _iconUrl = "https:$rawIcon";
            } else {
              _iconUrl = rawIcon;
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = "Failed to load weather";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    if (kIsWeb) {
      return await Geolocator.getCurrentPosition();
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  // --- LOGIC: Predict Disease using API Data ---
  String _analyzeRisk() {
    // High Humidity (>80%) is the biggest risk for Blight
    if (_humidity > 80) return 'risk_high';

    // Frost
    if (_temp < 5 && _temp != 0) return 'alert_frost';

    // Simple check for "Cloudy" if we want to mimic light sensor?
    // For now, let's keep it simple.
    
    return 'risk_low';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final langCode = languageProvider.currentLocale;
        
        if (_isLoading) {
          return Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_error != null) {
          return Container(
            height: 140,
             decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, color: Colors.red),
                   const SizedBox(height: 8),
                   Text(_error!, style: const TextStyle(color: Colors.red)),
                   TextButton(onPressed: _fetchWeather, child: const Text("Retry"))
                ],
              ),
            ),
          );
        }

        final riskKey = _analyzeRisk();
        final bool isHighRisk = riskKey == 'risk_high' || riskKey == 'alert_frost';

        // Card Colors
        final Color bg1 = isHighRisk ? Colors.red.shade400 : const Color(0xFF90CAF9);
        final Color bg2 = isHighRisk ? Colors.red.shade700 : const Color(0xFF1976D2);

        return Container(
          height: 150, 
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [bg1, bg2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: bg2.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Location & Condition
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         children: [
                           const Icon(Icons.location_on, color: Colors.white, size: 14),
                           const SizedBox(width: 4),
                           Text(_locationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                         ],
                       ),
                       const SizedBox(height: 4),
                       Text(_condition, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  if (_iconUrl.isNotEmpty)
                    Image.network(_iconUrl, width: 40, height: 40, errorBuilder: (_,__,___)=> const Icon(Icons.cloud, color: Colors.white, size: 40))
                  else
                    const Icon(Icons.cloud, color: Colors.white, size: 40),
                ],
              ),
              
              const Spacer(),
              
              // Sensor Readings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSensorItem(Icons.thermostat, "${_temp.toStringAsFixed(1)}°C"),
                  _buildSensorItem(Icons.water_drop, "${_humidity.toStringAsFixed(0)}%"),
                  _buildSensorItem(Icons.air, "${_wind.toStringAsFixed(0)} km/h"),
                ],
              ),
              
              const SizedBox(height: 8),

              // Risk Badge
               Center(
                 child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.5))
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isHighRisk ? Icons.warning : Icons.check_circle, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        AppTranslations.getText(langCode, riskKey),
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ),
               ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSensorItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}