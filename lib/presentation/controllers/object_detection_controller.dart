import 'dart:io';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:vibration/vibration.dart';
import '../../../data/models/detection_result.dart';
import '../../../data/models/detection_record.dart';
import '../../../data/service/history_service.dart';
import '../../../data/service/location_service.dart';
import '../../../data/service/tflite_service.dart';
import '../../../data/service/vision_service.dart';

class ObjectDetectionController extends GetxController {
  CameraController? cameraController;
  RxBool isCameraInitialized = false.obs;
  RxList<DetectionResult> predictions = <DetectionResult>[].obs;
  RxString statusMessage = 'Initializing...'.obs;
  RxBool isDangerDetected = false.obs;
  RxBool isOnlineMode = false.obs;

  final _tflite = TfliteService();
  final _vision = VisionService();
  final _location = LocationService();
  final _history = HistoryService();
  final _tts = FlutterTts();

  bool _isProcessing = false;
  bool _isDisposed = false;
  String _lastSpoken = '';
  String _lastSaved = '';
  DateTime _lastSpokenAt = DateTime.now().subtract(const Duration(seconds: 10));
  DateTime _lastSavedAt = DateTime.now().subtract(const Duration(seconds: 10));
  DateTime _lastOnlineAt = DateTime.now().subtract(const Duration(seconds: 5));
  DateTime _lastLocationAt = DateTime.now().subtract(const Duration(seconds: 30));

  @override
  void onInit() {
    super.onInit();
    _initTts();
    _initCamera();
    _watchConnectivity();
    _location.requestPermission();
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    final isEs = Get.locale?.languageCode == 'es';
    await _tts.setLanguage(isEs ? 'es-ES' : 'en-US');
  }

  void _watchConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      isOnlineMode.value = result != ConnectivityResult.none;
    });
    Connectivity().checkConnectivity().then((result) {
      isOnlineMode.value = result != ConnectivityResult.none;
    });
  }

  Future<void> _initCamera() async {
    try {
      statusMessage.value = 'Loading AI...';
      await _tflite.init();
      final cameras = await availableCameras();
      if (cameras.isEmpty) { statusMessage.value = 'No camera'; return; }
      cameraController = CameraController(
        cameras[0], ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await cameraController!.initialize();
      if (_isDisposed) return;
      isCameraInitialized.value = true;
      statusMessage.value = 'Scanning...';
      cameraController!.startImageStream((frame) {
        if (!_isProcessing && !_isDisposed) _processFrame(frame);
      });
    } catch (e) {
      statusMessage.value = 'Error: $e';
    }
  }

  Future<void> _processFrame(CameraImage frame) async {
    _isProcessing = true;
    try {
      List<DetectionResult> results = [];
      final now = DateTime.now();

      if (isOnlineMode.value &&
          now.difference(_lastOnlineAt).inSeconds >= 5) {
        _lastOnlineAt = now;
        final converted = await compute(_toImage, frame);
        if (converted != null) {
          final file = File('${Directory.systemTemp.path}/frame.jpg');
          await file.writeAsBytes(img.encodeJpg(converted, quality: 80));
          results = await _vision.analyzeImage(file);
        }
      }

      if (results.isEmpty) results = await _tflite.analyze(frame);
      if (!_isDisposed) await _handleResults(results);
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _isProcessing = false;
    }
  }

  Future<void> _handleResults(List<DetectionResult> results) async {
    predictions.assignAll(results);
    if (results.isEmpty || results.first.confidence < 0.7) {
      isDangerDetected.value = false;
      return;
    }
    final top = results.first;
    final isEs = Get.locale?.languageCode == 'es';
    final text = isEs ? top.labelEs : top.label;

    final now = DateTime.now();
    if (now.difference(_lastSpokenAt).inSeconds >= 3 || text != _lastSpoken) {
      _lastSpoken = text;
      _lastSpokenAt = now;
      await _tts.speak(text);
    }

    if (top.isDangerous) {
      isDangerDetected.value = true;
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
      if (now.difference(_lastLocationAt).inSeconds >= 30) {
        _lastLocationAt = now;
        await _location.getCurrentPosition();
      }
    } else {
      isDangerDetected.value = false;
    }

    if (now.difference(_lastSavedAt).inSeconds >= 10 || top.label != _lastSaved) {
      _lastSaved = top.label;
      _lastSavedAt = now;
      await _history.saveDetection(DetectionRecord(
        label: top.label,
        labelEs: top.labelEs,
        confidence: top.confidence,
        detectedAt: now,
        isDangerous: top.isDangerous,
        userId: _getUserId(),
        latitude: _location.lastPosition?.latitude,
        longitude: _location.lastPosition?.longitude,
      ));
    }
  }

  String _getUserId() {
    try {
      return Get.find<dynamic>().supabase.auth.currentUser?.id ?? 'anonymous';
    } catch (_) { return 'anonymous'; }
  }

  static img.Image? _toImage(CameraImage frame) {
    try {
      final w = frame.width, h = frame.height;
      final result = img.Image(width: w, height: h);
      final y = frame.planes[0].bytes;
      final u = frame.planes[1].bytes;
      final v = frame.planes[2].bytes;
      final uvRow = frame.planes[1].bytesPerRow;
      final uvPx = frame.planes[1].bytesPerPixel ?? 1;
      for (int row = 0; row < h; row++) {
        for (int col = 0; col < w; col++) {
          final uvi = uvPx * (col ~/ 2) + uvRow * (row ~/ 2);
          final yv = y[row * frame.planes[0].bytesPerRow + col];
          final uv = u[uvi], vv = v[uvi];
          result.setPixelRgb(col, row,
            (yv + 1.370705 * (vv - 128)).round().clamp(0, 255),
            (yv - 0.337633 * (uv - 128) - 0.698001 * (vv - 128)).round().clamp(0, 255),
            (yv + 1.732446 * (uv - 128)).round().clamp(0, 255),
          );
        }
      }
      return result;
    } catch (_) { return null; }
  }

  @override
  void onClose() {
    _isDisposed = true;
    _tts.stop();
    cameraController?.stopImageStream();
    cameraController?.dispose();
    _tflite.dispose();
    super.onClose();
  }
}