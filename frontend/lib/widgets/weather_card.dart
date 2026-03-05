import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Map<String, dynamic>? _weather;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      double lat = 20.5937;
      double lng = 78.9629;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low)
              .timeout(const Duration(seconds: 5));
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {
        // Use default coords if location fails
      }

      final data = await ApiService.fetchWeather(lat, lng);
      if (mounted) {
        setState(() {
          _weather = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load weather';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildShell(
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (_error != null || _weather == null) {
      return _buildShell(
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white70, size: 28),
            const SizedBox(width: 10),
            Text(
              _error ?? 'Weather unavailable',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final temp = _weather!['temp_c'];
    final condition = _weather!['condition'] ?? '';
    final humidity = _weather!['humidity'];
    final wind = _weather!['wind_kph'];
    final location = _weather!['location'] ?? '';
    final region = _weather!['region'] ?? '';

    return _buildShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.wb_sunny, color: Colors.amber, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temp != null ? '${temp.toStringAsFixed(1)}°C' : '--°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  condition,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (location.isNotEmpty)
                  Text(
                    '$location, $region',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _infoChip(Icons.water_drop, humidity != null ? '$humidity%' : '--'),
              const SizedBox(height: 6),
              _infoChip(Icons.air, wind != null ? '${wind} km/h' : '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
