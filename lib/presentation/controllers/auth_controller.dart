import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final _client = Supabase.instance.client;
  var isLoading = false.obs;

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _client.auth.signInWithPassword(email: email, password: password);
      Get.snackbar('Éxito', 'Bienvenido a Spider-Sense');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo iniciar sesión');
    } finally {
      isLoading.value = false;
    }
  }
}