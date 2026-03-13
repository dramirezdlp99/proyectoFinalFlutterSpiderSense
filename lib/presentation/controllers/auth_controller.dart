import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var email = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;

  // Método para Iniciar Sesión
  Future<void> login() async {
    try {
      isLoading.value = true;
      final response = await supabase.auth.signInWithPassword(
        email: email.value.trim(),
        password: password.value.trim(),
      );
      if (response.user != null) {
        Get.offAllNamed('/home');
      }
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  // Método para Registrarse (signUp)
  Future<void> signUp() async {
    try {
      isLoading.value = true;
      final response = await supabase.auth.signUp(
        email: email.value.trim(),
        password: password.value.trim(),
      );
      if (response.user != null) {
        Get.snackbar('Éxito', 'Usuario creado correctamente');
        Get.offAllNamed('/home');
      }
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }
}