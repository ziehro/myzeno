import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// CORRECT: Import only the main model files.
// The Adapters are automatically included from their 'part' files.
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';

// INCORRECT lines from previous step have been removed.
// Do NOT import the .g.dart files here.

import 'package:zeno/src/screens/decision_screen.dart';
import 'package:zeno/theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local database storage
  await Hive.initFlutter();

  // These calls will now work correctly because the main model
  // files expose the adapters from their generated parts.
  Hive.registerAdapter(UserGoalAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(SexAdapter());
  Hive.registerAdapter(WeightLogAdapter());

  // Open all the database "boxes"
  await Hive.openBox<UserGoal>('user_goal_box');
  await Hive.openBox<UserProfile>('user_profile_box');
  await Hive.openBox<WeightLog>('weight_log_box');

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