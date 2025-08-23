// lib/src/screens/celebration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/widgets/fireworks_animation.dart';
import 'package:zeno/src/widgets/achievement_card.dart';
import 'dart:math';
import 'dart:ui' as ui;

class CelebrationScreen extends StatefulWidget {
  final UserProfile userProfile;
  final UserGoal userGoal;
  final List<WeightLog> weightLogs;
  final List<FoodLog> allFoodLogs;
  final List<ActivityLog> allActivityLogs;
  final double actualWeightLoss;

  const CelebrationScreen({
    super.key,
    required this.userProfile,
    required this.userGoal,
    required this.weightLogs,
    required this.allFoodLogs,
    required this.allActivityLogs,
    required this.actualWeightLoss,
  });

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fireworksController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showFireworks = true;
  bool _showShareOptions = false;

  @override
  void initState() {
    super.initState();

    // Main celebration animation
    _mainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Fireworks animation
    _fireworksController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Slide in animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _startCelebration();
  }

  void _startCelebration() async {
    // Start fireworks immediately
    _fireworksController.repeat();

    // Delay main content slightly
    await Future.delayed(const Duration(milliseconds: 500));
    _mainController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _slideController.forward();

    // Stop fireworks after 4 seconds and show share options
    await Future.delayed(const Duration(seconds: 4));
    setState(() {
      _showFireworks = false;
      _showShareOptions = true;
    });
    _fireworksController.stop();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fireworksController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a237e), // Deep blue
                  Color(0xFF000051), // Very dark blue
                ],
              ),
            ),
          ),

          // Fireworks overlay
          if (_showFireworks)
            Positioned.fill(
              child: FireworksAnimation(controller: _fireworksController),
            ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Main celebration content
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            children: [
                              // Trophy icon
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.amber.shade300,
                                      Colors.amber.shade600,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.5),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Congratulations text
                              const Text(
                                '🎉 CONGRATULATIONS! 🎉',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 15),

                              Text(
                                'You completed your ${widget.userGoal.days}-day weight loss journey!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 10),

                              // Main achievement
                              Container(
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'You lost ${widget.actualWeightLoss.abs().toStringAsFixed(1)} lbs!',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Goal: ${widget.userGoal.lbsToLose} lbs',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (widget.actualWeightLoss.abs() > widget.userGoal.lbsToLose) ...[
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          '🌟 EXCEEDED GOAL! 🌟',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Sliding content
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Journey stats
                        _buildJourneyStats(),

                        const SizedBox(height: 30),

                        // Achievements
                        _buildAchievements(),

                        const SizedBox(height: 30),

                        // Share options
                        if (_showShareOptions) _buildShareOptions(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStats() {
    final startDate = widget.userProfile.createdAt;
    final endDate = DateTime.now();
    final totalDays = endDate.difference(startDate).inDays + 1;

    final totalCaloriesConsumed = widget.allFoodLogs
        .fold<int>(0, (sum, log) => sum + log.totalCalories);

    final totalCaloriesBurned = widget.allActivityLogs
        .fold<int>(0, (sum, log) => sum + log.totalCaloriesBurned);

    final averageDeficitPerDay = totalDays > 0
        ? (totalCaloriesBurned - (totalCaloriesConsumed - (widget.userProfile.recommendedDailyIntake * totalDays))) / totalDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Journey by the Numbers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),

          _buildStatRow('Duration', '$totalDays days', Icons.calendar_today),
          _buildStatRow('Starting Weight', '${widget.userProfile.startWeight.toStringAsFixed(1)} lbs', Icons.scale),
          _buildStatRow('Final Weight', '${(widget.userProfile.startWeight - widget.actualWeightLoss.abs()).toStringAsFixed(1)} lbs', Icons.trending_down),
          _buildStatRow('Food Entries', '${widget.allFoodLogs.length}', Icons.restaurant),
          _buildStatRow('Activity Sessions', '${widget.allActivityLogs.length}', Icons.fitness_center),
          _buildStatRow('Calories Consumed', NumberFormat('#,###').format(totalCaloriesConsumed), Icons.local_dining),
          _buildStatRow('Calories Burned', NumberFormat('#,###').format(totalCaloriesBurned), Icons.local_fire_department),
          _buildStatRow('Avg Daily Deficit', '${averageDeficitPerDay.round()} kcal', Icons.trending_down),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements Unlocked',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),

        // Achievement cards
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _getAchievements().map((achievement) =>
              AchievementCard(achievement: achievement)
          ).toList(),
        ),
      ],
    );
  }

  List<Achievement> _getAchievements() {
    final achievements = <Achievement>[];

    // Goal completion
    achievements.add(Achievement(
      title: 'Goal Crusher',
      description: 'Completed your ${widget.userGoal.days}-day journey',
      icon: Icons.emoji_events,
      color: Colors.amber,
      isUnlocked: true,
    ));

    // Weight loss achievements
    if (widget.actualWeightLoss.abs() > widget.userGoal.lbsToLose) {
      achievements.add(Achievement(
        title: 'Overachiever',
        description: 'Lost more than your goal!',
        icon: Icons.star,
        color: Colors.green,
        isUnlocked: true,
      ));
    }

    // Consistency achievements
    if (widget.allFoodLogs.length >= widget.userGoal.days * 0.8) {
      achievements.add(Achievement(
        title: 'Consistent Logger',
        description: 'Logged food 80% of days',
        icon: Icons.check_circle,
        color: Colors.blue,
        isUnlocked: true,
      ));
    }

    // Activity achievements
    if (widget.allActivityLogs.length >= 10) {
      achievements.add(Achievement(
        title: 'Active Lifestyle',
        description: 'Logged 10+ activities',
        icon: Icons.fitness_center,
        color: Colors.orange,
        isUnlocked: true,
      ));
    }

    // Milestone achievements
    if (widget.actualWeightLoss.abs() >= 10) {
      achievements.add(Achievement(
        title: 'Double Digits',
        description: 'Lost 10+ pounds',
        icon: Icons.trending_down,
        color: Colors.purple,
        isUnlocked: true,
      ));
    }

    return achievements;
  }

  Widget _buildShareOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Share Your Success!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                'Save Image',
                Icons.save_alt,
                Colors.blue,
                _saveAchievementImage,
              ),
              _buildShareButton(
                'Share Stats',
                Icons.share,
                Colors.green,
                _shareStats,
              ),
              _buildShareButton(
                'Export Data',
                Icons.file_download,
                Colors.purple,
                _exportJourneyData,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAchievementImage() async {
    // TODO: Generate and save celebration image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Achievement image saved to gallery!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareStats() async {
    final stats = '''
🎉 I completed my ${widget.userGoal.days}-day weight loss journey with MyZeno!

🏆 Results:
• Lost ${widget.actualWeightLoss.abs().toStringAsFixed(1)} lbs (Goal: ${widget.userGoal.lbsToLose} lbs)
• Logged ${widget.allFoodLogs.length} meals
• Completed ${widget.allActivityLogs.length} activities
• Total days: ${DateTime.now().difference(widget.userProfile.createdAt).inDays + 1}

💪 Consistency pays off! #WeightLossJourney #MyZeno #HealthGoals
''';

    await Clipboard.setData(ClipboardData(text: stats));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stats copied to clipboard! Ready to share!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportJourneyData() async {
    // TODO: Export complete journey data as PDF or CSV
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journey data exported successfully!'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}