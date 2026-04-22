import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const _keyDark = 'dark_mode';
  static const _keyLang = 'lang_code';

  final RxBool   isDark   = true.obs;
  final RxString langCode = 'es'.obs;
  bool _changingLang = false;

  Future<void> loadPrefsSync() async {
    final prefs = await SharedPreferences.getInstance();
    isDark.value   = prefs.getBool(_keyDark)   ?? true;
    langCode.value = prefs.getString(_keyLang) ?? 'es';
  }

  Future<void> toggleTheme() => setDark(!isDark.value);

  Future<void> setDark(bool dark) async {
    isDark.value = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDark, dark);
  }

  Future<void> setLanguage(String code, {String? currentRoute}) async {
    if (_changingLang) return;
    if (langCode.value == code) return;
    _changingLang = true;

    langCode.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, code);

    Get.updateLocale(
      code == 'es' ? const Locale('es', 'ES') : const Locale('en', 'US'),
    );

    final route = currentRoute ?? Get.currentRoute;

    // Rutas excluidas de navegación (cámara, login, vacía)
    final noNavRoutes = ['/', '/login', '/ia', ''];
    if (route.isNotEmpty && !noNavRoutes.contains(route)) {
      await Future.delayed(const Duration(milliseconds: 50));
      // /register usa toNamed (stack), las demás usan offAllNamed
      if (route == '/register') {
        Get.until((r) => r.settings.name == '/login');
        Get.toNamed('/register');
      } else {
        Get.offAllNamed(route);
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _changingLang = false;
  }
}