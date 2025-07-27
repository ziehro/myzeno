import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import the model blueprints
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';

import 'package:zeno/src/screens/decision_screen.dart';
import 'package:zeno/theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local database storage
  await Hive.initFlutter();

  // Register all the adapters
  Hive.registerAdapter(UserGoalAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(SexAdapter());
  Hive.registerAdapter(WeightLogAdapter());
  Hive.registerAdapter(FoodLogAdapter());
  Hive.registerAdapter(ActivityLogAdapter());
  Hive.registerAdapter(ActivityLevelAdapter()); // <-- THE MISSING LINE

  // Open all the database "boxes"
  await Hive.openBox<UserGoal>('user_goal_box');
  await Hive.openBox<UserProfile>('user_profile_box');
  await Hive.openBox<WeightLog>('weight_log_box');
  await Hive.openBox<FoodLog>('food_log_box');
  await Hive.openBox<ActivityLog>('activity_log_box');

  // Run the app
  runApp(const MyZenoApp());
}

class MyZenoApp extends StatelessWidget {
  const MyZenoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyZeno',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const DecisionScreen(),
    );
  }
}