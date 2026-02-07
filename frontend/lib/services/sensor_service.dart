import 'package:environment_sensors/environment_sensors.dart';

class SensorService {
  final EnvironmentSensors _sensors = EnvironmentSensors();

  // Stream for Temperature (If available)
  Stream<double> get temperatureStream => _sensors.temperature;

  // Stream for Humidity (If available)
  Stream<double> get humidityStream => _sensors.humidity;

  // Stream for Light (If available - standard on most phones)
  // Note: environment_sensors handles light on Android
  Stream<double> get lightStream => _sensors.light;

  // Check if sensor exists (Android only)
  Future<bool> checkSensorAvailability(SensorType type) async {
    return await _sensors.getSensorAvailable(type);
  }
}