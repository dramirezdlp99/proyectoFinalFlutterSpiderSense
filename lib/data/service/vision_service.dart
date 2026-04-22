import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/object_labels.dart';
import '../models/detection_result.dart';

class VisionService {
  static final VisionService _instance = VisionService._internal();
  factory VisionService() => _instance;
  VisionService._internal();

  // URL correcta para Hugging Face Inference API v2
  static const String _endpoint =
      'https://router.huggingface.co/hf-inference/models/facebook/detr-resnet-50';

  Future<List<DetectionResult>> analyzeBytes(Uint8List jpegBytes) async {
    final apiKey = dotenv.env['HUGGING_FACE_API_KEY'] ?? '';
    if (apiKey.isEmpty) return [];

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'image/jpeg',
          'Accept': 'application/json',
        },
        body: jpegBytes,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 503) {
        debugPrint('[HF] Modelo cargando, esperando...');
        await Future.delayed(const Duration(seconds: 5));
        return analyzeBytes(jpegBytes);
      }

      if (response.statusCode != 200) {
        debugPrint('[HF] HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
        return [];
      }

      final List<dynamic> data = jsonDecode(response.body);
      final results = <DetectionResult>[];
      final seen = <String>{};

      for (final item in data) {
        final label = (item['label'] as String).toLowerCase();
        final score = (item['score'] as num).toDouble();
        if (score < 0.5 || seen.contains(label)) continue;
        seen.add(label);
        results.add(DetectionResult(
          label: label,
          labelEs: ObjectLabels.translate(label),
          confidence: score,
          isDangerous: ObjectLabels.isDangerous(label),
        ));
      }

      results.sort((a, b) => b.confidence.compareTo(a.confidence));
      debugPrint('[HF] Detectados: ${results.map((r) => r.label).join(', ')}');
      return results;
    } catch (e) {
      debugPrint('[HF] Error: $e');
      return [];
    }
  }
}