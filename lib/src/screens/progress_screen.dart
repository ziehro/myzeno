import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'dart:math';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Future<Map<String, dynamic>>? _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final profile = await _firebaseService.getUserProfile();
    final goal = await _firebaseService.getUserGoal();
    return {'profile': profile, 'goal': goal};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError || snapshot.data!['profile'] == null) {
            return const Center(child: Text("Could not load user data."));
          }

          final UserProfile userProfile = snapshot.data!['profile'];
          final UserGoal userGoal = snapshot.data!['goal'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildNetCalorieChartSection(userProfile, userGoal),
              const SizedBox(height: 24),
              // The weight chart now needs all the data for its calculations
              _buildWeightChartSection(userProfile, userGoal),
              const SizedBox(height: 24),
              _buildCalorieChartSection(),
            ],
          );
        },
      ),
    );
  }

  // --- NET CALORIE CHART (No Changes) ---
  Widget _buildNetCalorieChartSection(UserProfile profile, UserGoal goal) {
    final calorieTarget = profile.recommendedDailyIntake - goal.dailyCalorieDeficitTarget;

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
            StreamBuilder<List<FoodLog>>(
              stream: _firebaseService.foodLogStream,
              builder: (context, foodSnapshot) {
                return StreamBuilder<List<ActivityLog>>(
                  stream: _firebaseService.activityLogStream,
                  builder: (context, activitySnapshot) {
                    if (foodSnapshot.connectionState == ConnectionState.waiting || activitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final foodLogs = foodSnapshot.data ?? [];
                    final activityLogs = activitySnapshot.data ?? [];

                    final chartData = _prepareNetCalorieBarData(foodLogs, activityLogs, calorieTarget);
                    final barGroups = chartData['barGroups'] as List<BarChartGroupData>;
                    final maxNetValue = chartData['maxNetValue'] as double;

                    final maxY = max(calorieTarget.toDouble(), maxNetValue) * 1.2;

                    if (barGroups.isEmpty) {
                      return const Center(heightFactor: 5, child: Text("Log data to see your net balance."));
                    }

                    return SizedBox(
                      height: 220,
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
                                  final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(DateFormat.E().format(day)));
                                },
                                reservedSize: 28,
                              ),
                            ),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 500),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _buildNetCalorieLegend(),
          ],
        ),
      ),
    );
  }


  // --- UPDATED: WEIGHT TREND CHART ---
  Widget _buildWeightChartSection(UserProfile profile, UserGoal goal) {
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
            // We now need to listen to all data streams to make the calculation
            StreamBuilder<List<WeightLog>>(
              stream: _firebaseService.weightLogStream,
              builder: (context, weightSnapshot) {
                return StreamBuilder<List<FoodLog>>(
                  stream: _firebaseService.foodLogStream,
                  builder: (context, foodSnapshot) {
                    return StreamBuilder<List<ActivityLog>>(
                      stream: _firebaseService.activityLogStream,
                      builder: (context, activitySnapshot) {
                        if (weightSnapshot.connectionState == ConnectionState.waiting ||
                            foodSnapshot.connectionState == ConnectionState.waiting ||
                            activitySnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final weightLogs = weightSnapshot.data ?? [];
                        if (weightLogs.length < 2) {
                          return const Center(heightFactor: 5, child: Text("Log weight for 2+ days to see a trend."));
                        }

                        final foodLogs = foodSnapshot.data ?? [];
                        final activityLogs = activitySnapshot.data ?? [];

                        // The new helper does all the heavy lifting
                        final chartData = _prepareWeightTrendData(profile, goal, weightLogs, foodLogs, activityLogs);
                        final actualSpots = chartData['actual']!;
                        final theoreticalSpots = chartData['theoretical']!;

                        return SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              // Data for both lines
                              lineBarsData: [
                                // Actual Weight Line
                                LineChartBarData(
                                  spots: actualSpots,
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 4,
                                  belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                ),
                                // Theoretical Weight Line
                                LineChartBarData(
                                  spots: theoreticalSpots,
                                  isCurved: true,
                                  color: Colors.grey,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  dashArray: [5, 5], // Dashed line
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
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _buildWeightTrendLegend(),
            const SizedBox(height: 16),
            _buildWeightHistoryList(),
          ],
        ),
      ),
    );
  }

  // --- COMPACT WEIGHT HISTORY (No Changes) ---
  Widget _buildWeightHistoryList() {
    return StreamBuilder<List<WeightLog>>(
      stream: _firebaseService.weightLogStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final recentLogs = snapshot.data!.take(5);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text("Recent Logs", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
              children: recentLogs.map((log) {
                return TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(DateFormat('MMMM d, yyyy').format(log.date)),
                  ),
                  Text("${log.weight.toStringAsFixed(1)} lbs", style: const TextStyle(fontWeight: FontWeight.bold)),
                ]);
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // --- CALORIE PROGRESS SECTION (No Changes) ---
  Widget _buildCalorieChartSection() {
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
            StreamBuilder<List<FoodLog>>(
              stream: _firebaseService.foodLogStream,
              builder: (context, foodSnapshot) {
                return StreamBuilder<List<ActivityLog>>(
                  stream: _firebaseService.activityLogStream,
                  builder: (context, activitySnapshot) {
                    if (foodSnapshot.connectionState == ConnectionState.waiting || activitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!foodSnapshot.hasData || foodSnapshot.data!.isEmpty) {
                      return const Center(heightFactor: 5, child: Text("Log food to see your calorie balance."));
                    }
                    final foodLogs = foodSnapshot.data!;
                    final activityLogs = activitySnapshot.data ?? [];
                    final barGroups = _prepareCalorieBarData(foodLogs, activityLogs);
                    if (barGroups.isEmpty) {
                      return const Center(heightFactor: 5, child: Text("No data for the last 7 days."));
                    }
                    return SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          barGroups: barGroups,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(DateFormat.E().format(day)));
                                },
                                reservedSize: 28,
                              ),
                            ),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(enabled: true),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _buildConsumedBurnedLegend(),
          ],
        ),
      ),
    );
  }

  // --- LEGENDS ---
  Widget _buildConsumedBurnedLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.orange, "Consumed"),
        const SizedBox(width: 20),
        _legendItem(Colors.lightGreen, "Burned"),
      ],
    );
  }

  Widget _buildNetCalorieLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green, "Below Goal"),
        const SizedBox(width: 16),
        _legendItem(Colors.orange, "Above Goal"),
        const SizedBox(width: 16),
        _legendItem(Colors.redAccent, "Daily Goal", isLine: true),
      ],
    );
  }

  Widget _buildWeightTrendLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Theme.of(context).colorScheme.primary, "Actual Weight"),
        const SizedBox(width: 16),
        _legendItem(Colors.grey, "Theoretical Weight", isLine: true),
      ],
    );
  }

  Widget _legendItem(Color color, String text, {bool isLine = false}) {
    return Row(
      children: [
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
      ],
    );
  }

  // --- DATA HELPERS ---

  Map<String, dynamic> _prepareNetCalorieBarData(List<FoodLog> foodLogs, List<ActivityLog> activityLogs, int calorieTarget) {
    final Map<int, double> dailyNet = {};
    double maxNetValue = 0;
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    for (int i = 0; i < 7; i++) {
      final day = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day).add(Duration(days: i));
      dailyNet[day.millisecondsSinceEpoch] = 0.0;
    }

    for (final log in foodLogs) {
      final dayKey = DateTime(log.date.year, log.date.month, log.date.day).millisecondsSinceEpoch;
      if (dailyNet.containsKey(dayKey)) {
        dailyNet[dayKey] = dailyNet[dayKey]! + log.calories;
      }
    }

    for (final log in activityLogs) {
      final dayKey = DateTime(log.date.year, log.date.month, log.date.day).millisecondsSinceEpoch;
      if (dailyNet.containsKey(dayKey)) {
        dailyNet[dayKey] = dailyNet[dayKey]! - log.caloriesBurned;
      }
    }

    final barGroups = List.generate(7, (index) {
      final day = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day).add(Duration(days: index));
      final dayKey = day.millisecondsSinceEpoch;
      final netValue = dailyNet[dayKey] ?? 0;
      final isOverGoal = netValue > calorieTarget;

      if (netValue > maxNetValue) {
        maxNetValue = netValue;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: netValue.toDouble(),
            color: isOverGoal ? Colors.orange : Colors.green,
            width: 16,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ],
      );
    });

    return {'barGroups': barGroups, 'maxNetValue': maxNetValue};
  }

  List<BarChartGroupData> _prepareCalorieBarData(List<FoodLog> foodLogs, List<ActivityLog> activityLogs) {
    final Map<int, double> dailyConsumed = {};
    final Map<int, double> dailyBurned = {};
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    for (int i = 0; i < 7; i++) {
      final day = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day).add(Duration(days: i));
      dailyConsumed[day.millisecondsSinceEpoch] = 0.0;
      dailyBurned[day.millisecondsSinceEpoch] = 0.0;
    }

    for (final log in foodLogs) {
      final dayKey = DateTime(log.date.year, log.date.month, log.date.day).millisecondsSinceEpoch;
      if (dailyConsumed.containsKey(dayKey)) {
        dailyConsumed[dayKey] = dailyConsumed[dayKey]! + log.calories;
      }
    }

    for (final log in activityLogs) {
      final dayKey = DateTime(log.date.year, log.date.month, log.date.day).millisecondsSinceEpoch;
      if (dailyBurned.containsKey(dayKey)) {
        dailyBurned[dayKey] = dailyBurned[dayKey]! + log.caloriesBurned;
      }
    }

    return List.generate(7, (index) {
      final day = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day).add(Duration(days: index));
      final dayKey = day.millisecondsSinceEpoch;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: dailyConsumed[dayKey] ?? 0, color: Colors.orange, width: 8, borderRadius: BorderRadius.circular(2)),
          BarChartRodData(toY: dailyBurned[dayKey] ?? 0, color: Colors.lightGreen, width: 8, borderRadius: BorderRadius.circular(2)),
        ],
      );
    });
  }

  // --- NEW: Helper for calculating both weight trend lines ---
  Map<String, List<FlSpot>> _prepareWeightTrendData(UserProfile profile, UserGoal goal, List<WeightLog> weightLogs, List<FoodLog> foodLogs, List<ActivityLog> activityLogs) {
    if (weightLogs.isEmpty) return {'actual': [], 'theoretical': []};

    // 1. Prepare actual weight spots
    weightLogs.sort((a, b) => a.date.compareTo(b.date));
    final actualSpots = weightLogs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    // 2. Prepare theoretical weight spots
    final List<FlSpot> theoreticalSpots = [];
    final dailyCalorieTarget = profile.recommendedDailyIntake - goal.dailyCalorieDeficitTarget;
    const caloriesPerPound = 3500;

    // Group calorie data by day
    final Map<DateTime, double> dailyNetCalories = {};
    for (var log in foodLogs) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      dailyNetCalories.update(day, (value) => value + log.calories, ifAbsent: () => log.calories.toDouble());
    }
    for (var log in activityLogs) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      dailyNetCalories.update(day, (value) => value - log.caloriesBurned, ifAbsent: () => -log.caloriesBurned.toDouble());
    }

    // Iterate through the same dates as the actual weight logs
    double currentTheoreticalWeight = profile.startWeight;
    DateTime lastDate = profile.createdAt;

    for (int i = 0; i < weightLogs.length; i++) {
      final logDate = DateTime(weightLogs[i].date.year, weightLogs[i].date.month, weightLogs[i].date.day);

      // Calculate weight change for the period between the last log and this one
      int daysSinceLastLog = logDate.difference(lastDate).inDays;
      for (int j = 0; j < daysSinceLastLog; j++) {
        final date = lastDate.add(Duration(days: j));
        final netCalories = dailyNetCalories[date] ?? 0;
        final calorieDifference = netCalories - dailyCalorieTarget;
        final weightChange = calorieDifference / caloriesPerPound;
        currentTheoreticalWeight += weightChange;
      }

      theoreticalSpots.add(FlSpot(i.toDouble(), currentTheoreticalWeight));
      lastDate = logDate;
    }

    return {'actual': actualSpots, 'theoretical': theoreticalSpots};
  }
}