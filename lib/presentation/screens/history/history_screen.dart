import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/detection_record.dart';
import '../../../data/service/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _historyService = HistoryService();
  late TabController _tabController;
  List<DetectionRecord> _all = [];
  List<DetectionRecord> _dangerous = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _all = _historyService.getAll();
      _dangerous = _historyService.getDangerousOnly();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('history_title'.tr),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'history_all'.tr),
            Tab(text: 'history_map'.tr),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(),
          _buildMap(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_all.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text('history_empty'.tr,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _all.length,
      itemBuilder: (context, index) {
        final record = _all[index];
        return _DetectionCard(record: record, onDelete: () async {
          await _historyService.deleteRecord(record);
          _loadData();
        });
      },
    );
  }

  Widget _buildMap() {
    final points = _dangerous
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();

    if (points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text('history_no_location'.tr,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final center = LatLng(
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
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showMarkerInfo(r),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 36,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  void _showMarkerInfo(DetectionRecord r) {
    final isEs = Get.locale?.languageCode == 'es';
    Get.snackbar(
      isEs ? r.labelEs : r.label,
      '${(r.confidence * 100).toStringAsFixed(0)}% — ${r.detectedAt.day}/${r.detectedAt.month}/${r.detectedAt.year}',
      backgroundColor: Colors.red.shade900,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _confirmClear() {
    Get.dialog(
      AlertDialog(
        title: Text('history_clear_title'.tr),
        content: Text('history_clear_msg'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              await _historyService.clearAll();
              Get.back();
              _loadData();
            },
            child: Text('confirm'.tr,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final DetectionRecord record;
  final VoidCallback onDelete;

  const _DetectionCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isEs = Get.locale?.languageCode == 'es';
    final label = isEs ? record.labelEs : record.label;
    final date =
        '${record.detectedAt.day}/${record.detectedAt.month}/${record.detectedAt.year} ${record.detectedAt.hour}:${record.detectedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              record.isDangerous ? Colors.red : Colors.green,
          child: Icon(
            record.isDangerous ? Icons.warning : Icons.check,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontSize: 12)),
            if (record.latitude != null)
              Text(
                '${record.latitude!.toStringAsFixed(4)}, ${record.longitude!.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}