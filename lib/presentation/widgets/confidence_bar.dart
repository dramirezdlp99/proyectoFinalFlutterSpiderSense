import 'package:flutter/material.dart';

class ConfidenceBar extends StatelessWidget {
  final double confidence;

  const ConfidenceBar({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = confidence > 0.7 ? Colors.greenAccent : Colors.orangeAccent;
    return Column(
      children: [
        LinearProgressIndicator(
          value: confidence,
          backgroundColor: Colors.white10,
          color: color,
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          '${(confidence * 100).toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}