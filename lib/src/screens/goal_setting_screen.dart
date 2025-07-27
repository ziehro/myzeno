import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/screens/decision_screen.dart';

class GoalSettingScreen extends StatefulWidget {
  // These are optional. If they are provided, we're in "edit mode".
  final UserProfile? userProfile;
  final UserGoal? userGoal;

  const GoalSettingScreen({
    super.key,
    this.userProfile,
    this.userGoal,
  });

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lbsController;
  late final TextEditingController _daysController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  Sex? _selectedSex;
  ActivityLevel? _selectedActivityLevel;

  // A flag to know if we are editing or creating for the first time
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    // Determine if we are in edit mode based on passed-in data
    _isEditing = widget.userProfile != null && widget.userGoal != null;

    // Pre-fill the controllers if we are in edit mode, otherwise leave them empty
    _ageController = TextEditingController(text: _isEditing ? widget.userProfile!.age.toString() : '');
    _heightController = TextEditingController(text: _isEditing ? widget.userProfile!.height.toString() : '');
    _weightController = TextEditingController(text: _isEditing ? widget.userProfile!.startWeight.toString() : '');
    _lbsController = TextEditingController(text: _isEditing ? widget.userGoal!.lbsToLose.toString() : '');
    _daysController = TextEditingController(text: _isEditing ? widget.userGoal!.days.toString() : '');

    // Pre-select the dropdowns if we are in edit mode
    _selectedSex = _isEditing ? widget.userProfile!.sex : null;
    _selectedActivityLevel = _isEditing ? widget.userProfile!.activityLevel : null;
  }

  void _saveData() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || _selectedSex == null || _selectedActivityLevel == null) {
      // Show error messages if dropdowns are not selected
      if (_selectedSex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select your sex.'),
              backgroundColor: Colors.red),
        );
      }
      if (_selectedActivityLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select your activity level.'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Preserve the original creation date if editing, otherwise use now.
    final DateTime creationDate = _isEditing ? widget.userProfile!.createdAt : DateTime.now();

    final profile = UserProfile(
      startWeight: double.parse(_weightController.text),
      height: double.parse(_heightController.text),
      age: int.parse(_ageController.text),
      sex: _selectedSex!,
      createdAt: creationDate,
      activityLevel: _selectedActivityLevel!,
    );

    final goal = UserGoal(
      lbsToLose: double.parse(_lbsController.text),
      days: int.parse(_daysController.text),
    );

    Hive.box<UserProfile>('user_profile_box').put(0, profile);
    Hive.box<UserGoal>('user_goal_box').put(0, goal);

    if (mounted) {
      if (_isEditing) {
        Navigator.of(context).pop(); // Just go back to the home screen
      } else {
        // On first setup, clear the navigation stack and go to the DecisionScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DecisionScreen()),
              (route) => false,
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
        // The back button now appears automatically when editing
        title: Text(_isEditing ? "Edit Profile & Goal" : "Your Profile & Goal"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEditing) // Only show this on first setup
                Text(
                  "Let's find your path to balance.",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              if (!_isEditing) const SizedBox(height: 24),
              Text("About You", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                validator: (value) =>
                value == null ? 'Please select a value' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityLevel>(
                value: _selectedActivityLevel,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Activity Level',
                  hintText: 'How active are you?',
                ),
                items: ActivityLevel.values.map((ActivityLevel level) {
                  String text = '';
                  switch (level) {
                    case ActivityLevel.sedentary:
                      text = 'Sedentary (Office Job)';
                      break;
                    case ActivityLevel.lightlyActive:
                      text = 'Lightly Active (1-3 days/wk)';
                      break;
                    case ActivityLevel.moderatelyActive:
                      text = 'Moderately Active (3-5 days/wk)';
                      break;
                    case ActivityLevel.veryActive:
                      text = 'Very Active (6-7 days/wk)';
                      break;
                  }
                  return DropdownMenuItem<ActivityLevel>(
                    value: level,
                    child: Text(text, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (ActivityLevel? newValue) {
                  setState(() {
                    _selectedActivityLevel = newValue;
                  });
                },
                validator: (value) =>
                value == null ? 'Please select a value' : null,
              ),
              const SizedBox(height: 32),
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
                child: Text(_isEditing ? 'SAVE CHANGES' : 'SAVE & START'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          return 'Please enter a number > 0';
        }
        return null;
      },
    );
  }
}