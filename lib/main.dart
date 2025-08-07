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

/// Simple app-level theme controller without external deps.
class ThemeController extends InheritedWidget {
  final ValueNotifier<ThemeMode> themeMode;
  final void Function(ThemeMode) setThemeMode;

  const ThemeController({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required Widget child,
  }) : super(child: child);

  static ThemeController of(BuildContext context) {
    final ThemeController? result = context.dependOnInheritedWidgetOfExactType<ThemeController>();
    assert(result != null, 'No ThemeController found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ThemeController old) => old.themeMode != themeMode;
}

class MyZenoApp extends StatefulWidget {
  const MyZenoApp({super.key});

  @override
  State<MyZenoApp> createState() => _MyZenoAppState();
}

class _MyZenoAppState extends State<MyZenoApp> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  void _setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      themeMode: _themeMode,
      setThemeMode: _setThemeMode,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'MyZeno',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
