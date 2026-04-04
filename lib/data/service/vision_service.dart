import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VisionResult {
  final String label;
  final String labelEs;
  final double confidence;
  final bool isDangerous;

  VisionResult({
    required this.label,
    required this.labelEs,
    required this.confidence,
    required this.isDangerous,
  });
}

class VisionService {
  static final VisionService _instance = VisionService._internal();
  factory VisionService() => _instance;
  VisionService._internal();

  static const List<String> _dangerousObjects = [
    'car', 'truck', 'bus', 'motorcycle', 'bicycle',
    'dog', 'person', 'train', 'traffic light',
    'stop sign', 'fire hydrant', 'cat',
  ];

  static const Map<String, String> _translations = {
    'person': 'Persona', 'bicycle': 'Bicicleta', 'car': 'Automóvil',
    'motorcycle': 'Motocicleta', 'bus': 'Bus', 'train': 'Tren',
    'truck': 'Camión', 'traffic light': 'Semáforo', 'dog': 'Perro',
    'cat': 'Gato', 'stop sign': 'Señal de pare',
    'fire hydrant': 'Hidrante', 'chair': 'Silla', 'bottle': 'Botella',
    'cup': 'Taza', 'laptop': 'Portátil', 'cell phone': 'Celular',
    'book': 'Libro', 'clock': 'Reloj', 'scissors': 'Tijeras',
    'table': 'Mesa', 'door': 'Puerta', 'window': 'Ventana',
    'stairs': 'Escaleras', 'wall': 'Pared', 'floor': 'Piso',
    'street': 'Calle', 'sidewalk': 'Andén', 'building': 'Edificio',
    'tree': 'Árbol', 'bench': 'Banco', 'sign': 'Señal',
  };

  Future<List<VisionResult>> analyzeImage(File imageFile) async {
    try {
      final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
      if (apiKey.isEmpty) return [];

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
          'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
        ),
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
      final List<VisionResult> results = [];
      final Set<String> seen = {};

      // Procesar objetos localizados primero (más precisos)
      final objects = responses['localizedObjectAnnotations'] as List? ?? [];
      for (final obj in objects) {
        final label = (obj['name'] as String).toLowerCase();
        final score = (obj['score'] as num).toDouble();
        if (score < 0.5 || seen.contains(label)) continue;
        seen.add(label);
        results.add(VisionResult(
          label: label,
          labelEs: _translations[label] ?? label,
          confidence: score,
          isDangerous: _dangerousObjects.contains(label),
        ));
      }

      // Complementar con etiquetas generales
      final labels = responses['labelAnnotations'] as List? ?? [];
      for (final lbl in labels) {
        final label = (lbl['description'] as String).toLowerCase();
        final score = (lbl['score'] as num).toDouble();
        if (score < 0.7 || seen.contains(label)) continue;
        seen.add(label);
        results.add(VisionResult(
          label: label,
          labelEs: _translations[label] ?? label,
          confidence: score,
          isDangerous: _dangerousObjects.contains(label),
        ));
      }

      return results;
    } catch (e) {
      debugPrint('Vision API error: $e');
      return [];
    }
  }
}