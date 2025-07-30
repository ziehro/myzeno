import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String name;
  final String ingredients;
  final String instructions;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
  });

  // Factory constructor to create a Recipe from a Firestore document
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      name: data['name'] ?? 'No Name',
      ingredients: data['ingredients'] ?? 'No Ingredients',
      instructions: data['instructions'] ?? 'No Instructions',
    );
  }

  // Method to convert a Recipe object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
    };
  }
}