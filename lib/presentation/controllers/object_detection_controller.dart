import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:permission_handler/permission_handler.dart';

class ObjectDetectionController extends GetxController {
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  var isCameraInitialized = false.obs;
  var predictions = [].obs;
  var isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadModel().then((_) => initCamera());
  }

  // 1. Carga el modelo con manejo de errores
  Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/models/model.tflite",
        labels: "assets/models/labels.txt",
        numThreads: 2, // Usamos 2 hilos para que el celular no se caliente tanto
        isAsset: true,
      );
      print("Cerebro de IA listo: $res");
    } catch (e) {
      print("Error fatal al cargar IA: $e");
    }
  }

  // 2. Inicializa la cámara con permisos
  Future<void> initCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0], // Cámara trasera
          ResolutionPreset.medium, // Resolución media para mejor rendimiento
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await cameraController!.initialize();
        isCameraInitialized.value = true;

        // 3. Flujo de imágenes controlado
        cameraController!.startImageStream((CameraImage image) async {
          if (!isProcessing.value) {
            isProcessing.value = true;
            
            // Damos un pequeño respiro al procesador (150ms)
            await Future.delayed(const Duration(milliseconds: 150));
            
            runModelOnFrame(image);
          }
        });
      }
    }
  }

  // 4. Inferencia de IA (CORREGIDA PARA MODELO CUANTIZADO)
  Future<void> runModelOnFrame(CameraImage image) async {
    try {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        // IMPORTANTE: Para modelos UINT8 (cuantizados) usamos estos valores:
        imageMean: 0.0, 
        imageStd: 255.0, 
        rotation: 90,
        numResults: 2,
        threshold: 0.2, // Umbral de confianza del 20%
        asynch: true,
      );

      predictions.value = recognitions ?? [];
    } catch (e) {
      print("Error en inferencia: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    cameraController?.stopImageStream();
    cameraController?.dispose();
    Tflite.close();
    super.onClose();
  }
}