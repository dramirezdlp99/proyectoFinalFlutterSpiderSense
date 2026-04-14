import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/detection_record.dart';

class DetectionCard extends StatelessWidget {
  final DetectionRecord record;
  final VoidCallback? onDelete;

  const DetectionCard({super.key, required this.record, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isEs = Get.locale?.languageCode == 'es';
    final label = isEs ? record.labelEs : record.label;
    final date =
        '${record.detectedAt.day}/${record.detectedAt.month}/${record.detectedAt.year} '
        '${record.detectedAt.hour}:${record.detectedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: record.isDangerous ? Colors.red : Colors.green,
          child: Icon(
            record.isDangerous ? Icons.warning : Icons.check,
            color: Colors.white, size: 20,
          ),
        ),
        title: Text(label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontSize: 11)),
            if (record.latitude != null)
              Text(
                '${record.latitude!.toStringAsFixed(4)}, '
                '${record.longitude!.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}