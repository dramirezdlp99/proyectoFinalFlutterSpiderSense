import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../../presentation/controllers/theme_controller.dart';
import '../../../../main.dart' show SpiderSenseLogo;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthController _auth;
  late ThemeController _theme;

  @override
  void initState() {
    super.initState();
    _auth  = Get.find<AuthController>();
    _theme = Get.find<ThemeController>();
    _auth.isLoading.listen((_) { if (mounted) setState(() {}); });
    _theme.isDark.listen((_)   { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = _theme.isDark.value;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bg        = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: bg,
      // AppBar transparente con los botones visibles
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Botón idioma
          Obx(() => TextButton(
            onPressed: () => _theme.setLanguage(
                _theme.langCode.value == 'es' ? 'en' : 'es'),
            child: Text(
              _theme.langCode.value.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          )),
          // Botón tema
          Obx(() => IconButton(
            onPressed: _theme.toggleTheme,
            icon: Icon(
              _theme.isDark.value
                  ? Icons.wb_sunny_outlined
                  : Icons.nightlight_round,
              color: isDark ? Colors.white : Colors.black87,
            ),
          )),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Glow de fondo
          if (isDark) Positioned.fill(
            child: Container(decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5), radius: 0.7,
                colors: [
                  const Color(0xFF8B0000).withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            )),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo centrado
                  const SizedBox(height: 20),
                  const Center(child: SpiderSenseLogo(size: 80)),
                  const SizedBox(height: 24),
                  // Título
                  Text('SPIDER-SENSE', style: TextStyle(
                    color: textColor, fontSize: 30,
                    fontWeight: FontWeight.w900, letterSpacing: 1.5,
                  )),
                  const SizedBox(height: 4),
                  Text('login_subtitle'.tr,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 14)),
                  const SizedBox(height: 28),
                  // Card del formulario
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('email_label'.tr,
                            style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          onChanged: (v) => _auth.email.value = v,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'user@example.com',
                            hintStyle: const TextStyle(
                                color: Color(0xFF555555)),
                            prefixIcon: const Icon(
                                Icons.email_outlined, size: 18),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('password_label'.tr,
                            style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          onChanged: (v) => _auth.password.value = v,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          decoration: const InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                                color: Color(0xFF555555)),
                            prefixIcon: Icon(
                                Icons.lock_outline, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botón login
                  _auth.isLoading.value
                      ? const Center(child: CircularProgressIndicator(
                          color: Color(0xFF8B0000)))
                      : ElevatedButton(
                          onPressed: _auth.login,
                          child: Text('login_button'.tr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: _auth.resetPassword,
                      child: Text('forgot_password'.tr,
                          style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 13)),
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.toNamed('/register'),
                      child: RichText(
                        text: TextSpan(
                          text: '${'go_to_register_prefix'.tr} ',
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 13),
                          children: [TextSpan(
                            text: 'go_to_register_action'.tr,
                            style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w700),
                          )],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}