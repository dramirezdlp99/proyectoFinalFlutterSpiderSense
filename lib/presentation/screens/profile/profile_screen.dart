import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('profile_title'.tr),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.red,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              auth.currentUserEmail,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _ProfileOption(
              icon: Icons.lock_outline,
              title: 'change_password'.tr,
              color: Colors.blue,
              onTap: () => _showChangePassword(auth),
            ),
            const SizedBox(height: 12),
            _ProfileOption(
              icon: Icons.logout,
              title: 'logout'.tr,
              color: Colors.orange,
              onTap: () => auth.logout(),
            ),
            const SizedBox(height: 12),
            _ProfileOption(
              icon: Icons.delete_forever,
              title: 'delete_account'.tr,
              color: Colors.red,
              onTap: () => _confirmDelete(auth),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(AuthController auth) {
    final controller = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('change_password'.tr),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'new_password'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          Obx(() => TextButton(
            onPressed: auth.isLoading.value
                ? null
                : () async {
                    await auth.changePassword(controller.text.trim());
                    Get.back();
                  },
            child: auth.isLoading.value
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('confirm'.tr,
                    style: const TextStyle(color: Colors.blue)),
          )),
        ],
      ),
    );
  }

  void _confirmDelete(AuthController auth) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_account'.tr),
        content: Text('delete_account_msg'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await auth.deleteAccount();
            },
            child: Text('confirm'.tr,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}