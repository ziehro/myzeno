import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zeno/firebase_options.dart';
import 'package:zeno/src/screens/auth_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/src/services/subscription_service.dart';
import 'package:zeno/src/services/hybrid_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase (required even for free users for auth)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue anyway - the app can still work with local storage
  }

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

    // CRITICAL: Listen for subscription changes and trigger data migration
    widget.subscriptionService.addListener(() {
      widget.hybridDataService.onSubscriptionChanged();
    });

    // Perform initial maintenance
    _performInitialSetup();
  }

  @override
  void dispose() {
    widget.subscriptionService.removeListener(_onSubscriptionChanged);
    _themeMode.dispose();
    super.dispose();
  }

  void _onSubscriptionChanged() {
    // Handle subscription tier changes
    widget.hybridDataService.onSubscriptionChanged();
  }

  Future<void> _performInitialSetup() async {
    try {
      // Perform maintenance tasks (cleanup old data for free users)
      await widget.hybridDataService.performMaintenance();
    } catch (e) {
      print('Error during initial setup: $e');
      // Continue anyway - don't block app startup
    }
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
              // Add error handling for the entire app
              builder: (context, child) {
                // Global error boundary
                ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            'Oops! Something went wrong',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please restart the app',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Try to recover by rebuilding the widget tree
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                                      (route) => false,
                                );
                              }
                            },
                            child: const Text('Restart App'),
                          ),
                        ],
                      ),
                    ),
                  );
                };
                return child ?? const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}