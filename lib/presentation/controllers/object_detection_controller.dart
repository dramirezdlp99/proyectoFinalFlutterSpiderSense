import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final String labelEs;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.labelEs,
  });
}

class ObjectDetectionController extends GetxController {
  CameraController? cameraController;
  RxBool isCameraInitialized = false.obs;
  RxList<DetectionResult> predictions = <DetectionResult>[].obs;
  RxString statusMessage = 'Initializing...'.obs;

  Interpreter? _interpreter;
  FlutterTts? _tts;
  List<String> _labels = [];
  bool _isProcessing = false;
  bool _isDisposed = false;
  String _lastSpokenLabel = '';
  DateTime _lastSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));

  static const Map<String, String> _translations = {
    'person': 'Persona',
    'bicycle': 'Bicicleta',
    'car': 'Automóvil',
    'motorcycle': 'Motocicleta',
    'airplane': 'Avión',
    'bus': 'Bus',
    'train': 'Tren',
    'truck': 'Camión',
    'boat': 'Bote',
    'traffic light': 'Semáforo',
    'fire hydrant': 'Hidrante',
    'stop sign': 'Señal de pare',
    'parking meter': 'Parquímetro',
    'bench': 'Banco',
    'bird': 'Pájaro',
    'cat': 'Gato',
    'dog': 'Perro',
    'horse': 'Caballo',
    'sheep': 'Oveja',
    'cow': 'Vaca',
    'elephant': 'Elefante',
    'bear': 'Oso',
    'zebra': 'Cebra',
    'giraffe': 'Jirafa',
    'backpack': 'Mochila',
    'umbrella': 'Paraguas',
    'handbag': 'Bolso',
    'tie': 'Corbata',
    'suitcase': 'Maleta',
    'bottle': 'Botella',
    'wine glass': 'Copa',
    'cup': 'Taza',
    'fork': 'Tenedor',
    'knife': 'Cuchillo',
    'spoon': 'Cuchara',
    'bowl': 'Tazón',
    'banana': 'Banano',
    'apple': 'Manzana',
    'sandwich': 'Sándwich',
    'orange': 'Naranja',
    'broccoli': 'Brócoli',
    'carrot': 'Zanahoria',
    'hot dog': 'Perro caliente',
    'pizza': 'Pizza',
    'donut': 'Dona',
    'cake': 'Torta',
    'chair': 'Silla',
    'couch': 'Sofá',
    'potted plant': 'Planta',
    'bed': 'Cama',
    'dining table': 'Mesa',
    'toilet': 'Inodoro',
    'tv': 'Televisor',
    'laptop': 'Portátil',
    'mouse': 'Ratón',
    'remote': 'Control remoto',
    'keyboard': 'Teclado',
    'cell phone': 'Celular',
    'microwave': 'Microondas',
    'oven': 'Horno',
    'toaster': 'Tostadora',
    'sink': 'Lavamanos',
    'refrigerator': 'Nevera',
    'book': 'Libro',
    'clock': 'Reloj',
    'vase': 'Florero',
    'scissors': 'Tijeras',
    'teddy bear': 'Oso de peluche',
    'hair drier': 'Secador',
    'toothbrush': 'Cepillo de dientes',
  };

  @override
  void onInit() {
    super.onInit();
    _initializeTts();
    _initializeModel();
  }

  Future<void> _initializeTts() async {
    _tts = FlutterTts();
    await _tts!.setVolume(1.0);
    await _tts!.setSpeechRate(0.5);
    await _tts!.setPitch(1.0);
    _updateTtsLanguage();
  }

  void _updateTtsLanguage() {
    final isSpanish = Get.locale?.languageCode == 'es';
    _tts?.setLanguage(isSpanish ? 'es-ES' : 'en-US');
  }

  Future<void> _speak(String text) async {
    final now = DateTime.now();
    // Solo habla si han pasado 3 segundos desde la última vez
    // y si el objeto detectado es diferente al anterior
    if (now.difference(_lastSpokenTime).inSeconds >= 3 ||
        text != _lastSpokenLabel) {
      _lastSpokenLabel = text;
      _lastSpokenTime = now;
      _updateTtsLanguage();
      await _tts?.speak(text);
    }
  }

  Future<void> _initializeModel() async {
    try {
      statusMessage.value = 'Loading AI model...';

      final labelsData =
          await rootBundle.loadString('assets/models/labelmap.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e != '???')
          .toList();

      _interpreter =
          await Interpreter.fromAsset('assets/models/detect.tflite');

      statusMessage.value = 'Starting camera...';
      await _initializeCamera();
    } catch (e) {
      statusMessage.value = 'Error: $e';
      debugPrint('Model error: $e');
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      statusMessage.value = 'No camera found';
      return;
    }

    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await cameraController!.initialize();
    if (_isDisposed) return;

    isCameraInitialized.value = true;
    statusMessage.value = 'Scanning...';

    cameraController!.startImageStream((image) {
      if (_isProcessing || _isDisposed) return;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage cameraImage) async {
    _isProcessing = true;
    try {
      final convertedImage =
          await compute(_convertCameraImage, cameraImage);
      if (convertedImage == null) return;

      final resized =
          img.copyResize(convertedImage, width: 300, height: 300);

      final input = List.generate(
        1,
        (_) => List.generate(
          300,
          (y) => List.generate(
            300,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r.toInt(),
                pixel.g.toInt(),
                pixel.b.toInt()
              ];
            },
          ),
        ),
      );

      final outputLocations = List.generate(
          1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
      final outputClasses =
          List.generate(1, (_) => List.filled(10, 0.0));
      final outputScores =
          List.generate(1, (_) => List.filled(10, 0.0));
      final outputCount = List.filled(1, 0.0);

      final outputs = {
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: outputCount,
      };

      _interpreter!.runForMultipleInputs([input], outputs);

      final List<DetectionResult> results = [];
      final int count = outputCount[0].toInt();

      for (int i = 0; i < count && i < 10; i++) {
        final score = outputScores[0][i];
        if (score < 0.5) continue;

        final classIndex = outputClasses[0][i].toInt();
        final labelIndex = classIndex + 1;
        final label = labelIndex < _labels.length
            ? _labels[labelIndex]
            : 'Unknown';

        final labelEs =
            _translations[label.toLowerCase()] ?? label;

        results.add(DetectionResult(
          label: label,
          confidence: score,
          labelEs: labelEs,
        ));
      }

      if (!_isDisposed) {
        predictions.assignAll(results);

        // Hablar si hay detección con más del 70% de confianza
        if (results.isNotEmpty && results.first.confidence >= 0.7) {
          final isSpanish = Get.locale?.languageCode == 'es';
          final textToSpeak = isSpanish
              ? results.first.labelEs
              : results.first.label;
          await _speak(textToSpeak);
        }
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _isProcessing = false;
    }
  }

  static img.Image? _convertCameraImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(image);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static img.Image _convertYUV420(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image result = img.Image(width: width, height: height);

    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() +
            uvRowStride * (y / 2).floor();
        final int yValue =
            yPlane[y * image.planes[0].bytesPerRow + x];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        int r = (yValue + 1.370705 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int g = (yValue -
                0.337633 * (uValue - 128) -
                0.698001 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.732446 * (uValue - 128))
            .round()
            .clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  static img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  @override
  void onClose() {
    _isDisposed = true;
    _tts?.stop();
    cameraController?.stopImageStream();
    cameraController?.dispose();
    _interpreter?.close();
    super.onClose();
  }
}