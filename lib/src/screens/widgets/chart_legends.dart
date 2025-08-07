// lib/src/screens/widgets/chart_legend.dart
import 'package:flutter/material.dart';

class ChartLegend extends StatelessWidget {
  final Color color;
  final String text;
  final bool isLine;

  const ChartLegend(this.color, this.text, {super.key, this.isLine = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 16,
        height: isLine ? 3 : 16,
        decoration: BoxDecoration(
          color: color,
          border: isLine ? Border.all(color: color, width: 0) : null,
          borderRadius: isLine ? null : BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 8),
      Text(text),
    ]);
  }
}