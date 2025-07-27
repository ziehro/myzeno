import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';
import 'package:zeno/src/screens/log_activity_screen.dart';
import 'package:zeno/src/screens/log_food_screen.dart';
import 'package:zeno/src/screens/progress_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserGoal userGoal;
  final UserProfile userProfile;

  const HomeScreen({
    super.key,
    required this.userGoal,
    required this.userProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late double _currentWeight;

  @override
  void initState() {
    super.initState();
    final weightLogBox = Hive.box<WeightLog>('weight_log_box');
    final latestWeightLog =
    weightLogBox.values.isNotEmpty ? weightLogBox.values.last : null;
    _currentWeight = latestWeightLog?.weight ?? widget.userProfile.startWeight;
  }

  Future<void> _showLogWeightDialog() async {
    final weightController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Today\'s Weight'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (lbs)',
                hintText: 'e.g., 178.5',
              ),
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a weight';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newWeight = double.parse(weightController.text);

                  final newLog =
                  WeightLog(date: DateTime.now(), weight: newWeight);
                  Hive.box<WeightLog>('weight_log_box').add(newLog);

                  setState(() {
                    _currentWeight = newWeight;
                  });

                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double actualLoss = widget.userProfile.startWeight - _currentWeight;
    final int daysPassed = DateTime.now().difference(widget.userProfile.createdAt).inDays;
    final double lbsPerDay = widget.userGoal.lbsToLose / widget.userGoal.days;
    final double theoreticalLoss = (daysPassed * lbsPerDay) > 0 ? (daysPassed * lbsPerDay) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyZeno'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProgressScreen()),
              );
            },
            icon: const Icon(Icons.timeline),
            tooltip: 'View Progress',
          ),
          IconButton(
            onPressed: () {
              // --- THIS IS THE CORRECTED NAVIGATION FOR EDITING ---
              // It 'pushes' the screen on top, allowing for a back button.
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GoalSettingScreen(
                    userProfile: widget.userProfile,
                    userGoal: widget.userGoal,
                  ),
                ),
              ).then((_) {
                // This 'then' block runs when we come back from the edit screen.
                // It forces the home screen to rebuild with any new data.
                setState(() {});
              });
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile & Goal',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("Welcome Back!",
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          _buildCalorieDashboard(),
          const SizedBox(height: 24),
          _buildWeightDashboard(actualLoss, theoreticalLoss),
        ],
      ),
      floatingActionButton: null, // FAB was removed
    );
  }

  Widget _buildCalorieDashboard() {
    final calorieTarget = widget.userProfile.recommendedDailyIntake - widget.userGoal.dailyCalorieDeficitTarget;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Balance",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: Hive.box<FoodLog>('food_log_box').listenable(),
              builder: (context, Box<FoodLog> foodBox, _) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box<ActivityLog>('activity_log_box').listenable(),
                  builder: (context, Box<ActivityLog> activityBox, _) {
                    final today = DateTime.now();

                    final caloriesConsumed = foodBox.values.where((log) =>
                    log.date.year == today.year && log.date.month == today.month && log.date.day == today.day)
                        .fold(0, (sum, item) => sum + item.calories);

                    final caloriesBurned = activityBox.values.where((log) =>
                    log.date.year == today.year && log.date.month == today.month && log.date.day == today.day)
                        .fold(0, (sum, item) => sum + item.caloriesBurned);

                    final netCalories = caloriesConsumed - caloriesBurned;
                    final caloriesRemaining = calorieTarget - netCalories;
                    final progress = calorieTarget > 0 ? (netCalories / calorieTarget) : 0.0;

                    return Column(
                      children: [
                        _buildInfoRow("Consumed:", "+$caloriesConsumed kcal"),
                        _buildInfoRow("Burned:", "-$caloriesBurned kcal", valueColor: Colors.green.shade700),
                        const Divider(height: 16),
                        _buildInfoRow("Net Calories:", "$netCalories kcal"),
                        _buildInfoRow("Remaining:", "$caloriesRemaining kcal", isBold: true),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          borderRadius: const BorderRadius.all(Radius.circular(5)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LogFoodScreen()),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text("Log Food"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LogActivityScreen()),
                    );
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text("Log Activity"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeightDashboard(double actualLoss, double theoreticalLoss) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Weight Progress",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow("Starting Weight:", "${widget.userProfile.startWeight.toStringAsFixed(1)} lbs"),
            _buildInfoRow("Current Weight:", "${_currentWeight.toStringAsFixed(1)} lbs"),
            const Divider(height: 24),
            _buildInfoRow("Theoretical Loss:", "${theoreticalLoss.toStringAsFixed(1)} lbs"),
            _buildInfoRow("Actual Loss:", "${actualLoss.toStringAsFixed(1)} lbs", isBold: true, valueColor: Colors.green.shade700),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                  onPressed: _showLogWeightDialog,
                  child: const Text("Log Today's Weight")),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: isBold
                ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Theme.of(context).colorScheme.primary)
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}