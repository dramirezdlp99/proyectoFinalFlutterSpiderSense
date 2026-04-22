import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/service/history_service.dart';
import '../../widgets/lang_theme_buttons.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final auth = Get.find<AuthController>();
  final supabase = Supabase.instance.client;
  String? _avatarUrl;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final userId = auth.currentUserId;
      if (userId.isEmpty) return;
      final data = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      if (data != null && data['avatar_url'] != null) {
        setState(() => _avatarUrl = data['avatar_url'] as String);
      }
    } catch (e) {
      debugPrint('Error cargando avatar: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final userId = auth.currentUserId;
      final path = 'avatars/$userId.jpg';

      // Intentar upload — si falla por bucket inexistente, mostrar error claro
      try {
        await supabase.storage.from('avatars').uploadBinary(
          path, bytes,
          fileOptions: const FileOptions(
              contentType: 'image/jpeg', upsert: true),
        );
      } catch (uploadError) {
        final msg = uploadError.toString();
        if (msg.contains('Bucket not found') || msg.contains('bucket')) {
          Get.snackbar('Error', 
            'Ejecuta supabase_storage.sql en Supabase primero',
            backgroundColor: Colors.orange, colorText: Colors.white,
            duration: const Duration(seconds: 5));
          return;
        }
        rethrow;
      }

      final publicUrl =
          supabase.storage.from('avatars').getPublicUrl(path);

      await supabase.from('profiles').upsert({
        'id': userId,
        'avatar_url': publicUrl,
      });

      setState(() => _avatarUrl = publicUrl);
      Get.snackbar('Perfil', 'Foto actualizada',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      debugPrint('Error subiendo avatar: $e');
      Get.snackbar('Error', 'No se pudo subir la foto',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hs = HistoryService();

    // Fecha de creación de la cuenta
    final createdAt = auth.currentUser?.createdAt;
    final createdStr = createdAt != null
        ? '${_month(DateTime.parse(createdAt).month)} ${DateTime.parse(createdAt).year}'
        : 'N/A';

    // Detecciones de hoy
    final today = DateTime.now();
    final todayCount = hs.getAll().where((r) =>
      r.detectedAt.day == today.day &&
      r.detectedAt.month == today.month &&
      r.detectedAt.year == today.year
    ).length;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: EdgeInsets.all(12),
            child: Icon(Icons.radar, color: Colors.white, size: 20)),
        title: const Text('SPIDER-SENSE'),
        actions: [LangThemeButtons(routeName: '/profile')],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar con botón de edición
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _uploadingAvatar
                        ? const CircularProgressIndicator(color: Colors.white)
                        : _avatarUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.visibility,
                                      color: Colors.white, size: 48),
                                ),
                              )
                            : const Icon(Icons.visibility,
                                color: Colors.white, size: 48),
                  ),
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.black, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => Text(
              auth.currentDisplayName,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 22, fontWeight: FontWeight.w800,
              ),
            )),
            const SizedBox(height: 4),
            Text(auth.currentUserEmail,
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 13)),
            const SizedBox(height: 12),
            Obx(() => auth.visualCondition.value.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '✱ ${auth.visualCondition.value.tr.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700, letterSpacing: 1,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
            // Stats — fecha real de creación y detecciones de hoy
            Row(
              children: [
                Expanded(child: _InfoCard(
                  label: 'active_since'.tr,
                  value: createdStr,
                  accentColor: const Color(0xFFFFD700),
                  isDark: isDark,
                )),
                const SizedBox(width: 12),
                Expanded(child: _InfoCard(
                  label: "TODAY'S PINGS",
                  value: '$todayCount',
                  accentColor: const Color(0xFF7B68EE),
                  isDark: isDark,
                )),
              ],
            ),
            const SizedBox(height: 24),
            _SectionLabel('security_account'.tr),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.lock_reset,
              iconBg: const Color(0xFF1565C0),
              title: 'change_password'.tr,
              subtitle: 'Update your security credentials',
              accentColor: const Color(0xFF1565C0),
              isDark: isDark,
              onTap: () => _showChangePassword(),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.logout,
              iconBg: const Color(0xFFB8860B),
              title: 'logout'.tr,
              subtitle: 'logout'.tr,
              accentColor: const Color(0xFFFFD700),
              isDark: isDark,
              onTap: auth.logout,
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.delete_forever,
              iconBg: const Color(0xFF8B0000),
              title: 'delete_account'.tr,
              subtitle: 'delete_account_msg'.tr,
              accentColor: const Color(0xFFFF6B6B),
              isDark: isDark,
              titleColor: const Color(0xFFFF6B6B),
              onTap: () => _confirmDelete(),
            ),
            const SizedBox(height: 32),
            Text('tactile_os'.tr,
                style: TextStyle(color: Color(0xFF444444),
                    fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 4),
            const Text('V.2.0.4 — ENCRYPTED NODES ACTIVE',
                style: TextStyle(color: Color(0xFF333333),
                    fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 3),
    );
  }

  void _showChangePassword() {
    final ctrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: Text('change_password'.tr),
      content: TextField(controller: ctrl, obscureText: true,
          decoration: InputDecoration(labelText: 'new_password'.tr)),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        Obx(() => TextButton(
          onPressed: auth.isLoading.value ? null : () async {
            await auth.changePassword(ctrl.text.trim());
            Get.back();
          },
          child: Text('confirm'.tr,
              style: const TextStyle(color: Color(0xFF8B0000))),
        )),
      ],
    ));
  }

  void _confirmDelete() => Get.dialog(AlertDialog(
    title: Text('delete_account'.tr),
    content: Text('delete_account_msg'.tr),
    actions: [
      TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
      TextButton(
        onPressed: () async { Get.back(); await auth.deleteAccount(); },
        child: Text('confirm'.tr,
            style: const TextStyle(color: Color(0xFF8B0000))),
      ),
    ],
  ));

  String _month(int m) => ['','JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'][m];
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final Color accentColor;
  final bool isDark;
  const _InfoCard({required this.label, required this.value,
      required this.accentColor, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: accentColor, width: 3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF666666),
          fontSize: 10, letterSpacing: 1)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: accentColor,
          fontSize: 20, fontWeight: FontWeight.w900)),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(color: Color(0xFF8B0000),
        fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, accentColor;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final Color? titleColor;
  const _ActionTile({required this.icon, required this.iconBg,
      required this.accentColor, required this.title, required this.subtitle,
      required this.onTap, required this.isDark, this.titleColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconBg, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                  color: titleColor ?? (isDark ? Colors.white : Colors.black),
                  fontWeight: FontWeight.w700, fontSize: 14)),
              Text(subtitle, style: const TextStyle(
                  color: Color(0xFF666666), fontSize: 11)),
            ])),
        Icon(Icons.chevron_right,
            color: isDark ? const Color(0xFF444444) : Colors.grey[400]),
      ]),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: (i) {
      switch (i) {
        case 0: Get.offAllNamed('/home'); break;
        case 1: Get.offAllNamed('/ia'); break;
        case 2: Get.offAllNamed('/history'); break;
        case 3: Get.offAllNamed('/settings'); break;
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Detect'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
    ],
  );
}