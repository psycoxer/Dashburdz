import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/tile_shape.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

class RpmGauge extends StatelessWidget {
  final double rpm;
  final TileShape shape;

  const RpmGauge({
    super.key,
    required this.rpm,
    this.shape = TileShape.square,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (shape == TileShape.chip) {
          return TweenAnimationBuilder<double>(
            tween: Tween(end: rpm),
            duration: AppConstants.gaugeAnimDuration,
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed, size: 16, color: AppColors.lavender),
                  const SizedBox(width: 4),
                  Text(
                    '${val.toStringAsFixed(0)} RPM',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }
          );
        }

        final size = min(constraints.maxWidth, constraints.maxHeight);
        final isHero = shape == TileShape.hero;

        return Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: rpm),
              duration: AppConstants.gaugeAnimDuration,
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _RpmGaugePainter(
                    rpm: val,
                    isDark: isDark,
                    shape: shape,
                  ),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.1),
              child: SizedBox(
                width: size * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('RPM', style: isHero ? theme.textTheme.titleMedium : theme.textTheme.titleSmall),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: rpm),
                      duration: AppConstants.gaugeAnimDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            val.toStringAsFixed(0),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontSize: isHero ? size * 0.3 : size * 0.25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RpmGaugePainter extends CustomPainter {
  final double rpm;
  final bool isDark;
  final TileShape shape;

  _RpmGaugePainter({
    required this.rpm,
    required this.isDark,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.85;
    final strokeWidth = shape == TileShape.hero ? size.width * 0.08 : size.width * 0.07;

    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = 0.75 * pi;
    const sweepAngle = 1.5 * pi;

    // Track background
    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    // Active arc
    final progress = (rpm / AppConstants.maxRpm).clamp(0.0, 1.0);
    if (progress > 0) {
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      activePaint.shader = SweepGradient(
        colors: [
          AppColors.lavenderLight,
          AppColors.lavender,
          Colors.redAccent,
        ],
        stops: const [0.0, 0.7, 1.0],
        startAngle: 0.0,
        endAngle: sweepAngle,
        transform: GradientRotation(startAngle),
      ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle * progress, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RpmGaugePainter old) =>
      old.rpm != rpm || old.isDark != isDark || old.shape != shape;
}
