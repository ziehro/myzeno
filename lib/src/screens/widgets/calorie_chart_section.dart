// lib/src/screens/widgets/calorie_chart_section.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'chart_legends.dart';
import 'dart:math';

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
    final chartWidth = max(MediaQuery.of(context).size.width - 64, barGroups.length * 50.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Consumed vs. Burned", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            barGroups.isEmpty
                ? const Center(heightFactor: 5, child: Text("No data for the last 7 days."))
                : SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 240,
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date = chartData['dates'][value.toInt()];
                            return SideTitleWidget(axisSide: meta.axisSide, child: Text(DateFormat('MMM\ndd').format(date)));
                          },
                          reservedSize: 36,
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(enabled: true),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ChartLegend(Colors.orange, "Consumed"),
              SizedBox(width: 20),
              ChartLegend(Colors.lightGreen, "Burned"),
            ]),
          ],
        ),
      ),
    );
  }
}