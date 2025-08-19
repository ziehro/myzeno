import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zeno/firebase_options.dart';
import 'package:zeno/src/screens/auth_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/src/services/subscription_service.dart';
import 'package:zeno/src/services/hybrid_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required even for free users for auth)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize services
  final subscriptionService = SubscriptionService();
  final hybridDataService = HybridDataService();

  runApp(MyZenoApp(
    subscriptionService: subscriptionService,
    hybridDataService: hybridDataService,
  ));
}

/// Enhanced app-level theme controller with service injection
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

/// Service provider for dependency injection
class ServiceProvider extends InheritedWidget {
  final SubscriptionService subscriptionService;
  final HybridDataService hybridDataService;

  const ServiceProvider({
    super.key,
    required this.subscriptionService,
    required this.hybridDataService,
    required Widget child,
  }) : super(child: child);

  static ServiceProvider of(BuildContext context) {
    final ServiceProvider? result = context.dependOnInheritedWidgetOfExactType<ServiceProvider>();
    assert(result != null, 'No ServiceProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ServiceProvider old) =>
      old.subscriptionService != subscriptionService ||
          old.hybridDataService != hybridDataService;
}

class MyZenoApp extends StatefulWidget {
  final SubscriptionService subscriptionService;
  final HybridDataService hybridDataService;

  const MyZenoApp({
    super.key,
    required this.subscriptionService,
    required this.hybridDataService,
  });

  @override
  State<MyZenoApp> createState() => _MyZenoAppState();
}

class _MyZenoAppState extends State<MyZenoApp> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  void _setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
  }

  @override
  void initState() {
    super.initState();

    // Listen to subscription changes
    widget.subscriptionService.addListener(_onSubscriptionChanged);

    // Perform initial maintenance
    _performInitialSetup();
  }

  @override
  void dispose() {
    widget.subscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    // Handle subscription tier changes
    widget.hybridDataService.onSubscriptionChanged();
  }

  Future<void> _performInitialSetup() async {
    // Perform maintenance tasks (cleanup old data for free users)
    await widget.hybridDataService.performMaintenance();
  }

  @override
  Widget build(BuildContext context) {
    return ServiceProvider(
      subscriptionService: widget.subscriptionService,
      hybridDataService: widget.hybridDataService,
      child: ThemeController(
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
      ),
    );
  }
}