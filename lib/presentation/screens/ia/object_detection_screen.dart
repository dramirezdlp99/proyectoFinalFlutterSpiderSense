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
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 20),
                Text("INICIALIZANDO LENTES...", 
                  style: TextStyle(color: Colors.white, letterSpacing: 2)),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: CameraPreview(controller.cameraController!),
            ),
            
            // Panel de resultados
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
                    Container(
                      width: 50,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    
                    const Text(
                      "ANÁLISIS DE ENTORNO EN TIEMPO REAL",
                      style: TextStyle(
                        color: Colors.redAccent, 
                        fontSize: 9, 
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Builder(builder: (context) {
                      if (controller.predictions.isEmpty) {
                        return const Text("BUSCANDO OBJETIVOS...", 
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic));
                      }

                      var topResult = controller.predictions[0];
                      double confidence = topResult['confidence'] ?? 0.0;

                      // Umbral de 0.25 para que detecte tus dispositivos
                      if (confidence < 0.25) {
                        return const Text("IDENTIFICANDO...", 
                          style: TextStyle(color: Colors.white54, fontSize: 16));
                      }

                      return Column(
                        children: [
                          Text(
                            topResult['label'].toString().toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle( // SE ELIMINÓ 'const' AQUÍ PARA EVITAR EL ERROR
                              color: Colors.white, 
                              fontSize: 26, 
                              fontWeight: FontWeight.w900, // Reemplazo seguro de .black
                              letterSpacing: 1.0
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: confidence,
                            backgroundColor: Colors.white10,
                            color: confidence > 0.6 ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${(confidence * 100).toStringAsFixed(1)}% DE PROBABILIDAD",
                            style: TextStyle(
                              color: confidence > 0.6 ? Colors.greenAccent : Colors.orangeAccent, 
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