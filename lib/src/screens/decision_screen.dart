import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';
import 'package:zeno/src/screens/home_screen.dart';

class DecisionScreen extends StatefulWidget {
  const DecisionScreen({super.key});

  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
  @override
  void initState() {
    super.initState();
    _checkIfDataExists();
  }

  Future<void> _checkIfDataExists() async {
    final goalBox = Hive.box<UserGoal>('user_goal_box');
    final profileBox = Hive.box<UserProfile>('user_profile_box');

    // Use a short delay to prevent screen flicker
    await Future.delayed(const Duration(milliseconds: 500));

    // The new, safer check for BOTH pieces of data
    if (mounted) {
      if (goalBox.isNotEmpty && profileBox.isNotEmpty) {
        // If data exists, get it and pass it to HomeScreen
        final userGoal = goalBox.get(0)!;
        final userProfile = profileBox.get(0)!;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen(
            userGoal: userGoal,
            userProfile: userProfile,
          )),
        );
      } else {
        // If any data is missing, go to the setup screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GoalSettingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}