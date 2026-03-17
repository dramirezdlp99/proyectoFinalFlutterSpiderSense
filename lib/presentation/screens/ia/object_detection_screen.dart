import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../controllers/object_detection_controller.dart';

class ObjectDetectionScreen extends StatelessWidget {
  const ObjectDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el controlador de GetX
    final controller = Get.put(ObjectDetectionController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spider-Sense Vision"),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.isCameraInitialized.value || controller.cameraController == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        return Stack(
          children: [
            // Vista previa de la cámara a pantalla completa
            Positioned.fill(
              child: CameraPreview(controller.cameraController!),
            ),
            
            // Panel inferior de resultados
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "SISTEMA DE ANÁLISIS ML KIT",
                      style: TextStyle(
                        color: Colors.redAccent, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    Builder(builder: (context) {
                      if (controller.predictions.isEmpty) {
                        return const Text(
                          "BUSCANDO OBJETIVOS...", 
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic)
                        );
                      }

                      // Tomamos el primer objeto detectado
                      final topObject = controller.predictions.first;
                      
                      // ML Kit devuelve una lista de posibles etiquetas (labels)
                      final String label = topObject.labels.isNotEmpty 
                          ? topObject.labels.first.text 
                          : "Objeto identificado";
                      
                      final double confidence = topObject.labels.isNotEmpty 
                          ? topObject.labels.first.confidence 
                          : 0.0;

                      return Column(
                        children: [
                          Text(
                            label.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 26, 
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: confidence,
                            backgroundColor: Colors.white10,
                            color: confidence > 0.5 ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${(confidence * 100).toStringAsFixed(1)}% DE PRECISIÓN",
                            style: TextStyle(
                              color: confidence > 0.5 ? Colors.greenAccent : Colors.orangeAccent, 
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      );
                    }),
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