import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final _client = Supabase.instance.client;
  var isLoading = false.obs;

  // Login Logic
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _client.auth.signInWithPassword(email: email, password: password);
      Get.snackbar('login_success_title'.tr, 'login_success_msg'.tr,
          snackPosition: SnackPosition.BOTTOM);
      // Get.offAllNamed('/home'); // Redirección a Home cuando esté lista
    } catch (e) {
      Get.snackbar('error_title'.tr, 'login_error_msg'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Register Logic
  Future<void> signUp(String email, String password) async {
    try {
      isLoading.value = true;
      await _client.auth.signUp(email: email, password: password);
      Get.snackbar('reg_success_title'.tr, 'reg_success_msg'.tr,
          snackPosition: SnackPosition.BOTTOM);
      Get.toNamed('/login');
    } catch (e) {
      Get.snackbar('error_title'.tr, 'reg_error_msg'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}