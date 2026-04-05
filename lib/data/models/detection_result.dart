class DetectionResult {
  final String label;
  final String labelEs;
  final double confidence;
  final bool isDangerous;

  const DetectionResult({
    required this.label,
    required this.labelEs,
    required this.confidence,
    required this.isDangerous,
  });
}