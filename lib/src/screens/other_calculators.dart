import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/alcohol_entry.dart';

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


class AlcoholCalculator extends StatefulWidget {
  const AlcoholCalculator({super.key});

  @override
  State<AlcoholCalculator> createState() => _AlcoholCalculatorState();
}

class _AlcoholCalculatorState extends State<AlcoholCalculator> with SingleTickerProviderStateMixin {
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

  late TabController _tabController;
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _drinkNameController.dispose();
    _alcoholPercentController.dispose();
    _volumeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

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

        // Color coding based on value
        if (_alcoholPerDollar >= 11) {
          _valueColor = Colors.green;
        } else if (_alcoholPerDollar >= 8) {
          _valueColor = Colors.orange;
        } else {
          _valueColor = Colors.red;
        }

        _hasCalculated = true;
      });
    }
  }

  void _saveEntry() async {
    if (!_hasCalculated || _drinkNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate first and enter a drink name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final entry = AlcoholEntry(
        id: '',
        name: _drinkNameController.text,
        alcoholPercent: double.parse(_alcoholPercentController.text),
        volume: double.parse(_volumeController.text),
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        date: DateTime.now(),
        totalAlcohol: _totalAlcohol,
        alcoholPerDollar: _alcoholPerDollar,
        totalCalories: _totalCalories,
      );

      await _firebaseService.addAlcoholEntry(entry);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${entry.name}" to your alcohol history!'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to history tab to show the saved entry
      _tabController.animateTo(1);

    } catch (e) {
      print('Error saving alcohol entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving entry. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addCaloriesToFoodLog() {
    if (_totalCalories > 0 && _drinkNameController.text.isNotEmpty) {
      final foodLog = FoodLog(
        id: '',
        name: '${_drinkNameController.text} (alcohol)',
        calories: _totalCalories.round(),
        quantity: 1,
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

  void _loadFromHistory(AlcoholEntry entry) {
    setState(() {
      _drinkNameController.text = entry.name;
      _alcoholPercentController.text = entry.alcoholPercent.toString();
      _volumeController.text = entry.volume.toString();
      _quantityController.text = entry.quantity.toString();
      _priceController.text = entry.price.toString();
      _totalAlcohol = entry.totalAlcohol;
      _alcoholPerDollar = entry.alcoholPerDollar;
      _totalCalories = entry.totalCalories;
      _valueColor = entry.valueColor;
      _hasCalculated = true;
    });

    // Switch to calculator tab
    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded "${entry.name}" into calculator'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Header with tabs
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alcohol Calculator', style: Theme.of(context).textTheme.titleLarge),
                const Text('Calculate alcohol content, value, and calories'),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.calculate), text: 'Calculator'),
                    Tab(icon: Icon(Icons.history), text: 'History'),
                  ],
                ),
              ],
            ),
          ),

          // Tab content
          SizedBox(
            height: 500, // Fixed height for the tab view
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCalculatorTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            onChanged: (_) => _hasCalculated = false,
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
            onChanged: (_) => _hasCalculated = false,
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
            onChanged: (_) => _hasCalculated = false,
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
            onChanged: (_) => _hasCalculated = false,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _valueColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _valueColor),
                    ),
                    child: Text(
                      _alcoholPerDollar >= 11 ? 'Excellent Value' :
                      _alcoholPerDollar >= 8 ? 'Good Value' : 'Poor Value',
                      style: TextStyle(
                        color: _valueColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Calories: ${_totalCalories.toStringAsFixed(0)} kcal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveEntry,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addCaloriesToFoodLog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add to Food Log'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<AlcoholEntry>>(
      stream: _firebaseService.alcoholEntriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading history'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No saved entries yet'),
                const SizedBox(height: 8),
                const Text(
                  'Calculate and save alcohol entries to see them here',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Go to Calculator'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(
                  entry.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.alcoholPercent}% • ${entry.volume}ml × ${entry.quantity} • \$${entry.price.toStringAsFixed(2)}'),
                    Text(
                      '${entry.alcoholPerDollar.toStringAsFixed(2)} ml/\$ • ${entry.valueRating}',
                      style: TextStyle(
                        color: entry.valueColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${entry.totalAlcohol.toStringAsFixed(1)}ml alcohol • ${entry.totalCalories.toStringAsFixed(0)} kcal',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'load':
                        _loadFromHistory(entry);
                        break;
                      case 'delete':
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Entry'),
                            content: Text('Delete "${entry.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          try {
                            await _firebaseService.deleteAlcoholEntry(entry.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Entry deleted'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error deleting entry'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'load',
                      child: ListTile(
                        leading: Icon(Icons.input),
                        title: Text('Load into Calculator'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete Entry'),
                      ),
                    ),
                  ],
                ),
                onTap: () => _loadFromHistory(entry),
              ),
            );
          },
        );
      },
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