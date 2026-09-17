import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Radial progress ring for temperature metrics (engineOil, intake air).
///
/// Uses sky blue → coral gradient (cold → hot) for engineOil,
/// and sky blue tint for intake air.
class TempRing extends StatelessWidget {
  final double temperature;
  final String label; // "OIL TEMP" or "INTAKE"
  final bool isEngineOil; // Determines gradient coloring
  final bool compact;

  const TempRing({
    super.key,
    required this.temperature,
    required this.label,
    this.isEngineOil = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
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
                      isDark: isDark,
                      isEngineOil: isEngineOil,
                      compact: compact,
                    ),
                  );
                },
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: temperature),
                    duration: AppConstants.gaugeAnimDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return Text(
                        val.toStringAsFixed(compact ? 0 : 1),
                        style: compact
                            ? theme.textTheme.displaySmall?.copyWith(
                                fontSize: size * 0.22,
                              )
                            : theme.textTheme.displaySmall,
                      );
                    },
                  ),
                  if (!compact)
                    Text(
                      '°C',
                      style: theme.textTheme.labelMedium,
                    ),
                  if (!compact) const SizedBox(height: 2),
                  if (!compact)
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.2,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TempRingPainter extends CustomPainter {
  final double temperature;
  final bool isDark;
  final bool isEngineOil;
  final bool compact;

  _TempRingPainter({
    required this.temperature,
    required this.isDark,
    required this.isEngineOil,
    required this.compact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    final strokeWidth = compact ? size.width * 0.07 : size.width * 0.06;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      bgPaint,
    );

    // Value ring
    // Normalize: -10°C to 150°C
    final normalizedTemp = ((temperature - AppConstants.minTemp) /
            (AppConstants.maxTemp - AppConstants.minTemp))
        .clamp(0.0, 1.0);

    if (normalizedTemp > 0.005) {
      Color arcColor;
      if (isEngineOil) {
        // Lerp from sky blue → coral based on temperature
        arcColor = Color.lerp(
          isDark ? AppColors.skyBlueDark : AppColors.skyBlue,
          isDark ? AppColors.coralDark : AppColors.coral,
          normalizedTemp,
        )!;
      } else {
        // Intake air: uniform sky blue
        arcColor = isDark ? AppColors.skyBlueDark : AppColors.skyBlue;
      }

      final valuePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = arcColor;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * normalizedTemp,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TempRingPainter old) =>
      old.temperature != temperature || old.isDark != isDark;
}
