import 'package:flutter/material.dart';

class TipsAndRecipesPage extends StatelessWidget {
  const TipsAndRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips and Recipes'),
      ),
      body: const Center(
        child: Text('Tips and recipes will be shown here.'),
      ),
    );
  }
}