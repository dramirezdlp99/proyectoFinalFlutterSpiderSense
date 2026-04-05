import 'dart:typed_data';
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

  Future<void> init() async {
    final labelsData =
        await rootBundle.loadString('assets/models/labelmap.txt');
    _labels = labelsData
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != '???')
        .toList();
    _interpreter =
        await Interpreter.fromAsset('assets/models/detect.tflite');
  }

  Future<List<DetectionResult>> analyze(CameraImage cameraImage) async {
    if (_interpreter == null) return [];
    final converted = await compute(_convertCameraImage, cameraImage);
    if (converted == null) return [];

    final resized = img.copyResize(converted, width: 300, height: 300);
    final input = List.generate(1, (_) => List.generate(300,
      (y) => List.generate(300, (x) {
        final p = resized.getPixel(x, y);
        return [p.r.toInt(), p.g.toInt(), p.b.toInt()];
      }),
    ));

    final outputLocations =
        List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
    final outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
    final outputScores = List.generate(1, (_) => List.filled(10, 0.0));
    final outputCount = List.filled(1, 0.0);

    _interpreter!.runForMultipleInputs([input], {
      0: outputLocations, 1: outputClasses,
      2: outputScores, 3: outputCount,
    });

    final results = <DetectionResult>[];
    final count = outputCount[0].toInt();
    for (int i = 0; i < count && i < 10; i++) {
      final score = outputScores[0][i];
      if (score < 0.5) continue;
      final labelIndex = outputClasses[0][i].toInt() + 1;
      final label =
          labelIndex < _labels.length ? _labels[labelIndex] : 'unknown';
      results.add(DetectionResult(
        label: label,
        labelEs: ObjectLabels.translate(label),
        confidence: score,
        isDangerous: ObjectLabels.isDangerous(label),
      ));
    }
    return results;
  }

  void dispose() => _interpreter?.close();

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
    final uvRow = image.planes[1].bytesPerRow;
    final uvPixel = image.planes[1].bytesPerPixel ?? 1;
    for (int row = 0; row < image.height; row++) {
      for (int col = 0; col < image.width; col++) {
        final uvIndex = uvPixel * (col / 2).floor() + uvRow * (row / 2).floor();
        final yVal = y[row * image.planes[0].bytesPerRow + col];
        final uVal = u[uvIndex];
        final vVal = v[uvIndex];
        result.setPixelRgb(col, row,
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
        width: image.width, height: image.height,
        bytes: image.planes[0].bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
}