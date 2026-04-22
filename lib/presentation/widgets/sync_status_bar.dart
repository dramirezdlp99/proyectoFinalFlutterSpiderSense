import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/service/sync_service.dart';

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = SyncService();
    return Obx(() {
      if (sync.isSyncing.value) return _bar(
        icon: const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
        ),
        text: 'sync_syncing'.tr,
        color: Colors.blue,
      );

      if (sync.pendingCount.value == 0) return _bar(
        icon: const Icon(Icons.cloud_done, color: Colors.green, size: 16),
        text: 'sync_done'.tr,
        color: Colors.green,
      );

      return _bar(
        icon: const Icon(Icons.cloud_upload_outlined,
            color: Colors.orange, size: 16),
        text: '${sync.pendingCount.value} ${'sync_pending'.tr}',
        color: Colors.orange,
        action: TextButton(
          onPressed: sync.syncAll,
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: Text('sync_now'.tr,
              style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      );
    });
  }

  Widget _bar({
    required Widget icon,
    required String text,
    required Color color,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
          if (action != null) ...[const Spacer(), action],
        ],
      ),
    );
  }
}