class FoodLog {
  final String id; // To store the Firestore document ID
  final String name;
  final int calories; // Calories per unit/serving
  final int quantity; // New field for quantity
  final DateTime date;

  FoodLog({
    required this.id,
    required this.name,
    required this.calories,
    this.quantity = 1, // Default to 1
    required this.date,
  });

  // Calculated total calories
  int get totalCalories => calories * quantity;

  // Convert to a Map for Firestore (ID is not stored in the document data)
  Map<String, dynamic> toJson() => {
    'name': name,
    'calories': calories,
    'quantity': quantity,
    'date': date.toIso8601String(),
  };

  // Create from a Firestore document, passing in the document's ID
  static FoodLog fromJson(Map<String, dynamic> json, String id) => FoodLog(
    id: id,
    name: json['name'],
    calories: json['calories'],
    quantity: json['quantity'] ?? 1, // Default to 1 for backward compatibility
    date: DateTime.parse(json['date']),
  );

  // Copy with method for updating quantity
  FoodLog copyWith({
    String? id,
    String? name,
    int? calories,
    int? quantity,
    DateTime? date,
  }) => FoodLog(
    id: id ?? this.id,
    name: name ?? this.name,
    calories: calories ?? this.calories,
    quantity: quantity ?? this.quantity,
    date: date ?? this.date,
  );
}