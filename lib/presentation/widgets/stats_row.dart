import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/service/history_service.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final hs = HistoryService();
    final total = hs.totalDetections;
    final dangerous = hs.dangerousDetections;

    return Row(
      children: [
        Expanded(child: _StatChip(
          icon: Icons.visibility_outlined,
          label: 'stats_total'.tr,
          value: '$total',
          color: const Color(0xFF8B0000),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(
          icon: Icons.warning_amber_rounded,
          label: 'stats_dangerous'.tr,
          value: '$dangerous',
          color: const Color(0xFFB45309),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(
          icon: Icons.check_circle_outline,
          label: 'stats_safe'.tr,
          value: '${total - dangerous}',
          color: const Color(0xFF166534),
        )),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}