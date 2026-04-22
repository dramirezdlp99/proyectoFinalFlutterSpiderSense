import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/object_detection_controller.dart';
import '../../widgets/confidence_bar.dart';
import '../../widgets/danger_badge.dart';
import '../../../presentation/widgets/lang_theme_buttons.dart';

class ObjectDetectionScreen extends StatelessWidget {
  const ObjectDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ObjectDetectionController>()
        ? Get.find<ObjectDetectionController>()
        : Get.put(ObjectDetectionController());

    return Scaffold(
      appBar: AppBar(
        // Botón de regreso al home
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAllNamed('/home'),
        ),
        title: const Text('Spider-Sense Vision'),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        actions: [LangThemeButtons(routeName: '')],
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
                Text(controller.statusMessage.value,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
                child: CameraPreview(controller.cameraController!)),
            Obx(() => controller.isDangerDetected.value
                ? Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 6)),
                    ))
                : const SizedBox.shrink()),
            Obx(() => controller.isDangerDetected.value
                ? const Positioned(top: 20, right: 20, child: DangerBadge())
                : const SizedBox.shrink()),
            Obx(() => Positioned(
                  top: 20, left: 20,
                  child: _ModeChip(isOnline: controller.isOnlineMode.value),
                )),
            Align(
              alignment: Alignment.bottomCenter,
              child: _DetectionPanel(controller: controller),
            ),
          ],
        );
      }),
      // Bottom nav con Detect activo
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0: Get.offAllNamed('/home'); break;
            case 2: Get.offAllNamed('/history'); break;
            case 3: Get.offAllNamed('/settings'); break;
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined), label: 'home_title_short'.tr),
          BottomNavigationBarItem(
              icon: const Icon(Icons.radar), label: 'detect'.tr),
          BottomNavigationBarItem(
              icon: const Icon(Icons.history), label: 'history_title'.tr),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined), label: 'settings_title'.tr),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final bool isOnline;
  const _ModeChip({required this.isOnline});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (isOnline ? Colors.green : Colors.orange)
          .withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isOnline ? Icons.cloud : Icons.offline_bolt,
            color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(isOnline ? 'AI Online' : 'AI Offline',
            style: const TextStyle(color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _DetectionPanel extends StatelessWidget {
  final ObjectDetectionController controller;
  const _DetectionPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDanger = controller.isDangerDetected.value;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDanger
                ? Colors.red
                : Colors.red.withValues(alpha: 0.4),
            width: isDanger ? 2 : 1,
          ),
          boxShadow: isDanger
              ? [BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 20, spreadRadius: 2)]
              : null,
        ),
        child: controller.predictions.isEmpty
            ? Text(controller.statusMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontStyle: FontStyle.italic))
            : _DetectionContent(controller: controller),
      );
    });
  }
}

class _DetectionContent extends StatelessWidget {
  final ObjectDetectionController controller;
  const _DetectionContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final top = controller.predictions.first;
    final isEs = Get.locale?.languageCode == 'es';
    final label = isEs ? top.labelEs : top.label;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('SPIDER-SENSE AI',
            style: TextStyle(
                color: Color(0xFF8B0000), fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Text(
          top.isDangerous
              ? 'CRITICAL: ${label.toUpperCase()}'
              : label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: top.isDangerous ? const Color(0xFFFF6B6B) : Colors.white,
            fontSize: 26, fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ConfidenceBar(confidence: top.confidence),
        if (controller.predictions.length > 1) ...[
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 6),
          ...controller.predictions.skip(1).take(2).map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text((isEs ? r.labelEs : r.label).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
                Text('${(r.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          )),
        ],
      ],
    );
  }
}