class DiseaseData {
  final String diseaseName;
  final String symptoms;
  final String treatment;
  final String imagePath; // Local path to image

  DiseaseData({
    required this.diseaseName,
    required this.symptoms,
    required this.treatment,
    required this.imagePath,
  });

  // Convert to Map for saving to JSON file
  Map<String, dynamic> toJson() => {
    'diseaseName': diseaseName,
    'symptoms': symptoms,
    'treatment': treatment,
    'imagePath': imagePath,
  };

  // Create from Map (when loading from JSON file)
  factory DiseaseData.fromJson(Map<String, dynamic> json) {
    return DiseaseData(
      diseaseName: json['diseaseName'],
      symptoms: json['symptoms'],
      treatment: json['treatment'],
      imagePath: json['imagePath'],
    );
  }
}