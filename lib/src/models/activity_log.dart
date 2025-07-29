class ActivityLog {
  final String id; // To store the Firestore document ID
  final String name;
  final int caloriesBurned;
  final DateTime date;

  ActivityLog({
    required this.id,
    required this.name,
    required this.caloriesBurned,
    required this.date,
  });

  // Convert to a Map for Firestore
  Map<String, dynamic> toJson() => {
    'name': name,
    'caloriesBurned': caloriesBurned,
    'date': date.toIso8601String(),
  };

  // Create from a Firestore document
  static ActivityLog fromJson(Map<String, dynamic> json, String id) =>
      ActivityLog(
        id: id,
        name: json['name'],
        caloriesBurned: json['caloriesBurned'],
        date: DateTime.parse(json['date']),
      );
}