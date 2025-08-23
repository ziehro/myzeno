// lib/src/widgets/journey_progress_widget.dart
import 'package:flutter/material.dart';
import 'package:zeno/src/services/journey_completion_service.dart';
import 'package:zeno/src/services/hybrid_data_service.dart';
import 'package:zeno/main.dart'; // For ServiceProvider

class JourneyProgressWidget extends StatefulWidget {
  const JourneyProgressWidget({super.key});

  @override
  State<JourneyProgressWidget> createState() => _JourneyProgressWidgetState();
}

class _JourneyProgressWidgetState extends State<JourneyProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late HybridDataService _dataService;

  double _currentProgress = 0.0;
  int? _daysRemaining;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadJourneyProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = ServiceProvider.of(context).hybridDataService;
  }

  Future<void> _loadJourneyProgress() async {
    try {
      final progress = await JourneyCompletionService.getJourneyProgress(_dataService);
      final daysRemaining = await JourneyCompletionService.getDaysUntilCompletion(_dataService);

      setState(() {
        _currentProgress = progress;
        _daysRemaining = daysRemaining;
        _isLoading = false;
      });

      // Animate progress bar
      _animationController.forward();

      // Check for journey completion
      if (mounted) {
        await JourneyCompletionService.checkJourneyCompletion(context, _dataService);
      }

    } catch (e) {
      print('Error loading journey progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_daysRemaining == null) {
      return const SizedBox.shrink(); // Don't show if no goal set
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _daysRemaining == 0
                ? [Colors.amber.shade400, Colors.orange.shade400] // Completion colors
                : [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _daysRemaining == 0
                          ? Colors.amber.withOpacity(0.3)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _daysRemaining == 0 ? Icons.emoji_events : Icons.track_changes,
                      color: _daysRemaining == 0
                          ? Colors.amber.shade700
                          : Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _daysRemaining == 0
                              ? 'Journey Complete! 🎉'
                              : 'Journey Progress',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _daysRemaining == 0
                                ? Colors.amber.shade700
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          _daysRemaining == 0
                              ? 'Congratulations on completing your goal!'
                              : _daysRemaining == 1
                              ? 'Final day - you\'re almost there!'
                              : '$_daysRemaining days remaining',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(_currentProgress * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _daysRemaining == 0
                                  ? Colors.amber.shade700
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Animated progress bar
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.shade300,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _progressAnimation.value * _currentProgress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _daysRemaining == 0
                                  ? Colors.amber
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            minHeight: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Motivational message or completion action
              const SizedBox(height: 16),

              if (_daysRemaining == 0) ...[
                // Completion actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Show celebration again
                          await JourneyCompletionService.checkJourneyCompletion(
                            context,
                            _dataService,
                          );
                        },
                        icon: const Icon(Icons.celebration, size: 18),
                        label: const Text('View Celebration'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_daysRemaining! <= 7) ...[
                // Final week motivation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.whatshot, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Final week! Keep pushing - you\'re so close to your goal! 💪',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_currentProgress >= 0.5) ...[
                // Halfway motivation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Great progress! You\'re over halfway there! 🎯',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Early journey motivation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You\'ve got this! Stay consistent and track your progress daily! 🚀',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}