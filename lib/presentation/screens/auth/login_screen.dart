import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.visibility, size: 100, color: Colors.red),
            const SizedBox(height: 10),
            Text(
              'Spider-Sense',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              // Conectamos directamente al observable del controlador
              onChanged: (value) => authController.email.value = value,
              decoration: InputDecoration(
                labelText: 'email_label'.tr,
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              // Conectamos directamente al observable del controlador
              onChanged: (value) => authController.password.value = value,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'password_label'.tr,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            Obx(() => authController.isLoading.value
                ? const CircularProgressIndicator(color: Colors.red)
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => authController.login(), // Sin argumentos
                          child: Text('login_button'.tr),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () => Get.toNamed('/register'),
                        child: Text(
                          'go_to_register'.tr,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )),
          ],
        ),
      ),
    );
  }
}