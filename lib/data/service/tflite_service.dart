import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../core/utils/object_labels.dart';
import '../models/detection_result.dart';

class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _disposed = false;

  Future<void> init() async {
    final labelsData =
        await rootBundle.loadString('assets/models/labelmap.txt');
    _labels = labelsData
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != '???')
        .toList();

    _interpreter = await Interpreter.fromAsset(
      'assets/models/detect.tflite',
      options: InterpreterOptions()..threads = 2,
    );
    _disposed = false;
    debugPrint('[TFLite] Modelo cargado. Labels: ${_labels.length}');
  }

  Future<List<DetectionResult>> analyze(CameraImage cameraImage) async {
    if (_disposed || _interpreter == null) return [];

    final converted = await compute(_convertCameraImage, cameraImage);
    if (_disposed || _interpreter == null || converted == null) return [];

    // 300x300 — compatible con SSD MobileNet V1 y V2
    final resized = img.copyResize(converted, width: 300, height: 300);

    final input = List.generate(
      1,
      (_) => List.generate(
        300,
        (y) => List.generate(300, (x) {
          final p = resized.getPixel(x, y);
          return [p.r.toInt(), p.g.toInt(), p.b.toInt()];
        }),
      ),
    );

    final outputLocations =
        List.generate(1, (_) => List.generate(20, (_) => List.filled(4, 0.0)));
    final outputClasses = List.generate(1, (_) => List.filled(20, 0.0));
    final outputScores  = List.generate(1, (_) => List.filled(20, 0.0));
    final outputCount   = List.filled(1, 0.0);

    if (_disposed || _interpreter == null) return [];

    try {
      _interpreter!.runForMultipleInputs([input], {
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: outputCount,
      });
    } catch (e) {
      debugPrint('[TFLite] Error en inferencia: $e');
      return [];
    }

    final results = <DetectionResult>[];
    final count = outputCount[0].toInt().clamp(0, 10);

    for (int i = 0; i < count; i++) {
      final score = outputScores[0][i];
      if (score < 0.45) continue;

      final labelIndex = outputClasses[0][i].toInt() + 1;
      final label = (labelIndex >= 0 && labelIndex < _labels.length)
          ? _labels[labelIndex]
          : 'unknown';
      if (label == 'unknown' || label.isEmpty) continue;

      results.add(DetectionResult(
        label: label,
        labelEs: ObjectLabels.translate(label),
        confidence: score,
        isDangerous: ObjectLabels.isDangerous(label),
      ));
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  void dispose() {
    _disposed = true;
    _interpreter?.close();
    _interpreter = null;
  }

  static img.Image? _convertCameraImage(CameraImage image) {
    try {
      return image.format.group == ImageFormatGroup.yuv420
          ? _convertYUV420(image)
          : _convertBGRA8888(image);
    } catch (e) {
      return null;
    }
  }

  static img.Image _convertYUV420(CameraImage image) {
    final result = img.Image(width: image.width, height: image.height);
    final y = image.planes[0].bytes;
    final u = image.planes[1].bytes;
    final v = image.planes[2].bytes;
    final uvRow   = image.planes[1].bytesPerRow;
    final uvPixel = image.planes[1].bytesPerPixel ?? 1;
    for (int row = 0; row < image.height; row++) {
      for (int col = 0; col < image.width; col++) {
        final uvIndex = uvPixel * (col ~/ 2) + uvRow * (row ~/ 2);
        final yVal = y[row * image.planes[0].bytesPerRow + col];
        final uVal = u[uvIndex];
        final vVal = v[uvIndex];
        result.setPixelRgb(
          col, row,
          (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255),
          (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).round().clamp(0, 255),
          (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255),
        );
      }
    }
    return result;
  }

  static img.Image _convertBGRA8888(CameraImage image) =>
      img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: image.planes[0].bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
}