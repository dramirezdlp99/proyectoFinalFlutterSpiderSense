import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../../presentation/widgets/lang_theme_buttons.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth   = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAllNamed('/login'),
        ),
        title: Text('register_title'.tr),
        actions: [LangThemeButtons(routeName: '/register')],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header radar glow
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0E0E0E)
                    : const Color(0xFFF0F0F0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(3, (i) => Container(
                    width: 60.0 + i * 40,
                    height: 60.0 + i * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B0000)
                            .withValues(alpha: 0.3 - i * 0.08),
                        width: 1,
                      ),
                    ),
                  )),
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF8B0000).withValues(alpha: 0.6),
                        blurRadius: 20, spreadRadius: 5,
                      )],
                    ),
                    child: const Icon(Icons.radar, color: Colors.white, size: 28),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Text('SCANNING IDENTITY',
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormLabel('register_name'.tr),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => auth.displayName.value = v,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'register_name'.tr,
                      hintStyle: const TextStyle(color: Color(0xFF555555)),
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FormLabel('register_visual_condition'.tr),
                  const SizedBox(height: 6),
                  Obx(() => DropdownButtonFormField<String>(
                    value: auth.visualCondition.value.isEmpty
                        ? null
                        : auth.visualCondition.value,
                    decoration: InputDecoration(
                      hintText: 'register_visual_condition'.tr,
                      prefixIcon: const Icon(Icons.visibility_outlined, size: 18),
                    ),
                    items: [
                      'register_cond_total',
                      'register_cond_partial',
                      'register_cond_caregiver',
                    ].map((k) => DropdownMenuItem(
                          value: k, child: Text(k.tr))).toList(),
                    onChanged: (v) => auth.visualCondition.value = v ?? '',
                  )),
                  const SizedBox(height: 16),
                  _FormLabel('email_label'.tr),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => auth.email.value = v,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'email@example.com',
                      hintStyle: TextStyle(color: Color(0xFF555555)),
                      prefixIcon: Icon(Icons.alternate_email, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FormLabel('password_label'.tr),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => auth.password.value = v,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: Color(0xFF555555)),
                      prefixIcon: Icon(Icons.lock_outline, size: 18),
                      suffixIcon: Icon(Icons.visibility_off_outlined,
                          size: 18, color: Color(0xFF666666)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Obx(() => auth.isLoading.value
                      ? const Center(child: CircularProgressIndicator(
                          color: Color(0xFF8B0000)))
                      : ElevatedButton.icon(
                          onPressed: auth.signUp,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text('register_button'.tr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2)),
                        )),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.offAllNamed('/login'),
                      child: RichText(
                        text: TextSpan(
                          text: '${'go_to_register_prefix'.tr.replaceAll('?', '')} ',
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 13),
                          children: [TextSpan(
                            text: 'login_button'.tr,
                            style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w700),
                          )],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: Text('sensory_grid'.tr,
                      style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 10, letterSpacing: 2))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 13,
          fontWeight: FontWeight.w700));
}