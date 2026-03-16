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

  // 1. Carga el modelo
  Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/models/model.tflite",
        labels: "assets/models/labels.txt",
        numThreads: 1, // Reducimos a 1 para máxima estabilidad en la prueba
        isAsset: true,
      );
      print("Cerebro de IA cargado: $res");
    } catch (e) {
      print("Error fatal al cargar IA: $e");
    }
  }

  // 2. Inicializa la cámara
  Future<void> initCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0],
          ResolutionPreset.low, // Bajamos la resolución a LOW para que el proceso sea más ligero
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await cameraController!.initialize();
        isCameraInitialized.value = true;

        cameraController!.startImageStream((CameraImage image) {
          if (!isProcessing.value) {
            isProcessing.value = true;
            // Quitamos el delay para ver si el flujo directo ayuda a la librería
            runModelOnFrame(image);
          }
        });
      }
    }
  }

  // 3. Inferencia de IA (ESTA ES LA PARTE CRÍTICA)
  Future<void> runModelOnFrame(CameraImage image) async {
    try {
      // Intentamos con los valores de normalización estándar para MobileNet Quant
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5, // Valor estándar para modelos MobileNet
        imageStd: 127.5,  // Valor estándar para modelos MobileNet
        rotation: 90,
        numResults: 2,
        threshold: 0.1, 
        asynch: true,
      );

      predictions.value = recognitions ?? [];
    } catch (e) {
      print("Error en inferencia: $e");
    } finally {
      // Pequeño respiro después del proceso
      Future.delayed(const Duration(milliseconds: 200), () {
        isProcessing.value = false;
      });
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