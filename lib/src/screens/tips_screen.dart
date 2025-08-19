import 'package:flutter/material.dart';
import 'package:zeno/src/models/recipe.dart';
import 'package:zeno/src/models/tip.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/services/subscription_service.dart';   // ← NEW FILE
import 'package:zeno/src/widgets/app_menu_button.dart';
import 'package:zeno/src/widgets/paywall_widget.dart';          // ← NEW FILE
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newTip = Tip(id: '', title: titleController.text, content: contentController.text);
                  _firebaseService.addTip(newTip);
                  Navigator.of(context).pop();
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
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final newRecipe = Recipe(
                      id: '',
                      name: nameController.text,
                      ingredients: ingredientsController.text,
                      instructions: instructionsController.text,
                    );
                    _firebaseService.addRecipe(newRecipe);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Premium badge
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
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

        _buildSectionHeader("Health & Wellness Tips", _showAddTipDialog),
        _buildTipsCarousel(),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        _buildSectionHeader("Healthy Recipes", _showAddRecipeDialog),
        _buildRecipesCarousel(),
      ],
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

  Widget _buildTipsCarousel() {
    return StreamBuilder<List<Tip>>(
      stream: _firebaseService.tipsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No tips yet. Add one!"));
        }
        final tips = snapshot.data!;
        return SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade50,
                        Colors.green.shade50,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              tip.content,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildRecipesCarousel() {
    return StreamBuilder<List<Recipe>>(
      stream: _firebaseService.recipesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No recipes yet. Add one!"));
        }
        final recipes = snapshot.data!;
        return SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade50,
                        Colors.red.shade50,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant_menu, color: Colors.orange.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  recipe.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text("Ingredients:", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(recipe.ingredients),
                          const Divider(height: 20),
                          Text("Instructions:", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(recipe.instructions),
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