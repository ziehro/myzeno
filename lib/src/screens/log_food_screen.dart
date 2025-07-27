import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/food_log.dart';

class LogFoodScreen extends StatefulWidget {
  const LogFoodScreen({super.key});

  @override
  State<LogFoodScreen> createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  // --- Function to show the pop-up dialog for adding food ---
  Future<void> _showAddFoodDialog() async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Food Entry'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Food Name'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
                ),
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(labelText: 'Calories (kcal)'),
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
                  final newLog = FoodLog(
                    name: nameController.text,
                    calories: int.parse(caloriesController.text),
                    date: DateTime.now(),
                  );
                  // Use .add() to append to the box
                  Hive.box<FoodLog>('food_log_box').add(newLog);
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
    final foodBox = Hive.box<FoodLog>('food_log_box');

    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Log (${DateFormat.yMMMd().format(DateTime.now())})'),
      ),
      // This builder automatically listens for changes in the database box
      body: ValueListenableBuilder(
        valueListenable: foodBox.listenable(),
        builder: (context, Box<FoodLog> box, _) {
          // Filter logs to show only entries from today
          final today = DateTime.now();
          final todaysLogs = box.values.where((log) =>
          log.date.year == today.year &&
              log.date.month == today.month &&
              log.date.day == today.day
          ).toList();

          if (todaysLogs.isEmpty) {
            return const Center(child: Text('No food logged yet today.'));
          }

          // Calculate the total calories for the day
          final totalCalories = todaysLogs.fold(0, (sum, item) => sum + item.calories);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total: $totalCalories kcal',
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
                      trailing: Text('${log.calories} kcal'),
                      // TODO: Add functionality to delete or edit an entry
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodDialog,
        tooltip: 'Add Food',
        child: const Icon(Icons.add),
      ),
    );
  }
}