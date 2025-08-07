import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/widgets/app_menu_button.dart'; // <-- added

class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final _firebaseService = FirebaseService();

  Future<void> _showAddEditActivityDialog({ActivityLog? activityLog}) async {
    final nameController = TextEditingController(text: activityLog?.name);
    final caloriesController = TextEditingController(text: activityLog?.caloriesBurned.toString());
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(activityLog == null ? 'Add Activity Entry' : 'Edit Activity Entry'),
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
                  final logToSave = ActivityLog(
                    id: activityLog?.id ?? '',
                    name: nameController.text,
                    caloriesBurned: int.parse(caloriesController.text),
                    date: activityLog?.date ?? DateTime.now(),
                  );
                  if (activityLog != null) {
                    _firebaseService.updateActivityLog(logToSave);
                  } else {
                    _firebaseService.addActivityLog(logToSave);
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

  Future<void> _showEditDeleteDialog(ActivityLog log) async {
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
                _showAddEditActivityDialog(activityLog: log);
              },
              child: const Text("Edit"),
            ),
            TextButton(
              onPressed: () {
                _firebaseService.deleteActivityLog(log.id);
                Navigator.of(context).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFrequentActivityMenu() {
    return StreamBuilder<List<ActivityLog>>(
      stream: _firebaseService.frequentActivityLogStream,
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
        return PopupMenuButton<ActivityLog>(
          offset: const Offset(0, -120),
          onSelected: (ActivityLog activityLog) {
            _firebaseService.addActivityLog(ActivityLog(
              id: '',
              name: activityLog.name,
              caloriesBurned: activityLog.caloriesBurned,
              date: DateTime.now(),
            ));
          },
          itemBuilder: (BuildContext context) {
            return frequentLogs.map((ActivityLog log) {
              return PopupMenuItem<ActivityLog>(
                value: log,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.name),
                    Text(
                      '${log.caloriesBurned} kcal',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
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
        title: Text('Today\'s Activity (${DateFormat.yMMMd().format(DateTime.now())})'),
        actions: const [AppMenuButton()], // <-- added
      ),
      body: StreamBuilder<List<ActivityLog>>(
        stream: _firebaseService.activityLogStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No activities logged yet.'));
          }

          final allLogs = snapshot.data!;
          final today = DateTime.now();
          final todaysLogs = allLogs.where((log) =>
          log.date.year == today.year &&
              log.date.month == today.month &&
              log.date.day == today.day).toList();

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
        onPressed: () => _showAddEditActivityDialog(),
        tooltip: 'Add Activity',
        child: const Icon(Icons.fitness_center),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(width: 4),
            _buildFrequentActivityMenu(),
          ],
        ),
      ),
    );
  }
}
