import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/object_labels.dart';
import '../models/detection_result.dart';

class VisionService {
  static final VisionService _instance = VisionService._internal();
  factory VisionService() => _instance;
  VisionService._internal();

  Future<List<DetectionResult>> analyzeImage(File imageFile) async {
    try {
      final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
      if (apiKey.isEmpty) return [];

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'LABEL_DETECTION', 'maxResults': 10},
                {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},
              ],
            }
          ],
        }),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final responses = data['responses'][0];
      final results = <DetectionResult>[];
      final seen = <String>{};

      for (final obj
          in responses['localizedObjectAnnotations'] as List? ?? []) {
        final label = (obj['name'] as String).toLowerCase();
        final score = (obj['score'] as num).toDouble();
        if (score < 0.5 || seen.contains(label)) continue;
        seen.add(label);
        results.add(DetectionResult(
          label: label,
          labelEs: ObjectLabels.translate(label),
          confidence: score,
          isDangerous: ObjectLabels.isDangerous(label),
        ));
      }

      for (final lbl in responses['labelAnnotations'] as List? ?? []) {
        final label = (lbl['description'] as String).toLowerCase();
        final score = (lbl['score'] as num).toDouble();
        if (score < 0.7 || seen.contains(label)) continue;
        seen.add(label);
        results.add(DetectionResult(
          label: label,
          labelEs: ObjectLabels.translate(label),
          confidence: score,
          isDangerous: ObjectLabels.isDangerous(label),
        ));
      }

      return results;
    } catch (e) {
      debugPrint('Vision API error: $e');
      return [];
    }
  }
}