import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/services/firebase_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  UserProfile? _userProfile;
  UserGoal? _userGoal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _firebaseService.getUserProfile();
    final goal = await _firebaseService.getUserGoal();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _userGoal = goal;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null || _userGoal == null
          ? const Center(child: Text('Could not load user data.'))
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Weight History', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildWeightChart(context),
          const SizedBox(height: 32),
          Text('Daily Calorie Balance', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildCalorieChart(context),
        ],
      ),
    );
  }

  Widget _buildWeightChart(BuildContext context) {
    return StreamBuilder<List<WeightLog>>(
      stream: _firebaseService.weightLogStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        final weightLogs = snapshot.data!;

        if (weightLogs.length < 2) {
          return const SizedBox(height: 200, child: Center(child: Text('Log weight for at least two days to see a chart.')));
        }

        final spots = weightLogs.map((log) => FlSpot(log.date.millisecondsSinceEpoch.toDouble(), log.weight)).toList();

        return SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              // ... Chart configuration ...
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalorieChart(BuildContext context) {
    final calorieTarget = _userProfile!.recommendedDailyIntake - _userGoal!.dailyCalorieDeficitTarget;

    return StreamBuilder<List<FoodLog>>(
      stream: _firebaseService.foodLogStream,
      builder: (context, foodSnapshot) {
        return StreamBuilder<List<ActivityLog>>(
          stream: _firebaseService.activityLogStream,
          builder: (context, activitySnapshot) {
            if (!foodSnapshot.hasData || !activitySnapshot.hasData) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            final foodLogs = foodSnapshot.data!;
            final activityLogs = activitySnapshot.data!;

            if (foodLogs.isEmpty && activityLogs.isEmpty) {
              return const SizedBox(height: 200, child: Center(child: Text('Log food or activities to see a chart.')));
            }

            // ... Logic to group data and build the bar chart ...

            return SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  // ... Bar chart configuration ...
                ),
              ),
            );
          },
        );
      },
    );
  }
}