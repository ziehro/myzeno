import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';
import 'package:zeno/src/services/hybrid_data_service.dart';
import 'package:zeno/src/widgets/app_menu_button.dart';
import 'package:zeno/src/widgets/welcome_banner.dart';
import 'package:zeno/src/widgets/quick_tips_card.dart';
import 'package:zeno/src/widgets/journey_progress_widget.dart';
import 'package:zeno/src/services/journey_completion_service.dart';
import 'package:zeno/main.dart'; // For ServiceProvider

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HybridDataService _dataService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = ServiceProvider.of(context).hybridDataService;

    // Check for journey completion when home screen loads
    _checkJourneyCompletion();
  }

  Future<void> _checkJourneyCompletion() async {
    // Small delay to ensure the screen is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await JourneyCompletionService.checkJourneyCompletion(context, _dataService);
    }
  }

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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your data...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text('Error loading data'),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}), // Retry
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _handleEditProfileAndGoal,
                    child: const Text('Set Up Profile'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to MyZeno!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Let\'s set up your profile to get started.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleEditProfileAndGoal,
                    child: const Text('Set Up Profile'),
                  ),
                ],
              ),
            );
          }

          final UserProfile? userProfile = data['profile'];
          final UserGoal? userGoal = data['goal'];

          // Check if either profile or goal is missing
          if (userProfile == null || userGoal == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_outlined, size: 64, color: Colors.orange.shade400),
                  const SizedBox(height: 16),
                  Text(
                    userProfile == null ? 'Profile Setup Required' : 'Goal Setup Required',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userProfile == null
                        ? 'Please complete your profile setup to continue.'
                        : 'Please set your weight loss goal to continue.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleEditProfileAndGoal,
                    child: Text(userProfile == null ? 'Complete Profile' : 'Set Goal'),
                  ),
                ],
              ),
            );
          }

          // Both profile and goal exist, show main content
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Welcome banner for new users
                WelcomeBanner(
                  userName: userProfile.email,
                  dailyCalorieTarget: userProfile.recommendedDailyIntake - userGoal.dailyCalorieDeficitTarget,
                  dailyDeficit: userGoal.dailyCalorieDeficitTarget,
                ),

                // Journey Progress Widget
                const JourneyProgressWidget(),
                const SizedBox(height: 16),

                _buildCalorieDashboard(userProfile, userGoal),
                const SizedBox(height: 16),

                // Daily tips card
                QuickTipsCard(onNavigateToTab: widget.onNavigateToTab),
                const SizedBox(height: 8),

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
      final profile = await _dataService.getUserProfile();
      final goal = await _dataService.getUserGoal();

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
                  _dataService.addWeightLog(newLog);
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sign Out'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _dataService.signOut();
                  // The AuthWrapper will automatically show the login screen
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
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
              stream: _dataService.todaysFoodLogStream,
              initialData: [], // Start with empty data
              builder: (context, foodSnapshot) {
                return StreamBuilder<List<ActivityLog>>(
                  stream: _dataService.todaysActivityLogStream,
                  initialData: [], // Start with empty data
                  builder: (context, activitySnapshot) {
                    print('HomeScreen: Food connection state: ${foodSnapshot.connectionState}');
                    print('HomeScreen: Activity connection state: ${activitySnapshot.connectionState}');
                    print('HomeScreen: Food has data: ${foodSnapshot.hasData}');
                    print('HomeScreen: Activity has data: ${activitySnapshot.hasData}');
                    print('HomeScreen: Food data length: ${foodSnapshot.data?.length ?? 0}');
                    print('HomeScreen: Activity data length: ${activitySnapshot.data?.length ?? 0}');

                    // Only show loading for the first few seconds
                    if (foodSnapshot.connectionState == ConnectionState.waiting && !foodSnapshot.hasData ||
                        activitySnapshot.connectionState == ConnectionState.waiting && !activitySnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (foodSnapshot.hasError) {
                      print('HomeScreen: Food stream error: ${foodSnapshot.error}');
                    }

                    if (activitySnapshot.hasError) {
                      print('HomeScreen: Activity stream error: ${activitySnapshot.error}');
                    }

                    final caloriesConsumed = (foodSnapshot.data ?? [])
                        .fold(0, (sum, item) => sum + item.totalCalories);

                    final caloriesBurned = (activitySnapshot.data ?? [])
                        .fold(0, (sum, item) => sum + item.totalCaloriesBurned);

                    final netCalories = caloriesConsumed - caloriesBurned;
                    final caloriesRemaining = calorieTarget - netCalories;
                    final progress = calorieTarget > 0 ? (netCalories / calorieTarget) : 0.0;

                    print('HomeScreen: Calculated values - Consumed: $caloriesConsumed, Burned: $caloriesBurned, Net: $netCalories');

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
      stream: _dataService.weightLogStream,
      builder: (context, snapshot) {
        // Better error handling and loading states
        if (snapshot.hasError) {
          print('HomeScreen: Weight stream error: ${snapshot.error}');
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
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 8),
                        const Text('Error loading weight data'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}), // Trigger rebuild
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading weight data...'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final weightLogs = snapshot.data ?? [];
        print('HomeScreen: Displaying ${weightLogs.length} weight logs');

        final currentWeight = weightLogs.isNotEmpty ? weightLogs.first.weight : userProfile.startWeight;
        final actualLoss = userProfile.startWeight - currentWeight;
        final int daysPassed = DateTime.now().difference(userProfile.createdAt).inDays;

        // Load goal data for theoretical calculation
        return FutureBuilder<UserGoal?>(
          future: _dataService.getUserGoal(),
          builder: (context, goalSnapshot) {
            if (!goalSnapshot.hasData) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
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
                    if (weightLogs.isEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Log your weight daily to track real progress!',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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