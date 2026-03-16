import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../controllers/object_detection_controller.dart';

class ObjectDetectionScreen extends StatelessWidget {
  const ObjectDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el controlador
    final controller = Get.put(ObjectDetectionController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spider-Sense Vision"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Obx(() {
        // Pantalla de carga mientras se inicia la cámara
        if (!controller.isCameraInitialized.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        return Stack(
          children: [
            // 1. Vista de la cámara
            SizedBox.expand(
              child: CameraPreview(controller.cameraController!),
            ),
            
            // 2. Panel de resultados inferior
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barra decorativa superior del panel
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15), // ERROR CORREGIDO AQUÍ
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Text(
                      "SISTEMA DE RECONOCIMIENTO",
                      style: TextStyle(
                        color: Colors.redAccent, 
                        fontSize: 10, 
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Lógica de visualización de predicciones
                    Builder(builder: (context) {
                      if (controller.predictions.isEmpty) {
                        return const Text("ANALIZANDO...", 
                          style: TextStyle(color: Colors.white, fontSize: 18));
                      }

                      var topResult = controller.predictions[0];
                      double confidence = topResult['confidence'] ?? 0.0;

                      // Filtro de confianza para evitar resultados "extraños"
                      if (confidence < 0.40) {
                        return const Text("BUSCANDO OBJETO...", 
                          style: TextStyle(color: Colors.white54, fontSize: 18));
                      }

                      return Column(
                        children: [
                          Text(
                            topResult['label'].toString().toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 28, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${(confidence * 100).toStringAsFixed(1)}% de precisión",
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 16),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 10),
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