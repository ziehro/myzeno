import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickTipsCard extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const QuickTipsCard({super.key, this.onNavigateToTab});

  @override
  State<QuickTipsCard> createState() => _QuickTipsCardState();
}

class _QuickTipsCardState extends State<QuickTipsCard> {
  bool _isVisible = true;
  int _currentTipIndex = 0;

  final List<Map<String, dynamic>> _tips = [
    {
      'title': '🍎 Log Everything You Eat',
      'description': 'Even small snacks add up! Track every calorie to stay on target.',
      'action': 'Log Food',
      'actionTab': 1,
      'icon': Icons.restaurant_menu,
      'color': Colors.orange,
    },
    {
      'title': '🏃‍♂️ Add Your Workouts',
      'description': 'Exercise burns extra calories and gets you to your goal faster!',
      'action': 'Log Activity',
      'actionTab': 2,
      'icon': Icons.fitness_center,
      'color': Colors.green,
    },
    {
      'title': '⚖️ Weigh Yourself Daily',
      'description': 'Daily weigh-ins help you track real progress vs. theoretical.',
      'action': 'Log Weight',
      'actionTab': null,
      'icon': Icons.monitor_weight,
      'color': Colors.blue,
    },
    {
      'title': '📊 Check Your Progress',
      'description': 'See how well you\'re sticking to your calorie deficit plan.',
      'action': 'View Progress',
      'actionTab': 3,
      'icon': Icons.timeline,
      'color': Colors.purple,
    },
    {
      'title': '🧮 Use Calculators',
      'description': 'Calculate calories for recipes, activities, and more!',
      'action': 'Open Calculators',
      'actionTab': 5,
      'icon': Icons.calculate,
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTipIndex();
  }

  Future<void> _loadTipIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('current_tip_index') ?? 0;
    final lastShown = prefs.getString('last_tip_shown');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastShown != today) {
      // Show new tip each day
      final newIndex = (savedIndex + 1) % _tips.length;
      await prefs.setInt('current_tip_index', newIndex);
      await prefs.setString('last_tip_shown', today);
      setState(() {
        _currentTipIndex = newIndex;
      });
    } else {
      setState(() {
        _currentTipIndex = savedIndex;
      });
    }
  }

  Future<void> _dismissCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tips_dismissed_today', true);
    setState(() {
      _isVisible = false;
    });
  }

  Future<void> _nextTip() async {
    final newIndex = (_currentTipIndex + 1) % _tips.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_tip_index', newIndex);

    setState(() {
      _currentTipIndex = newIndex;
    });
  }

  void _handleAction() {
    final tip = _tips[_currentTipIndex];
    if (tip['actionTab'] != null && widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tip['actionTab']);
    }
    // For "Log Weight", we'll just dismiss the card since it's handled in the main screen
    if (tip['actionTab'] == null) {
      _dismissCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final currentTip = _tips[_currentTipIndex];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              currentTip['color'].withOpacity(0.1),
              currentTip['color'].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: currentTip['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      currentTip['icon'],
                      color: currentTip['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Tip',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: currentTip['color'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentTip['title'],
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _nextTip,
                        icon: Icon(
                          Icons.refresh,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        tooltip: 'Next tip',
                      ),
                      IconButton(
                        onPressed: _dismissCard,
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                currentTip['description'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleAction,
                      icon: Icon(
                        currentTip['icon'],
                        size: 16,
                      ),
                      label: Text(currentTip['action']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentTip['color'],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentTipIndex + 1}/${_tips.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}