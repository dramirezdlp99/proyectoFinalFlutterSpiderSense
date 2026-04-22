import 'package:hive/hive.dart';

part 'detection_record.g.dart';

@HiveType(typeId: 0)
class DetectionRecord extends HiveObject {
  @HiveField(0)
  late String label;

  @HiveField(1)
  late String labelEs;

  @HiveField(2)
  late double confidence;

  @HiveField(3)
  late DateTime detectedAt;

  @HiveField(4)
  double? latitude;

  @HiveField(5)
  double? longitude;

  @HiveField(6)
  late bool isDangerous;

  @HiveField(7)
  late String userId;

  /// Nuevo campo — indica si ya fue enviado a Supabase.
  /// Default false para registros nuevos y para los existentes
  /// (Hive retorna false automáticamente al leer campos no escritos).
  @HiveField(8)
  bool synced = false;

  DetectionRecord({
    required this.label,
    required this.labelEs,
    required this.confidence,
    required this.detectedAt,
    required this.isDangerous,
    required this.userId,
    this.latitude,
    this.longitude,
    this.synced = false,
  });
}