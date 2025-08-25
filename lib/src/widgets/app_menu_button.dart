import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zeno/src/screens/main_screen.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';
import 'package:zeno/src/services/subscription_service.dart';
import 'package:zeno/src/services/hybrid_data_service.dart';
import '../../../main.dart'; // ThemeController and ServiceProvider

class AppMenuButton extends StatelessWidget {
  final VoidCallback? onSignOut;
  final VoidCallback? onEditProfileAndGoal;
  final Function(int)? onNavigateToTab;

  const AppMenuButton({
    super.key,
    this.onSignOut,
    this.onEditProfileAndGoal,
    this.onNavigateToTab,
  });

  void _go(BuildContext context, int index) {
    if (onNavigateToTab != null) {
      // Use callback if available (preferred method)
      onNavigateToTab!(index);
    } else {
      // Fallback to navigation (for standalone usage)
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MainScreen(initialIndex: index),
      ));
    }
  }

  void _handleEditProfileAndGoal(BuildContext context) {
    if (onEditProfileAndGoal != null) {
      onEditProfileAndGoal!();
    } else {
      // Fallback navigation
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const GoalSettingScreen(),
      ));
    }
  }

  void _handleSignOut(BuildContext context) async {
    if (onSignOut != null) {
      onSignOut!();
    } else {
      // Fallback sign out using the hybrid data service
      try {
        final dataService = ServiceProvider.of(context).hybridDataService;
        await dataService.signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.of(context);
    final subscriptionService = ServiceProvider.of(context).subscriptionService;

    return ListenableBuilder(
      // Listen to both theme and subscription changes
      listenable: Listenable.merge([controller.themeMode, subscriptionService]),
      builder: (context, _) {
        final ThemeMode current = controller.themeMode.value;
        final bool isDark = current == ThemeMode.dark;
        final bool isSystem = current == ThemeMode.system;

        return PopupMenuButton<_AppMenuAction>(
          tooltip: 'Menu',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case _AppMenuAction.home:
                _go(context, 0);
                break;
              case _AppMenuAction.progress:
                _go(context, 3);
                break;
              case _AppMenuAction.logFood:
                _go(context, 1);
                break;
              case _AppMenuAction.logActivity:
                _go(context, 2);
                break;
              case _AppMenuAction.tips:
                _go(context, 4);
                break;
              case _AppMenuAction.calculators:
                _go(context, 5);
                break;
              case _AppMenuAction.editProfileGoal:
                _handleEditProfileAndGoal(context);
                break;
              case _AppMenuAction.signOut:
              // Show confirmation dialog
                final shouldSignOut = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (shouldSignOut == true && context.mounted) {
                  _handleSignOut(context);
                }
                break;
              case _AppMenuAction.lightTheme:
                controller.setThemeMode(ThemeMode.light);
                break;
              case _AppMenuAction.darkTheme:
                controller.setThemeMode(ThemeMode.dark);
                break;
              case _AppMenuAction.systemTheme:
                controller.setThemeMode(ThemeMode.system);
                break;
              case _AppMenuAction.debugTogglePremium:
                await subscriptionService.toggleDebugPremium();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        subscriptionService.debugPremiumOverride
                            ? '🔓 Debug Premium Mode ENABLED'
                            : '🔒 Debug Premium Mode DISABLED',
                      ),
                      backgroundColor: subscriptionService.debugPremiumOverride
                          ? Colors.orange
                          : Colors.grey,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                break;
            }
          },
          itemBuilder: (context) {
            List<PopupMenuEntry<_AppMenuAction>> items = [
              // Navigation section
              const PopupMenuItem(
                enabled: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Navigate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: _AppMenuAction.home,
                child: ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _AppMenuAction.progress,
                child: ListTile(
                  leading: Icon(Icons.timeline),
                  title: Text('Progress'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _AppMenuAction.logFood,
                child: ListTile(
                  leading: Icon(Icons.restaurant),
                  title: Text('Log Food'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _AppMenuAction.logActivity,
                child: ListTile(
                  leading: Icon(Icons.fitness_center),
                  title: Text('Log Activity'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _AppMenuAction.tips,
                child: ListTile(
                  leading: Icon(Icons.lightbulb),
                  title: Text('Tips & Recipes'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _AppMenuAction.calculators,
                child: ListTile(
                  leading: Icon(Icons.calculate),
                  title: Text('Calculators'),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),

              // Subscription status
              const PopupMenuItem(
                enabled: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Account',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                enabled: false,
                child: ListTile(
                  leading: Icon(
                    subscriptionService.isPremium ? Icons.star : Icons.star_border,
                    color: subscriptionService.subscriptionStatusColor,
                  ),
                  title: Text(
                    'Status: ${subscriptionService.subscriptionStatusText}',
                    style: TextStyle(
                      color: subscriptionService.subscriptionStatusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  dense: true,
                ),
              ),
            ];

            // Debug section - only show in debug mode
            if (kDebugMode) {
              items.addAll([
                const PopupMenuDivider(),
                const PopupMenuItem(
                  enabled: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '🐛 Debug Controls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: _AppMenuAction.debugTogglePremium,
                  child: ListTile(
                    leading: Icon(
                      subscriptionService.debugPremiumOverride
                          ? Icons.toggle_on
                          : Icons.toggle_off,
                      color: subscriptionService.debugPremiumOverride
                          ? Colors.orange
                          : Colors.grey,
                    ),
                    title: Text(
                      subscriptionService.debugPremiumOverride
                          ? 'Disable Debug Premium'
                          : 'Enable Debug Premium',
                      style: const TextStyle(fontSize: 14),
                    ),
                    dense: true,
                  ),
                ),
              ]);
            }

            // Theme and settings section
            items.addAll([
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Theme',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                value: current == ThemeMode.light ? null : _AppMenuAction.lightTheme,
                child: ListTile(
                  leading: Icon(
                    Icons.light_mode,
                    color: current == ThemeMode.light ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(
                    'Light Theme',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: current == ThemeMode.light ? FontWeight.bold : FontWeight.normal,
                      color: current == ThemeMode.light ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  trailing: current == ThemeMode.light ? const Icon(Icons.check, size: 16) : null,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: current == ThemeMode.dark ? null : _AppMenuAction.darkTheme,
                child: ListTile(
                  leading: Icon(
                    Icons.dark_mode,
                    color: current == ThemeMode.dark ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(
                    'Dark Theme',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: current == ThemeMode.dark ? FontWeight.bold : FontWeight.normal,
                      color: current == ThemeMode.dark ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  trailing: current == ThemeMode.dark ? const Icon(Icons.check, size: 16) : null,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: current == ThemeMode.system ? null : _AppMenuAction.systemTheme,
                child: ListTile(
                  leading: Icon(
                    Icons.settings_suggest,
                    color: current == ThemeMode.system ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(
                    'System Theme',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: current == ThemeMode.system ? FontWeight.bold : FontWeight.normal,
                      color: current == ThemeMode.system ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  trailing: current == ThemeMode.system ? const Icon(Icons.check, size: 16) : null,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),

              // Settings section
              const PopupMenuItem(
                enabled: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: _AppMenuAction.editProfileGoal,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit Profile & Goal', style: TextStyle(fontSize: 14)),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _AppMenuAction.signOut,
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 14)),
                  dense: true,
                ),
              ),
            ]);

            return items;
          },
        );
      },
    );
  }
}

enum _AppMenuAction {
  home,
  progress,
  logFood,
  logActivity,
  tips,
  calculators,
  editProfileGoal,
  signOut,
  lightTheme,
  darkTheme,
  systemTheme,
  debugTogglePremium,
}