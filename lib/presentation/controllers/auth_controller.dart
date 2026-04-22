import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var email = ''.obs;
  var password = ''.obs;
  var confirmPassword = ''.obs;
  var displayName = ''.obs;
  var visualCondition = ''.obs;
  var isLoading = false.obs;
  var isAdmin = false.obs;

  // ─── LOGIN ───────────────────────────────────────────────────────────────
  Future<void> login() async {
    if (email.value.trim().isEmpty || password.value.trim().isEmpty) {
      Get.snackbar('error_title'.tr, 'Please fill all fields');
      return;
    }
    try {
      isLoading.value = true;
      final response = await supabase.auth.signInWithPassword(
        email: email.value.trim(),
        password: password.value.trim(),
      );
      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          Get.snackbar('error_title'.tr,
              'Please confirm your email before signing in',
              duration: const Duration(seconds: 4));
          await supabase.auth.signOut();
          return;
        }
        await _loadProfile(response.user!.id);
        Get.offAllNamed('/home');
      }
    } on AuthException catch (e) {
      Get.snackbar('error_title'.tr, e.message);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── REGISTER ────────────────────────────────────────────────────────────
  Future<void> signUp() async {
    if (email.value.trim().isEmpty || password.value.trim().isEmpty) {
      Get.snackbar('error_title'.tr, 'Please fill all fields');
      return;
    }
    if (password.value.trim().length < 6) {
      Get.snackbar('error_title'.tr, 'Password must be at least 6 characters');
      return;
    }
    try {
      isLoading.value = true;
      final response = await supabase.auth.signUp(
        email: email.value.trim(),
        password: password.value.trim(),
      );
      if (response.user != null) {
        // Guarda el perfil en Supabase con los datos extra del formulario
        await supabase.from('profiles').upsert({
          'id': response.user!.id,
          'email': email.value.trim(),
          'display_name': displayName.value.trim(),
          'visual_condition': visualCondition.value,
          'role': 'user',
        });

        if (response.user!.emailConfirmedAt == null) {
          Get.snackbar('reg_success_title'.tr, 'reg_success_msg'.tr,
              duration: const Duration(seconds: 5));
          Get.offAllNamed('/login');
        } else {
          Get.offAllNamed('/home');
        }
      }
    } on AuthException catch (e) {
      Get.snackbar('error_title'.tr, e.message);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      isAdmin.value = false;
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('error_title'.tr, 'Could not sign out');
    }
  }

  // ─── CHANGE PASSWORD ─────────────────────────────────────────────────────
  Future<void> changePassword(String newPassword) async {
    if (newPassword.length < 6) {
      Get.snackbar('error_title'.tr, 'Password must be at least 6 characters');
      return;
    }
    try {
      isLoading.value = true;
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      Get.snackbar('login_success_title'.tr, 'Password updated successfully');
    } on AuthException catch (e) {
      Get.snackbar('error_title'.tr, e.message);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── DELETE ACCOUNT ──────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase.from('detection_history').delete().eq('user_id', userId);
      await supabase.from('profiles').delete().eq('id', userId);
      await supabase.auth.signOut();
      isAdmin.value = false;
      Get.offAllNamed('/login');
      Get.snackbar('login_success_title'.tr, 'Account deleted successfully');
    } catch (e) {
      Get.snackbar('error_title'.tr, 'Could not delete account');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── RESET PASSWORD ──────────────────────────────────────────────────────
  Future<void> resetPassword() async {
    if (email.value.trim().isEmpty) {
      Get.snackbar('error_title'.tr, 'Please enter your email');
      return;
    }
    try {
      isLoading.value = true;
      await supabase.auth.resetPasswordForEmail(email.value.trim());
      Get.snackbar('login_success_title'.tr,
          'Password reset email sent. Check your inbox.',
          duration: const Duration(seconds: 4));
    } on AuthException catch (e) {
      Get.snackbar('error_title'.tr, e.message);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LOAD PROFILE ────────────────────────────────────────────────────────
  Future<void> _loadProfile(String userId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select('role, display_name, visual_condition')
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        isAdmin.value = data['role'] == 'admin';
        displayName.value = data['display_name'] ?? '';
        visualCondition.value = data['visual_condition'] ?? '';
      } else {
        // Fallback: admin por correo hardcodeado solo si no hay perfil aún
        isAdmin.value =
            supabase.auth.currentUser?.email ==
            'davidramirezdelaparra99@gmail.com';
      }
    } catch (_) {
      isAdmin.value =
          supabase.auth.currentUser?.email ==
          'davidramirezdelaparra99@gmail.com';
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────
  User? get currentUser => supabase.auth.currentUser;
  String get currentUserId => supabase.auth.currentUser?.id ?? '';
  String get currentUserEmail => supabase.auth.currentUser?.email ?? '';
  String get currentDisplayName => displayName.value.isNotEmpty
      ? displayName.value
      : currentUserEmail;
}