import 'package:flutter/material.dart';
import 'package:zeno/src/screens/home_screen.dart';
import 'package:zeno/src/screens/log_activity_screen.dart';
import 'package:zeno/src/screens/log_food_screen.dart';
import 'package:zeno/src/screens/progress_screen.dart';
import 'package:zeno/src/screens/tips_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomeScreen(),
    const LogFoodScreen(),
    const LogActivityScreen(),
    const ProgressScreen(),
    const TipsScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Tips',
          ),
        ],
        type: BottomNavigationBarType.fixed, // This ensures all labels are visible
      ),
    );
  }
}