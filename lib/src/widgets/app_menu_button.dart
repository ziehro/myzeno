import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zeno/src/screens/main_screen.dart';
import 'package:zeno/src/services/subscription_service.dart';
import '../../../main.dart'; // ThemeController

class AppMenuButton extends StatelessWidget {
  final VoidCallback? onSignOut;
  final VoidCallback? onEditProfileAndGoal;
  final Function(int)? onNavigateToTab; // Add navigation callback

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

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.of(context);
    final ThemeMode current = controller.themeMode.value;
    final bool isDark = current == ThemeMode.dark;
    final subscriptionService = SubscriptionService();

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
          case _AppMenuAction.editProfileGoal:
            onEditProfileAndGoal?.call();
            break;
          case _AppMenuAction.signOut:
            onSignOut?.call();
            break;
          case _AppMenuAction.toggleDark:
            controller.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
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
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<_AppMenuAction>> items = [
          const PopupMenuItem(
            value: _AppMenuAction.home,
            child: ListTile(leading: Icon(Icons.home), title: Text('Home')),
          ),
          const PopupMenuItem(
            value: _AppMenuAction.progress,
            child: ListTile(leading: Icon(Icons.timeline), title: Text('Progress')),
          ),
          const PopupMenuItem(
            value: _AppMenuAction.logFood,
            child: ListTile(leading: Icon(Icons.restaurant), title: Text('Log Food')),
          ),
          const PopupMenuItem(
            value: _AppMenuAction.logActivity,
            child: ListTile(leading: Icon(Icons.fitness_center), title: Text('Log Activity')),
          ),
          const PopupMenuItem(
            value: _AppMenuAction.tips,
            child: ListTile(leading: Icon(Icons.lightbulb), title: Text('Tips')),
          ),
          const PopupMenuDivider(),
        ];

        // Add subscription status
        items.add(
          PopupMenuItem(
            enabled: false,
            child: ListenableBuilder(
              listenable: subscriptionService,
              builder: (context, _) {
                return ListTile(
                  leading: Icon(
                    subscriptionService.isPremium ? Icons.star : Icons.star_border,
                    color: subscriptionService.subscriptionStatusColor,
                  ),
                  title: Text(
                    'Status: ${subscriptionService.subscriptionStatusText}',
                    style: TextStyle(
                      color: subscriptionService.subscriptionStatusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Debug section - only show in debug mode
        if (kDebugMode) {
          items.addAll([
            const PopupMenuDivider(),
            const PopupMenuItem(
              enabled: false,
              child: Text('🐛 Debug Controls', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            PopupMenuItem(
              value: _AppMenuAction.debugTogglePremium,
              child: ListenableBuilder(
                listenable: subscriptionService,
                builder: (context, _) {
                  return ListTile(
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
                    ),
                  );
                },
              ),
            ),
          ]);
        }

        // Regular menu items
        items.addAll([
          const PopupMenuDivider(),
          const PopupMenuItem(
            enabled: false,
            child: Text('Appearance'),
          ),
          const PopupMenuItem(
            value: _AppMenuAction.toggleDark,
            child: ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark theme (toggle)'),
            ),
          ),
          const PopupMenuItem(
            value: _AppMenuAction.systemTheme,
            child: ListTile(leading: Icon(Icons.settings_suggest), title: Text('Use system theme')),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _AppMenuAction.editProfileGoal,
            child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Profile & Goal')),
          ),
          const PopupMenuItem(
            value: _AppMenuAction.signOut,
            child: ListTile(leading: Icon(Icons.logout), title: Text('Sign out')),
          ),
        ]);

        return items;
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
  editProfileGoal,
  signOut,
  toggleDark,
  systemTheme,
  debugTogglePremium,
}