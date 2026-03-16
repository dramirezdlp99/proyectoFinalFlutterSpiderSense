import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var email = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;
  // Variable para manejar el rol de administrador
  var isAdmin = false.obs;

  // Método para Iniciar Sesión
  Future<void> login() async {
    try {
      isLoading.value = true;
      final response = await supabase.auth.signInWithPassword(
        email: email.value.trim(),
        password: password.value.trim(),
      );
      
      if (response.user != null) {
        // Verificamos si es administrador (puedes cambiar este correo por el tuyo)
        isAdmin.value = response.user!.email == 'davidramirezdelaparra99@gmail.com';
        Get.offAllNamed('/home');
      }
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  // Método para Registrarse
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

  // NUEVO: Método para Cerrar Sesión (Seguridad de Tokens)
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      isAdmin.value = false; // Reset de rol
      Get.offAllNamed('/login'); // Regresa al login y limpia navegación
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cerrar sesión');
    }
  }
}