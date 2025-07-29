// Enums no longer need Hive annotations
enum ActivityLevel { sedentary, lightlyActive, moderatelyActive, veryActive }
enum Sex { male, female }

class UserProfile {
  final String uid; // User ID from Firebase Auth
  final String email;
  final double startWeight;
  final double height;
  final int age;
  final Sex sex;
  final DateTime createdAt;
  final ActivityLevel activityLevel;

  UserProfile({
    required this.uid,
    required this.email,
    required this.startWeight,
    required this.height,
    required this.age,
    required this.sex,
    required this.createdAt,
    required this.activityLevel,
  });

  // Convert a UserProfile object into a Map for writing to Firestore
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'startWeight': startWeight,
    'height': height,
    'age': age,
    'sex': sex.toString(), // Convert enum to string
    'createdAt': createdAt.toIso8601String(), // Convert DateTime to string
    'activityLevel': activityLevel.toString(), // Convert enum to string
  };

  // Create a UserProfile object from a Firestore document snapshot
  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'],
    email: json['email'],
    startWeight: (json['startWeight'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    age: json['age'],
    // Parse string back to enum
    sex: Sex.values.firstWhere((e) => e.toString() == json['sex']),
    // Parse string back to DateTime
    createdAt: DateTime.parse(json['createdAt']),
    activityLevel: ActivityLevel.values
        .firstWhere((e) => e.toString() == json['activityLevel']),
  );

  // The TDEE calculation logic remains the same
  int get recommendedDailyIntake {
    double weightInKg = startWeight / 2.20462;
    double bmr;
    if (sex == Sex.male) {
      bmr = (10 * weightInKg + 6.25 * height - 5 * age + 5);
    } else {
      bmr = (10 * weightInKg + 6.25 * height - 5 * age - 161);
    }
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
    return (bmr * multiplier).round();
  }
}