import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildMenuCard('ai_object_detection'.tr, Icons.camera_alt, Colors.red, () {}),
          _buildMenuCard('ai_text_reader'.tr, Icons.text_fields, Colors.blue, () {}),
        ],
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