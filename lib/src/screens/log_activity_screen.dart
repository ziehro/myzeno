import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/activity_log.dart';

class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  Future<void> _showAddActivityDialog() async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Activity Entry'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Activity Name'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
                ),
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(labelText: 'Calories Burned'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter calories' : null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newLog = ActivityLog(
                    name: nameController.text,
                    caloriesBurned: int.parse(caloriesController.text),
                    date: DateTime.now(),
                  );
                  Hive.box<ActivityLog>('activity_log_box').add(newLog);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Activity (${DateFormat.yMMMd().format(DateTime.now())})'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ActivityLog>('activity_log_box').listenable(),
        builder: (context, Box<ActivityLog> box, _) {
          final today = DateTime.now();
          final todaysLogs = box.values.where((log) =>
          log.date.year == today.year &&
              log.date.month == today.month &&
              log.date.day == today.day
          ).toList();

          if (todaysLogs.isEmpty) {
            return const Center(child: Text('No activities logged yet today.'));
          }

          final totalCaloriesBurned = todaysLogs.fold(0, (sum, item) => sum + item.caloriesBurned);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Burned: $totalCaloriesBurned kcal',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: todaysLogs.length,
                  itemBuilder: (context, index) {
                    final log = todaysLogs[index];
                    return ListTile(
                      title: Text(log.name),
                      trailing: Text('-${log.caloriesBurned} kcal', style: TextStyle(color: Colors.green.shade700)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityDialog,
        tooltip: 'Add Activity',
        child: const Icon(Icons.fitness_center),
      ),
    );
  }
}