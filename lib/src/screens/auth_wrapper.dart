import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';
import 'package:zeno/src/screens/login_screen.dart';
import 'package:zeno/src/screens/main_screen.dart'; // Import the new main screen
import 'package:zeno/src/services/firebase_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<User?>(
      stream: firebaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: firebaseService.checkIfUserProfileExists(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (profileSnapshot.data == true) {
                // Profile exists, go to the new MainScreen.
                return const MainScreen();
              } else {
                // No profile, go to GoalSettingScreen to create one.
                return const GoalSettingScreen();
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}