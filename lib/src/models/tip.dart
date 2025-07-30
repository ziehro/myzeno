import 'package:cloud_firestore/cloud_firestore.dart';

class Tip {
  final String id;
  final String title;
  final String content;

  Tip({required this.id, required this.title, required this.content});

  // Factory constructor to create a Tip from a Firestore document
  factory Tip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tip(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      content: data['content'] ?? 'No Content',
    );
  }

  // Method to convert a Tip object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
    };
  }
}