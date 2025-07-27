import 'package:hive/hive.dart';

part 'user_profile.g.dart';

// Enum for Activity Level with its own Hive type ID
@HiveType(typeId: 101)
enum ActivityLevel {
  @HiveField(0)
  sedentary, // BMR x 1.2

  @HiveField(1)
  lightlyActive, // BMR x 1.375

  @HiveField(2)
  moderatelyActive, // BMR x 1.55

  @HiveField(3)
  veryActive, // BMR x 1.725
}

// Enum for Sex with its own Hive type ID
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
  double height; // Stored in cm

  @HiveField(2)
  int age;

  @HiveField(3)
  Sex sex;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  ActivityLevel activityLevel;

  UserProfile({
    required this.startWeight,
    required this.height,
    required this.age,
    required this.sex,
    required this.createdAt,
    required this.activityLevel,
  });

  // This getter calculates the Total Daily Energy Expenditure (TDEE)
  int get recommendedDailyIntake {
    // 1. Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor formula
    double weightInKg = startWeight / 2.20462;
    double bmr;

    if (sex == Sex.male) {
      // Formula for Men
      bmr = (10 * weightInKg + 6.25 * height - 5 * age + 5);
    } else {
      // Formula for Women
      bmr = (10 * weightInKg + 6.25 * height - 5 * age - 161);
    }

    // 2. Determine the activity multiplier based on the user's selection
    double multiplier;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        multiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        multiplier = 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        multiplier = 1.55;
        break;
      case ActivityLevel.veryActive:
        multiplier = 1.725;
        break;
    }

    // 3. Calculate the final TDEE and return it as a whole number
    return (bmr * multiplier).round();
  }
}