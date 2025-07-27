import 'package:hive/hive.dart';

part 'activity_log.g.dart';

@HiveType(typeId: 4)
class ActivityLog extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int caloriesBurned;

  @HiveField(2)
  DateTime date;

  ActivityLog({
    required this.name,
    required this.caloriesBurned,
    required this.date,
  });
}