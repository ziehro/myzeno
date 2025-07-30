import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String ingredients;
  final String instructions;
  final String imageUrl; // URL to an image for the recipe

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      ingredients: data['ingredients'] ?? '',
      instructions: data['instructions'] ?? '',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150', // Default image
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'ingredients': ingredients,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(), // To sort by newest
    };
  }
}