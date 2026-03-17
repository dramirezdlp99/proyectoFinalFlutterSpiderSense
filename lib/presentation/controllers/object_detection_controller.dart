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
      ResolutionPreset.medium,
      enableAudio: false,
      // Forzamos el formato para evitar el error de IllegalArgumentException
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
      // Nueva forma de extraer bytes para evitar el error de InputImageConverter
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation90deg, 
          format: InputImageFormat.yuv420, // Formato estándar Android
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<DetectedObject> objects = await _objectDetector!.processImage(inputImage);
      predictions.assignAll(objects);
      
    } catch (e) {
      // Si el error persiste, lo capturamos aquí para que no rompa la app
      debugPrint("Fallo en conversión de imagen: $e");
    } finally {
      // Aumentamos un poco el delay para dar respiro al procesador
      await Future.delayed(const Duration(milliseconds: 500));
      _isProcessing = false;
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