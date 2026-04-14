import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/object_detection_controller.dart';
import '../../widgets/confidence_bar.dart';
import '../../widgets/danger_badge.dart';

class ObjectDetectionScreen extends StatelessWidget {
  const ObjectDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ObjectDetectionController>()
        ? Get.find<ObjectDetectionController>()
        : Get.put(ObjectDetectionController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spider-Sense Vision'),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
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
            Positioned.fill(
              child: CameraPreview(controller.cameraController!),
            ),
            Obx(() => controller.isDangerDetected.value
                ? Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 6),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
            Obx(() => controller.isDangerDetected.value
                ? const Positioned(top: 20, right: 20, child: DangerBadge())
                : const SizedBox.shrink()),
            Obx(() => controller.isOnlineMode.value
                ? Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'AI Online',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                : Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.offline_bolt,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI Offline',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )),
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
                    color: controller.isDangerDetected.value
                        ? Colors.red
                        : Colors.redAccent.withOpacity(0.5),
                  ),
                ),
                child: Obx(() {
                  if (controller.predictions.isEmpty) {
                    return Text(
                      controller.statusMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }

                  final top = controller.predictions.first;
                  final isSpanish = Get.locale?.languageCode == 'es';
                  final label = isSpanish ? top.labelEs : top.label;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SPIDER-SENSE AI',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              top.isDangerous ? Colors.redAccent : Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConfidenceBar(confidence: top.confidence),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }
}
