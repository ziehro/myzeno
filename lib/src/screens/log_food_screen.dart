import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/widgets/app_menu_button.dart';

class LogFoodScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const LogFoodScreen({super.key, this.onNavigateToTab});

  @override
  State<LogFoodScreen> createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  final _firebaseService = FirebaseService();

  Future<void> _showAddEditFoodDialog({FoodLog? foodLog}) async {
    final nameController = TextEditingController(text: foodLog?.name);
    final caloriesController = TextEditingController(text: foodLog?.calories.toString());
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(foodLog == null ? 'Add Food Entry' : 'Edit Food Entry'),
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
                  final logToSave = FoodLog(
                    id: foodLog?.id ?? '',
                    name: nameController.text,
                    calories: int.parse(caloriesController.text),
                    date: foodLog?.date ?? DateTime.now(),
                  );

                  if (foodLog != null) {
                    _firebaseService.updateFoodLog(logToSave);
                  } else {
                    _firebaseService.addFoodLog(logToSave);
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDeleteDialog(FoodLog log) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(log.name),
          content: const Text("Would you like to edit or delete this item?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddEditFoodDialog(foodLog: log);
              },
              child: const Text("Edit"),
            ),
            TextButton(
              onPressed: () {
                _firebaseService.deleteFoodLog(log.id);
                Navigator.of(context).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFrequentFoodMenu() {
    return StreamBuilder<List<FoodLog>>(
      stream: _firebaseService.frequentFoodLogStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.star, color: Theme.of(context).disabledColor),
                const SizedBox(width: 8),
                Text("From Favorites", style: TextStyle(color: Theme.of(context).disabledColor)),
              ],
            ),
          );
        }
        final frequentLogs = snapshot.data!;
        return PopupMenuButton<FoodLog>(
          offset: const Offset(0, -120),
          onSelected: (FoodLog foodLog) {
            _firebaseService.addFoodLog(FoodLog(
              id: '',
              name: foodLog.name,
              calories: foodLog.calories,
              date: DateTime.now(),
            ));
          },
          itemBuilder: (BuildContext context) {
            return frequentLogs.map((FoodLog log) {
              return PopupMenuItem<FoodLog>(
                value: log,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.name),
                    Text('${log.calories} kcal', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              );
            }).toList();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                Icon(Icons.star),
                SizedBox(width: 8),
                Text("From Favorites"),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Log (${DateFormat.yMMMd().format(DateTime.now())})'),
        actions: [AppMenuButton(onNavigateToTab: widget.onNavigateToTab)],
      ),
      body: StreamBuilder<List<FoodLog>>(
        stream: _firebaseService.foodLogStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No food logged yet today.'));
          }

          final allLogs = snapshot.data!;
          final today = DateTime.now();
          final todaysLogs = allLogs.where((log) =>
          log.date.year == today.year &&
              log.date.month == today.month &&
              log.date.day == today.day).toList();

          if (todaysLogs.isEmpty) {
            return const Center(child: Text('No food logged yet today.'));
          }

          final totalCalories = todaysLogs.fold(0, (sum, item) => sum + item.calories);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Total: $totalCalories kcal', style: Theme.of(context).textTheme.headlineSmall),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: todaysLogs.length,
                  itemBuilder: (context, index) {
                    final log = todaysLogs[index];
                    return ListTile(
                      title: Text(log.name),
                      trailing: Text('${log.calories} kcal'),
                      onLongPress: () => _showEditDeleteDialog(log),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditFoodDialog(),
        tooltip: 'Add Food',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(width: 4),
            _buildFrequentFoodMenu(),
          ],
        ),
      ),
    );
  }
}