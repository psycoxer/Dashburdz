import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/tile_shape.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Arc gauge for vehicle speed with sage green accent.
class SpeedGauge extends StatelessWidget {
  final double speed;
  final TileShape shape;

  const SpeedGauge({
    super.key,
    required this.speed,
    this.shape = TileShape.square,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (shape == TileShape.chip) {
      return TweenAnimationBuilder<double>(
        tween: Tween(end: speed),
        duration: AppConstants.gaugeAnimDuration,
        curve: Curves.easeOutCubic,
        builder: (context, val, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bike, size: 16, color: AppColors.sage),
              const SizedBox(width: 4),
              Text(
                '${val.toStringAsFixed(0)} km/h',
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

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: speed),
                duration: AppConstants.gaugeAnimDuration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedSpeed, _) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _SpeedGaugePainter(
                      speed: animatedSpeed,
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
                      tween: Tween(end: speed),
                      duration: AppConstants.gaugeAnimDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            val.toStringAsFixed(0),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontSize: isHero ? size * 0.35 : size * 0.25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('km/h', style: isHero ? theme.textTheme.titleMedium : theme.textTheme.titleSmall),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  final double speed;
  final bool isDark;
  final TileShape shape;

  _SpeedGaugePainter({
    required this.speed,
    required this.isDark,
    required this.shape,
  });

  static const double _startAngle = 135 * pi / 180;
  static const double _sweepAngle = 270 * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;
    final strokeWidth = shape == TileShape.hero ? size.width * 0.05 : size.width * 0.06;
    final isHero = shape == TileShape.hero;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    canvas.drawArc(
      rect,
      _startAngle,
      _sweepAngle,
      false,
      bgPaint,
    );

    // Value arc
    final fraction = (speed / AppConstants.maxSpeed).clamp(0.0, 1.0);
    if (fraction > 0.005) {
      final valuePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: _sweepAngle,
          colors: isDark
              ? [AppColors.sageDark.withValues(alpha: 0.5), AppColors.sageDark]
              : [AppColors.sageMuted, AppColors.sage],
          transform: const GradientRotation(_startAngle),
        ).createShader(rect);

      canvas.drawArc(
        rect,
        _startAngle,
        _sweepAngle * fraction,
        false,
        valuePaint,
      );
    }

    // Tick marks
    if (isHero || shape == TileShape.square) {
      final tickPaint = Paint()
        ..color = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      // Speed ticks at 20 km/h intervals (0, 20, 40, ... 160)
      for (int i = 0; i <= 8; i++) {
        final tickFraction = i / 8;
        final angle = _startAngle + _sweepAngle * tickFraction;
        final innerR = radius - strokeWidth / 2 - 8;
        final outerR = radius - strokeWidth / 2 - 2;

        canvas.drawLine(
          Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
          Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
          tickPaint,
        );

        if (isHero) {
          final labelR = radius - strokeWidth / 2 - 22;
          final textSpan = TextSpan(
            text: '${i * 20}',
            style: TextStyle(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          );
          final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
          tp.paint(
            canvas,
            Offset(
              center.dx + labelR * cos(angle) - tp.width / 2,
              center.dy + labelR * sin(angle) - tp.height / 2,
            ),
          );
        }
      }
    }

    // Needle
    final needleAngle = _startAngle + _sweepAngle * fraction;
    final needleLength = radius * (isHero ? 0.75 : 0.65);
    final needlePaint = Paint()
      ..color = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary
      ..strokeWidth = isHero ? 2.5 : 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + needleLength * cos(needleAngle),
        center.dy + needleLength * sin(needleAngle),
      ),
      needlePaint,
    );

    // Center dot
    canvas.drawCircle(
      center,
      isHero ? 5 : 3,
      Paint()..color = isDark ? AppColors.sageDark : AppColors.sage,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter old) =>
      old.speed != speed || old.isDark != isDark || old.shape != shape;
}
