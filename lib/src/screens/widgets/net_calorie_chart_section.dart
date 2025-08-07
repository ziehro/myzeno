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
    const frozenAxisWidth = 56.0;
    const step = 500.0;

    final calorieTarget = (profile.recommendedDailyIntake - goal.dailyCalorieDeficitTarget).toDouble();
    final barGroups = chartData['barGroups'] as List<BarChartGroupData>;
    if (barGroups.isEmpty) {
      return _emptyCard(context);
    }

    double maxYData = calorieTarget;
    double minYData = 0;
    for (final g in barGroups) {
      for (final r in g.barRods) {
        if (r.toY > maxYData) maxYData = r.toY;
        if (r.toY < minYData) minYData = r.toY;
      }
    }
    double maxY = (max((maxYData) * 1.2, step) / step).ceil() * step;
    double minY = ((min(minYData, 0) * 1.2) / step).floor() * step;

    final screen = MediaQuery.of(context).size;
    final textScale = MediaQuery.textScaleFactorOf(context);
    final bottomReserved = (52.0 * textScale).clamp(52.0, 80.0);
    final chartHeight = 200.0 + bottomReserved;

    // Extra right padding so the last (today) label is fully visible
    const _extraRightPaddingForLastLabel = 24.0;
    final innerViewportMinWidth = screen.width - 64 - frozenAxisWidth;
    final chartWidth = max(
      innerViewportMinWidth,
      barGroups.length * 50.0 + _extraRightPaddingForLastLabel,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Net Calorie Balance",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Frozen Y-axis
                SizedBox(
                  width: frozenAxisWidth,
                  height: chartHeight,
                  child: _FrozenYAxis(minY: minY, maxY: maxY, step: step),
                ),
                // Scrollable plot
                Expanded(
                  child: SingleChildScrollView(
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
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: calorieTarget,
                                color: Colors.redAccent,
                                strokeWidth: 3,
                                dashArray: [10, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  labelResolver: (line) => 'Goal',
                                ),
                              ),
                            ],
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: bottomReserved,
                                getTitlesWidget: (value, meta) {
                                  final date = chartData['dates'][value.toInt()];
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
                ChartLegend(Colors.green, "Below Goal"),
                SizedBox(width: 16),
                ChartLegend(Colors.orange, "Above Goal"),
                SizedBox(width: 16),
                ChartLegend(Colors.redAccent, "Daily Goal", isLine: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Center(heightFactor: 5, child: Text("Log data to see your net balance.")),
      ),
    );
  }
}

class _FrozenYAxis extends StatelessWidget {
  final double minY;
  final double maxY;
  final double step;

  const _FrozenYAxis({required this.minY, required this.maxY, required this.step});

  @override
  Widget build(BuildContext context) {
    final ticks = <double>[];
    for (double v = maxY; v >= minY - 0.001; v -= step) {
      ticks.add((v / step).roundToDouble() * step);
    }
    final numberFmt = NumberFormat.decimalPattern();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ticks
          .map((t) => Align(
        alignment: Alignment.centerRight,
        child: Text(
          numberFmt.format(t.toInt()),
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ))
          .toList(),
    );
  }
}
