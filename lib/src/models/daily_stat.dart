// lib/src/models/daily_stat.dart
class DailyStat {
  final DateTime date;
  final double caloriesIn;
  final double caloriesOut; // Logged activity burn
  final double differenceFromGoal;
  final double theoreticalGainLoss;

  DailyStat({
    required this.date,
    required this.caloriesIn,
    required this.caloriesOut,
    required this.differenceFromGoal,
    required this.theoreticalGainLoss,
  });
}