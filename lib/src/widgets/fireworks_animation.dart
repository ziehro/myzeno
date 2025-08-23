// lib/src/widgets/fireworks_animation.dart
import 'package:flutter/material.dart';
import 'dart:math';

class FireworksAnimation extends StatelessWidget {
  final AnimationController controller;

  const FireworksAnimation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: FireworksPainter(controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class FireworksPainter extends CustomPainter {
  final double animationValue;
  final Random random = Random();

  FireworksPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create multiple fireworks
    _drawFirework(canvas, size, Offset(size.width * 0.2, size.height * 0.3), Colors.red, 0.0);
    _drawFirework(canvas, size, Offset(size.width * 0.8, size.height * 0.4), Colors.blue, 0.2);
    _drawFirework(canvas, size, Offset(size.width * 0.5, size.height * 0.2), Colors.amber, 0.4);
    _drawFirework(canvas, size, Offset(size.width * 0.3, size.height * 0.5), Colors.green, 0.6);
    _drawFirework(canvas, size, Offset(size.width * 0.7, size.height * 0.3), Colors.purple, 0.8);
  }

  void _drawFirework(Canvas canvas, Size size, Offset center, Color color, double offset) {
    final adjustedValue = ((animationValue + offset) % 1.0);

    if (adjustedValue < 0.1) return; // Delay before explosion

    final explosionProgress = (adjustedValue - 0.1) / 0.9;
    final paint = Paint()
      ..color = color.withOpacity(1.0 - explosionProgress)
      ..style = PaintingStyle.fill;

    // Draw particles in a circular explosion pattern
    const particleCount = 12;
    final maxRadius = 100.0 * explosionProgress;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final radius = maxRadius * (0.5 + 0.5 * random.nextDouble());

      final particleX = center.dx + cos(angle) * radius;
      final particleY = center.dy + sin(angle) * radius + (explosionProgress * 50); // Gravity effect

      // Draw particle with trail
      canvas.drawCircle(
        Offset(particleX, particleY),
        4.0 * (1.0 - explosionProgress),
        paint,
      );

      // Draw smaller trailing particles
      if (explosionProgress > 0.3) {
        final trailPaint = Paint()
          ..color = color.withOpacity(0.3 * (1.0 - explosionProgress))
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(particleX - cos(angle) * 10, particleY - sin(angle) * 10),
          2.0 * (1.0 - explosionProgress),
          trailPaint,
        );
      }
    }

    // Central flash at the beginning
    if (explosionProgress < 0.2) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(1.0 - explosionProgress * 5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, 20.0 * (1.0 - explosionProgress * 5), flashPaint);
    }
  }

  @override
  bool shouldRepaint(FireworksPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}