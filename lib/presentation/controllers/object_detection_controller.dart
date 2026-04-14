import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import '../../data/models/detection_record.dart';
import '../../data/models/detection_result.dart';
import '../../data/service/history_service.dart';
import '../../data/service/location_service.dart';
import '../../data/service/tflite_service.dart';
import 'auth_controller.dart';

class ObjectDetectionController extends GetxController {
  final TfliteService _tfliteService = TfliteService();
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

  static const Duration _processingInterval = Duration(milliseconds: 700);
  static const Duration _announcementCooldown = Duration(seconds: 3);
  static const Duration _saveCooldown = Duration(seconds: 5);

  @override
  void onInit() {
    super.onInit();
    _initializeDetection();
  }

  Future<void> _initializeDetection() async {
    statusMessage.value = 'Loading AI model...';
    isOnlineMode.value =
        (dotenv.env['GOOGLE_VISION_API_KEY'] ?? '').trim().isNotEmpty;

    try {
      await _tfliteService.init();
      await _configureTts();
      await _initializeCamera();
      statusMessage.value = 'Scanning environment...';
    } catch (e, stackTrace) {
      debugPrint('Object detection init error: $e');
      debugPrintStack(stackTrace: stackTrace);
      statusMessage.value = 'Could not initialize object detection.';
      isCameraInitialized.value = false;
    }
  }

  Future<void> _configureTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    final languageCode = Get.locale?.languageCode ?? 'en';
    if (languageCode == 'es') {
      await _tts.setLanguage('es-ES');
    } else {
      await _tts.setLanguage('en-US');
    }
  }

  Future<void> _initializeCamera() async {
    statusMessage.value = 'Opening camera...';

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    final selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
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

    final now = DateTime.now();
    if (_lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _processingInterval) {
      return;
    }

    _isProcessingFrame = true;
    _lastProcessedAt = now;

    try {
      final results = await _tfliteService.analyze(image);
      if (_isDisposed) return;
      _applyResults(results);
    } catch (e) {
      debugPrint('Frame analysis error: $e');
      if (!_isDisposed) {
        statusMessage.value = 'Analyzing scene...';
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _applyResults(List<DetectionResult> results) {
    final sortedResults = [...results]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    predictions.assignAll(sortedResults);

    if (sortedResults.isEmpty) {
      isDangerDetected.value = false;
      statusMessage.value = 'Scanning environment...';
      return;
    }

    final topResult = sortedResults.first;
    isDangerDetected.value = sortedResults.any((result) => result.isDangerous);
    statusMessage.value = 'Detected: ${topResult.labelEs}';

    _announceDetection(topResult);
    _saveDetection(topResult);
  }

  Future<void> _announceDetection(DetectionResult result) async {
    final now = DateTime.now();
    final canRepeatSameLabel = _lastAnnouncementAt == null ||
        now.difference(_lastAnnouncementAt!) >= _announcementCooldown;
    final isNewLabel = _lastAnnouncedLabel != result.label;

    if (!isNewLabel && !canRepeatSameLabel) {
      return;
    }

    _lastAnnouncedLabel = result.label;
    _lastAnnouncementAt = now;

    try {
      if (result.isDangerous) {
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) {
          await Vibration.vibrate(duration: 250);
        }
      }

      final spokenLabel =
          Get.locale?.languageCode == 'es' ? result.labelEs : result.label;
      await _tts.stop();
      await _tts.speak(spokenLabel);
    } catch (e) {
      debugPrint('Announcement error: $e');
    }
  }

  Future<void> _saveDetection(DetectionResult result) async {
    final now = DateTime.now();
    final withinCooldown = _lastSavedAt != null &&
        _lastSavedLabel == result.label &&
        now.difference(_lastSavedAt!) < _saveCooldown;

    if (withinCooldown) {
      return;
    }

    _lastSavedAt = now;
    _lastSavedLabel = result.label;

    try {
      final position = await _locationService.getCurrentPosition();
      final authController =
          Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

      final record = DetectionRecord(
        label: result.label,
        labelEs: result.labelEs,
        confidence: result.confidence,
        detectedAt: now,
        isDangerous: result.isDangerous,
        userId: authController?.currentUserId ?? '',
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      await _historyService.saveDetection(record);
    } catch (e) {
      debugPrint('Save detection error: $e');
    }
  }

  @override
  void onClose() {
    _isDisposed = true;

    final controller = cameraController;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }

    _tts.stop();
    _tfliteService.dispose();
    super.onClose();
  }
}
