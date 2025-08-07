import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';
import 'package:zeno/src/screens/log_activity_screen.dart';
import 'package:zeno/src/screens/log_food_screen.dart';
import 'package:zeno/src/screens/progress_screen.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/screens/tips_screen.dart';
import 'package:zeno/src/widgets/app_menu_button.dart'; // <-- added
import 'package:zeno/src/screens/main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  UserProfile? _userProfile;
  UserGoal? _userGoal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

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

  // Confirmation Dialog for Signing Out
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

  // Used by the menu item to keep previous behavior
  void _handleEditProfileAndGoal() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => GoalSettingScreen(
        userProfile: _userProfile,
        userGoal: _userGoal,
      ),
    )).then((_) => _loadInitialData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userProfile == null || _userGoal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Could not load user data.'),
              ElevatedButton(onPressed: _loadInitialData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyZeno'),
        actions: [
          AppMenuButton(
            onEditProfileAndGoal: _handleEditProfileAndGoal,
            onSignOut: _showSignOutConfirmationDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildCalorieDashboard(),
            const SizedBox(height: 24),
            _buildWeightDashboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieDashboard() {
    final calorieTarget = _userProfile!.recommendedDailyIntake - _userGoal!.dailyCalorieDeficitTarget;

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
              stream: _firebaseService.foodLogStream,
              builder: (context, foodSnapshot) {
                return StreamBuilder<List<ActivityLog>>(
                  stream: _firebaseService.activityLogStream,
                  builder: (context, activitySnapshot) {
                    if (foodSnapshot.connectionState == ConnectionState.waiting || activitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final today = DateTime.now();
                    bool isSameDay(DateTime date) => date.year == today.year && date.month == today.month && date.day == today.day;

                    final caloriesConsumed = (foodSnapshot.data ?? []).where((log) => isSameDay(log.date)).fold(0, (sum, item) => sum + item.calories);
                    final caloriesBurned = (activitySnapshot.data ?? []).where((log) => isSameDay(log.date)).fold(0, (sum, item) => sum + item.caloriesBurned);

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
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MainScreen(initialIndex: 1), // Food tab
                    ));
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text("Log Food"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MainScreen(initialIndex: 2), // Activity tab
                    ));
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

  Widget _buildWeightDashboard() {
    return StreamBuilder<List<WeightLog>>(
      stream: _firebaseService.weightLogStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));
        }

        final weightLogs = snapshot.data ?? [];
        final currentWeight = weightLogs.isNotEmpty ? weightLogs.first.weight : _userProfile!.startWeight;
        final actualLoss = _userProfile!.startWeight - currentWeight;

        final int daysPassed = DateTime.now().difference(_userProfile!.createdAt).inDays;
        final double lbsPerDay = _userGoal!.days > 0 ? _userGoal!.lbsToLose / _userGoal!.days : 0;
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
                _buildInfoRow("Starting Weight:", "${_userProfile!.startWeight.toStringAsFixed(1)} lbs"),
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
