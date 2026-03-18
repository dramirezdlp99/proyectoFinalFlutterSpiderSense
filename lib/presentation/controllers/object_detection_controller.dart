import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  List<String> _labels = [];
  bool _isProcessing = false;
  bool _isDisposed = false;

  // Traducción básica de los objetos más comunes
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
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      statusMessage.value = 'Loading AI model...';

      // Cargar etiquetas
      final labelsData =
          await rootBundle.loadString('assets/models/labelmap.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Cargar modelo TFLite
      _interpreter = await Interpreter.fromAsset('assets/models/detect.tflite');

      statusMessage.value = 'Starting camera...';
      await _initializeCamera();
    } catch (e) {
      statusMessage.value = 'Error loading model: $e';
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
      // Convertir CameraImage a img.Image en un isolate separado
      final convertedImage = await compute(_convertCameraImage, cameraImage);
      if (convertedImage == null) return;

      // Redimensionar a 300x300 que es lo que espera el modelo SSD MobileNet
      final resized = img.copyResize(convertedImage, width: 300, height: 300);

      // Preparar el tensor de entrada [1, 300, 300, 3]
      final input = List.generate(
        1,
        (_) => List.generate(
          300,
          (y) => List.generate(
            300,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
            },
          ),
        ),
      );

      // Preparar tensores de salida del modelo SSD MobileNet
      // Salida 0: locations [1, 10, 4]
      // Salida 1: classes [1, 10]
      // Salida 2: scores [1, 10]
      // Salida 3: count [1]
      final outputLocations =
          List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
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

      // Procesar resultados
      final List<DetectionResult> results = [];
      final int count = outputCount[0].toInt();

      for (int i = 0; i < count && i < 10; i++) {
        final score = outputScores[0][i];
        if (score < 0.5) continue; // Solo mostrar con más del 50% de confianza

        final classIndex = outputClasses[0][i].toInt();
        final label = classIndex < _labels.length
            ? _labels[classIndex]
            : 'Unknown';
        final labelEs = _translations[label.toLowerCase()] ?? label;

        results.add(DetectionResult(
          label: label,
          confidence: score,
          labelEs: labelEs,
        ));
      }

      if (!_isDisposed) {
        predictions.assignAll(results);
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _isProcessing = false;
    }
  }

  // Función estática para ejecutar en isolate (no puede ser método de instancia)
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
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int yValue = yPlane[y * image.planes[0].bytesPerRow + x];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        int r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);

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
    cameraController?.stopImageStream();
    cameraController?.dispose();
    _interpreter?.close();
    super.onClose();
  }
}