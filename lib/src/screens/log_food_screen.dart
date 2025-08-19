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
    final quantityController = TextEditingController(text: (foodLog?.quantity ?? 1).toString());
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
                const SizedBox(height: 8),
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories per serving',
                    helperText: 'Calories for one unit/serving',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter calories' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    helperText: 'Number of servings',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    final qty = int.tryParse(value ?? '');
                    if (qty == null || qty < 1) return 'Quantity must be at least 1';
                    return null;
                  },
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
                    quantity: int.parse(quantityController.text),
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

  Future<void> _showQuantityControlDialog(FoodLog log) async {
    return showDialog(
      context: context,
      builder: (context) {
        // OPTIMIZED: Use today's stream only, much faster
        return StreamBuilder<List<FoodLog>>(
          stream: _firebaseService.todaysFoodLogStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }

            // Find the current log in the stream data
            final currentLog = snapshot.data!.firstWhere(
                  (item) => item.id == log.id,
              orElse: () => log, // Fallback to original if not found
            );

            return AlertDialog(
              title: Text(currentLog.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${currentLog.calories} kcal per serving'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: currentLog.quantity > 1 ? () {
                          final updatedLog = currentLog.copyWith(quantity: currentLog.quantity - 1);
                          _firebaseService.updateFoodLog(updatedLog);
                        } : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 36,
                        color: currentLog.quantity > 1 ? Colors.red : Colors.grey,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${currentLog.quantity}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: currentLog.quantity < 99 ? () {
                          final updatedLog = currentLog.copyWith(quantity: currentLog.quantity + 1);
                          _firebaseService.updateFoodLog(updatedLog);
                        } : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 36,
                        color: currentLog.quantity < 99 ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total: ${currentLog.totalCalories} kcal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAddEditFoodDialog(foodLog: currentLog);
                  },
                  child: const Text("Edit"),
                ),
                TextButton(
                  onPressed: () {
                    _firebaseService.deleteFoodLog(currentLog.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ],
            );
          },
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
              quantity: 1, // Always start with quantity 1 from favorites
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
        // OPTIMIZED: Use today's data only - much faster!
        stream: _firebaseService.todaysFoodLogStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No food logged yet today.'));
          }

          final todaysLogs = snapshot.data!;
          final totalCalories = todaysLogs.fold(0, (sum, item) => sum + item.totalCalories);

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
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(log.name),
                        subtitle: log.quantity > 1
                            ? Text('${log.calories} kcal × ${log.quantity}')
                            : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (log.quantity > 1) ...[
                              Text(
                                '${log.totalCalories} kcal',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'qty: ${log.quantity}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ] else ...[
                              Text('${log.calories} kcal'),
                            ],
                          ],
                        ),
                        onLongPress: () => _showQuantityControlDialog(log),
                      ),
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