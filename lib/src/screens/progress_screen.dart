import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/daily_stat.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'dart:math';
import 'widgets/daily_stats_carousel.dart';
import 'widgets/net_calorie_chart_section.dart';
import 'widgets/weight_chart_section.dart';
import 'widgets/calorie_chart_section.dart';
import 'package:zeno/src/widgets/app_menu_button.dart';

class ProgressScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ProgressScreen({super.key, this.onNavigateToTab});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Future<Map<String, dynamic>>? _userDataFuture;
  final ScrollController _netCalorieScrollController = ScrollController();
  final ScrollController _weightChartScrollController = ScrollController();
  final ScrollController _calorieChartScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  @override
  void dispose() {
    _netCalorieScrollController.dispose();
    _weightChartScrollController.dispose();
    _calorieChartScrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final profile = await _firebaseService.getUserProfile();
    final goal = await _firebaseService.getUserGoal();
    return {'profile': profile, 'goal': goal};
  }

  DateTime _asLocalDate(DateTime dt) {
    final l = dt.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  // Add Food Dialog
  Future<void> _showAddEditFoodDialog(
      {FoodLog? foodLog, DateTime? forDate}) async {
    final nameController = TextEditingController(text: foodLog?.name);
    final caloriesController = TextEditingController(
        text: foodLog?.calories.toString());
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
                  validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(
                      labelText: 'Calories (kcal)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter calories'
                      : null,
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
                    date: foodLog?.date ?? forDate ?? DateTime.now(),
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

  // Add Activity Dialog
  Future<void> _showAddEditActivityDialog(
      {ActivityLog? activityLog, DateTime? forDate}) async {
    final nameController = TextEditingController(text: activityLog?.name);
    final caloriesController = TextEditingController(
        text: activityLog?.caloriesBurned.toString());
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(activityLog == null
              ? 'Add Activity Entry'
              : 'Edit Activity Entry'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Activity Name'),
                  validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(
                      labelText: 'Calories Burned'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter calories'
                      : null,
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
                    date: activityLog?.date ?? forDate ?? DateTime.now(),
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

  // Enhanced Daily Details Dialog with item management
  // Enhanced Daily Details Dialog without menu dots
  Future<void> _showDailyDetailsDialog(BuildContext context, DailyStat stat, List<FoodLog> allFood, List<ActivityLog> allActivities) {
    final day = _asLocalDate(stat.date);
    final foodForDay = allFood.where((log) => _asLocalDate(log.date) == day).toList();
    final activitiesForDay = allActivities.where((log) => _asLocalDate(log.date) == day).toList();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Details for ${DateFormat('MMMM d').format(day)}"),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Food Intake", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showAddEditFoodDialog(forDate: day);
                        },
                        tooltip: 'Add Food',
                      ),
                    ],
                  ),
                  const Divider(),
                  if (foodForDay.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("No food logged for this day."),
                    )
                  else
                    ...foodForDay.map((log) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                              Text("${log.calories} kcal"),
                            ],
                          ],
                        ),
                        // Removed the PopupMenuButton entirely
                      ),
                    )),
                  const SizedBox(height: 24),

                  // Activities Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Activities", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showAddEditActivityDialog(forDate: day);
                        },
                        tooltip: 'Add Activity',
                      ),
                    ],
                  ),
                  const Divider(),
                  if (activitiesForDay.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("No activities logged for this day."),
                    )
                  else
                    ...activitiesForDay.map((log) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(log.name),
                        subtitle: log.quantity > 1
                            ? Text('${log.caloriesBurned} kcal × ${log.quantity}')
                            : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (log.quantity > 1) ...[
                              Text(
                                '${log.totalCaloriesBurned} kcal',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'qty: ${log.quantity}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ] else ...[
                              Text("${log.caloriesBurned} kcal", style: TextStyle(color: Colors.green.shade700)),
                            ],
                          ],
                        ),
                        // Removed the PopupMenuButton entirely
                      ),
                    )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
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
        title: const Text('My Progress'),
        actions: [AppMenuButton(onNavigateToTab: widget.onNavigateToTab)],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError ||
              snapshot.data!['profile'] == null) {
            return const Center(child: Text("Could not load user data."));
          }

          final UserProfile userProfile = snapshot.data!['profile'];
          final UserGoal userGoal = snapshot.data!['goal'];

          return StreamBuilder<List<FoodLog>>(
            stream: _firebaseService.foodLogStream,
            builder: (context, foodSnapshot) {
              return StreamBuilder<List<ActivityLog>>(
                stream: _firebaseService.activityLogStream,
                builder: (context, activitySnapshot) {
                  if (foodSnapshot.connectionState == ConnectionState.waiting ||
                      activitySnapshot.connectionState ==
                          ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final foodLogs = (foodSnapshot.data ?? []).toList();
                  final activityLogs = (activitySnapshot.data ?? []).toList();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_netCalorieScrollController.hasClients) {
                      _netCalorieScrollController.jumpTo(
                          _netCalorieScrollController.position.maxScrollExtent);
                    }
                    if (_weightChartScrollController.hasClients) {
                      _weightChartScrollController.jumpTo(
                          _weightChartScrollController.position
                              .maxScrollExtent);
                    }
                    if (_calorieChartScrollController.hasClients) {
                      _calorieChartScrollController.jumpTo(
                          _calorieChartScrollController.position
                              .maxScrollExtent);
                    }
                  });

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      DailyStatsCarousel(
                        dailyStats: _prepareDailyStats(
                            userProfile, userGoal, foodLogs, activityLogs),
                        userProfile: userProfile,
                        userGoal: userGoal,
                        onShowDetails: (stat) =>
                            _showDailyDetailsDialog(
                                context, stat, foodLogs, activityLogs),
                      ),
                      const SizedBox(height: 24),
                      NetCalorieChartSection(
                        profile: userProfile,
                        goal: userGoal,
                        chartData: _prepareNetCalorieBarData(
                          foodLogs,
                          activityLogs,
                          userProfile.recommendedDailyIntake -
                              userGoal.dailyCalorieDeficitTarget,
                          userProfile.createdAt,
                        ),
                        scrollController: _netCalorieScrollController,
                      ),
                      const SizedBox(height: 24),
                      StreamBuilder<List<WeightLog>>(
                        stream: _firebaseService.weightLogStream,
                        builder: (context, weightSnapshot) {
                          if (weightSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final weightLogs = weightSnapshot.data ?? [];
                          if (weightLogs.length < 2) {
                            return const Center(heightFactor: 5,
                                child: Text(
                                    "Log weight for 2+ days to see a trend."));
                          }
                          return WeightChartSection(
                            profile: userProfile,
                            goal: userGoal,
                            chartData: _prepareWeightTrendData(
                                userProfile, userGoal, weightLogs, foodLogs,
                                activityLogs),
                            scrollController: _weightChartScrollController,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      CalorieChartSection(
                        chartData: _prepareCalorieBarData(
                            foodLogs, activityLogs),
                        scrollController: _calorieChartScrollController,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<DailyStat> _prepareDailyStats(UserProfile profile, UserGoal goal,
      List<FoodLog> foodLogs, List<ActivityLog> activityLogs) {
    final Map<DateTime, DailyStat> dailyStatsMap = {};
    const caloriesPerPound = 3500.0;
    final dailyCalorieTarget = (profile.recommendedDailyIntake -
        goal.dailyCalorieDeficitTarget).toDouble();
    final baseBurn = profile.recommendedDailyIntake.toDouble();

    final startDate = _asLocalDate(profile.createdAt);
    final today = _asLocalDate(DateTime.now());
    final daysSinceStart = today
        .difference(startDate)
        .inDays;

    for (int i = 0; i <= daysSinceStart; i++) {
      final date = startDate.add(Duration(days: i));
      dailyStatsMap[date] = DailyStat(
        date: date,
        caloriesIn: 0.0,
        caloriesOut: 0.0,
        differenceFromGoal: 0.0,
        theoreticalGainLoss: 0.0,
      );
    }

    // Use totalCalories for quantity-aware calculations
    for (final log in foodLogs) {
      final day = _asLocalDate(log.date);
      if (dailyStatsMap.containsKey(day)) {
        final current = dailyStatsMap[day]!;
        dailyStatsMap[day] = DailyStat(
          date: day,
          caloriesIn: current.caloriesIn + log.totalCalories,
          // Changed from log.calories
          caloriesOut: current.caloriesOut,
          differenceFromGoal: 0,
          theoreticalGainLoss: 0,
        );
      }
    }

    // Use totalCaloriesBurned for quantity-aware calculations
    for (final log in activityLogs) {
      final day = _asLocalDate(log.date);
      if (dailyStatsMap.containsKey(day)) {
        final current = dailyStatsMap[day]!;
        dailyStatsMap[day] = DailyStat(
          date: day,
          caloriesIn: current.caloriesIn,
          caloriesOut: current.caloriesOut + log.totalCaloriesBurned,
          // Changed from log.caloriesBurned
          differenceFromGoal: 0,
          theoreticalGainLoss: 0,
        );
      }
    }

    // Fixed calculation to match weight trend graph
    dailyStatsMap.forEach((date, stat) {
      // stat.caloriesOut is just activity calories burned
      // Total calories out = base burn + activity calories
      final totalCaloriesOut = baseBurn + stat.caloriesOut;

      // Net calorie intake after all burns
      final netCalorieIntake = stat.caloriesIn - totalCaloriesOut;

      dailyStatsMap[date] = DailyStat(
        date: date,
        caloriesIn: stat.caloriesIn,
        caloriesOut: stat.caloriesOut,
        // Keep as activity calories only
        differenceFromGoal: stat.caloriesIn - stat.caloriesOut -
            dailyCalorieTarget,
        theoreticalGainLoss: netCalorieIntake / caloriesPerPound,
      );
    });

    var sortedStats = dailyStatsMap.values.toList();
    sortedStats.sort((a, b) => a.date.compareTo(b.date));
    return sortedStats;
  }

  Map<String, dynamic> _prepareNetCalorieBarData(List<FoodLog> foodLogs,
      List<ActivityLog> activityLogs, int calorieTarget,
      DateTime startDateRaw) {
    final Map<int, double> dailyNet = {};
    final List<DateTime> dates = [];
    double maxNetValue = 0.0;

    final startDate = _asLocalDate(startDateRaw);
    final today = _asLocalDate(DateTime.now());
    final daysSinceStart = today
        .difference(startDate)
        .inDays;

    for (int i = 0; i <= daysSinceStart; i++) {
      final day = startDate.add(Duration(days: i));
      dailyNet[day.millisecondsSinceEpoch] = 0.0;
      dates.add(day);
    }

    // Use totalCalories for quantity-aware calculations
    for (final log in foodLogs) {
      final d = _asLocalDate(log.date);
      final key = d.millisecondsSinceEpoch;
      if (dailyNet.containsKey(key)) {
        dailyNet[key] =
            dailyNet[key]! + log.totalCalories; // Changed from log.calories
      }
    }

    // Use totalCaloriesBurned for quantity-aware calculations
    for (final log in activityLogs) {
      final d = _asLocalDate(log.date);
      final key = d.millisecondsSinceEpoch;
      if (dailyNet.containsKey(key)) {
        dailyNet[key] = dailyNet[key]! -
            log.totalCaloriesBurned; // Changed from log.caloriesBurned
      }
    }

    final barGroups = List.generate(dates.length, (index) {
      final key = dates[index].millisecondsSinceEpoch;
      final netValue = dailyNet[key] ?? 0.0;
      final isOverGoal = netValue > calorieTarget;

      if (netValue > maxNetValue) {
        maxNetValue = netValue;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: netValue,
            color: isOverGoal ? Colors.orange : Colors.green,
            width: 16,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ],
      );
    });

    return {'barGroups': barGroups, 'maxNetValue': maxNetValue, 'dates': dates};
  }

  Map<String, dynamic> _prepareCalorieBarData(List<FoodLog> foodLogs,
      List<ActivityLog> activityLogs) {
    final Map<int, double> dailyConsumed = {};
    final Map<int, double> dailyBurned = {};
    final List<DateTime> dates = [];

    if (foodLogs.isEmpty && activityLogs.isEmpty) {
      return {'barGroups': [], 'dates': []};
    }

    DateTime firstDate = _asLocalDate(DateTime.now());
    if (foodLogs.isNotEmpty) {
      firstDate = foodLogs
          .map((e) => _asLocalDate(e.date))
          .reduce((a, b) => a.isBefore(b) ? a : b);
    }
    if (activityLogs.isNotEmpty) {
      final firstActivityDate = activityLogs
          .map((e) => _asLocalDate(e.date))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (firstActivityDate.isBefore(firstDate)) {
        firstDate = firstActivityDate;
      }
    }

    final today = _asLocalDate(DateTime.now());
    final daysSinceStart = today
        .difference(firstDate)
        .inDays;

    for (int i = 0; i <= daysSinceStart; i++) {
      final day = firstDate.add(Duration(days: i));
      dailyConsumed[day.millisecondsSinceEpoch] = 0.0;
      dailyBurned[day.millisecondsSinceEpoch] = 0.0;
      dates.add(day);
    }

    // Use totalCalories for quantity-aware calculations
    for (final log in foodLogs) {
      final d = _asLocalDate(log.date);
      final key = d.millisecondsSinceEpoch;
      if (dailyConsumed.containsKey(key)) {
        dailyConsumed[key] = dailyConsumed[key]! +
            log.totalCalories; // Changed from log.calories
      }
    }

    // Use totalCaloriesBurned for quantity-aware calculations
    for (final log in activityLogs) {
      final d = _asLocalDate(log.date);
      final key = d.millisecondsSinceEpoch;
      if (dailyBurned.containsKey(key)) {
        dailyBurned[key] = dailyBurned[key]! +
            log.totalCaloriesBurned; // Changed from log.caloriesBurned
      }
    }

    final barGroups = List.generate(dates.length, (index) {
      final key = dates[index].millisecondsSinceEpoch;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dailyConsumed[key] ?? 0.0,
            color: Colors.orange,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
          BarChartRodData(
            toY: dailyBurned[key] ?? 0.0,
            color: Colors.lightGreen,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });

    return {'barGroups': barGroups, 'dates': dates};
  }

  Map<String, dynamic> _prepareWeightTrendData(UserProfile profile,
      UserGoal goal,
      List<WeightLog> weightLogs,
      List<FoodLog> foodLogs,
      List<ActivityLog> activityLogs,) {
    // Create daily net calorie map first
    final Map<DateTime, double> dailyNetCalories = {};

    // Use totalCalories and totalCaloriesBurned for quantity-aware calculations
    for (var log in foodLogs) {
      final day = _asLocalDate(log.date);
      dailyNetCalories.update(day, (value) => value + log.totalCalories,
          ifAbsent: () => log.totalCalories.toDouble());
    }
    for (var log in activityLogs) {
      final day = _asLocalDate(log.date);
      dailyNetCalories.update(day, (value) => value - log.totalCaloriesBurned,
          ifAbsent: () => -log.totalCaloriesBurned.toDouble());
    }

    // Create a list of all days from start to today
    final startDate = _asLocalDate(profile.createdAt);
    final today = _asLocalDate(DateTime.now());
    final daysSinceStart = today
        .difference(startDate)
        .inDays;

    final List<DateTime> allDates = [];
    final List<FlSpot> theoreticalSpots = [];
    final List<FlSpot> actualSpots = [];

    // Build arrays for every day
    final baseBurn = profile.recommendedDailyIntake.toDouble();
    const caloriesPerPound = 3500.0;
    double currentTheoreticalWeight = profile.startWeight;

    // Create weight log lookup map (day -> list of weights for that day)
    final Map<DateTime, List<WeightLog>> weightsByDay = {};
    for (var log in weightLogs) {
      final day = _asLocalDate(log.date);
      weightsByDay.update(day, (list) => list..add(log), ifAbsent: () => [log]);
    }

    for (int i = 0; i <= daysSinceStart; i++) {
      final currentDay = startDate.add(Duration(days: i));
      allDates.add(currentDay);

      // Calculate theoretical weight for this day
      if (i > 0) {
        // Get net calories for previous day (since weight change happens overnight)
        final previousDay = startDate.add(Duration(days: i - 1));
        final netCaloriesForDay = dailyNetCalories[previousDay] ?? 0.0;
        final netIntake = netCaloriesForDay - baseBurn;
        final weightChange = netIntake / caloriesPerPound;
        currentTheoreticalWeight += weightChange;
      }

      theoreticalSpots.add(FlSpot(i.toDouble(), currentTheoreticalWeight));

      // Add actual weight spots if any exist for this day
      if (weightsByDay.containsKey(currentDay)) {
        for (var weightLog in weightsByDay[currentDay]!) {
          actualSpots.add(FlSpot(i.toDouble(), weightLog.weight));
        }
      }
    }

    return {
      'actual': actualSpots,
      'theoretical': theoreticalSpots,
      'dates': allDates,
    };
  }
}