import 'package:flutter/material.dart';
import 'package:zeno/src/widgets/app_menu_button.dart';
import 'package:zeno/src/widgets/paywall_widget.dart';
import 'package:zeno/src/services/subscription_service.dart';
import 'package:zeno/main.dart'; // For ServiceProvider
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
  late SubscriptionService _subscriptionService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscriptionService = ServiceProvider.of(context).subscriptionService;
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
        title: ListenableBuilder(
          listenable: _subscriptionService,
          builder: (context, _) {
            return Row(
              children: [
                const Text('Calculators'),
                if (_subscriptionService.isFree) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'LIMITED',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          ListenableBuilder(
            listenable: _subscriptionService,
            builder: (context, _) {
              return _subscriptionService.isFree
                  ? IconButton(
                onPressed: _showUpgradeDialog,
                icon: const Icon(Icons.star_outline),
                tooltip: 'Unlock All Calculators',
              )
                  : const SizedBox.shrink();
            },
          ),
          AppMenuButton(onNavigateToTab: widget.onNavigateToTab),
        ],
        bottom: _SubscriptionAwareTabBar(
          controller: _tabController,
          subscriptionService: _subscriptionService,
        ),
      ),
      body: ListenableBuilder(
        listenable: _subscriptionService,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Food calculators - Basic access for free users
              _buildFoodCalculatorsTab(),

              // Activity calculators - Basic access for free users
              _buildActivityCalculatorsTab(),

              // Other calculators - Premium only
              FeatureGate(
                feature: 'advanced_calculators',
                child: const OtherCalculatorTab(),
                fallback: PaywallWidget(
                  feature: 'advanced_calculators',
                  customTitle: 'Advanced Calculators',
                  customDescription: 'Unlock BMR, BMI, Alcohol, and Water intake calculators with detailed analysis and recommendations.',
                  child: const OtherCalculatorTab(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFoodCalculatorsTab() {
    return ListenableBuilder(
      listenable: _subscriptionService,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_subscriptionService.isFree) _buildLimitedAccessBanner('food'),
              const FoodCalculatorTabContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCalculatorsTab() {
    return ListenableBuilder(
      listenable: _subscriptionService,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_subscriptionService.isFree) _buildLimitedAccessBanner('activity'),
              const ActivityCalculatorTabContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLimitedAccessBanner(String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Version - Basic Calculator',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Upgrade to Premium for advanced ${type} calculators and detailed analysis.',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showUpgradeDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Upgrade',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => const SubscriptionDialog(),
    );
  }
}

// Custom TabBar that listens to subscription changes
class _SubscriptionAwareTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final SubscriptionService subscriptionService;

  const _SubscriptionAwareTabBar({
    required this.controller,
    required this.subscriptionService,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: subscriptionService,
      builder: (context, _) {
        return TabBar(
          controller: controller,
          tabs: [
            Tab(
              icon: const Icon(Icons.restaurant),
              text: 'Food',
            ),
            Tab(
              icon: const Icon(Icons.fitness_center),
              text: 'Activity',
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calculate),
                  if (subscriptionService.isFree) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.lock, size: 14, color: Colors.amber.shade600),
                  ],
                ],
              ),
              text: 'Others',
            ),
          ],
        );
      },
    );
  }
}

// Modified Food Calculator Tab to show only basic calculator for free users
class FoodCalculatorTabContent extends StatefulWidget {
  const FoodCalculatorTabContent({super.key});

  @override
  State<FoodCalculatorTabContent> createState() => _FoodCalculatorTabContentState();
}

