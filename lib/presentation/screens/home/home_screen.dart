import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart'; // Asegúrate de importar el controlador

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Buscamos el controlador existente
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr),
        actions: [
          TextButton(
            onPressed: () {
              Locale? current = Get.locale;
              Get.updateLocale(current?.languageCode == 'es' 
                ? const Locale('en', 'US') 
                : const Locale('es', 'ES'));
            },
            child: Text(
              Get.locale?.languageCode == 'es' ? 'EN' : 'ES',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              Get.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: Get.isDarkMode ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              Get.changeTheme(Get.isDarkMode ? ThemeData.light() : ThemeData.dark());
            },
          ),
          // NUEVO: Botón de Cerrar Sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView( // Usamos SingleChildScrollView por si el contenido crece
        child: Column(
          children: [
            // SECCIÓN ADMIN: Solo visible si isAdmin es true
            Obx(() => authController.isAdmin.value 
              ? Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red)
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Modo Administrador Activo", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : const SizedBox.shrink()
            ),

            GridView.count(
              shrinkWrap: true, // Importante para que funcione dentro de Column
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildMenuCard('ai_object_detection'.tr, Icons.camera_alt, Colors.red, () {
                  // Aquí conectaremos la cámara pronto
                }),
                _buildMenuCard('ai_text_reader'.tr, Icons.text_fields, Colors.blue, () {
                  // Aquí el lector de texto
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}