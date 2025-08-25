import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zeno/src/models/recipe.dart';
import 'package:zeno/src/models/tip.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/services/subscription_service.dart';
import 'package:zeno/src/widgets/app_menu_button.dart';
import 'package:zeno/src/widgets/paywall_widget.dart';
import 'package:zeno/main.dart'; // For ServiceProvider

class TipsScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const TipsScreen({super.key, this.onNavigateToTab});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  late SubscriptionService _subscriptionService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscriptionService = ServiceProvider.of(context).subscriptionService;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Tips & Recipes"),
            if (_subscriptionService.isFree) ...[
              const SizedBox(width: 8),
              Icon(Icons.lock, size: 16, color: Colors.amber.shade600),
            ],
            if (_subscriptionService.isPremium) ...[
              const SizedBox(width: 8),
              Icon(Icons.star, size: 16, color: Colors.amber.shade600),
            ],
          ],
        ),
        actions: [
          if (_subscriptionService.isFree)
            IconButton(
              onPressed: _showUpgradeDialog,
              icon: const Icon(Icons.star_outline),
              tooltip: 'Unlock Tips & Recipes',
            ),
          AppMenuButton(onNavigateToTab: widget.onNavigateToTab),
        ],
      ),
      body: FeatureGate(
        feature: 'tips',
        child: const TipsScreenContent(),
        fallback: PaywallWidget(
          feature: 'tips',
          customTitle: '💡 Expert Health Tips & Recipes',
          customDescription: 'Get access to professionally curated health tips and nutritious recipes to accelerate your wellness journey.',
          child: const TipsScreenContent(),
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => const SubscriptionDialog(),
    );
  }
}

class TipsScreenContent extends StatefulWidget {
  const TipsScreenContent({super.key});

  @override
  State<TipsScreenContent> createState() => _TipsScreenContentState();
}

class _TipsScreenContentState extends State<TipsScreenContent> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _showAddTipDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a New Tip'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter content' : null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await FirebaseFirestore.instance.collection('tips').add({
                      'title': titleController.text,
                      'content': contentController.text,
                    });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tip added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding tip: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddRecipeDialog() async {
    final nameController = TextEditingController();
    final ingredientsController = TextEditingController();
    final instructionsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add a New Recipe'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Recipe Name'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
                    ),
                    TextFormField(
                      controller: ingredientsController,
                      decoration: const InputDecoration(labelText: 'Ingredients'),
                      maxLines: 4,
                      validator: (value) => (value == null || value.isEmpty) ? 'Please list ingredients' : null,
                    ),
                    TextFormField(
                      controller: instructionsController,
                      decoration: const InputDecoration(labelText: 'Instructions'),
                      maxLines: 5,
                      validator: (value) => (value == null || value.isEmpty) ? 'Please provide instructions' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await FirebaseFirestore.instance.collection('recipes').add({
                        'name': nameController.text,
                        'ingredients': ingredientsController.text,
                        'instructions': instructionsController.text,
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recipe added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding recipe: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium badge
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Premium Content',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Curated by nutrition experts and fitness professionals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tips section
          _buildSectionHeader("Health & Wellness Tips", _showAddTipDialog),
          const SizedBox(height: 16),
          _buildTipsGrid(),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Recipes section
          _buildSectionHeader("Healthy Recipes", _showAddRecipeDialog),
          const SizedBox(height: 16),
          _buildRecipesGrid(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text("Add"),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tips').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No Tips Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Add your first health tip!'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddTipDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Tip'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return SizedBox(
          height: 280, // Fixed height for horizontal scroll
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title']?.toString() ?? 'No Title';
              final content = data['content']?.toString() ?? 'No Content';

              return Container(
                width: 320, // Fixed width for each card
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade50, Colors.green.shade50],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Tip'),
                                        content: Text('Delete "$title"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldDelete == true) {
                                      await doc.reference.delete();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tip deleted'), backgroundColor: Colors.green),
                                        );
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Scrollable content area
                          Expanded(
                            child: SingleChildScrollView(
                              child: SelectableText(
                                content,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecipesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No Recipes Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Add your first healthy recipe!'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddRecipeDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Recipe'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return SizedBox(
          height: 350, // Taller height for recipes with more content
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name']?.toString() ?? 'No Name';
              final ingredients = data['ingredients']?.toString() ?? 'No Ingredients';
              final instructions = data['instructions']?.toString() ?? 'No Instructions';

              return Container(
                width: 340, // Slightly wider for recipes
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.orange.shade50, Colors.red.shade50],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.restaurant_menu, color: Colors.orange.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Recipe'),
                                        content: Text('Delete "$name"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldDelete == true) {
                                      await doc.reference.delete();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Recipe deleted'), backgroundColor: Colors.green),
                                        );
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Scrollable content area
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ingredients Section
                                  Text(
                                    "Ingredients:",
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    ingredients,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Instructions Section
                                  Text(
                                    "Instructions:",
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    instructions,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}