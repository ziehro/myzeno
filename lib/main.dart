import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zeno/firebase_options.dart';
import 'package:zeno/src/screens/auth_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase using the auto-generated options file
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
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // The AuthWrapper now decides the first screen to show
      home: const AuthWrapper(),
    );
  }
}