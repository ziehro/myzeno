// lib/src/screens/widgets/net_calorie_chart_section.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'chart_legends.dart';
import 'dart:math';

class NetCalorieChartSection extends StatelessWidget {
  final UserProfile profile;
  final UserGoal goal;
  final Map<String, dynamic> chartData;
  final ScrollController scrollController;

  const NetCalorieChartSection({
    super.key,
    required this.profile,
    required this.goal,
    required this.chartData,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final calorieTarget = profile.recommendedDailyIntake - goal.dailyCalorieDeficitTarget;
    final barGroups = chartData['barGroups'] as List<BarChartGroupData>;
    final maxNetValue = chartData['maxNetValue'] as double;
    final maxY = max(calorieTarget.toDouble(), maxNetValue) * 1.2;
    final chartWidth = max(MediaQuery.of(context).size.width - 64, barGroups.length * 50.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Net Calorie Balance", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            barGroups.isEmpty
                ? const Center(heightFactor: 5, child: Text("Log data to see your net balance."))
                : SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 240,
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barGroups: barGroups,
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: calorieTarget.toDouble(),
                          color: Colors.redAccent,
                          strokeWidth: 3,
                          dashArray: [10, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 5, bottom: 5),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                            labelResolver: (line) => 'Goal',
                          ),
                        ),
                      ],
                    ),
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
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 500),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ChartLegend(Colors.green, "Below Goal"),
              SizedBox(width: 16),
              ChartLegend(Colors.orange, "Above Goal"),
              SizedBox(width: 16),
              ChartLegend(Colors.redAccent, "Daily Goal", isLine: true),
            ]),
          ],
        ),
      ),
    );
  }
}