// lib/src/screens/widgets/weight_chart_section.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'chart_legends.dart';
import 'dart:math';

class WeightChartSection extends StatelessWidget {
  final UserProfile profile;
  final UserGoal goal;
  final Map<String, dynamic> chartData; // Changed from Map<String, List<FlSpot>>
  final ScrollController scrollController;

  const WeightChartSection({
    super.key,
    required this.profile,
    required this.goal,
    required this.chartData,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final actualSpots = (chartData['actual'] as List<FlSpot>?) ?? const <FlSpot>[];
    final theoreticalSpots = (chartData['theoretical'] as List<FlSpot>?) ?? const <FlSpot>[];
    final dates = (chartData['dates'] as List<DateTime>?) ?? const <DateTime>[];

    if (actualSpots.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text("Log weight for 2+ days to see a trend."),
          ),
        ),
      );
    }

    // Width calculation
    final chartWidth = max(MediaQuery.of(context).size.width - 64, actualSpots.length * 80.0);

    // ---- Unified Y scale across both series ----
    double minYData = double.infinity;
    double maxYData = -double.infinity;

    void _scan(List<FlSpot> spots) {
      for (final s in spots) {
        if (s.y < minYData) minYData = s.y;
        if (s.y > maxYData) maxYData = s.y;
      }
    }

    _scan(actualSpots);
    _scan(theoreticalSpots);

    if (!minYData.isFinite || !maxYData.isFinite) {
      minYData = 0;
      maxYData = 1;
    }

    // Add headroom (5%) and pick a nice step; round min/max to step
    final range = (maxYData - minYData).abs();
    final step = _niceWeightStep(range);
    final paddedMin = minYData - range * 0.05;
    final paddedMax = maxYData + range * 0.05;

    final minY = (paddedMin / step).floor() * step;
    final maxY = (paddedMax / step).ceil() * step;

    // Start scrolled to the right after first frame
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
            Text("Weight Trend", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 280, // Increased height to accommodate labels
                width: chartWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20, right: 60), // Added padding for labels
                  child: LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: actualSpots,
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 4,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        ),
                        if (theoreticalSpots.isNotEmpty)
                          LineChartBarData(
                            spots: theoreticalSpots,
                            isCurved: true,
                            color: Colors.grey,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            dashArray: [5, 5],
                          ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 55, // Increased reserved space
                            interval: step,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "${value.toStringAsFixed(1)} lb",
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40, // Increased reserved space
                            interval: max(1.0, (dates.length / 8).ceil().toDouble()), // Show ~8 labels max
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= dates.length) return const Text('');

                              final date = dates[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('M/d').format(date),
                                  style: Theme.of(context).textTheme.bodySmall,
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
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ChartLegend(Theme.of(context).colorScheme.primary, "Actual Weight"),
              const SizedBox(width: 16),
              const ChartLegend(Colors.grey, "Theoretical Weight", isLine: true),
            ]),
            const SizedBox(height: 16),
            _buildWeightHistoryList(),
          ],
        ),
      ),
    );
  }

  // Choose a pleasant tick interval for weight ranges
  double _niceWeightStep(double range) {
    if (range <= 10) return 1;
    if (range <= 25) return 2.5;
    if (range <= 60) return 5;
    if (range <= 120) return 10;
    return 20;
  }

  Widget _buildWeightHistoryList() {
    return StreamBuilder<List<WeightLog>>(
      stream: FirebaseService().weightLogStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final recentLogs = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            DropdownButtonFormField<WeightLog>(
              decoration: InputDecoration(
                labelText: "Recent Logs",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: recentLogs.map((log) {
                return DropdownMenuItem<WeightLog>(
                  value: log,
                  child: Text(
                    '${DateFormat('MMMM d, yyyy').format(log.date)} - ${log.weight.toStringAsFixed(1)} lbs',
                  ),
                );
              }).toList(),
              onChanged: (WeightLog? newValue) {
                // Handle the selection if needed
              },
            ),
          ],
        );
      },
    );
  }
}