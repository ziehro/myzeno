import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // We can confidently get these because DecisionScreen ensures they exist.
  final UserGoal userGoal = Hive.box<UserGoal>('user_goal_box').get(0)!;
  final UserProfile userProfile = Hive.box<UserProfile>('user_profile_box').get(0)!;
  final weightLogBox = Hive.box<WeightLog>('weight_log_box');

  @override
  Widget build(BuildContext context) {
    // Get the latest weight log, if any
    final WeightLog? latestWeightLog = weightLogBox.values.isNotEmpty ? weightLogBox.values.last : null;
    final double currentWeight = latestWeightLog?.weight ?? userProfile.startWeight;
    final double actualLoss = userProfile.startWeight - currentWeight;

    // Calculate theoretical weight loss
    final int daysPassed = DateTime.now().difference(userProfile.createdAt!).inDays; // Assumes createdAt is set
    final double lbsPerDay = userGoal.lbsToLose / userGoal.days;
    final double theoreticalLoss = daysPassed * lbsPerDay;


    return Scaffold(
      appBar: AppBar(
        title: const Text('MyZeno'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const GoalSettingScreen()),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile & Goal',
          ),
        ],
      ),
      body: ListView( // Changed to ListView to prevent overflow
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("Welcome Back!", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          _buildCalorieDashboard(),
          const SizedBox(height: 24),
          _buildWeightDashboard(currentWeight, actualLoss, theoreticalLoss),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to the Calorie Logging Screen
        },
        tooltip: 'Log Food',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalorieDashboard() {
    final calorieTarget = userProfile.recommendedDailyIntake - userGoal.dailyCalorieDeficitTarget;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Calorie Goals", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow("Maintenance Intake:", "${userProfile.recommendedDailyIntake} kcal"),
            _buildInfoRow("Weight Loss Deficit:", "-${userGoal.dailyCalorieDeficitTarget} kcal"),
            const Divider(height: 24),
            _buildInfoRow("Your Daily Target:", "$calorieTarget kcal", isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightDashboard(double currentWeight, double actualLoss, double theoreticalLoss) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Weight Progress", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow("Starting Weight:", "${userProfile.startWeight.toStringAsFixed(1)} lbs"),
            _buildInfoRow("Current Weight:", "${currentWeight.toStringAsFixed(1)} lbs"),
            const Divider(height: 24),
            _buildInfoRow("Theoretical Loss:", "${theoreticalLoss.toStringAsFixed(1)} lbs"),
            _buildInfoGains("Actual Loss:", "${actualLoss.toStringAsFixed(1)} lbs", isBold: true),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                  onPressed: (){
                    // TODO: Show a dialog or navigate to a screen to log today's weight
                  },
                  child: const Text("Log Today's Weight")
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper widget for consistent rows
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: isBold
                ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGains(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: isBold
                ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}