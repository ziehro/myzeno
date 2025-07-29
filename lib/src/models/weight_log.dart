class WeightLog {
  final String id; // To store the Firestore document ID
  final DateTime date;
  final double weight;

  WeightLog({
    required this.id,
    required this.date,
    required this.weight,
  });

  // Convert to a Map for Firestore
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
  };

  // Create from a Firestore document
  static WeightLog fromJson(Map<String, dynamic> json, String id) => WeightLog(
    id: id,
    date: DateTime.parse(json['date']),
    weight: (json['weight'] as num).toDouble(),
  );
}