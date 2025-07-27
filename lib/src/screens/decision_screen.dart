import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zeno/src/models/user_goal.dart';
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
    _checkIfGoalExists();
  }

  Future<void> _checkIfGoalExists() async {
    final goalBox = Hive.box<UserGoal>('user_goal_box');

    // Use a short delay to prevent screen flicker
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) { // Check if the widget is still in the tree
      if (goalBox.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GoalSettingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while we decide which screen to show
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}