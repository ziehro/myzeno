import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/widgets/app_menu_button.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyZeno'),
        actions: [
          AppMenuButton(
            onEditProfileAndGoal: _handleEditProfileAndGoal,
            onSignOut: _showSignOutConfirmationDialog,
            onNavigateToTab: widget.onNavigateToTab,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error loading data: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}), // Retry
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data;
          if (data == null || data['profile'] == null || data['goal'] == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Profile not found. Please set up your profile.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleEditProfileAndGoal,
                    child: const Text('Set Up Profile'),
                  ),
                ],
              ),
            );
          }

          final UserProfile userProfile = data['profile'];
          final UserGoal userGoal = data['goal'];

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildCalorieDashboard(userProfile, userGoal),
                const SizedBox(height: 24),
                _buildWeightDashboard(userProfile),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final profile = await _firebaseService.getUserProfile();
      final goal = await _firebaseService.getUserGoal();

      return {
        'profile': profile,
        'goal': goal,
      };
    } catch (e) {
      print('Error loading user data: $e');
      rethrow;
    }
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
              decoration: const InputDecoration(labelText: 'Weight (lbs)'),
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a weight' : null,
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
                  final newLog = WeightLog(id: '', date: DateTime.now(), weight: newWeight);
                  _firebaseService.addWeightLog(newLog);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSignOutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sign Out'),
              onPressed: () {
                Navigator.of(context).pop();
                _firebaseService.signOut();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleEditProfileAndGoal() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const GoalSettingScreen(),
    )).then((_) => setState(() {})); // Refresh after returning
  }

  Widget _buildCalorieDashboard(UserProfile userProfile, UserGoal userGoal) {
    final calorieTarget = userProfile.recommendedDailyIntake - userGoal.dailyCalorieDeficitTarget;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Balance", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<List<FoodLog>>(
              stream: _firebaseService.todaysFoodLogStream,
              builder: (context, foodSnapshot) {
                return StreamBuilder<List<ActivityLog>>(
                  stream: _firebaseService.todaysActivityLogStream,
                  builder: (context, activitySnapshot) {
                    if (foodSnapshot.connectionState == ConnectionState.waiting ||
                        activitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final caloriesConsumed = (foodSnapshot.data ?? [])
                        .fold(0, (sum, item) => sum + item.totalCalories);

                    final caloriesBurned = (activitySnapshot.data ?? [])
                        .fold(0, (sum, item) => sum + item.totalCaloriesBurned);

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
                    widget.onNavigateToTab?.call(1); // Food tab
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text("Log Food"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onNavigateToTab?.call(2); // Activity tab
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

  Widget _buildWeightDashboard(UserProfile userProfile) {
    return StreamBuilder<List<WeightLog>>(
      stream: _firebaseService.weightLogStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));
        }

        final weightLogs = snapshot.data ?? [];
        final currentWeight = weightLogs.isNotEmpty ? weightLogs.first.weight : userProfile.startWeight;
        final actualLoss = userProfile.startWeight - currentWeight;

        final int daysPassed = DateTime.now().difference(userProfile.createdAt).inDays;

        // Load goal data for theoretical calculation
        return FutureBuilder<UserGoal?>(
          future: _firebaseService.getUserGoal(),
          builder: (context, goalSnapshot) {
            if (!goalSnapshot.hasData) {
              return const Card(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));
            }

            final userGoal = goalSnapshot.data!;
            final double lbsPerDay = userGoal.days > 0 ? userGoal.lbsToLose / userGoal.days : 0;
            final double theoreticalLoss = (daysPassed * lbsPerDay) > 0 ? (daysPassed * lbsPerDay) : 0;

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
                    _buildInfoRow("Actual Loss:", "${actualLoss.toStringAsFixed(1)} lbs", isBold: true, valueColor: Colors.green.shade700),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _showLogWeightDialog,
                        child: const Text("Log Today's Weight"),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
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