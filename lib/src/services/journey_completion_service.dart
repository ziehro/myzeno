// lib/src/services/journey_completion_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/screens/celebration_screen.dart';
import 'package:zeno/src/services/hybrid_data_service.dart';

class JourneyCompletionService {
  static const String _celebrationShownKey = 'celebration_shown_';

  static Future<void> checkJourneyCompletion(
      BuildContext context,
      HybridDataService dataService,
      ) async {
    try {
      final profile = await dataService.getUserProfile();
      final goal = await dataService.getUserGoal();

      if (profile == null || goal == null) return;

      final daysSinceStart = DateTime.now().difference(profile.createdAt).inDays;
      final isJourneyComplete = daysSinceStart >= goal.days;

      if (!isJourneyComplete) return;

      // Check if we've already shown celebration for this journey
      final prefs = await SharedPreferences.getInstance();
      final celebrationKey = _celebrationShownKey + profile.uid + '_' + goal.days.toString();
      final hasShownCelebration = prefs.getBool(celebrationKey) ?? false;

      if (hasShownCelebration) return;

      print('JourneyCompletionService: Journey completed! Showing celebration...');

      // Get all data for celebration
      final weightLogs = await dataService.getWeightLogs();
      final foodLogs = await dataService.getRecentFoodLogs();
      final activityLogs = await dataService.getRecentActivityLogs();

      // Calculate actual weight loss
      final currentWeight = weightLogs.isNotEmpty
          ? weightLogs.first.weight
          : profile.startWeight;
      final actualWeightLoss = profile.startWeight - currentWeight;

      // Mark celebration as shown
      await prefs.setBool(celebrationKey, true);

      // Show celebration screen
      if (context.mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => CelebrationScreen(
              userProfile: profile,
              userGoal: goal,
              weightLogs: weightLogs,
              allFoodLogs: foodLogs,
              allActivityLogs: activityLogs,
              actualWeightLoss: actualWeightLoss,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
            opaque: false,
          ),
        );
      }

    } catch (e) {
      print('JourneyCompletionService: Error checking completion: $e');
    }
  }

  // Check if user is close to completing journey (for motivation)
  static Future<int?> getDaysUntilCompletion(HybridDataService dataService) async {
    try {
      final profile = await dataService.getUserProfile();
      final goal = await dataService.getUserGoal();

      if (profile == null || goal == null) return null;

      final daysSinceStart = DateTime.now().difference(profile.createdAt).inDays;
      final daysRemaining = goal.days - daysSinceStart;

      return daysRemaining > 0 ? daysRemaining : 0;
    } catch (e) {
      print('JourneyCompletionService: Error getting days until completion: $e');
      return null;
    }
  }

  // Get journey progress percentage
  static Future<double> getJourneyProgress(HybridDataService dataService) async {
    try {
      final profile = await dataService.getUserProfile();
      final goal = await dataService.getUserGoal();

      if (profile == null || goal == null) return 0.0;

      final daysSinceStart = DateTime.now().difference(profile.createdAt).inDays;
      final progress = (daysSinceStart / goal.days).clamp(0.0, 1.0);

      return progress;
    } catch (e) {
      print('JourneyCompletionService: Error getting journey progress: $e');
      return 0.0;
    }
  }

  // Reset celebration status (for testing or if user wants to see it again)
  static Future<void> resetCelebrationStatus(String userId, int goalDays) async {
    final prefs = await SharedPreferences.getInstance();
    final celebrationKey = _celebrationShownKey + userId + '_' + goalDays.toString();
    await prefs.remove(celebrationKey);
  }
}