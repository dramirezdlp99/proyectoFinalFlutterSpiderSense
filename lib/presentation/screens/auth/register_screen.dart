import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('register_title'.tr),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.person_add_outlined, size: 80, color: theme.primaryColor),
            const SizedBox(height: 20),
            Text(
              'create_account_subtitle'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 40),
            TextField(
              onChanged: (value) => authController.email.value = value,
              decoration: InputDecoration(
                labelText: 'email_label'.tr,
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => authController.password.value = value,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'password_label'.tr,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            Obx(() => authController.isLoading.value
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => authController.signUp(), // Sin argumentos
                      child: Text('register_button'.tr),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}