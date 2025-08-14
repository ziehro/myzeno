import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/src/widgets/app_menu_button.dart';

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
          OthersCalculatorTab(),
        ],
      ),
    );
  }
}

// FOOD CALCULATOR TAB
class FoodCalculatorTab extends StatefulWidget {
  const FoodCalculatorTab({super.key});

  @override
  State<FoodCalculatorTab> createState() => _FoodCalculatorTabState();
}

class _FoodCalculatorTabState extends State<FoodCalculatorTab> {
  String _selectedCalculator = 'basic';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Calculator selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                value: _selectedCalculator,
                decoration: const InputDecoration(
                  labelText: 'Select Food Calculator',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'basic', child: Text('Basic Food Calculator')),
                  DropdownMenuItem(value: 'recipe', child: Text('Recipe Calculator')),
                  DropdownMenuItem(value: 'macro', child: Text('Macronutrient Calculator')),
                  DropdownMenuItem(value: 'portion', child: Text('Portion Size Calculator')),
                ],
                onChanged: (value) => setState(() => _selectedCalculator = value!),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Display selected calculator
          if (_selectedCalculator == 'basic') const BasicFoodCalculator(),
          if (_selectedCalculator == 'recipe') const RecipeCalculator(),
          if (_selectedCalculator == 'macro') const MacronutrientCalculator(),
          if (_selectedCalculator == 'portion') const PortionSizeCalculator(),
        ],
      ),
    );
  }
}

// Basic Food Calculator
class BasicFoodCalculator extends StatefulWidget {
  const BasicFoodCalculator({super.key});

  @override
  State<BasicFoodCalculator> createState() => _BasicFoodCalculatorState();
}

class _BasicFoodCalculatorState extends State<BasicFoodCalculator> {
  final _caloriesPer100gController = TextEditingController();
  final _weightController = TextEditingController();
  double _totalCalories = 0;

