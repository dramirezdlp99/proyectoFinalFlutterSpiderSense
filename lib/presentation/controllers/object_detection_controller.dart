import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // NECESARIO PARA debugPrint
import 'dart:io';
import 'dart:ui';

class ObjectDetectionController extends GetxController {
  CameraController? cameraController;
  RxBool isCameraInitialized = false.obs;
  
  // Lista de objetos detectados (Formato ML Kit)
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
    // Configuramos el motor de búsqueda de Google
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
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    await cameraController!.initialize();
    isCameraInitialized.value = true;

    // Escuchamos el flujo de imágenes constantemente
    cameraController!.startImageStream((image) {
      if (_isProcessing) return;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    _isProcessing = true;
    
    try {
      // Conversión de bytes para el motor de Google
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
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<DetectedObject> objects = await _objectDetector!.processImage(inputImage);
      
      // Actualizamos la lista observable
      predictions.assignAll(objects);
      
    } catch (e) {
      debugPrint("Error de detección: $e");
    } finally {
      // Pequeño delay para no saturar el procesador del móvil
      await Future.delayed(const Duration(milliseconds: 300));
      _isProcessing = false;
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _objectDetector?.close();
    super.onClose();
  }
}