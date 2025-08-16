import 'package:flutter/material.dart';
import 'package:zeno/src/widgets/app_menu_button.dart';
import 'food_calculators.dart';
import 'activity_calculators.dart';
import 'other_calculators.dart';

class CalculatorScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const CalculatorScreen({super.key, this.onNavigateToTab});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculators'),
        actions: [AppMenuButton(onNavigateToTab: widget.onNavigateToTab)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Food'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Activity'),
            Tab(icon: Icon(Icons.calculate), text: 'Others'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FoodCalculatorTab(),
          ActivityCalculatorTab(),
          OtherCalculatorTab(),
        ],
      ),
    );
  }
}