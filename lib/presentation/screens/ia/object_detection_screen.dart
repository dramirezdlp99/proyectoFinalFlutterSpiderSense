import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../controllers/object_detection_controller.dart';

class ObjectDetectionScreen extends StatelessWidget {
  const ObjectDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        if (!controller.isCameraInitialized.value ||
            controller.cameraController == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  controller.statusMessage.value,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            // Vista previa de cámara
            Positioned.fill(
              child: CameraPreview(controller.cameraController!),
            ),

            // Panel inferior de resultados
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "SPIDER-SENSE AI",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Obx(() {
                      if (controller.predictions.isEmpty) {
                        return Text(
                          controller.statusMessage.value,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }

                      final top = controller.predictions.first;
                      // Mostrar en español si el idioma es español
                      final isSpanish =
                          Get.locale?.languageCode == 'es';
                      final displayLabel =
                          isSpanish ? top.labelEs : top.label;

                      return Column(
                        children: [
                          Text(
                            displayLabel.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: top.confidence,
                            backgroundColor: Colors.white10,
                            color: top.confidence > 0.7
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${(top.confidence * 100).toStringAsFixed(1)}% ${'confidence'.tr}",
                            style: TextStyle(
                              color: top.confidence > 0.7
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Mostrar otros objetos detectados si hay más
                          if (controller.predictions.length > 1) ...[
                            const SizedBox(height: 10),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 5),
                            ...controller.predictions
                                .skip(1)
                                .take(2)
                                .map((p) {
                              final label =
                                  isSpanish ? p.labelEs : p.label;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      "${(p.confidence * 100).toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
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