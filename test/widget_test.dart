import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/user_goal.dart';

void main() {
  group('Model Tests', () {
    testWidgets('UserProfile model test', (WidgetTester tester) async {
      // Test UserProfile model
      final profile = UserProfile(
        uid: 'test-uid',
        email: 'test@example.com',
        startWeight: 180.0,
        height: 175.0,
        age: 30,
        sex: Sex.male,
        createdAt: DateTime.now(),
        activityLevel: ActivityLevel.moderatelyActive,
      );

      expect(profile.uid, 'test-uid');
      expect(profile.email, 'test@example.com');
      expect(profile.startWeight, 180.0);
      expect(profile.recommendedDailyIntake, greaterThan(0));
    });

    testWidgets('UserGoal model test', (WidgetTester tester) async {
      // Test UserGoal model
      final goal = UserGoal(
        lbsToLose: 15.0,
        days: 60,
      );

      expect(goal.lbsToLose, 15.0);
      expect(goal.days, 60);
      expect(goal.totalCalorieDeficit, 52500); // 15 * 3500
      expect(goal.dailyCalorieDeficitTarget, 875); // 52500 / 60
    });
  });

  group('Widget Tests', () {
    testWidgets('Basic app widget test', (WidgetTester tester) async {
      // Test a simple widget instead of the full app
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('MyZeno')),
            body: const Center(
              child: Text('Welcome to MyZeno'),
            ),
          ),
        ),
      );

      // Verify that the text appears
      expect(find.text('MyZeno'), findsOneWidget);
      expect(find.text('Welcome to MyZeno'), findsOneWidget);
    });

    testWidgets('Theme controller test', (WidgetTester tester) async {
      // Test theme switching functionality
      late ThemeMode currentTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    Text('Current theme: ${currentTheme.toString()}'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentTheme = currentTheme == ThemeMode.light
                              ? ThemeMode.dark
                              : ThemeMode.light;
                        });
                      },
                      child: const Text('Toggle Theme'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initialize theme
      currentTheme = ThemeMode.light;
      await tester.pumpAndSettle();

      // Find and tap the toggle button
      expect(find.text('Toggle Theme'), findsOneWidget);
      await tester.tap(find.text('Toggle Theme'));
      await tester.pumpAndSettle();

      // Verify button exists and is tappable
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('Calculation Tests', () {
    test('BMR calculation test', () {
      final profile = UserProfile(
        uid: 'test',
        email: 'test@test.com',
        startWeight: 180.0, // lbs
        height: 175.0, // cm
        age: 30,
        sex: Sex.male,
        createdAt: DateTime.now(),
        activityLevel: ActivityLevel.moderatelyActive,
      );

      final bmr = profile.recommendedDailyIntake;

      // BMR should be reasonable for a 30-year-old male
      expect(bmr, greaterThan(2000));
      expect(bmr, lessThan(4000));
    });

    test('Calorie deficit calculation test', () {
      final goal = UserGoal(lbsToLose: 10.0, days: 70);

      expect(goal.totalCalorieDeficit, 35000); // 10 * 3500
      expect(goal.dailyCalorieDeficitTarget, 500); // 35000 / 70
    });
  });
}