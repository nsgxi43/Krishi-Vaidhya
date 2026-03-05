/// Data models for the Predictive Analysis feature.

class PredictionResponse {
  final List<DiseaseAlert> alerts;
  final AlertSummary summary;
  final WeatherInfo? weather;
  final List<String> cropsMonitored;
  final String generatedAt;
  final String? message;

  PredictionResponse({
    required this.alerts,
    required this.summary,
    this.weather,
    required this.cropsMonitored,
    required this.generatedAt,
    this.message,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((e) => DiseaseAlert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: AlertSummary.fromJson(json['summary'] ?? {}),
      weather: json['weather'] != null
          ? WeatherInfo.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
      cropsMonitored: (json['crops_monitored'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      generatedAt: json['generated_at'] ?? '',
      message: json['message'],
    );
  }
}

class DiseaseAlert {
  final String crop;
  final String diseaseKey;
  final String diseaseName;
  final int caseCount;
  final double riskScore;
  final String riskLevel;
  final bool communicable;
  final String vector;
  final String spreadDescription;
  final bool weatherFavorsSpread;
  final List<String> weatherFactors;
  final List<String> prevention;
  final List<String> chemicalTreatments;
  final List<String> organicTreatments;
  final String? aiSummary;

  DiseaseAlert({
    required this.crop,
    required this.diseaseKey,
    required this.diseaseName,
    required this.caseCount,
    required this.riskScore,
    required this.riskLevel,
    required this.communicable,
    required this.vector,
    required this.spreadDescription,
    required this.weatherFavorsSpread,
    required this.weatherFactors,
    required this.prevention,
    required this.chemicalTreatments,
    required this.organicTreatments,
    this.aiSummary,
  });

  factory DiseaseAlert.fromJson(Map<String, dynamic> json) {
    return DiseaseAlert(
      crop: json['crop'] ?? '',
      diseaseKey: json['disease_key'] ?? '',
      diseaseName: json['disease_name'] ?? '',
      caseCount: json['case_count'] ?? 0,
      riskScore: (json['risk_score'] ?? 0).toDouble(),
      riskLevel: json['risk_level'] ?? 'low',
      communicable: json['communicable'] ?? false,
      vector: json['vector'] ?? 'unknown',
      spreadDescription: json['spread_description'] ?? '',
      weatherFavorsSpread: json['weather_favors_spread'] ?? false,
      weatherFactors: _parseStringList(json['weather_factors']),
      prevention: _parseStringList(json['prevention']),
      chemicalTreatments: _parseStringList(json['chemical_treatments']),
      organicTreatments: _parseStringList(json['organic_treatments']),
      aiSummary: json['ai_summary'],
    );
  }

  static List<String> _parseStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    return [];
  }
}

class AlertSummary {
  final int totalAlerts;
  final int highRisk;
  final int mediumRisk;
  final int lowRisk;

  AlertSummary({
    required this.totalAlerts,
    required this.highRisk,
    required this.mediumRisk,
    required this.lowRisk,
  });

  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    return AlertSummary(
      totalAlerts: json['total_alerts'] ?? 0,
      highRisk: json['high_risk'] ?? 0,
      mediumRisk: json['medium_risk'] ?? 0,
      lowRisk: json['low_risk'] ?? 0,
    );
  }
}

class WeatherInfo {
  final double? tempC;
  final int? humidity;
  final String? condition;
  final String? icon;
  final String? locationName;

  WeatherInfo({this.tempC, this.humidity, this.condition, this.icon, this.locationName});

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      tempC: (json['temp_c'] as num?)?.toDouble(),
      humidity: json['humidity'] as int?,
      condition: json['condition'] as String?,
      icon: json['icon'] as String?,
      locationName: json['location_name'] as String?,
    );
  }
}
