class ActivityLog {
  final String id; // To store the Firestore document ID
  final String name;
  final int caloriesBurned; // Calories burned per unit/session
  final int quantity; // New field for quantity (e.g., sets, sessions, etc.)
  final DateTime date;

  ActivityLog({
    required this.id,
    required this.name,
    required this.caloriesBurned,
    this.quantity = 1, // Default to 1
    required this.date,
  });

  // Calculated total calories burned
  int get totalCaloriesBurned => caloriesBurned * quantity;

  // Convert to a Map for Firestore
  Map<String, dynamic> toJson() => {
    'name': name,
    'caloriesBurned': caloriesBurned,
    'quantity': quantity,
    'date': date.toIso8601String(),
  };

  // Create from a Firestore document
  static ActivityLog fromJson(Map<String, dynamic> json, String id) =>
      ActivityLog(
        id: id,
        name: json['name'],
        caloriesBurned: json['caloriesBurned'],
        quantity: json['quantity'] ?? 1, // Default to 1 for backward compatibility
        date: DateTime.parse(json['date']),
      );

  // Copy with method for updating quantity
  ActivityLog copyWith({
    String? id,
    String? name,
    int? caloriesBurned,
    int? quantity,
    DateTime? date,
  }) => ActivityLog(
    id: id ?? this.id,
    name: name ?? this.name,
    caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    quantity: quantity ?? this.quantity,
    date: date ?? this.date,
  );
}