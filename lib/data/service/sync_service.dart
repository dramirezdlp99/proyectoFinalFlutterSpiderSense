import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/detection_record.dart';
import 'history_service.dart';

class SyncService extends GetxService {
  final RxInt pendingCount = 0.obs;
  final RxBool isSyncing = false.obs;
  final _supabase = Supabase.instance.client;
  late HistoryService _hs;

  Future<void> init() async {
    _hs = HistoryService();
    _updatePending();
  }

  void _updatePending() {
    pendingCount.value = _hs.getAll().where((r) => !r.synced).length;
  }

  Future<void> syncAll() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;

    final pending = _hs.getAll().where((r) => !r.synced).toList();
    if (pending.isEmpty) return;

    isSyncing.value = true;
    int synced = 0;

    for (final record in pending) {
      try {
        // Usar key de Hive como ID único
        final recordId =
            '${session.user.id}_${record.key}_${record.detectedAt.millisecondsSinceEpoch}';

        await _supabase.from('detection_history').upsert({
          'id': recordId,
          'user_id': session.user.id,
          'label': record.label,
          'label_es': record.labelEs,
          'confidence': record.confidence,
          'is_dangerous': record.isDangerous,
          'latitude': record.latitude,
          'longitude': record.longitude,
          'detected_at': record.detectedAt.toIso8601String(),
        });

        // Si es peligroso Y tiene coordenadas → también en danger_zones
        if (record.isDangerous &&
            record.latitude != null &&
            record.longitude != null) {
          await _supabase.from('danger_zones').upsert({
            'id': recordId,
            'user_id': session.user.id,
            'label': record.label,
            'label_es': record.labelEs,
            'latitude': record.latitude,
            'longitude': record.longitude,
            'detected_at': record.detectedAt.toIso8601String(),
          });
        }

        record.synced = true;
        await record.save();
        synced++;
      } catch (e) {
        debugPrint('[Sync] Error en ${record.label}: $e');
      }
    }

    debugPrint('[Sync] Completado: $synced/${pending.length}');
    isSyncing.value = false;
    _updatePending();
  }
}