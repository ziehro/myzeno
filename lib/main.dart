import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zeno/firebase_options.dart';
import 'package:zeno/src/screens/auth_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyZenoApp());
}

class MyZenoApp extends StatelessWidget {
  const MyZenoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyZeno',
      debugShowCheckedModeBanner: false,

      // --- THE THEME CONFIGURATION ---
      theme: AppTheme.lightTheme,      // Sets the default light theme.
      darkTheme: AppTheme.darkTheme,  // Sets the dark theme.
      themeMode: ThemeMode.system,    // This tells the app to automatically switch!
      // -------------------------------

      home: const AuthWrapper(),
    );
  }
}