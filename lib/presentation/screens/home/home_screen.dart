import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        actions: [
          _LangButton(),
          _ThemeButton(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => auth.isAdmin.value ? _AdminBanner() : const SizedBox.shrink()),
            _WelcomeCard(email: auth.currentUserEmail),
            const SizedBox(height: 24),
            Text('menu_features'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _FeatureCard(
                  title: 'ai_object_detection'.tr,
                  icon: Icons.camera_alt,
                  color: Colors.red,
                  onTap: () => Get.toNamed('/ia'),
                ),
                _FeatureCard(
                  title: 'history_title'.tr,
                  icon: Icons.history,
                  color: Colors.orange,
                  onTap: () => Get.toNamed('/history'),
                ),
                _FeatureCard(
                  title: 'profile_title'.tr,
                  icon: Icons.person,
                  color: Colors.blue,
                  onTap: () => Get.toNamed('/profile'),
                ),
                _FeatureCard(
                  title: 'settings_title'.tr,
                  icon: Icons.settings,
                  color: Colors.green,
                  onTap: () => Get.toNamed('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String email;
  const _WelcomeCard({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade900, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text('welcome_user'.tr,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(email,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AdminBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red),
      ),
      child: const Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.red),
          SizedBox(width: 10),
          Text('Modo Administrador',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEs = Get.locale?.languageCode == 'es';
      return TextButton(
        onPressed: () => Get.updateLocale(
          isEs ? const Locale('en', 'US') : const Locale('es', 'ES'),
        ),
        child: Text(isEs ? 'EN' : 'ES',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      );
    });
  }
}

class _ThemeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Get.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
        color: Colors.white,
      ),
      onPressed: () => Get.changeTheme(
        Get.isDarkMode ? ThemeData.light() : ThemeData.dark(),
      ),
    );
  }
}