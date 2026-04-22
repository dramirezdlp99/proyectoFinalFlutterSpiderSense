import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/service/history_service.dart';
import '../../../presentation/controllers/theme_controller.dart';
import '../../widgets/lang_theme_buttons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.radar, color: Colors.white, size: 20),
        ),
        title: const Text('SPIDER-SENSE'),
        actions: [LangThemeButtons(routeName: '/settings')],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('settings_title'.tr.toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 4),
            Text('configure_sensory'.tr,
                style: TextStyle(
                    color: Color(0xFF666666), fontSize: 13)),
            const SizedBox(height: 28),

            // LANGUAGE
            _SectionLabel('settings_language'.tr),
            const SizedBox(height: 10),
            Obx(() => _OptionCard(
              isDark: isDark,
              children: [
                _OptionTile(
                  icon: Icons.language,
                  iconColor: const Color(0xFFFFD700),
                  label: 'English',
                  selected: ctrl.langCode.value == 'en',
                  isDark: isDark,
                  onTap: () => ctrl.setLanguage('en'),
                ),
                Divider(height: 1,
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE)),
                _OptionTile(
                  icon: Icons.translate,
                  iconColor: const Color(0xFFFFD700),
                  label: 'Español',
                  selected: ctrl.langCode.value == 'es',
                  isDark: isDark,
                  onTap: () => ctrl.setLanguage('es'),
                ),
              ],
            )),
            const SizedBox(height: 24),

            // APPEARANCE
            _SectionLabel('settings_appearance'.tr),
            const SizedBox(height: 10),
            Obx(() => Row(
              children: [
                Expanded(child: _ThemeCard(
                  name: 'settings_dark'.tr,
                  description: 'settings_dark'.tr == 'The Void' ? 'High-contrast mode' : 'Dark mode',
                  icon: Icons.nightlight_round,
                  isActive: ctrl.isDark.value,
                  isDark: isDark,
                  onTap: () => ctrl.setDark(true),
                )),
                const SizedBox(width: 12),
                Expanded(child: _ThemeCard(
                  name: 'settings_light'.tr,
                  description: 'settings_light'.tr == 'Pulse Edge' ? 'High luminosity mode' : 'Light mode',
                  icon: Icons.remove_red_eye_outlined,
                  isActive: !ctrl.isDark.value,
                  isDark: isDark,
                  onTap: () => ctrl.setDark(false),
                )),
              ],
            )),
            const SizedBox(height: 24),

            // DATA MANAGEMENT
            _SectionLabel('settings_data'.tr),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Visual Logs Persistence',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                )),
                            const SizedBox(height: 2),
                            const Text(
                                'Store sensory history for 30 days locally.',
                                style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: true,
                        onChanged: (_) {},
                        activeColor: const Color(0xFF8B0000),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Clearing your history will permanently delete all recorded sensory pings and navigation logs. This action cannot be reversed.',
                    style: TextStyle(
                        color: Color(0xFF555555), fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _confirmClear(),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: Text('history_clear_title'.tr.toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text('secure_link'.tr,
                  style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 10,
                      letterSpacing: 2)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 3),
    );
  }

  void _confirmClear() => Get.dialog(AlertDialog(
    title: Text('history_clear_title'.tr),
    content: Text('history_clear_msg'.tr),
    actions: [
      TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
      TextButton(
        onPressed: () async {
          await HistoryService().clearAll();
          Get.back();
          Get.snackbar('settings_title'.tr, 'history_empty'.tr,
              backgroundColor: Colors.green, colorText: Colors.white);
        },
        child: Text('confirm'.tr,
            style: const TextStyle(color: Color(0xFF8B0000))),
      ),
    ],
  ));
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Color(0xFF8B0000),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2));
}

class _OptionCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _OptionCard({required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: children),
  );
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon, required this.iconColor, required this.label,
    required this.selected, required this.isDark, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: iconColor, size: 20),
    title: Text(label,
        style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600)),
    trailing: selected
        ? const Icon(Icons.check_circle,
            color: Color(0xFF8B0000), size: 20)
        : Icon(Icons.circle_outlined,
            color: isDark ? const Color(0xFF444444) : Colors.grey[300],
            size: 20),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _ThemeCard extends StatelessWidget {
  final String name, description;
  final IconData icon;
  final bool isActive, isDark;
  final VoidCallback onTap;
  const _ThemeCard({
    required this.name, required this.description, required this.icon,
    required this.isActive, required this.isDark, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: const Color(0xFF8B0000), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 20),
              const Spacer(),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('ACTIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(name,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 4),
          Text(description,
              style: const TextStyle(
                  color: Color(0xFF666666), fontSize: 11, height: 1.4)),
        ],
      ),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: (i) {
      switch (i) {
        case 0: Get.offAllNamed('/home'); break;
        case 1: Get.offAllNamed('/ia'); break;
        case 2: Get.offAllNamed('/history'); break;
        case 3: Get.offAllNamed('/settings'); break;
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Detect'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
    ],
  );
}