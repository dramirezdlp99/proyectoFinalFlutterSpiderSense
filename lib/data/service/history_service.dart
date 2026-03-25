import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/detection_record.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _boxName = 'detection_history';
  Box<DetectionRecord>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DetectionRecordAdapter());
    }
    _box = await Hive.openBox<DetectionRecord>(_boxName);
  }

  Future<void> saveDetection(DetectionRecord record) async {
    try {
      await _box?.add(record);
      debugPrint('Detection saved: ${record.label} at ${record.detectedAt}');
    } catch (e) {
      debugPrint('Error saving detection: $e');
    }
  }

  List<DetectionRecord> getAll() {
    return _box?.values.toList().reversed.toList() ?? [];
  }

  List<DetectionRecord> getDangerousOnly() {
    return _box?.values
            .where((r) => r.isDangerous)
            .toList()
            .reversed
            .toList() ??
        [];
  }

  Future<void> deleteRecord(DetectionRecord record) async {
    try {
      await record.delete();
    } catch (e) {
      debugPrint('Error deleting record: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _box?.clear();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  int get totalDetections => _box?.length ?? 0;

  int get dangerousDetections =>
      _box?.values.where((r) => r.isDangerous).length ?? 0;
}