import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/service/history_service.dart';
import '../../../data/service/sync_service.dart';
import '../../../presentation/widgets/lang_theme_buttons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF0F0F0),
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.radar, color: Colors.white, size: 20),
        ),
        title: const Text('SPIDER-SENSE'),
        actions: [
          LangThemeButtons(routeName: '/home'),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner admin
          Obx(() => auth.isAdmin.value
              ? Container(
                  width: double.infinity,
                  color: const Color(0xFF1A0000),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'SYSTEM ADMINISTRATOR MODE ACTIVE • RESTRICTED ACCESS',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeCard(auth: auth, isDark: isDark),
                  const SizedBox(height: 16),
                  _StatsRow(isDark: isDark),
                  const SizedBox(height: 12),
                  _SyncBar(isDark: isDark),
                  const SizedBox(height: 24),
                  Text('menu_features'.tr,
                      style: const TextStyle(
                        color: Color(0xFF8B0000),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      )),
                  const SizedBox(height: 12),
                  _FeaturesGrid(isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 0),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final AuthController auth;
  final bool isDark;
  const _WelcomeCard({required this.auth, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A0000), const Color(0xFF1A1A1A)]
              : [const Color(0xFF8B0000), const Color(0xFFB71C1C)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, bottom: -20,
            child: Icon(Icons.radar, size: 120,
                color: Colors.white.withValues(alpha: 0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text('welcome_user'.tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 2),
              Text(auth.currentUserEmail,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8B0000) : Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final bool isDark;
  const _StatsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hs = HistoryService();
    final total = hs.totalDetections;
    final dangerous = hs.dangerousDetections;
    final safe = total - dangerous;

    return Row(
      children: [
        Expanded(child: _StatCard(
          value: '$total', label: 'stats_total'.tr,
          valueColor: const Color(0xFF8B0000),
          accentColor: const Color(0xFF8B0000), isDark: isDark,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          value: '$dangerous', label: 'stats_dangerous'.tr,
          valueColor: const Color(0xFFFFD700),
          accentColor: const Color(0xFFFFD700), isDark: isDark,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          value: '$safe', label: 'stats_safe'.tr,
          valueColor: const Color(0xFF7B68EE),
          accentColor: const Color(0xFF7B68EE), isDark: isDark,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color valueColor, accentColor;
  final bool isDark;
  const _StatCard({required this.value, required this.label,
      required this.valueColor, required this.accentColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(bottom: BorderSide(color: accentColor, width: 2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(
              color: valueColor, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
              color: Color(0xFF666666), fontSize: 10,
              fontWeight: FontWeight.w600, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _SyncBar extends StatelessWidget {
  final bool isDark;
  const _SyncBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sync = SyncService();
    return Obx(() {
      final pending = sync.pendingCount.value;
      final syncing = sync.isSyncing.value;
      final text = syncing
          ? 'sync_syncing'.tr
          : pending > 0
              ? '$pending ${'sync_pending'.tr}'
              : 'sync_done'.tr;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (syncing || pending > 0)
                    ? Colors.orange
                    : const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 10),
            Text(text, style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
            const Spacer(),
            if (!syncing)
              Text('JUST NOW', style: const TextStyle(
                  color: Color(0xFF555555), fontSize: 11, letterSpacing: 1)),
          ],
        ),
      );
    });
  }
}

class _FeaturesGrid extends StatelessWidget {
  final bool isDark;
  const _FeaturesGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      _FeatureData('ai_object_detection'.tr, Icons.camera_alt,
          const Color(0xFF8B0000), '/ia'),
      _FeatureData('history_title'.tr, Icons.history,
          const Color(0xFFB8860B), '/history'),
      _FeatureData('profile_title'.tr, Icons.person,
          const Color(0xFF1565C0), '/profile'),
      _FeatureData('settings_title'.tr, Icons.settings,
          const Color(0xFF424242), '/settings'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: items.map((e) => _FeatureCard(data: e, isDark: isDark)).toList(),
    );
  }
}

class _FeatureData {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _FeatureData(this.label, this.icon, this.color, this.route);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  final bool isDark;
  const _FeatureCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(data.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const Spacer(),
            Text(data.label, style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14, fontWeight: FontWeight.w700, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 0: Get.offAllNamed('/home'); break;
          case 1: Get.offAllNamed('/ia'); break;
          case 2: Get.offAllNamed('/history'); break;
          case 3: Get.offAllNamed('/settings'); break;
        }
      },
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: 'home_title_short'.tr),
        BottomNavigationBarItem(
            icon: const Icon(Icons.radar),
            label: 'detect'.tr),
        BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: 'history_title'.tr),
        BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: 'settings_title'.tr),
      ],
    );
  }
}