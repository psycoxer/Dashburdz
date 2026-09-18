import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/tile_shape.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

class TempRing extends StatelessWidget {
  final double temperature;
  final String label;
  final bool isEngineOil;
  final TileShape shape;

  const TempRing({
    super.key,
    required this.temperature,
    required this.label,
    required this.isEngineOil,
    this.shape = TileShape.square,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final accentColor = isEngineOil ? AppColors.coral : AppColors.skyBlue;

    if (shape == TileShape.chip) {
      return TweenAnimationBuilder<double>(
        tween: Tween(end: temperature),
        duration: AppConstants.gaugeAnimDuration,
        curve: Curves.easeOutCubic,
        builder: (context, val, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isEngineOil ? Icons.oil_barrel : Icons.air, size: 16, color: accentColor),
              const SizedBox(width: 4),
              Text(
                '${val.toStringAsFixed(0)}°C',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      );
    }

    final isHero = shape == TileShape.hero;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: temperature),
              duration: AppConstants.gaugeAnimDuration,
              curve: Curves.easeOutCubic,
              builder: (context, animatedTemp, _) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _TempRingPainter(
                    temperature: animatedTemp,
                    isEngineOil: isEngineOil,
                    isDark: isDark,
                    shape: shape,
                  ),
                );
              },
            ),
            SizedBox(
              width: size * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: temperature),
                    duration: AppConstants.gaugeAnimDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${val.toStringAsFixed(0)}°',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: isHero ? size * 0.25 : size * 0.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, style: theme.textTheme.labelSmall),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TempRingPainter extends CustomPainter {
  final double temperature;
  final bool isEngineOil;
  final bool isDark;
  final TileShape shape;

  _TempRingPainter({
    required this.temperature,
    required this.isEngineOil,
    required this.isDark,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.85;
    final strokeWidth = shape == TileShape.hero ? size.width * 0.08 : size.width * 0.07;

    // Background circle
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);
    
    canvas.drawCircle(center, radius, bgPaint);

    // Active arc
    // Normal temp max: Engine Oil ~120C, Intake Air ~60C
    final maxTemp = isEngineOil ? 120.0 : 60.0;
    final progress = (temperature / maxTemp).clamp(0.0, 1.0);
    
    if (progress > 0) {
      final activeColor = isEngineOil ? AppColors.coral : AppColors.skyBlue;
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = activeColor;
      
      // Arc from bottom center (pi/2) going clockwise
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi / 2,
        2 * pi * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TempRingPainter old) =>
      old.temperature != temperature || old.isDark != isDark;
}
