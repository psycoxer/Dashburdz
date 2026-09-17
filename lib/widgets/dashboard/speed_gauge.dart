import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Arc gauge for vehicle speed with sage green accent.
class SpeedGauge extends StatelessWidget {
  final double speed;
  final bool compact;

  const SpeedGauge({
    super.key,
    required this.speed,
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
                tween: Tween(end: speed),
                duration: AppConstants.gaugeAnimDuration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedSpeed, _) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _SpeedGaugePainter(
                      speed: animatedSpeed,
                      isDark: isDark,
                      compact: compact,
                    ),
                  );
                },
              ),
              if (!compact)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: speed),
                      duration: AppConstants.gaugeAnimDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return Text(
                          val.toStringAsFixed(0),
                          style: theme.textTheme.displayMedium,
                        );
                      },
                    ),
                    Text('km/h', style: theme.textTheme.titleSmall),
                  ],
                )
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(end: speed),
                  duration: AppConstants.gaugeAnimDuration,
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return Text(
                      val.toStringAsFixed(0),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: size * 0.25,
                      ),
                    );
                  },
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
  final bool compact;

  _SpeedGaugePainter({
    required this.speed,
    required this.isDark,
    required this.compact,
  });

  static const double _startAngle = 135 * pi / 180;
  static const double _sweepAngle = 270 * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;
    final strokeWidth = compact ? size.width * 0.06 : size.width * 0.05;

    // Background arc
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
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
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepAngle,
          colors: isDark
              ? [AppColors.sageDark.withValues(alpha: 0.5), AppColors.sageDark]
              : [AppColors.sageMuted, AppColors.sage],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        _sweepAngle * fraction,
        false,
        valuePaint,
      );
    }

    // Tick marks
    if (!compact) {
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

        final labelR = radius - strokeWidth / 2 - 18;
        final textSpan = TextSpan(
          text: '${i * 20}',
          style: TextStyle(
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            fontSize: 8,
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

    // Needle
    final needleAngle = _startAngle + _sweepAngle * fraction;
    final needleLength = radius * (compact ? 0.65 : 0.75);
    final needlePaint = Paint()
      ..color = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary
      ..strokeWidth = compact ? 2 : 2.5
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
      compact ? 3 : 5,
      Paint()..color = isDark ? AppColors.sageDark : AppColors.sage,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter old) =>
      old.speed != speed || old.isDark != isDark;
}
