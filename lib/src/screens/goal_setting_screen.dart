import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/screens/auth_wrapper.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zeno/src/screens/login_screen.dart';

class GoalSettingScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final UserGoal? userGoal;
  final double? currentWeight;

  const GoalSettingScreen({
    super.key,
    this.userProfile,
    this.userGoal,
    this.currentWeight,
  });

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _firebaseService = FirebaseService(); // Use Firebase directly for profile creation
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lbsController;
  late final TextEditingController _daysController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  Sex? _selectedSex;
  ActivityLevel? _selectedActivityLevel;
  DateTime _startDate = DateTime.now();

  late bool _isEditing;

  // For real-time calculations
  double _calculatedDeficit = 0;
  double _recommendedCalories = 0;
  bool _showCalculations = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.userProfile != null && widget.userGoal != null;
    final weightToDisplay = _isEditing ? (widget.currentWeight ?? widget.userProfile!.startWeight) : '';

    _ageController = TextEditingController(text: _isEditing ? widget.userProfile!.age.toString() : '');
    _heightController = TextEditingController(text: _isEditing ? widget.userProfile!.height.toString() : '');
    _weightController = TextEditingController(text: weightToDisplay.toString());
    _lbsController = TextEditingController(text: _isEditing ? widget.userGoal!.lbsToLose.toString() : '');
    _daysController = TextEditingController(text: _isEditing ? widget.userGoal!.days.toString() : '');
    _startDate = widget.userProfile?.createdAt ?? DateTime.now();

    _selectedSex = _isEditing ? widget.userProfile!.sex : null;
    _selectedActivityLevel = _isEditing ? widget.userProfile!.activityLevel : null;

    // Add listeners for real-time calculations
    _lbsController.addListener(_updateCalculations);
    _daysController.addListener(_updateCalculations);
    _ageController.addListener(_updateCalculations);
    _heightController.addListener(_updateCalculations);
    _weightController.addListener(_updateCalculations);
  }

  void _updateCalculations() {
    if (_lbsController.text.isNotEmpty &&
        _daysController.text.isNotEmpty &&
        _ageController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _weightController.text.isNotEmpty &&
        _selectedSex != null &&
        _selectedActivityLevel != null) {

      final lbs = double.tryParse(_lbsController.text) ?? 0;
      final days = int.tryParse(_daysController.text) ?? 0;
      final age = int.tryParse(_ageController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      final weight = double.tryParse(_weightController.text) ?? 0;

      if (lbs > 0 && days > 0 && age > 0 && height > 0 && weight > 0) {
        // Calculate BMR and TDEE
        final weightKg = weight / 2.20462;
        double bmr;
        if (_selectedSex == Sex.male) {
          bmr = (10 * weightKg + 6.25 * height - 5 * age + 5);
        } else {
          bmr = (10 * weightKg + 6.25 * height - 5 * age - 161);
        }

        double multiplier;
        switch (_selectedActivityLevel!) {
          case ActivityLevel.sedentary:
            multiplier = 1.2;
            break;
          case ActivityLevel.lightlyActive:
            multiplier = 1.375;
            break;
          case ActivityLevel.moderatelyActive:
            multiplier = 1.55;
            break;
          case ActivityLevel.veryActive:
            multiplier = 1.725;
            break;
        }

        final tdee = (bmr * multiplier).round();
        final totalDeficit = (lbs * 3500).round();
        final dailyDeficit = (totalDeficit / days).round();
        final targetCalories = tdee - dailyDeficit;

        setState(() {
          _calculatedDeficit = dailyDeficit.toDouble();
          _recommendedCalories = targetCalories.toDouble();
          _showCalculations = true;
        });
      }
    } else {
      setState(() {
        _showCalculations = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveData() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || _selectedSex == null || _selectedActivityLevel == null) {
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

    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in')));
      return;
    }

    final newWeight = double.parse(_weightController.text);
    final startWeight = _isEditing ? widget.userProfile!.startWeight : newWeight;

    final profile = UserProfile(
      uid: currentUser.uid,
      email: currentUser.email!,
      startWeight: startWeight,
      height: double.parse(_heightController.text),
      age: int.parse(_ageController.text),
      sex: _selectedSex!,
      createdAt: _startDate,
      activityLevel: _selectedActivityLevel!,
    );

    final goal = UserGoal(
      lbsToLose: double.parse(_lbsController.text),
      days: int.parse(_daysController.text),
    );

    // Show success message with calculations
    if (!_isEditing) {
      await _showSuccessDialog(profile, goal);
    }

    await _firebaseService.saveUserProfileAndGoal(profile, goal);

    if (_isEditing) {
      if (newWeight != widget.currentWeight) {
        final newLog = WeightLog(id: '', date: DateTime.now(), weight: newWeight);
        await _firebaseService.addWeightLog(newLog);
      }
      if (mounted) Navigator.of(context).pop();
    } else {
      final newLog = WeightLog(id: '', date: DateTime.now(), weight: newWeight);
      await _firebaseService.addWeightLog(newLog);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _showSuccessDialog(UserProfile profile, UserGoal goal) async {
    final dailyCalories = profile.recommendedDailyIntake - goal.dailyCalorieDeficitTarget;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Your Plan is Ready!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Here\'s your personalized weight loss plan:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildPlanItem('Goal', '${goal.lbsToLose} lbs in ${goal.days} days'),
              _buildPlanItem('Daily Calorie Target', '$dailyCalories kcal'),
              _buildPlanItem('Daily Deficit Needed', '${goal.dailyCalorieDeficitTarget} kcal'),
              _buildPlanItem('Your Daily Burn', '${profile.recommendedDailyIntake} kcal'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Quick Tips:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Log everything you eat\n• Add your workouts and activities\n• Check your progress daily\n• Stay consistent!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Let\'s Start!'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
        title: Text(_isEditing ? "Edit Profile & Goal" : "Set Your Goals"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Let's Create Your Personal Plan",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "We'll calculate everything based on science",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              Text("About You", style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              )),
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
                      icon: Icons.cake,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      hint: 'e.g., 175',
                      icon: Icons.height,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _weightController,
                label: 'Current Weight (lbs)',
                hint: 'e.g., 180',
                icon: Icons.monitor_weight,
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                value: _selectedSex,
                label: 'Sex',
                icon: Icons.person,
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
                  _updateCalculations();
                },
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                value: _selectedActivityLevel,
                label: 'Activity Level',
                icon: Icons.directions_run,
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
                  _updateCalculations();
                },
              ),

              const SizedBox(height: 32),

              Text("Your Weight Loss Goal", style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              )),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _lbsController,
                      label: 'Weight to Lose (lbs)',
                      hint: 'e.g., 15',
                      icon: Icons.trending_down,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _daysController,
                      label: 'Timeframe (days)',
                      hint: 'e.g., 60',
                      isDigitsOnly: true,
                      icon: Icons.calendar_today,
                    ),
                  ),
                ],
              ),

              // Real-time calculations display
              if (_showCalculations) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calculate,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Personalized Plan',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCalculationRow('Daily calorie target:', '${_recommendedCalories.toInt()} kcal'),
                      _buildCalculationRow('Daily deficit needed:', '${_calculatedDeficit.toInt()} kcal'),
                      _buildCalculationRow('Total deficit goal:', '${(_calculatedDeficit * int.parse(_daysController.text)).toInt()} kcal'),
                      const SizedBox(height: 8),
                      Text(
                        '💡 This means eating ${_recommendedCalories.toInt()} calories per day (or less with exercise) to lose ${_lbsController.text} lbs in ${_daysController.text} days!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditing ? 'SAVE CHANGES' : 'CREATE MY PLAN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isDigitsOnly = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
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

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a value' : null,
    );
  }
}