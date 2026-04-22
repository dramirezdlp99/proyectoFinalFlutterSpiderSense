import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/detection_record.dart';
import '../../../data/service/history_service.dart';
import '../../widgets/lang_theme_buttons.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _hs = HistoryService();
  late TabController _tab;
  List<DetectionRecord> _all = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _load() => setState(() { _all = _hs.getAll(); });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: EdgeInsets.all(12),
            child: Icon(Icons.history, color: Colors.white, size: 20)),
        title: const Text('HISTORY'),
        actions: [
          LangThemeButtons(routeName: '/history'),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _confirmClear,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF888888),
              dividerColor: Colors.transparent,
              tabs: [Tab(text: 'history_all'.tr.toUpperCase()), Tab(text: 'history_map'.tr.toUpperCase())],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildList(isDark), _buildMap(isDark)],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 2),
    );
  }

  Widget _buildList(bool isDark) {
    if (_all.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60,
              color: isDark ? const Color(0xFF333333) : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('history_empty'.tr,
              style: const TextStyle(color: Color(0xFF555555))),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _all.length + 1,
      itemBuilder: (_, i) {
        if (i == _all.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('end_of_logs'.tr,
                style: TextStyle(color: Color(0xFF444444),
                    fontSize: 11, letterSpacing: 2))),
          );
        }
        return _HistoryCard(
          record: _all[i], isDark: isDark,
          onDelete: () async { await _hs.deleteRecord(_all[i]); _load(); },
        );
      },
    );
  }

  Widget _buildMap(bool isDark) {
    // Mapa siempre visible — todos los puntos con GPS
    final points = _all
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();

    // Centro de Colombia (Pasto) como default si no hay puntos
    final defaultCenter = LatLng(1.2136, -77.2811);
    final center = points.isEmpty
        ? defaultCenter
        : LatLng(
            points.map((p) => p.latitude!).reduce((a, b) => a + b) / points.length,
            points.map((p) => p.longitude!).reduce((a, b) => a + b) / points.length,
          );

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 15),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ramirez.spidersense',
        ),
        MarkerLayer(
          markers: points.map((r) => Marker(
            point: LatLng(r.latitude!, r.longitude!),
            width: 44, height: 44,
            child: GestureDetector(
              onTap: () => _showMarkerInfo(r),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: r.isDangerous
                      ? const Color(0xFF8B0000)
                      : const Color(0xFF1565C0),
                  boxShadow: [BoxShadow(
                    color: (r.isDangerous
                        ? const Color(0xFF8B0000)
                        : const Color(0xFF1565C0)).withValues(alpha: 0.5),
                    blurRadius: 8, spreadRadius: 2,
                  )],
                ),
                child: Icon(
                  r.isDangerous
                      ? Icons.warning_amber_rounded
                      : Icons.location_on,
                  color: Colors.white, size: 22,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  void _showMarkerInfo(DetectionRecord r) {
    final isEs = Get.locale?.languageCode == 'es';
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: r.isDangerous
                        ? const Color(0xFF8B0000).withValues(alpha: 0.2)
                        : const Color(0xFF1565C0).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    r.isDangerous
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: r.isDangerous
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF7B68EE),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (isEs ? r.labelEs : r.label).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(Get.context!).brightness == Brightness.dark
                              ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w800, fontSize: 16,
                        ),
                      ),
                      Text(
                        '${(r.confidence * 100).toStringAsFixed(0)}% confidence',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Coordenadas clickeables — abre Google Maps
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(
                    'https://maps.google.com/?q=${r.latitude},${r.longitude}');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${r.latitude!.toStringAsFixed(4)}° N, ${r.longitude!.abs().toStringAsFixed(4)}° W',
                      style: const TextStyle(
                          color: Color(0xFFFFD700), fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.open_in_new,
                        color: Color(0xFFFFD700), size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${r.detectedAt.day}/${r.detectedAt.month}/${r.detectedAt.year} ${r.detectedAt.hour.toString().padLeft(2,'0')}:${r.detectedAt.minute.toString().padLeft(2,'0')}',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear() => Get.dialog(AlertDialog(
    title: Text('history_clear_title'.tr),
    content: Text('history_clear_msg'.tr),
    actions: [
      TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
      TextButton(
        onPressed: () async { await _hs.clearAll(); Get.back(); _load(); },
        child: Text('confirm'.tr,
            style: const TextStyle(color: Color(0xFF8B0000))),
      ),
    ],
  ));
}

class _HistoryCard extends StatelessWidget {
  final DetectionRecord record;
  final bool isDark;
  final VoidCallback onDelete;
  const _HistoryCard({required this.record, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isEs = Get.locale?.languageCode == 'es';
    final label = isEs ? record.labelEs : record.label;
    final months = ['','JAN','FEB','MAR','APR','MAY','JUN',
        'JUL','AUG','SEP','OCT','NOV','DEC'];
    final date =
        '${months[record.detectedAt.month]} ${record.detectedAt.day}, ${record.detectedAt.year} · ${record.detectedAt.hour.toString().padLeft(2,'0')}:${record.detectedAt.minute.toString().padLeft(2,'0')}:${record.detectedAt.second.toString().padLeft(2,'0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16, fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.calendar_today,
                          size: 11, color: Color(0xFF666666)),
                      const SizedBox(width: 4),
                      Text(date,
                          style: const TextStyle(
                              color: Color(0xFF666666), fontSize: 11)),
                    ]),
                  ],
                )),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: record.isDangerous
                          ? const Color(0xFF8B0000).withValues(alpha: 0.2)
                          : const Color(0xFF1565C0).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      record.isDangerous
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: record.isDangerous
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF7B68EE),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (record.latitude != null) ...[
            Divider(height: 1,
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE)),
            // Coordenadas clickeables → abre Google Maps
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(
                    'https://maps.google.com/?q=${record.latitude},${record.longitude}');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF252525)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.location_on_outlined,
                          color: Color(0xFFFFD700), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('COORDINATES',
                            style: TextStyle(color: Color(0xFF666666),
                                fontSize: 10, letterSpacing: 1)),
                        Text(
                          '${record.latitude!.toStringAsFixed(4)}° N, ${record.longitude!.abs().toStringAsFixed(4)}° W',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFFFFD700), size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
        case 2: break;
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