// lib/src/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:zeno/main.dart'; // ServiceProvider
import 'package:zeno/src/screens/login_screen.dart';
import 'package:zeno/src/screens/main_screen.dart';
import 'package:zeno/src/screens/onboarding_screen.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';

import 'package:zeno/src/services/hybrid_data_service.dart';
import 'package:zeno/src/services/subscription_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = ServiceProvider.of(context).hybridDataService;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // Initial / waiting
        if (snap.connectionState == ConnectionState.waiting) {
          return const _FullScreenMessage(
            icon: Icons.hourglass_empty,
            title: 'Loading...',
            subtitle: 'Please wait while we check your session.',
            busy: true,
          );
        }

        // Signed-out → Login
        if (!snap.hasData || snap.data == null) {
          return const LoginScreen();
        }

        // Signed-in → check local/cloud profile+goal via HybridDataService
        return FutureBuilder<bool>(
          future: _checkHasCompleteSetup(dataService),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const _FullScreenMessage(
                icon: Icons.person_search,
                title: 'Setting up your profile...',
                subtitle: 'Fetching your info.',
                busy: true,
              );
            }

            if (profileSnap.hasError) {
              return _FullScreenError(
                error: profileSnap.error,
                onRetry: () => (context as Element).markNeedsBuild(),
              );
            }

            final hasProfileAndGoal = profileSnap.data ?? false;
            if (hasProfileAndGoal) {
              return const MainScreen();
            } else {
              return _MissingProfileScreen(dataService: dataService);
            }
          },
        );
      },
    );
  }

  Future<bool> _checkHasCompleteSetup(HybridDataService data) async {
    try {
      final p = await data.getUserProfile();
      final g = await data.getUserGoal();
      return p != null && g != null;
    } catch (_) {
      return false;
    }
  }
}

class _MissingProfileScreen extends StatefulWidget {
  final HybridDataService dataService;
  const _MissingProfileScreen({required this.dataService});

  @override
  State<_MissingProfileScreen> createState() => _MissingProfileScreenState();
}

class _MissingProfileScreenState extends State<_MissingProfileScreen> {
  bool _checkingCloud = false;
  bool _migrating = false;

  HybridDataService get _data => widget.dataService;
  SubscriptionService get _subs => ServiceProvider.of(context).subscriptionService;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_sync, size: 84, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Signed in as: ${user?.email ?? 'Unknown'}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'We couldn’t find your profile on this device.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose how you’d like to continue:',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_subs.canAccessCloudSync) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_checkingCloud || _migrating) ? null : _onRestoreFromCloud,
                    icon: _checkingCloud
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cloud_download),
                    label: Text(_checkingCloud ? 'Checking Cloud Data...' : 'Restore from Cloud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'OR',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Start fresh
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_checkingCloud || _migrating) ? null : _onStartFresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start Fresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: (_checkingCloud || _migrating) ? null : _onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out & Use Different Account'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              ),

              if (_migrating) ...[
                const SizedBox(height: 20),
                _InlineProgress(text: 'Restoring your data from the cloud...'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRestoreFromCloud() async {
    setState(() => _checkingCloud = true);

    try {
      // 👇 Requires the two tiny public methods on HybridDataService
      final cloudProfile = await _data.getCloudUserProfileDirect();
      final cloudGoal = await _data.getCloudUserGoalDirect();

      if (cloudProfile != null && cloudGoal != null) {
        // Temporarily ensure cloud access if needed (debug override allowed in debug builds)
        if (!_subs.canAccessCloudSync && _subs.isDebugMode) {
          await _subs.setDebugPremium(true);
        }

        setState(() {
          _checkingCloud = false;
          _migrating = true;
        });

        // Trigger HybridDataService to migrate data (cloud -> local or ensure cloud state consistent)
        _data.onSubscriptionChanged();

        // Give the migration a moment (your migration already batches with small delays)
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() => _checkingCloud = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data found in the cloud. You can start fresh!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _checkingCloud = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking cloud data: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onStartFresh() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final creation = user.metadata.creationTime;
    final isNew = creation != null && DateTime.now().difference(creation).inHours < 1;

    if (isNew) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GoalSettingScreen()));
    }
  }

  Future<void> _onSignOut() async {
    try {
      await _data.signOut();
      // Auth stream will rebuild to LoginScreen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _InlineProgress extends StatelessWidget {
  final String text;
  const _InlineProgress({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.blue.shade700))),
        ],
      ),
    );
  }
}

class _FullScreenMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool busy;

  const _FullScreenMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
              if (busy) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _FullScreenError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 72, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Error', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
