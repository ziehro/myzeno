import 'package:flutter/material.dart';
import 'package:zeno/src/screens/main_screen.dart';
import '../../../main.dart'; // ThemeController

class AppMenuButton extends StatelessWidget {
  final VoidCallback? onSignOut;
  final VoidCallback? onEditProfileAndGoal;

  const AppMenuButton({
    super.key,
    this.onSignOut,
    this.onEditProfileAndGoal,
  });

  void _go(BuildContext context, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MainScreen(initialIndex: index),
    ));
  }

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
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _AppMenuAction.home,
          child: ListTile(leading: Icon(Icons.home), title: Text('Home')),
        ),
        PopupMenuItem(
          value: _AppMenuAction.progress,
          child: ListTile(leading: Icon(Icons.timeline), title: Text('Progress')),
        ),
        PopupMenuItem(
          value: _AppMenuAction.logFood,
          child: ListTile(leading: Icon(Icons.restaurant), title: Text('Log Food')),
        ),
        PopupMenuItem(
          value: _AppMenuAction.logActivity,
          child: ListTile(leading: Icon(Icons.fitness_center), title: Text('Log Activity')),
        ),
        PopupMenuItem(
          value: _AppMenuAction.tips,
          child: ListTile(leading: Icon(Icons.lightbulb), title: Text('Tips')),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          child: Text('Appearance'),
        ),
        PopupMenuItem(
          value: _AppMenuAction.toggleDark,
          child: ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('Dark theme (toggle)'),
          ),
        ),
        PopupMenuItem(
          value: _AppMenuAction.systemTheme,
          child: ListTile(leading: Icon(Icons.settings_suggest), title: Text('Use system theme')),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _AppMenuAction.editProfileGoal,
          child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Profile & Goal')),
        ),
        PopupMenuItem(
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
