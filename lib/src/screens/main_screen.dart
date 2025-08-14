import 'package:flutter/material.dart';
import 'package:zeno/src/screens/home_screen.dart';
import 'package:zeno/src/screens/log_activity_screen.dart';
import 'package:zeno/src/screens/log_food_screen.dart';
import 'package:zeno/src/screens/progress_screen.dart';
import 'package:zeno/src/screens/tips_screen.dart';
import 'package:zeno/src/screens/calculator_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  // Add this method to handle navigation from child screens
  void _navigateToTab(int index) {
    _onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    // Create pages with navigation callback
    final List<Widget> pages = [
      HomeScreen(onNavigateToTab: _navigateToTab),
      LogFoodScreen(onNavigateToTab: _navigateToTab),
      LogActivityScreen(onNavigateToTab: _navigateToTab),
      ProgressScreen(onNavigateToTab: _navigateToTab),
      TipsScreen(onNavigateToTab: _navigateToTab),
      CalculatorScreen(onNavigateToTab: _navigateToTab),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Food'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Tips'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Calculator'),
        ],
      ),
    );
  }
}