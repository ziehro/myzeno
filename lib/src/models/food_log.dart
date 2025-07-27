import 'package:hive/hive.dart';

part 'food_log.g.dart';

@HiveType(typeId: 3)
class FoodLog extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int calories;

  @HiveField(2)
  DateTime date;

  FoodLog({
    required this.name,
    required this.calories,
    required this.date,
  });
}