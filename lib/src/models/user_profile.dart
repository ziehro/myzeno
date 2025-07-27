import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 100)
enum Sex {
  @HiveField(0)
  male,

  @HiveField(1)
  female,
}

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  double startWeight;

  @HiveField(1)
  double height;

  @HiveField(2)
  int age;

  @HiveField(3)
  Sex sex;

  // --- ADD THIS NEW FIELD ---
  @HiveField(4)
  DateTime createdAt;
  // --------------------------

  UserProfile({
    required this.startWeight,
    required this.height,
    required this.age,
    required this.sex,
    required this.createdAt, // <-- Also add it to the constructor
  });

  // ... (the rest of the file is the same)
  int get recommendedDailyIntake {
    double weightInKg = startWeight / 2.20462;
    if (sex == Sex.male) {
      return (10 * weightInKg + 6.25 * height - 5 * age + 5).round();
    } else {
      return (10 * weightInKg + 6.25 * height - 5 * age - 161).round();
    }
  }
}