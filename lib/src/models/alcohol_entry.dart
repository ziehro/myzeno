import 'package:flutter/material.dart';

class AlcoholEntry {
  final String id;
  final String name;
  final double alcoholPercent;
  final double volume; // ml per container
  final int quantity; // number of containers
  final double price; // total price
  final DateTime date;

  // Calculated values
  final double totalAlcohol; // total ml of alcohol
  final double alcoholPerDollar; // ml of alcohol per dollar
  final double totalCalories; // total calories from alcohol

  AlcoholEntry({
    required this.id,
    required this.name,
    required this.alcoholPercent,
    required this.volume,
    required this.quantity,
    required this.price,
    required this.date,
    required this.totalAlcohol,
    required this.alcoholPerDollar,
    required this.totalCalories,
  });

  // Convert to a Map for storage
  Map<String, dynamic> toJson() => {
    'name': name,
    'alcoholPercent': alcoholPercent,
    'volume': volume,
    'quantity': quantity,
    'price': price,
    'date': date.toIso8601String(),
    'totalAlcohol': totalAlcohol,
    'alcoholPerDollar': alcoholPerDollar,
    'totalCalories': totalCalories,
  };

  // Create from storage
  static AlcoholEntry fromJson(Map<String, dynamic> json, String id) => AlcoholEntry(
    id: id,
    name: json['name'],
    alcoholPercent: (json['alcoholPercent'] as num).toDouble(),
    volume: (json['volume'] as num).toDouble(),
    quantity: json['quantity'],
    price: (json['price'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    totalAlcohol: (json['totalAlcohol'] as num).toDouble(),
    alcoholPerDollar: (json['alcoholPerDollar'] as num).toDouble(),
    totalCalories: (json['totalCalories'] as num).toDouble(),
  );

  // Copy with method for easy updates
  AlcoholEntry copyWith({
    String? id,
    String? name,
    double? alcoholPercent,
    double? volume,
    int? quantity,
    double? price,
    DateTime? date,
    double? totalAlcohol,
    double? alcoholPerDollar,
    double? totalCalories,
  }) => AlcoholEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    alcoholPercent: alcoholPercent ?? this.alcoholPercent,
    volume: volume ?? this.volume,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    date: date ?? this.date,
    totalAlcohol: totalAlcohol ?? this.totalAlcohol,
    alcoholPerDollar: alcoholPerDollar ?? this.alcoholPerDollar,
    totalCalories: totalCalories ?? this.totalCalories,
  );

  // Helper to get value rating color
  Color get valueColor {
    if (alcoholPerDollar >= 11) return Colors.green;
    if (alcoholPerDollar >= 8) return Colors.orange;
    return Colors.red;
  }

  // Helper to get value rating text
  String get valueRating {
    if (alcoholPerDollar >= 11) return 'Excellent Value';
    if (alcoholPerDollar >= 8) return 'Good Value';
    return 'Poor Value';
  }
}