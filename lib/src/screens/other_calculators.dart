import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/models/food_log.dart';

// OTHERS CALCULATOR TAB
class OtherCalculatorTab extends StatefulWidget {
  const OtherCalculatorTab({super.key});

  @override
  State<OtherCalculatorTab> createState() => _OtherCalculatorTabState();
}

class _OtherCalculatorTabState extends State<OtherCalculatorTab> {
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
  final FirebaseService _firebaseService = FirebaseService();
  final _drinkNameController = TextEditingController();
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

  void _addCaloriesToFoodLog() {
    if (_totalCalories > 0 && _drinkNameController.text.isNotEmpty) {
      final foodLog = FoodLog(
        id: '',
        name: '${_drinkNameController.text} (alcohol)',
        calories: _totalCalories.round(),
        date: DateTime.now(),
      );
      _firebaseService.addFoodLog(foodLog);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_drinkNameController.text} (${_totalCalories.round()} kcal) to food log!'),
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
            Text('Alcohol Calculator', style: Theme.of(context).textTheme.titleLarge),
            const Text('Calculate alcohol content, value, and calories'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _drinkNameController,
              decoration: const InputDecoration(
                labelText: 'Drink name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                  prefixText: '\$',
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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addCaloriesToFoodLog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Calories to Food Log'),
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