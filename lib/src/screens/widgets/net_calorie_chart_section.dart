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
    final calorieTarget =
    (profile.recommendedDailyIntake - goal.dailyCalorieDeficitTarget).toDouble();
    final barGroups = chartData['barGroups'] as List<BarChartGroupData>;
    final dates = chartData['dates'] as List<DateTime>;
    if (barGroups.isEmpty) {
      return _emptyCard(context);
    }

    // --- Y range: start bars at 0 ---
    double maxYData = calorieTarget;
    for (final g in barGroups) {
      for (final r in g.barRods) {
        if (r.toY > maxYData) maxYData = r.toY;
      }
    }
    final maxYPadded = maxYData * 1.2;
    final step = _niceStep(maxYPadded);
    final maxY = (max(maxYPadded, step) / step).ceil() * step;
    const minY = 0.0;

    // --- Layout sizing ---
    final screen = MediaQuery.of(context).size;
    final textScale = MediaQuery.textScaleFactorOf(context);
    final bottomReserved = (52.0 * textScale).clamp(52.0, 80.0);
    final chartHeight = 200.0 + bottomReserved;

    // Extra space for last label
    const extraRightPadding = 12.0;
    final innerViewportMinWidth = screen.width - 64;
    final chartWidth = max(
      innerViewportMinWidth,
      barGroups.length * 50.0 + extraRightPadding,
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
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: step,
                          getTitlesWidget: (value, meta) => SizedBox(
                            width: meta.axisSide == AxisSide.right ? 48 : null,
                            child: Text(
                              NumberFormat.decimalPattern().format(value.toInt()),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center, // centered horizontally in box
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
                  ),
                ),
              ),
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

  double _niceStep(double maxY) {
    if (maxY <= 1500) return 250;
    if (maxY <= 4000) return 500;
    if (maxY <= 8000) return 1000;
    return 2000;
  }

  Widget _emptyCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Center(
          heightFactor: 5,
          child: Text("Log data to see your net balance."),
        ),
      ),
    );
  }
}
