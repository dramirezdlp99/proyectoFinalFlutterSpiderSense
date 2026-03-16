import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../controllers/object_detection_controller.dart';

class ObjectDetectionScreen extends StatelessWidget {
  const ObjectDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Buscamos o inyectamos el controlador
    final controller = Get.put(ObjectDetectionController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spider-Sense Vision"),
        backgroundColor: Colors.red,
      ),
      body: Obx(() {
        // Si la cámara no está lista, mostramos un loading
        if (!controller.isCameraInitialized.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        return Stack(
          children: [
            // Vista de la cámara
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(controller.cameraController!),
            ),
            
            // Panel de resultados inferior
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "OBJETO DETECTADO",
                      style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      controller.predictions.isEmpty 
                        ? "ANALIZANDO..." 
                        : controller.predictions[0]['label'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 24, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    // Mostramos el porcentaje de confianza
                    if (controller.predictions.isNotEmpty)
                      Text(
                        "${(controller.predictions[0]['confidence'] * 100).toStringAsFixed(1)}% de certeza",
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}