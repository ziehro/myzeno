import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';
import 'package:zeno/src/screens/login_screen.dart';
import 'package:zeno/src/screens/main_screen.dart';
import 'package:zeno/src/screens/onboarding_screen.dart';
import 'package:zeno/src/services/hybrid_data_service.dart';
import 'package:zeno/main.dart'; // For ServiceProvider

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = ServiceProvider.of(context).hybridDataService;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // User is not signed in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // User is signed in, check if profile exists
        return FutureBuilder<bool>(
          future: _checkUserSetup(dataService),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Setting up your profile...'),
                    ],
                  ),
                ),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Error: ${profileSnapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Force rebuild
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Check if user has completed setup
            final hasProfile = profileSnapshot.data ?? false;

            if (hasProfile) {
              // Profile exists, go to main app
              return const MainScreen();
            } else {
              // No profile, check if this is first time user
              return FutureBuilder<bool>(
                future: _isFirstTimeUser(),
                builder: (context, firstTimeSnapshot) {
                  if (firstTimeSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final isFirstTime = firstTimeSnapshot.data ?? true;

                  if (isFirstTime) {
                    // Show onboarding for new users
                    return const OnboardingScreen();
                  } else {
                    // Returning user without profile, go straight to goal setting
                    return const GoalSettingScreen();
                  }
                },
              );
            }
          },
        );
      },
    );
  }

  Future<bool> _checkUserSetup(HybridDataService dataService) async {
    try {
      final profile = await dataService.getUserProfile();
      final goal = await dataService.getUserGoal();

      print('Checking user setup - Profile: ${profile != null}, Goal: ${goal != null}');

      // Both profile and goal must exist for complete setup
      return profile != null && goal != null;
    } catch (e) {
      print('Error checking user setup: $e');
      return false;
    }
  }

  Future<bool> _isFirstTimeUser() async {
    try {
      // Check if user has ever signed in before by checking Firebase Auth metadata
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return true;

      // If account was created recently (within last hour), show onboarding
      final creationTime = user.metadata.creationTime;
      if (creationTime != null) {
        final hoursSinceCreation = DateTime.now().difference(creationTime).inHours;
        return hoursSinceCreation < 1;
      }

      return false;
    } catch (e) {
      print('Error checking if first time user: $e');
      return true; // Default to showing onboarding if we can't determine
    }
  }
}