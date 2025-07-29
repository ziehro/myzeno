class FoodLog {
  final String id; // To store the Firestore document ID
  final String name;
  final int calories;
  final DateTime date;

  FoodLog({
    required this.id,
    required this.name,
    required this.calories,
    required this.date,
  });

  // Convert to a Map for Firestore (ID is not stored in the document data)
  Map<String, dynamic> toJson() => {
    'name': name,
    'calories': calories,
    'date': date.toIso8601String(),
  };

  // Create from a Firestore document, passing in the document's ID
  static FoodLog fromJson(Map<String, dynamic> json, String id) => FoodLog(
    id: id,
    name: json['name'],
    calories: json['calories'],
    date: DateTime.parse(json['date']),
  );
}