import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

/// [routeName] — la ruta de la pantalla actual, ej: '/home', '/settings'
/// Necesario para que al cambiar idioma, la pantalla se recargue correctamente
class LangThemeButtons extends StatelessWidget {
  final String routeName;
  const LangThemeButtons({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ThemeController>();
    return Obx(() {
      final lang = ctrl.langCode.value;
      final dark = ctrl.isDark.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => ctrl.setLanguage(
              lang == 'es' ? 'en' : 'es',
              currentRoute: routeName,
            ),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              lang.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: ctrl.toggleTheme,
            icon: Icon(
              dark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: Colors.white,
              size: 20,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),
        ],
      );
    });
  }
}