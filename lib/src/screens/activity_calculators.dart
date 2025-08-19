import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';

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
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedActivity = 'walking_moderate';
  final _activityNameController = TextEditingController();
  final _durationController = TextEditingController();
  double _caloriesBurned = 0;
  double _currentWeight = 0;
  bool _isLoadingWeight = true;

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

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
  }

  Future<void> _loadUserWeight() async {
    try {
      // First try to get the latest weight log
      final weightLogs = await _firebaseService.weightLogStream.first;

      if (weightLogs.isNotEmpty) {
        setState(() {
          _currentWeight = weightLogs.first.weight;
          _isLoadingWeight = false;
        });
      } else {
        // Fall back to user profile start weight
        final userProfile = await _firebaseService.getUserProfile();
        if (userProfile != null) {
          setState(() {
            _currentWeight = userProfile.startWeight;
            _isLoadingWeight = false;
          });
        }
      }
    } catch (e) {
      // If all else fails, default to 150 lbs
      setState(() {
        _currentWeight = 150.0;
        _isLoadingWeight = false;
      });
    }
  }

  void _calculate() {
    final duration = double.tryParse(_durationController.text) ?? 0;
    final metValue = _activities[_selectedActivity]!['metValue'];

    if (_currentWeight > 0 && duration > 0) {
      // Formula: Calories = MET × weight(kg) × time(hours)
      final weightKg = _currentWeight * 0.453592; // Convert lbs to kg
      final durationHours = duration / 60; // Convert minutes to hours

      setState(() {
        _caloriesBurned = metValue * weightKg * durationHours;
      });
    }
  }

  void _addToActivityLog() {
    if (_caloriesBurned > 0) {
      final activityName = _activityNameController.text.isNotEmpty
          ? _activityNameController.text
          : _activities[_selectedActivity]!['name'];

      final activityLog = ActivityLog(
        id: '',
        name: activityName,
        caloriesBurned: _caloriesBurned.round(),
        quantity: 1, // Always add as quantity 1 from calculator
        date: DateTime.now(),
      );
      _firebaseService.addActivityLog(activityLog);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $activityName (${_caloriesBurned.round()} kcal) to activity log!'),
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
            Text('Basic Activity Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _activityNameController,
              decoration: const InputDecoration(
                labelText: 'Custom activity name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration',
                border: const OutlineInputBorder(),
                suffixText: 'minutes',
                helperText: _isLoadingWeight
                    ? 'Loading weight...'
                    : 'Using weight: ${_currentWeight.toStringAsFixed(1)} lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoadingWeight ? null : _calculate,
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
                      'Calories Burned: ${_caloriesBurned.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addToActivityLog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Activity Log'),
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

// Walking/Running Calculator
class WalkingRunningCalculator extends StatefulWidget {
  const WalkingRunningCalculator({super.key});

  @override
  State<WalkingRunningCalculator> createState() => _WalkingRunningCalculatorState();
}

class _WalkingRunningCalculatorState extends State<WalkingRunningCalculator> {
  final FirebaseService _firebaseService = FirebaseService();
  final _activityNameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _speedController = TextEditingController();
  double _caloriesBurned = 0;
  double _duration = 0;
  double _currentWeight = 0;
  bool _isLoadingWeight = true;

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
  }

  Future<void> _loadUserWeight() async {
    try {
      // First try to get the latest weight log
      final weightLogs = await _firebaseService.weightLogStream.first;

      if (weightLogs.isNotEmpty) {
        setState(() {
          _currentWeight = weightLogs.first.weight;
          _isLoadingWeight = false;
        });
      } else {
        // Fall back to user profile start weight
        final userProfile = await _firebaseService.getUserProfile();
        if (userProfile != null) {
          setState(() {
            _currentWeight = userProfile.startWeight;
            _isLoadingWeight = false;
          });
        }
      }
    } catch (e) {
      // If all else fails, default to 150 lbs
      setState(() {
        _currentWeight = 150.0;
        _isLoadingWeight = false;
      });
    }
  }

  void _calculate() {
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final speed = double.tryParse(_speedController.text) ?? 0;

    if (_currentWeight > 0 && distance > 0 && speed > 0) {
      final durationHours = distance / speed;
      final weightKg = _currentWeight * 0.453592;

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

  void _addToActivityLog() {
    if (_caloriesBurned > 0) {
      final activityName = _activityNameController.text.isNotEmpty
          ? _activityNameController.text
          : 'Walking/Running ${_speedController.text} mph';

      final activityLog = ActivityLog(
        id: '',
        name: activityName,
        caloriesBurned: _caloriesBurned.round(),
        quantity: 1, // Always add as quantity 1 from calculator
        date: DateTime.now(),
      );
      _firebaseService.addActivityLog(activityLog);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $activityName (${_caloriesBurned.round()} kcal) to activity log!'),
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
            Text('Walking/Running Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _activityNameController,
              decoration: const InputDecoration(
                labelText: 'Custom activity name (optional)',
                border: OutlineInputBorder(),
              ),
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
              decoration: InputDecoration(
                labelText: 'Average speed',
                border: const OutlineInputBorder(),
                suffixText: 'mph',
                helperText: _isLoadingWeight
                    ? 'Loading weight...'
                    : 'Using weight: ${_currentWeight.toStringAsFixed(1)} lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoadingWeight ? null : _calculate,
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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addToActivityLog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Activity Log'),
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

// Gym Workout Calculator
class GymWorkoutCalculator extends StatefulWidget {
  const GymWorkoutCalculator({super.key});

  @override
  State<GymWorkoutCalculator> createState() => _GymWorkoutCalculatorState();
}

class _GymWorkoutCalculatorState extends State<GymWorkoutCalculator> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedWorkout = 'weight_training';
  final _activityNameController = TextEditingController();
  final _durationController = TextEditingController();
  double _caloriesBurned = 0;
  double _currentWeight = 0;
  bool _isLoadingWeight = true;

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

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
  }

  Future<void> _loadUserWeight() async {
    try {
      // First try to get the latest weight log
      final weightLogs = await _firebaseService.weightLogStream.first;

      if (weightLogs.isNotEmpty) {
        setState(() {
          _currentWeight = weightLogs.first.weight;
          _isLoadingWeight = false;
        });
      } else {
        // Fall back to user profile start weight
        final userProfile = await _firebaseService.getUserProfile();
        if (userProfile != null) {
          setState(() {
            _currentWeight = userProfile.startWeight;
            _isLoadingWeight = false;
          });
        }
      }
    } catch (e) {
      // If all else fails, default to 150 lbs
      setState(() {
        _currentWeight = 150.0;
        _isLoadingWeight = false;
      });
    }
  }

  void _calculate() {
    final duration = double.tryParse(_durationController.text) ?? 0;
    final metValue = _workouts[_selectedWorkout]!['metValue'];

    if (_currentWeight > 0 && duration > 0) {
      final weightKg = _currentWeight * 0.453592;
      final durationHours = duration / 60;

      setState(() {
        _caloriesBurned = metValue * weightKg * durationHours;
      });
    }
  }

  void _addToActivityLog() {
    if (_caloriesBurned > 0) {
      final activityName = _activityNameController.text.isNotEmpty
          ? _activityNameController.text
          : _workouts[_selectedWorkout]!['name'];

      final activityLog = ActivityLog(
        id: '',
        name: activityName,
        caloriesBurned: _caloriesBurned.round(),
        quantity: 1, // Always add as quantity 1 from calculator
        date: DateTime.now(),
      );
      _firebaseService.addActivityLog(activityLog);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $activityName (${_caloriesBurned.round()} kcal) to activity log!'),
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
            Text('Gym Workout Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _activityNameController,
              decoration: const InputDecoration(
                labelText: 'Custom workout name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration',
                border: const OutlineInputBorder(),
                suffixText: 'minutes',
                helperText: _isLoadingWeight
                    ? 'Loading weight...'
                    : 'Using weight: ${_currentWeight.toStringAsFixed(1)} lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoadingWeight ? null : _calculate,
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
                      'Calories Burned: ${_caloriesBurned.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addToActivityLog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Activity Log'),
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

// Sports Activity Calculator
class SportsActivityCalculator extends StatefulWidget {
  const SportsActivityCalculator({super.key});

  @override
  State<SportsActivityCalculator> createState() => _SportsActivityCalculatorState();
}

class _SportsActivityCalculatorState extends State<SportsActivityCalculator> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedSport = 'basketball';
  final _activityNameController = TextEditingController();
  final _durationController = TextEditingController();
  double _caloriesBurned = 0;
  double _currentWeight = 0;
  bool _isLoadingWeight = true;

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

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
  }

  Future<void> _loadUserWeight() async {
    try {
      // First try to get the latest weight log
      final weightLogs = await _firebaseService.weightLogStream.first;

      if (weightLogs.isNotEmpty) {
        setState(() {
          _currentWeight = weightLogs.first.weight;
          _isLoadingWeight = false;
        });
      } else {
        // Fall back to user profile start weight
        final userProfile = await _firebaseService.getUserProfile();
        if (userProfile != null) {
          setState(() {
            _currentWeight = userProfile.startWeight;
            _isLoadingWeight = false;
          });
        }
      }
    } catch (e) {
      // If all else fails, default to 150 lbs
      setState(() {
        _currentWeight = 150.0;
        _isLoadingWeight = false;
      });
    }
  }

  void _calculate() {
    final duration = double.tryParse(_durationController.text) ?? 0;
    final metValue = _sports[_selectedSport]!['metValue'];

    if (_currentWeight > 0 && duration > 0) {
      final weightKg = _currentWeight * 0.453592;
      final durationHours = duration / 60;

      setState(() {
        _caloriesBurned = metValue * weightKg * durationHours;
      });
    }
  }

  void _addToActivityLog() {
    if (_caloriesBurned > 0) {
      final activityName = _activityNameController.text.isNotEmpty
          ? _activityNameController.text
          : _sports[_selectedSport]!['name'];

      final activityLog = ActivityLog(
        id: '',
        name: activityName,
        caloriesBurned: _caloriesBurned.round(),
        quantity: 1, // Always add as quantity 1 from calculator
        date: DateTime.now(),
      );
      _firebaseService.addActivityLog(activityLog);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $activityName (${_caloriesBurned.round()} kcal) to activity log!'),
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
            Text('Sports Activity Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _activityNameController,
              decoration: const InputDecoration(
                labelText: 'Custom sport name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration',
                border: const OutlineInputBorder(),
                suffixText: 'minutes',
                helperText: _isLoadingWeight
                    ? 'Loading weight...'
                    : 'Using weight: ${_currentWeight.toStringAsFixed(1)} lbs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoadingWeight ? null : _calculate,
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
                      'Calories Burned: ${_caloriesBurned.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addToActivityLog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Activity Log'),
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