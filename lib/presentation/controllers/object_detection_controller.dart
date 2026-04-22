import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:vibration/vibration.dart';

import '../../data/models/detection_record.dart';
import '../../data/models/detection_result.dart';
import '../../data/service/history_service.dart';
import '../../data/service/location_service.dart';
import '../../data/service/tflite_service.dart';
import '../../data/service/vision_service.dart';
import 'auth_controller.dart';

class ObjectDetectionController extends GetxController {
  final TfliteService _tfliteService = TfliteService();
  final VisionService _visionService = VisionService();
  final HistoryService _historyService = HistoryService();
  final LocationService _locationService = LocationService();
  final FlutterTts _tts = FlutterTts();

  CameraController? cameraController;

  final RxBool isCameraInitialized = false.obs;
  final RxBool isDangerDetected = false.obs;
  final RxBool isOnlineMode = false.obs;
  final RxString statusMessage = 'Initializing camera...'.obs;
  final RxList<DetectionResult> predictions = <DetectionResult>[].obs;

  bool _isProcessingFrame = false;
  bool _isDisposed = false;
  DateTime? _lastProcessedAt;
  DateTime? _lastAnnouncementAt;
  DateTime? _lastSavedAt;
  String? _lastAnnouncedLabel;
  String? _lastSavedLabel;

  // Online cada 4s para no gastar cuota; offline cada 700ms
  static const Duration _onlineInterval  = Duration(seconds: 4);
  static const Duration _offlineInterval = Duration(milliseconds: 700);
  static const Duration _announcementCooldown = Duration(seconds: 3);
  static const Duration _saveCooldown = Duration(seconds: 5);

  @override
  void onInit() {
    super.onInit();
    _initializeDetection();
  }

  Future<void> _initializeDetection() async {
    statusMessage.value = 'Loading AI model...';
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
    final hfKey = dotenv.env["HUGGING_FACE_API_KEY"] ?? "";
    isOnlineMode.value = hfKey.trim().isNotEmpty;

    try {
      await _tfliteService.init();
      await _configureTts();
      await _initializeCamera();
      statusMessage.value = 'Scanning environment...';
    } catch (e, st) {
      debugPrint('Detection init error: $e');
      debugPrintStack(stackTrace: st);
      statusMessage.value = 'Could not initialize.';
      isCameraInitialized.value = false;
    }
  }

  Future<void> _configureTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    final lang = Get.locale?.languageCode ?? 'en';
    await _tts.setLanguage(lang == 'es' ? 'es-ES' : 'en-US');
  }

  Future<void> _initializeCamera() async {
    statusMessage.value = 'Opening camera...';
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras available');

    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      cam, ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller.initialize();
    await controller.startImageStream(_processCameraImage);
    cameraController = controller;
    isCameraInitialized.value = true;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed || _isProcessingFrame) return;

    final interval = isOnlineMode.value ? _onlineInterval : _offlineInterval;
    final now = DateTime.now();
    if (_lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < interval) return;

    _isProcessingFrame = true;
    _lastProcessedAt = now;

    try {
      List<DetectionResult> results;

      if (isOnlineMode.value) {
        // Convierte el frame YUV a JPEG en un isolate y lo envía a Vision
        results = await _analyzeFrameOnline(image);
        if (results.isEmpty) results = await _tfliteService.analyze(image);
      } else {
        results = await _tfliteService.analyze(image);
      }

      if (!_isDisposed) _applyResults(results);
    } catch (e) {
      debugPrint('Frame analysis error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Convierte CameraImage a JPEG bytes y los envía a Vision API.
  /// No toca el stream de cámara en absoluto.
  Future<List<DetectionResult>> _analyzeFrameOnline(CameraImage frame) async {
    try {
      // Convertir YUV → JPEG en isolate (no bloquea UI)
      final jpegBytes = await compute(_frameToJpeg, frame);
      if (jpegBytes == null || jpegBytes.isEmpty) return [];
      return await _visionService.analyzeBytes(jpegBytes);
    } catch (e) {
      debugPrint('[Vision] Error procesando frame: $e');
      return [];
    }
  }

  /// Corre en un isolate separado para no bloquear el stream
  static Uint8List? _frameToJpeg(CameraImage image) {
    try {
      img.Image? converted;
      if (image.format.group == ImageFormatGroup.yuv420) {
        converted = _convertYUV420(image);
      } else {
        converted = img.Image.fromBytes(
          width: image.width, height: image.height,
          bytes: image.planes[0].bytes.buffer,
          order: img.ChannelOrder.bgra,
        );
      }
      if (converted == null) return null;
      // Redimensionar para reducir tamaño del payload (Vision acepta hasta 10MB)
      final resized = img.copyResize(converted, width: 640);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
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
        result.setPixelRgb(col, row,
          (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255),
          (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).round().clamp(0, 255),
          (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255),
        );
      }
    }
    return result;
  }

  void _applyResults(List<DetectionResult> results) {
    final sorted = [...results]..sort((a, b) => b.confidence.compareTo(a.confidence));
    predictions.assignAll(sorted);
    if (sorted.isEmpty) {
      isDangerDetected.value = false;
      statusMessage.value = 'Scanning environment...';
      return;
    }
    final top = sorted.first;
    isDangerDetected.value = sorted.any((r) => r.isDangerous);
    statusMessage.value = 'Detected: ${top.labelEs}';
    _announceDetection(top);
    _saveDetection(top);
  }

  Future<void> _announceDetection(DetectionResult result) async {
    final now = DateTime.now();
    final canRepeat = _lastAnnouncementAt == null ||
        now.difference(_lastAnnouncementAt!) >= _announcementCooldown;
    if (_lastAnnouncedLabel == result.label && !canRepeat) return;
    _lastAnnouncedLabel = result.label;
    _lastAnnouncementAt = now;
    try {
      if (result.isDangerous) {
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) await Vibration.vibrate(duration: 250);
      }
      final spoken = Get.locale?.languageCode == 'es' ? result.labelEs : result.label;
      await _tts.stop();
      await _tts.speak(spoken);
    } catch (e) { debugPrint('TTS error: $e'); }
  }

  Future<void> _saveDetection(DetectionResult result) async {
    final now = DateTime.now();
    if (_lastSavedAt != null && _lastSavedLabel == result.label &&
        now.difference(_lastSavedAt!) < _saveCooldown) return;
    _lastSavedAt = now;
    _lastSavedLabel = result.label;
    try {
      final position = await _locationService.getCurrentPosition();
      final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
      await _historyService.saveDetection(DetectionRecord(
        label: result.label, labelEs: result.labelEs,
        confidence: result.confidence, detectedAt: now,
        isDangerous: result.isDangerous, userId: auth?.currentUserId ?? '',
        latitude: position?.latitude, longitude: position?.longitude,
      ));
    } catch (e) { debugPrint('Save error: $e'); }
  }

  @override
  void onClose() {
    _isDisposed = true;
    final ctrl = cameraController;
    if (ctrl != null) {
      if (ctrl.value.isStreamingImages) ctrl.stopImageStream();
      ctrl.dispose();
    }
    _tts.stop();
    _tfliteService.dispose();
    super.onClose();
  }
}