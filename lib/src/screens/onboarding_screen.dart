import 'package:flutter/material.dart';
import 'package:zeno/src/screens/goal_setting_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to goal setting
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GoalSettingScreen()),
      );
    }
  }

  void _skipToEnd() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const GoalSettingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipToEnd,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  return _onboardingPages[index];
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingPages.length,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _onboardingPages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> get _onboardingPages => [
    _OnboardingPage(
      title: "Welcome to MyZeno",
      subtitle: "Your Personal Weight Loss Companion",
      description: "MyZeno helps you lose weight by tracking the fundamental equation:\n\n3,500 calories = 1 pound of weight",
      icon: Icons.favorite,
      gradient: [Colors.purple.shade400, Colors.blue.shade400],
    ),
    _OnboardingPage(
      title: "The Science Behind It",
      subtitle: "How It Actually Works",
      description: "To lose 1 pound, you need a calorie deficit of 3,500 calories.\n\nWant to lose 10 pounds in 30 days?\nThat's 35,000 calories ÷ 30 days = 1,167 calories deficit per day!",
      icon: Icons.science,
      gradient: [Colors.green.shade400, Colors.teal.shade400],
      showCalculation: true,
    ),
    _OnboardingPage(
      title: "Your Daily Balance",
      subtitle: "Track Calories In vs Calories Out",
      description: "• Log food you eat (calories IN)\n• Log activities & exercise (calories OUT)\n• We calculate your daily balance automatically\n• Stay within your target to reach your goal!",
      icon: Icons.balance,
      gradient: [Colors.orange.shade400, Colors.red.shade400],
    ),
    _OnboardingPage(
      title: "Smart Tracking",
      subtitle: "We Do the Math For You",
      description: "Based on your age, weight, height, and activity level, we calculate:\n\n• Your daily calorie burn\n• How much deficit you need\n• Your daily calorie target\n• Progress toward your goal",
      icon: Icons.calculate,
      gradient: [Colors.indigo.shade400, Colors.purple.shade400],
    ),
    _OnboardingPage(
      title: "Visual Progress",
      subtitle: "See Your Success",
      description: "Track your journey with beautiful charts:\n\n• Weight loss trends\n• Daily calorie balance\n• Theoretical vs actual progress\n• Achievement milestones",
      icon: Icons.trending_up,
      gradient: [Colors.teal.shade400, Colors.green.shade400],
    ),
    _OnboardingPage(
      title: "Ready to Start?",
      subtitle: "Let's Set Your Goals",
      description: "Tell us about yourself and your weight loss goals. We'll create a personalized plan that works with the science of calories.",
      icon: Icons.flag,
      gradient: [Colors.blue.shade400, Colors.purple.shade400],
      isLast: true,
    ),
  ];
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final bool showCalculation;
  final bool isLast;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    this.showCalculation = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Icon with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: gradient.first,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Special calculation box for science page
          if (showCalculation)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Example Calculation:",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "10 lbs × 3,500 cal/lb = 35,000 calories\n35,000 ÷ 30 days = 1,167 cal/day deficit",
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Description
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Call to action for last page
          if (isLast)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient.map((c) => c.withOpacity(0.1)).toList(),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: gradient.first,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "It takes 2 minutes to set up!",
                    style: TextStyle(
                      color: gradient.first,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}