import 'package:flutter/material.dart';
import 'package:zeno/src/screens/progress_screen.dart';
import 'package:zeno/src/screens/log_food_screen.dart';
import 'package:zeno/src/screens/log_activity_screen.dart';
import 'package:zeno/src/screens/tips_screen.dart';
import 'package:zeno/src/screens/home_screen.dart';
import '../../../main.dart'; // for ThemeController

/// A single overflow menu button to replace clusters of AppBar icons.
/// Shows navigation shortcuts and a Dark Theme switch.
class AppMenuButton extends StatelessWidget {
  final VoidCallback? onSignOut;
  final VoidCallback? onEditProfileAndGoal;

  const AppMenuButton({
    super.key,
    this.onSignOut,
    this.onEditProfileAndGoal,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.of(context);
    final ThemeMode current = controller.themeMode.value;
    final bool isDark = current == ThemeMode.dark;

    return PopupMenuButton<_AppMenuAction>(
      tooltip: 'Menu',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case _AppMenuAction.home:
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
            break;
          case _AppMenuAction.progress:
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
            break;
          case _AppMenuAction.logFood:
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogFoodScreen()));
            break;
          case _AppMenuAction.logActivity:
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogActivityScreen()));
            break;
          case _AppMenuAction.tips:
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TipsScreen()));
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
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<_AppMenuAction>>[
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
        // Appearance section
        PopupMenuItem<_AppMenuAction>(
          enabled: false,
          child: Text('Appearance', style: Theme.of(context).textTheme.labelLarge),
        ),
        PopupMenuItem<_AppMenuAction>(
          value: _AppMenuAction.toggleDark,
          child: StatefulBuilder(
            builder: (context, setState) {
              final ThemeMode mode = ThemeController.of(context).themeMode.value;
              final bool isDark = mode == ThemeMode.dark;
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark theme'),
                value: isDark,
                onChanged: (_) {
                  Navigator.of(context).pop(); // close the menu so the switch feels responsive
                  ThemeController.of(context).setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              );
            },
          ),
        ),
        const PopupMenuItem(
          value: _AppMenuAction.systemTheme,
          child: ListTile(leading: Icon(Icons.settings_suggest), title: Text('Use system theme')),
        ),
        const PopupMenuDivider(),
        // Account / settings section
        const PopupMenuItem(
          value: _AppMenuAction.editProfileGoal,
          child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Profile & Goal')),
        ),
        const PopupMenuItem(
          value: _AppMenuAction.signOut,
          child: ListTile(leading: Icon(Icons.logout), title: Text('Sign out')),
        ),
      ],
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
}
