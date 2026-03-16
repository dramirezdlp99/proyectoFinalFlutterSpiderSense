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
    initCamera();
    loadModel();
  }

  // Carga los archivos que bajamos a assets/models/
  Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/models/model.tflite",
        labels: "assets/models/labels.txt",
      );
      print("Modelo cargado con éxito: $res");
    } catch (e) {
      print("Error al cargar el modelo de IA: $e");
    }
  }

  // Configura la cámara del celular
  Future<void> initCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0], // Usamos la cámara trasera principal
          ResolutionPreset.medium,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await cameraController!.initialize();
        isCameraInitialized.value = true;

        // Empezar el flujo de imágenes para la IA
        cameraController!.startImageStream((CameraImage image) {
          if (!isProcessing.value) {
            isProcessing.value = true;
            runModelOnFrame(image);
          }
        });
      }
    }
  }

  // Procesa cada frame con el modelo TFLite
  Future<void> runModelOnFrame(CameraImage image) async {
    var recognitions = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 2,
      threshold: 0.1,
      asynch: true,
    );

    predictions.value = recognitions ?? [];
    isProcessing.value = false;
  }

  @override
  void onClose() {
    cameraController?.dispose();
    Tflite.close();
    super.onClose();
  }
}