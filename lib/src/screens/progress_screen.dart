import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Weight History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildWeightChart(context),
          const SizedBox(height: 32),
          Text(
            'Daily Calorie Balance',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildCalorieChart(context),
        ],
      ),
    );
  }

  // --- Widget for the Weight Progress Line Chart ---
  Widget _buildWeightChart(BuildContext context) {
    final weightLogs = Hive.box<WeightLog>('weight_log_box').values.toList();
    if (weightLogs.length < 2) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Log weight for at least two days to see a chart.')),
      );
    }

    final spots = weightLogs.map((log) {
      return FlSpot(log.date.millisecondsSinceEpoch.toDouble(), log.weight);
    }).toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (meta.min == value || meta.max == value) return const SizedBox();
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(DateFormat.MMMd().format(date)),
                  );
                },
                reservedSize: 30,
                interval: (spots.last.x - spots.first.x) / 3,
              ),
            ),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
      ),
    );
  }

  // --- Widget for the Daily Calorie Bar Chart ---
  Widget _buildCalorieChart(BuildContext context) {
    // --- THE FIX IS HERE ---
    // Safely get the profile and goal without the '!' operator
    final userProfile = Hive.box<UserProfile>('user_profile_box').get(0);
    final userGoal = Hive.box<UserGoal>('user_goal_box').get(0);

    // Add a check to ensure the data exists before proceeding.
    if (userProfile == null || userGoal == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Please set up your profile and goal first.')),
      );
    }
    // ----------------------

    final foodLogs = Hive.box<FoodLog>('food_log_box').values;
    final activityLogs = Hive.box<ActivityLog>('activity_log_box').values;
    final calorieTarget = userProfile.recommendedDailyIntake - userGoal.dailyCalorieDeficitTarget;

    if (foodLogs.isEmpty && activityLogs.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Log food or activities to see a chart.')),
      );
    }

    final Map<DateTime, int> netCaloriesPerDay = {};
    for (var log in foodLogs) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      netCaloriesPerDay.update(day, (value) => value + log.calories, ifAbsent: () => log.calories);
    }
    for (var log in activityLogs) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      netCaloriesPerDay.update(day, (value) => value - log.caloriesBurned, ifAbsent: () => -log.caloriesBurned);
    }

    final sortedDays = netCaloriesPerDay.keys.toList()..sort();
    final barGroups = sortedDays.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      final netCalories = netCaloriesPerDay[day]!;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: netCalories.toDouble(),
            color: netCalories > calorieTarget ? Colors.red.shade400 : Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles:false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final day = sortedDays[value.toInt()];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(DateFormat.MMMd().format(day)),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}