// lib/src/screens/widgets/calorie_chart_section.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'chart_legends.dart';

class CalorieChartSection extends StatelessWidget {
  final Map<String, dynamic> chartData;
  final ScrollController scrollController;

  const CalorieChartSection({
    super.key,
    required this.chartData,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final barGroups = chartData['barGroups'] as List<BarChartGroupData>;
    // Account for Card padding (16 + 16) and frozen Y-axis width (48)
    final innerViewportMinWidth =
        MediaQuery.of(context).size.width - 64 - 48; // <- important
    final chartWidth = max(innerViewportMinWidth, barGroups.length * 50.0);

    // Determine max Y from both bars (consumed & burned), add headroom, round to nice step.
    double maxY = 0;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxY) maxY = rod.toY;
      }
    }
    maxY *= 1.2;
    // Round to a nice step (nearest 500 or 1000 depending on scale)
    final step = maxY >= 4000 ? 1000 : 500;
    maxY = ((maxY / step).ceil() * step).toDouble();

    const divisions = 4;
    final interval = maxY / divisions;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Consumed vs. Burned",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            barGroups.isEmpty
                ? const Center(
                heightFactor: 5, child: Text("No data for the last 7 days."))
                : Row(
              children: [
                // --- FROZEN Y-AXIS LABELS (do not scroll) ---
                SizedBox(
                  width: 48,
                  height: 240,
                  child: _YAxis(
                    maxY: maxY,
                    divisions: divisions,
                  ),
                ),

                // --- SCROLLABLE CHART AREA ---
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      height: 240,
                      width: chartWidth,
                      child: BarChart(
                        BarChartData(
                          maxY: maxY,
                          barGroups: barGroups,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final date =
                                  chartData['dates'][value.toInt()];
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(DateFormat('MMM\ndd')
                                        .format(date)),
                                  );
                                },
                                reservedSize: 36,
                              ),
                            ),
                            // Hide chart's own left titles so only frozen labels show
                            leftTitles: AxisTitles(
                              sideTitles:
                              SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                                sideTitles:
                                SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles:
                                SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: interval,
                          ),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(enabled: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChartLegend(Colors.orange, "Consumed"),
                SizedBox(width: 20),
                ChartLegend(Colors.lightGreen, "Burned"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _YAxis extends StatelessWidget {
  final double maxY;
  final int divisions;
  const _YAxis({required this.maxY, this.divisions = 4});

  @override
  Widget build(BuildContext context) {
    // Generate tick labels from max down to 0
    final ticks = List<double>.generate(
      divisions + 1,
          (i) => maxY - (maxY / divisions) * i,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ticks
          .map(
            (t) => Align(
          alignment: Alignment.centerRight,
          child: Text(
            _formatNumber(t),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      )
          .toList(),
    );
  }

  String _formatNumber(double v) {
    // 1000 -> 1,000
    return NumberFormat.compact().format(v.round());
  }
}
