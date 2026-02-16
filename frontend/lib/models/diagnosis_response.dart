class DiagnosisResponse {
  final String diagnosisId;
  final String crop;
  final String predictedDisease;
  final double confidence;
  final String displayLabel; // e.g., "Tomato Early Blight"
  final bool isHealthy;
  final DiagnosisLLM? llm;
  final List<NearbyStore> nearbyStores;

  DiagnosisResponse({
    required this.diagnosisId,
    required this.crop,
    required this.predictedDisease,
    required this.confidence,
    required this.displayLabel,
    required this.isHealthy,
    this.llm,
    this.nearbyStores = const [],
  });

  factory DiagnosisResponse.fromJson(Map<String, dynamic> json) {
    // Helper to format label
    String rawLabel = json['predicted_disease'] ?? "Unknown";
    String label = rawLabel.replaceAll('_', ' ');
    bool healthy = rawLabel.toLowerCase().contains("healthy");

    // Parse LLM section
    DiagnosisLLM? llmParsed;
    if (json['llm'] != null && json['llm'] is Map<String, dynamic>) {
      llmParsed = DiagnosisLLM.fromJson(json['llm']);
    }

    // Parse Stores
    List<NearbyStore> storesParsed = [];
    if (json['nearbyAgriStores'] != null && json['nearbyAgriStores'] is List) {
      storesParsed = (json['nearbyAgriStores'] as List)
          .map((s) => NearbyStore.fromJson(s))
          .toList();
    }

    return DiagnosisResponse(
      diagnosisId: json['diagnosisId'] ?? "",
      crop: json['crop'] ?? "Unknown",
      predictedDisease: rawLabel,
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : 0.0,
      displayLabel: label,
      isHealthy: healthy,
      llm: llmParsed,
      nearbyStores: storesParsed,
    );
  }
}

class DiagnosisLLM {
  final String diseaseOverview;
  final String whyThisPrediction;
  final List<String> chemicalTreatments;
  final List<String> organicTreatments;
  final List<String> preventionTips;

  DiagnosisLLM({
    this.diseaseOverview = "",
    this.whyThisPrediction = "",
    this.chemicalTreatments = const [],
    this.organicTreatments = const [],
    this.preventionTips = const [],
  });

  factory DiagnosisLLM.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse list fields that might be strings
    List<String> _parseListField(dynamic field) {
      if (field == null) return [];
      if (field is List) {
        return field.map((e) => e.toString()).toList();
      }
      if (field is String) {
        // If it's a string, wrap it in a list
        return [field];
      }
      return [];
    }
    
    return DiagnosisLLM(
      diseaseOverview: json['disease_overview'] ?? "",
      whyThisPrediction: json['why_this_prediction'] ?? "",
      chemicalTreatments: _parseListField(json['chemical_treatments']),
      organicTreatments: _parseListField(json['organic_treatments']),
      preventionTips: _parseListField(json['prevention_tips']),
    );
  }
}

class NearbyStore {
  final String name;
  final double distanceKm;
  final String mapsUrl;
  final String address;
  final double? rating;

  NearbyStore({
    required this.name,
    required this.distanceKm,
    required this.mapsUrl,
    required this.address,
    this.rating,
  });

  factory NearbyStore.fromJson(Map<String, dynamic> json) {
    return NearbyStore(
      name: json['name'] ?? "Unknown Store",
      distanceKm: (json['distance_km'] is num)
          ? (json['distance_km'] as num).toDouble()
          : 0.0,
      mapsUrl: json['maps_url'] ?? "",
      address: json['address'] ?? "",
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : null,
    );
  }
}
