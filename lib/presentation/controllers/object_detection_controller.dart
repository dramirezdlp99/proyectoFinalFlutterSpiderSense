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
    // Cargamos el modelo primero, luego la cámara
    loadModel().then((_) => initCamera());
  }

  Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/models/model.tflite",
        labels: "assets/models/labels.txt",
        numThreads: 2,
        isAsset: true,
      );
      print("IA Spider-Sense cargada: $res");
    } catch (e) {
      print("Error al cargar el cerebro de la IA: $e");
    }
  }

  Future<void> initCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await cameraController!.initialize();
        isCameraInitialized.value = true;

        // Escuchamos el flujo de imágenes
        cameraController!.startImageStream((CameraImage image) {
          if (!isProcessing.value) {
            isProcessing.value = true;
            runModelOnFrame(image);
          }
        });
      }
    }
  }

  Future<void> runModelOnFrame(CameraImage image) async {
    try {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5, // Requerido para modelos MobileNet Float
        imageStd: 127.5,  // Requerido para modelos MobileNet Float
        rotation: 90,
        numResults: 2,
        threshold: 0.2,
        asynch: true,
      );

      predictions.value = recognitions ?? [];
    } catch (e) {
      print("Error en reconocimiento: $e");
    } finally {
      // Pequeño respiro para evitar que el celular se caliente
      Future.delayed(const Duration(milliseconds: 100), () {
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
