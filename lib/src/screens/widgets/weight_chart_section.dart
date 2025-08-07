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
  final Map<String, List<FlSpot>> chartData;
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
    final actualSpots = chartData['actual']!;
    final chartWidth = max(MediaQuery.of(context).size.width - 64, actualSpots.length * 50.0);

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
                height: 200,
                width: chartWidth,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: actualSpots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 4,
                        belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      ),
                      LineChartBarData(
                        spots: chartData['theoretical']!,
                        isCurved: true,
                        color: Colors.grey,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
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