import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/screens/home_screen.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lbsController = TextEditingController();
  final _daysController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  Sex? _selectedSex;

  void _saveData() {
    if (_formKey.currentState!.validate() && _selectedSex != null) {

      // --- ADD THIS LINE to capture the current time ---
      final DateTime now = DateTime.now();
      // ---------------------------------------------------

      // Create and save UserProfile, now with the createdAt date
      final profile = UserProfile(
        startWeight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        age: int.parse(_ageController.text),
        sex: _selectedSex!,
        createdAt: now, // <-- Pass the date here
      );
      Hive.box<UserProfile>('user_profile_box').put(0, profile);

      // Create and save UserGoal
      final goal = UserGoal(
        lbsToLose: double.parse(_lbsController.text),
        days: int.parse(_daysController.text),
      );
      Hive.box<UserGoal>('user_goal_box').put(0, goal);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      if (_selectedSex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your sex.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _lbsController.dispose();
    _daysController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile & Goal"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Let's find your path to balance.",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // --- Profile Section ---
              Text("About You", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      hint: 'e.g., 30',
                      isDigitsOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      hint: 'e.g., 175',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _weightController,
                label: 'Current Weight (lbs)',
                hint: 'e.g., 180',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Sex>(
                value: _selectedSex,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: Sex.values.map((Sex sex) {
                  return DropdownMenuItem<Sex>(
                    value: sex,
                    child: Text(sex.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
                onChanged: (Sex? newValue) {
                  setState(() {
                    _selectedSex = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select your sex' : null,
              ),
              const SizedBox(height: 32),

              // --- Goal Section ---
              Text("Your Goal", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lbsController,
                label: 'Weight to Lose (lbs)',
                hint: 'e.g., 15',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _daysController,
                label: 'Timeframe (days)',
                hint: 'e.g., 60',
                isDigitsOnly: true,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('SAVE & START'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to reduce code duplication
  TextFormField _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isDigitsOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      keyboardType: isDigitsOnly
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isDigitsOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a value';
        if (double.tryParse(value) == null || double.parse(value) <= 0) {
          return 'Please enter a number greater than 0';
        }
        return null;
      },
    );
  }
}