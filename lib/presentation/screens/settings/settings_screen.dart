import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/service/history_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: 'settings_language'.tr),
            const SizedBox(height: 8),
            _LanguageSelector(),
            const SizedBox(height: 24),
            _SectionTitle(title: 'settings_appearance'.tr),
            const SizedBox(height: 8),
            _ThemeSelector(),
            const SizedBox(height: 24),
            _SectionTitle(title: 'settings_data'.tr),
            const SizedBox(height: 8),
            _DataOptions(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
            letterSpacing: 1.1));
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.language,
            title: 'Español',
            trailing: Obx(() => Get.locale?.languageCode == 'es'
                ? const Icon(Icons.check_circle, color: Colors.red)
                : const SizedBox.shrink()),
            onTap: () => Get.updateLocale(const Locale('es', 'ES')),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.language,
            title: 'English',
            trailing: Obx(() => Get.locale?.languageCode == 'en'
                ? const Icon(Icons.check_circle, color: Colors.red)
                : const SizedBox.shrink()),
            onTap: () => Get.updateLocale(const Locale('en', 'US')),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.wb_sunny,
            title: 'settings_light'.tr,
            trailing: const SizedBox.shrink(),
            onTap: () => Get.changeTheme(ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: Colors.red,
            )),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.nightlight_round,
            title: 'settings_dark'.tr,
            trailing: const SizedBox.shrink(),
            onTap: () => Get.changeTheme(ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.red,
            )),
          ),
        ],
      ),
    );
  }
}

class _DataOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _SettingsTile(
        icon: Icons.delete_sweep,
        title: 'history_clear_title'.tr,
        color: Colors.red,
        trailing: const SizedBox.shrink(),
        onTap: () => Get.dialog(
          AlertDialog(
            title: Text('history_clear_title'.tr),
            content: Text('history_clear_msg'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () async {
                  await HistoryService().clearAll();
                  Get.back();
                  Get.snackbar(
                    'settings_title'.tr,
                    'history_empty'.tr,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                child: Text('confirm'.tr,
                    style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.red.shade700),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color)),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}