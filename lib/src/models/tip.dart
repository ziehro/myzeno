class Tip {
  final String id;
  final String text;

  Tip({required this.id, required this.text});

  factory Tip.fromMap(String id, Map<String, dynamic> data) {
    return Tip(
      id: id,
      text: data['text'] ?? '',
    );
  }
}