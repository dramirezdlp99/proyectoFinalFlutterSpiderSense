import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:io';
import 'dart:ui';

class ObjectDetectionController extends GetxController {
  CameraController? cameraController;
  RxBool isCameraInitialized = false.obs;
  RxList<DetectedObject> predictions = <DetectedObject>[].obs;
  
  ObjectDetector? _objectDetector;
  bool _isProcessing = false;

  @override
  void onInit() {
    super.onInit();
    _initializeDetector();
    _initializeCamera();
  }

  void _initializeDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.low, 
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    await cameraController!.initialize();
    isCameraInitialized.value = true;

    cameraController!.startImageStream((image) {
      if (_isProcessing) return;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    _isProcessing = true;
    
    try {
      // PROCESAMIENTO ROBUSTO DE BYTES (Solución al IllegalArgumentException)
      final allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getRotation(cameraController!.description.sensorOrientation), 
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<DetectedObject> objects = await _objectDetector!.processImage(inputImage);
      predictions.assignAll(objects);
      
    } catch (e) {
      debugPrint("Fallo en conversión de imagen: $e");
    } finally {
      // Delay mayor para evitar saturación en el procesador del móvil
      await Future.delayed(const Duration(milliseconds: 600));
      _isProcessing = false;
    }
  }

  // Ajuste preciso de rotación según el sensor del dispositivo
  InputImageRotation _getRotation(int orientation) {
    switch (orientation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  @override
  void onClose() {
    cameraController?.stopImageStream();
    cameraController?.dispose();
    _objectDetector?.close();
    super.onClose();
  }
}