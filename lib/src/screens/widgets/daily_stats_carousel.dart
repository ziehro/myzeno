// lib/src/screens/widgets/daily_stats_carousel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/daily_stat.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'dart:math';

class DailyStatsCarousel extends StatelessWidget {
  final List<DailyStat> dailyStats;
  final UserProfile userProfile;
  final Function(DailyStat) onShowDetails;

  const DailyStatsCarousel({
    super.key,
    required this.dailyStats,
    required this.userProfile,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Daily Summaries", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 255,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9, initialPage: max(0, dailyStats.length - 1)),
            itemCount: dailyStats.length,
            itemBuilder: (context, index) {
              final stat = dailyStats[index];
              final totalCaloriesOut = userProfile.recommendedDailyIntake + stat.caloriesOut;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDate(stat.date), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _statRow(context, "Calories In:", "${stat.caloriesIn.toInt()} kcal"),
                              _statRow(context, "Calories Out:", "${totalCaloriesOut.toInt()} kcal"),
                              const SizedBox(height: 8),
                              _statRow(context, "Net vs Goal:", "${stat.differenceFromGoal.toStringAsFixed(0)} kcal",
                                  valueColor: stat.differenceFromGoal > 0 ? Colors.orange.shade700 : Colors.green.shade700),
                              _statRow(context, "Theoretical Change:", "${stat.theoreticalGainLoss.toStringAsFixed(2)} lbs",
                                  valueColor: stat.theoreticalGainLoss >= 0 ? Colors.orange.shade700 : Colors.green.shade700),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () => onShowDetails(stat),
                          child: const Text("Details"),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Today";
    if (checkDate == yesterday) return "Yesterday";
    return DateFormat('MMMM d').format(date);
  }

  Widget _statRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}