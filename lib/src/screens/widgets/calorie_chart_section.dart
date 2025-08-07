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
    final dates = chartData['dates'] as List<DateTime>? ?? const <DateTime>[];

    if (barGroups.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Center(
            heightFactor: 5,
            child: Text("No data for the last 7 days."),
          ),
        ),
      );
    }

    // ---- Y-range: start at zero; find max across both series and add headroom ----
    double maxYData = 0;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxYData) maxYData = rod.toY;
      }
    }
    final maxYPadded = maxYData * 1.2;
    final step = _niceStep(maxYPadded);
    final maxY = (max(maxYPadded, step) / step).ceil() * step;
    const minY = 0.0;

    // ---- Layout sizing (keep bottom labels clear of legend) ----
    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.textScaleFactorOf(context);
    final bottomReserved = (52.0 * textScale).clamp(52.0, 80.0);
    final chartHeight = 200.0 + bottomReserved;

    // A touch of right padding so the last date label isn't flush with edge
    const extraRightPadding = 12.0;
    final innerViewportMinWidth = size.width - 64; // card padding L+R
    final chartWidth = max(
      innerViewportMinWidth,
      barGroups.length * 50.0 + extraRightPadding,
    );

    // --- Start scrolled to the right after first frame ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

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
            SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: chartHeight,
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    minY: minY,
                    maxY: maxY,
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: step,
                          getTitlesWidget: (value, meta) => SizedBox(
                            width: 48,
                            child: Text(
                              NumberFormat.decimalPattern().format(value.toInt()),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: bottomReserved,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= dates.length) {
                              return const SizedBox.shrink();
                            }
                            final date = dates[idx];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                DateFormat('MMM\ndd').format(date),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: step,
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(enabled: true),
                  ),
                ),
              ),
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

  double _niceStep(double maxY) {
    if (maxY <= 1500) return 250;
    if (maxY <= 4000) return 500;
    if (maxY <= 8000) return 1000;
    return 2000;
  }
}
