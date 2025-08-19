import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/models/food_log.dart';

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
  final FirebaseService _firebaseService = FirebaseService();
  final _foodNameController = TextEditingController();
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

  void _addToFoodLog() {
    if (_totalCalories > 0 && _foodNameController.text.isNotEmpty) {
      final foodLog = FoodLog(
        id: '',
        name: _foodNameController.text,
        calories: _totalCalories.round(),
        quantity: 1, // Always add as quantity 1 from calculator
        date: DateTime.now(),
      );
      _firebaseService.addFoodLog(foodLog);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_foodNameController.text} (${_totalCalories.round()} kcal) to food log!'),
          backgroundColor: Colors.green,
        ),
      );
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
            Text('Basic Food Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _foodNameController,
              decoration: const InputDecoration(
                labelText: 'Food name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                child: Column(
                  children: [
                    Text(
                      'Total Calories: ${_totalCalories.toStringAsFixed(1)} kcal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addToFoodLog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Food Log'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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

// Recipe Calculator
class RecipeCalculator extends StatefulWidget {
  const RecipeCalculator({super.key});

  @override
  State<RecipeCalculator> createState() => _RecipeCalculatorState();
}

class _RecipeCalculatorState extends State<RecipeCalculator> {
  final FirebaseService _firebaseService = FirebaseService();
  final List<Map<String, dynamic>> _ingredients = [];
  final _recipeNameController = TextEditingController();
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

  void _addRecipeToFoodLog() {
    if (_caloriesPerServing > 0 && _recipeNameController.text.isNotEmpty) {
      final foodLog = FoodLog(
        id: '',
        name: '${_recipeNameController.text} (1 serving)',
        calories: _caloriesPerServing.round(),
        quantity: 1, // Always add as quantity 1 from calculator
        date: DateTime.now(),
      );
      _firebaseService.addFoodLog(foodLog);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_recipeNameController.text} (${_caloriesPerServing.round()} kcal per serving) to food log!'),
          backgroundColor: Colors.green,
        ),
      );
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
            Text('Recipe Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Recipe name
            TextFormField(
              controller: _recipeNameController,
              decoration: const InputDecoration(
                labelText: 'Recipe name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addRecipeToFoodLog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Serving to Food Log'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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