  void _calculate() {
    final caloriesPer100g = double.tryParse(_caloriesPer100gController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    setState(() {
      _totalCalories = (caloriesPer100g * weight) / 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Food Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesPer100gController,
              decoration: const InputDecoration(
                labelText: 'Calories per 100g',
                border: OutlineInputBorder(),
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Food weight',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_totalCalories > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Calories: ${_totalCalories.toStringAsFixed(1)} kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Recipe Calculator
class RecipeCalculator extends StatefulWidget {
  const RecipeCalculator({super.key});

  @override
  State<RecipeCalculator> createState() => _RecipeCalculatorState();
}

class _RecipeCalculatorState extends State<RecipeCalculator> {
  final List<Map<String, dynamic>> _ingredients = [];
  final _ingredientController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _amountController = TextEditingController();
  final _servingsController = TextEditingController();

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty &&
        _caloriesController.text.isNotEmpty &&
        _amountController.text.isNotEmpty) {
      setState(() {
        _ingredients.add({
          'name': _ingredientController.text,
          'calories': double.parse(_caloriesController.text),
          'amount': double.parse(_amountController.text),
        });
      });
      _ingredientController.clear();
      _caloriesController.clear();
      _amountController.clear();
    }
  }

  double get _totalCalories => _ingredients.fold(0, (sum, ingredient) => sum + ingredient['calories']);

  double get _caloriesPerServing {
    final servings = double.tryParse(_servingsController.text) ?? 1;
    return servings > 0 ? _totalCalories / servings : _totalCalories;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipe Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Add ingredient form
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: _addIngredient,
                child: const Text('Add Ingredient'),
              ),
            ),

            // Ingredients list
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Ingredients:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._ingredients.map((ingredient) => ListTile(
                title: Text(ingredient['name']),
                trailing: Text('${ingredient['calories'].toInt()} kcal'),
                onTap: () => setState(() => _ingredients.remove(ingredient)),
              )),
            ],

            // Servings input
            const SizedBox(height: 16),
            TextFormField(
              controller: _servingsController,
              decoration: const InputDecoration(
                labelText: 'Number of servings',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            // Results
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Recipe: ${_totalCalories.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Per Serving: ${_caloriesPerServing.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Macro Calculator (simplified)
class MacronutrientCalculator extends StatefulWidget {
  const MacronutrientCalculator({super.key});

  @override
  State<MacronutrientCalculator> createState() => _MacronutrientCalculatorState();
}

class _MacronutrientCalculatorState extends State<MacronutrientCalculator> {
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  double _totalCalories = 0;

  void _calculate() {
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    setState(() {
      _totalCalories = (protein * 4) + (carbs * 4) + (fat * 9);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Macronutrient Calculator', style: Theme.of(context).textTheme.titleLarge),
            const Text('Calculate calories from macros (4 cal/g protein & carbs, 9 cal/g fat)'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proteinController,
              decoration: const InputDecoration(
                labelText: 'Protein',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _carbsController,
              decoration: const InputDecoration(
                labelText: 'Carbohydrates',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fatController,
              decoration: const InputDecoration(
                labelText: 'Fat',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_totalCalories > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Calories: ${_totalCalories.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Portion Size Calculator (simplified)
class PortionSizeCalculator extends StatefulWidget {
  const PortionSizeCalculator({super.key});

  @override
  State<PortionSizeCalculator> createState() => _PortionSizeCalculatorState();
}

class _PortionSizeCalculatorState extends State<PortionSizeCalculator> {
  String _selectedFood = 'rice';
  final _portionsController = TextEditingController();
  double _totalCalories = 0;

  final Map<String, Map<String, dynamic>> _foodData = {
    'rice': {'name': 'Cooked Rice', 'caloriesPerPortion': 130, 'portionSize': '1/2 cup'},
    'pasta': {'name': 'Cooked Pasta', 'caloriesPerPortion': 110, 'portionSize': '1/2 cup'},
    'chicken': {'name': 'Chicken Breast', 'caloriesPerPortion': 140, 'portionSize': '3 oz'},
    'beef': {'name': 'Lean Beef', 'caloriesPerPortion': 180, 'portionSize': '3 oz'},
    'salmon': {'name': 'Salmon', 'caloriesPerPortion': 175, 'portionSize': '3 oz'},
    'bread': {'name': 'Whole Grain Bread', 'caloriesPerPortion': 80, 'portionSize': '1 slice'},
    'apple': {'name': 'Medium Apple', 'caloriesPerPortion': 95, 'portionSize': '1 medium'},
    'banana': {'name': 'Medium Banana', 'caloriesPerPortion': 105, 'portionSize': '1 medium'},
  };

  void _calculate() {
    final portions = double.tryParse(_portionsController.text) ?? 0;
    final caloriesPerPortion = _foodData[_selectedFood]!['caloriesPerPortion'];
    setState(() {
      _totalCalories = portions * caloriesPerPortion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Portion Size Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFood,
              decoration: const InputDecoration(
                labelText: 'Select Food',
                border: OutlineInputBorder(),
              ),
              items: _foodData.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text('${entry.value['name']} (${entry.value['portionSize']})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedFood = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _portionsController,
              decoration: InputDecoration(
                labelText: 'Number of portions',
                border: const OutlineInputBorder(),
                suffixText: _foodData[_selectedFood]!['portionSize'],
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_totalCalories > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Calories: ${_totalCalories.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ACTIVITY CALCULATOR TAB
class ActivityCalculatorTab extends StatefulWidget {
  const ActivityCalculatorTab({super.key});

  @override
  State<ActivityCalculatorTab> createState() => _ActivityCalculatorTabState();
}

class _ActivityCalculatorTabState extends State<ActivityCalculatorTab> {
  String _selectedCalculator = 'basic';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                value: _selectedCalculator,
                decoration: const InputDecoration(
                  labelText: 'Select Activity Calculator',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'basic', child: Text('Basic Activity Calculator')),
                  DropdownMenuItem(value: 'walking', child: Text('Walking/Running Calculator')),
                  DropdownMenuItem(value: 'gym', child: Text('Gym Workout Calculator')),
                  DropdownMenuItem(value: 'sports', child: Text('Sports Activity Calculator')),
                ],
                onChanged: (value) => setState(() => _selectedCalculator = value!),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedCalculator == 'basic') const BasicActivityCalculator(),
          if (_selectedCalculator == 'walking') const WalkingRunningCalculator(),
          if (_selectedCalculator == 'gym') const GymWorkoutCalculator(),
          if (_selectedCalculator == 'sports') const SportsActivityCalculator(),
        ],
      ),
    );
  }
}

// Basic Activity Calculator
class BasicActivityCalculator extends StatefulWidget {
  const BasicActivityCalculator({super.key});

  @override
  State<BasicActivityCalculator> createState() => _BasicActivityCalculatorState();
}

class _BasicActivityCalculatorState extends State<BasicActivityCalculator> {
  String _selectedActivity = 'walking_moderate';
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  double _caloriesBurned = 0;

  final Map<String, Map<String, dynamic>> _activities = {
    'walking_moderate': {'name': 'Walking (3.5 mph)', 'metValue': 4.3},
    'walking_brisk': {'name': 'Walking (4.5 mph)', 'metValue': 5.0},
    'running_6mph': {'name': 'Running (6 mph)', 'metValue': 9.8},
    'running_8mph': {'name': 'Running (8 mph)', 'metValue': 11.8},
    'cycling_moderate': {'name': 'Cycling (12-14 mph)', 'metValue': 8.0},
    'cycling_vigorous': {'name': 'Cycling (16-19 mph)', 'metValue': 12.0},
    'swimming': {'name': 'Swimming (moderate)', 'metValue': 5.8},
    'dancing': {'name': 'Dancing', 'metValue': 4.8},
    'gardening': {'name': 'Gardening', 'metValue': 4.0},
    'cleaning': {'name': 'House Cleaning', 'metValue': 3.3},
  };

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final duration = double.tryParse(_durationController.text) ?? 0;
    final metValue = _activities[_selectedActivity]!['metValue'];

    // Formula: Calories = MET × weight(kg) × time(hours)
    final weightKg = weight * 0.453592; // Convert lbs to kg
    final durationHours = duration / 60; // Convert minutes to hours

    setState(() {
      _caloriesBurned = metValue * weightKg * durationHours;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Activity Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedActivity,
              decoration: const InputDecoration(
                labelText: 'Select Activity',
                border: OutlineInputBorder(),
              ),
              items: _activities.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedActivity = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Your weight',
                border: OutlineInputBorder(),
                suffixText: 'lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
                suffixText: 'minutes',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_caloriesBurned > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Calories Burned: ${_caloriesBurned.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Walking/Running Calculator (simplified for brevity)
class WalkingRunningCalculator extends StatefulWidget {
  const WalkingRunningCalculator({super.key});

  @override
  State<WalkingRunningCalculator> createState() => _WalkingRunningCalculatorState();
}

class _WalkingRunningCalculatorState extends State<WalkingRunningCalculator> {
  final _weightController = TextEditingController();
  final _distanceController = TextEditingController();
  final _speedController = TextEditingController();
  double _caloriesBurned = 0;
  double _duration = 0;

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final speed = double.tryParse(_speedController.text) ?? 0;

    if (weight > 0 && distance > 0 && speed > 0) {
      final durationHours = distance / speed;
      final weightKg = weight * 0.453592;

      // Simple formula based on speed
      double metValue;
      if (speed < 4) metValue = 3.5; // Walking
      else if (speed < 6) metValue = 6.0; // Jogging
      else if (speed < 8) metValue = 9.8; // Running
      else metValue = 11.8; // Fast running

      setState(() {
        _duration = durationHours * 60; // minutes
        _caloriesBurned = metValue * weightKg * durationHours;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Walking/Running Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Your weight',
                border: OutlineInputBorder(),
                suffixText: 'lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _distanceController,
              decoration: const InputDecoration(
                labelText: 'Distance',
                border: OutlineInputBorder(),
                suffixText: 'miles',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _speedController,
              decoration: const InputDecoration(
                labelText: 'Average speed',
                border: OutlineInputBorder(),
                suffixText: 'mph',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_caloriesBurned > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Duration: ${_duration.toStringAsFixed(0)} minutes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calories Burned: ${_caloriesBurned.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Simplified Gym Workout Calculator
class GymWorkoutCalculator extends StatefulWidget {
  const GymWorkoutCalculator({super.key});

  @override
  State<GymWorkoutCalculator> createState() => _GymWorkoutCalculatorState();
}

class _GymWorkoutCalculatorState extends State<GymWorkoutCalculator> {
  String _selectedWorkout = 'weight_training';
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  double _caloriesBurned = 0;

  final Map<String, Map<String, dynamic>> _workouts = {
    'weight_training': {'name': 'Weight Training (moderate)', 'metValue': 6.0},
    'weight_training_vigorous': {'name': 'Weight Training (vigorous)', 'metValue': 8.0},
    'cardio_machines': {'name': 'Cardio Machines (moderate)', 'metValue': 7.0},
    'cardio_machines_vigorous': {'name': 'Cardio Machines (vigorous)', 'metValue': 9.0},
    'circuit_training': {'name': 'Circuit Training', 'metValue': 8.0},
    'crossfit': {'name': 'CrossFit', 'metValue': 12.0},
    'stretching': {'name': 'Stretching/Yoga', 'metValue': 2.5},
    'pilates': {'name': 'Pilates', 'metValue': 3.0},
  };

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final duration = double.tryParse(_durationController.text) ?? 0;
    final metValue = _workouts[_selectedWorkout]!['metValue'];

    final weightKg = weight * 0.453592;
    final durationHours = duration / 60;

    setState(() {
      _caloriesBurned = metValue * weightKg * durationHours;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gym Workout Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedWorkout,
              decoration: const InputDecoration(
                labelText: 'Select Workout Type',
                border: OutlineInputBorder(),
              ),
              items: _workouts.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedWorkout = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Your weight',
                border: OutlineInputBorder(),
                suffixText: 'lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
                suffixText: 'minutes',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_caloriesBurned > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Calories Burned: ${_caloriesBurned.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Sports Activity Calculator
class SportsActivityCalculator extends StatefulWidget {
  const SportsActivityCalculator({super.key});

  @override
  State<SportsActivityCalculator> createState() => _SportsActivityCalculatorState();
}

class _SportsActivityCalculatorState extends State<SportsActivityCalculator> {
  String _selectedSport = 'basketball';
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  double _caloriesBurned = 0;

  final Map<String, Map<String, dynamic>> _sports = {
    'basketball': {'name': 'Basketball', 'metValue': 6.5},
    'soccer': {'name': 'Soccer', 'metValue': 7.0},
    'tennis': {'name': 'Tennis', 'metValue': 5.0},
    'badminton': {'name': 'Badminton', 'metValue': 4.5},
    'volleyball': {'name': 'Volleyball', 'metValue': 4.0},
    'golf': {'name': 'Golf (walking)', 'metValue': 4.8},
    'bowling': {'name': 'Bowling', 'metValue': 3.0},
    'table_tennis': {'name': 'Table Tennis', 'metValue': 4.0},
    'martial_arts': {'name': 'Martial Arts', 'metValue': 10.0},
    'rock_climbing': {'name': 'Rock Climbing', 'metValue': 11.0},
  };

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final duration = double.tryParse(_durationController.text) ?? 0;
    final metValue = _sports[_selectedSport]!['metValue'];

    final weightKg = weight * 0.453592;
    final durationHours = duration / 60;

    setState(() {
      _caloriesBurned = metValue * weightKg * durationHours;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sports Activity Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSport,
              decoration: const InputDecoration(
                labelText: 'Select Sport',
                border: OutlineInputBorder(),
              ),
              items: _sports.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSport = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Your weight',
                border: OutlineInputBorder(),
                suffixText: 'lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
                suffixText: 'minutes',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_caloriesBurned > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Calories Burned: ${_caloriesBurned.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// OTHERS CALCULATOR TAB
class OthersCalculatorTab extends StatefulWidget {
  const OthersCalculatorTab({super.key});

  @override
  State<OthersCalculatorTab> createState() => _OthersCalculatorTabState();
}

class _OthersCalculatorTabState extends State<OthersCalculatorTab> {
  String _selectedCalculator = 'alcohol';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                value: _selectedCalculator,
                decoration: const InputDecoration(
                  labelText: 'Select Calculator',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'alcohol', child: Text('Alcohol Calculator')),
                  DropdownMenuItem(value: 'bmr', child: Text('BMR Calculator')),
                  DropdownMenuItem(value: 'bmi', child: Text('BMI Calculator')),
                  DropdownMenuItem(value: 'water', child: Text('Water Intake Calculator')),
                ],
                onChanged: (value) => setState(() => _selectedCalculator = value!),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedCalculator == 'alcohol') const AlcoholCalculator(),
          if (_selectedCalculator == 'bmr') const BMRCalculator(),
          if (_selectedCalculator == 'bmi') const BMICalculator(),
          if (_selectedCalculator == 'water') const WaterIntakeCalculator(),
        ],
      ),
    );
  }
}

// Alcohol Calculator (based on your Android code)
class AlcoholCalculator extends StatefulWidget {
  const AlcoholCalculator({super.key});

  @override
  State<AlcoholCalculator> createState() => _AlcoholCalculatorState();
}

class _AlcoholCalculatorState extends State<AlcoholCalculator> {
  final _alcoholPercentController = TextEditingController();
  final _volumeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  double _totalAlcohol = 0;
  double _alcoholPerDollar = 0;
  double _totalCalories = 0;
  Color _valueColor = Colors.green;

  void _calculate() {
    final alcoholPercent = double.tryParse(_alcoholPercentController.text) ?? 0;
    final volume = double.tryParse(_volumeController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (alcoholPercent > 0 && volume > 0 && quantity > 0 && price > 0) {
      setState(() {
        // Total alcohol volume (like your TVA calculation)
        _totalAlcohol = (volume / 100 * alcoholPercent * quantity);

        // Alcohol per dollar (like your alcPerBuck calculation)
        _alcoholPerDollar = _totalAlcohol / price;

        // Alcohol calories (7 calories per gram, alcohol density ~0.789 g/ml)
        _totalCalories = _totalAlcohol * 0.789 * 7;

        // Color coding based on value (like your original)
        if (_alcoholPerDollar >= 11) {
          _valueColor = Colors.green;
        } else if (_alcoholPerDollar >= 8) {
          _valueColor = Colors.orange;
        } else {
          _valueColor = Colors.red;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alcohol Calculator', style: Theme.of(context).textTheme.titleLarge),
            const Text('Calculate alcohol content, value, and calories'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alcoholPercentController,
              decoration: const InputDecoration(
                labelText: 'Alcohol percentage',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _volumeController,
              decoration: const InputDecoration(
                labelText: 'Volume per container',
                border: OutlineInputBorder(),
                suffixText: 'ml',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                suffixText: 'containers',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                  labelText: 'Total price',
                  border: OutlineInputBorder(),
                  prefixText: '\$'
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_totalAlcohol > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Alcohol: ${_totalAlcohol.toStringAsFixed(1)} ml',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alcohol per \$: ${_alcoholPerDollar.toStringAsFixed(2)} ml',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _valueColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Calories: ${_totalCalories.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// BMR Calculator
class BMRCalculator extends StatefulWidget {
  const BMRCalculator({super.key});

  @override
  State<BMRCalculator> createState() => _BMRCalculatorState();
}

class _BMRCalculatorState extends State<BMRCalculator> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedSex = 'male';
  double _bmr = 0;

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final age = double.tryParse(_ageController.text) ?? 0;

    if (weight > 0 && height > 0 && age > 0) {
      final weightKg = weight * 0.453592; // lbs to kg
      final heightCm = height * 2.54; // inches to cm

      setState(() {
        if (_selectedSex == 'male') {
          _bmr = (10 * weightKg + 6.25 * heightCm - 5 * age + 5);
        } else {
          _bmr = (10 * weightKg + 6.25 * heightCm - 5 * age - 161);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BMR Calculator', style: Theme.of(context).textTheme.titleLarge),
            const Text('Calculate your Basal Metabolic Rate'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSex,
              decoration: const InputDecoration(
                labelText: 'Sex',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) => setState(() => _selectedSex = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight',
                border: OutlineInputBorder(),
                suffixText: 'lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
                suffixText: 'inches',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                suffixText: 'years',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_bmr > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BMR: ${_bmr.toStringAsFixed(0)} calories/day',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// BMI Calculator
class BMICalculator extends StatefulWidget {
  const BMICalculator({super.key});

  @override
  State<BMICalculator> createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double _bmi = 0;
  String _bmiCategory = '';
  Color _categoryColor = Colors.green;

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;

    if (weight > 0 && height > 0) {
      final weightKg = weight * 0.453592;
      final heightM = height * 0.0254;

      setState(() {
        _bmi = weightKg / (heightM * heightM);

        if (_bmi < 18.5) {
          _bmiCategory = 'Underweight';
          _categoryColor = Colors.blue;
        } else if (_bmi < 25) {
          _bmiCategory = 'Normal';
          _categoryColor = Colors.green;
        } else if (_bmi < 30) {
          _bmiCategory = 'Overweight';
          _categoryColor = Colors.orange;
        } else {
          _bmiCategory = 'Obese';
          _categoryColor = Colors.red;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BMI Calculator', style: Theme.of(context).textTheme.titleLarge),
            const Text('Calculate your Body Mass Index'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight',
                border: OutlineInputBorder(),
                suffixText: 'lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
                suffixText: 'inches',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_bmi > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'BMI: ${_bmi.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bmiCategory,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Water Intake Calculator
class WaterIntakeCalculator extends StatefulWidget {
  const WaterIntakeCalculator({super.key});

  @override
  State<WaterIntakeCalculator> createState() => _WaterIntakeCalculatorState();
}

class _WaterIntakeCalculatorState extends State<WaterIntakeCalculator> {
  final _weightController = TextEditingController();
  final _exerciseController = TextEditingController();
  String _selectedActivity = 'sedentary';
  double _waterIntake = 0;

  final Map<String, double> _activityMultipliers = {
    'sedentary': 1.0,
    'light': 1.2,
    'moderate': 1.4,
    'active': 1.6,
    'very_active': 1.8,
  };

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final exercise = double.tryParse(_exerciseController.text) ?? 0;

    if (weight > 0) {
      // Basic calculation: weight in lbs * 0.67 = ounces per day
      final baseWater = weight * 0.67;

      // Add for exercise: 12 oz for every 30 minutes
      final exerciseWater = (exercise / 30) * 12;

      // Activity level multiplier
      final activityMultiplier = _activityMultipliers[_selectedActivity]!;

      setState(() {
        _waterIntake = (baseWater + exerciseWater) * activityMultiplier;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Water Intake Calculator', style: Theme.of(context).textTheme.titleLarge),
            const Text('Calculate your daily water needs'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight',
                border: OutlineInputBorder(),
                suffixText: 'lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedActivity,
              decoration: const InputDecoration(
                labelText: 'Activity Level',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                DropdownMenuItem(value: 'light', child: Text('Lightly Active')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderately Active')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'very_active', child: Text('Very Active')),
              ],
              onChanged: (value) => setState(() => _selectedActivity = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _exerciseController,
              decoration: const InputDecoration(
                labelText: 'Exercise duration',
                border: OutlineInputBorder(),
                suffixText: 'minutes',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_waterIntake > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Daily Water Intake',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_waterIntake.toStringAsFixed(0)} fl oz',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '≈ ${(_waterIntake / 8).toStringAsFixed(1)} cups',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}