class _FoodCalculatorTabContentState extends State<FoodCalculatorTabContent> {
  String _selectedCalculator = 'basic';
  late SubscriptionService _subscriptionService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscriptionService = ServiceProvider.of(context).subscriptionService;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _subscriptionService,
      builder: (context, _) {
        // Available calculators based on subscription
        final availableCalculators = _subscriptionService.isPremium
            ? [
          const DropdownMenuItem(value: 'basic', child: Text('Basic Food Calculator')),
          const DropdownMenuItem(value: 'recipe', child: Text('Recipe Calculator')),
          const DropdownMenuItem(value: 'macro', child: Text('Macronutrient Calculator')),
          const DropdownMenuItem(value: 'portion', child: Text('Portion Size Calculator')),
        ]
            : [
          const DropdownMenuItem(value: 'basic', child: Text('Basic Food Calculator (Free)')),
        ];

        // Reset to basic if premium calculator was selected but user is now free
        if (_subscriptionService.isFree && _selectedCalculator != 'basic') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedCalculator = 'basic';
            });
          });
        }

        return Column(
          children: [
            // Calculator selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCalculator,
                      decoration: const InputDecoration(
                        labelText: 'Select Food Calculator',
                        border: OutlineInputBorder(),
                      ),
                      items: availableCalculators,
                      onChanged: (value) => setState(() => _selectedCalculator = value!),
                    ),
                    if (_subscriptionService.isFree && _selectedCalculator != 'basic') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.amber.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This calculator requires Premium',
                                style: TextStyle(
                                  color: Colors.amber.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showUpgradeDialog(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Text('Upgrade', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Display selected calculator
            if (_selectedCalculator == 'basic')
              const BasicFoodCalculator()
            else
              PaywallWidget(
                feature: 'advanced_calculators',
                customTitle: 'Premium Food Calculator',
                customDescription: 'Unlock advanced food calculators including recipe analysis, macronutrient breakdown, and portion size guidance.',
                child: const BasicFoodCalculator(), // This won't be shown due to paywall
              ),
          ],
        );
      },
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => const SubscriptionDialog(),
    );
  }
}

// Modified Activity Calculator Tab to show only basic calculator for free users
class ActivityCalculatorTabContent extends StatefulWidget {
  const ActivityCalculatorTabContent({super.key});

  @override
  State<ActivityCalculatorTabContent> createState() => _ActivityCalculatorTabContentState();
}

class _ActivityCalculatorTabContentState extends State<ActivityCalculatorTabContent> {
  String _selectedCalculator = 'basic';
  late SubscriptionService _subscriptionService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscriptionService = ServiceProvider.of(context).subscriptionService;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _subscriptionService,
      builder: (context, _) {
        // Available calculators based on subscription
        final availableCalculators = _subscriptionService.isPremium
            ? [
          const DropdownMenuItem(value: 'basic', child: Text('Basic Activity Calculator')),
          const DropdownMenuItem(value: 'walking', child: Text('Walking/Running Calculator')),
          const DropdownMenuItem(value: 'gym', child: Text('Gym Workout Calculator')),
          const DropdownMenuItem(value: 'sports', child: Text('Sports Activity Calculator')),
        ]
            : [
          const DropdownMenuItem(value: 'basic', child: Text('Basic Activity Calculator (Free)')),
        ];

        // Reset to basic if premium calculator was selected but user is now free
        if (_subscriptionService.isFree && _selectedCalculator != 'basic') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedCalculator = 'basic';
            });
          });
        }

        return Column(
          children: [
            // Calculator selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCalculator,
                      decoration: const InputDecoration(
                        labelText: 'Select Activity Calculator',
                        border: OutlineInputBorder(),
                      ),
                      items: availableCalculators,
                      onChanged: (value) => setState(() => _selectedCalculator = value!),
                    ),
                    if (_subscriptionService.isFree && _selectedCalculator != 'basic') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.amber.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This calculator requires Premium',
                                style: TextStyle(
                                  color: Colors.amber.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showUpgradeDialog(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Text('Upgrade', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Display selected calculator
            if (_selectedCalculator == 'basic')
              const BasicActivityCalculator()
            else
              PaywallWidget(
                feature: 'advanced_calculators',
                customTitle: 'Premium Activity Calculator',
                customDescription: 'Unlock specialized calculators for walking/running, gym workouts, and sports activities with detailed calorie burn analysis.',
                child: const BasicActivityCalculator(), // This won't be shown due to paywall
              ),
          ],
        );
      },
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => const SubscriptionDialog(),
    );
  }
}