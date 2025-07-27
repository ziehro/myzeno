import 'package:hive/hive.dart';

part 'weight_log.g.dart';

@HiveType(typeId: 2)
class WeightLog extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double weight;

  WeightLog({
    required this.date,
    required this.weight,
  });
}