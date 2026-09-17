import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Beautiful arc/sweep gauge for RPM with animated needle and gradient arc.
///
/// Features:
/// - 270° sweep arc with tick marks at 1000 RPM intervals
/// - Gradient fill from lavender (low) to coral (high/redline)
/// - Smooth animated needle via implicit animations
/// - Redline zone highlight above 7500 RPM
/// - Large numeric center readout with unit label
class RpmGauge extends StatelessWidget {
  final double rpm;
  final bool compact;

  const RpmGauge({
    super.key,
    required this.rpm,
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
              // Gauge arcs
              TweenAnimationBuilder<double>(
                tween: Tween(end: rpm),
                duration: AppConstants.gaugeAnimDuration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedRpm, _) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _RpmGaugePainter(
                      rpm: animatedRpm,
                      isDark: isDark,
                      compact: compact,
                    ),
                  );
                },
              ),

              // Center readout
              if (!compact)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: rpm),
                      duration: AppConstants.gaugeAnimDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return Text(
                          val.toStringAsFixed(0),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: rpm > AppConstants.redlineRpm
                                ? (isDark
                                    ? AppColors.coralDark
                                    : AppColors.coral)
                                : null,
                          ),
                        );
                      },
                    ),
                    Text(
                      'RPM',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                )
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(end: rpm),
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

class _RpmGaugePainter extends CustomPainter {
  final double rpm;
  final bool isDark;
  final bool compact;

  _RpmGaugePainter({
    required this.rpm,
    required this.isDark,
    required this.compact,
  });

  static const double _startAngle = 135 * pi / 180; // 7 o'clock
  static const double _sweepAngle = 270 * pi / 180; // 270° total
  static const int _maxRpm = 9000;
  static const int _redline = 7500;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;
    final strokeWidth = compact ? size.width * 0.06 : size.width * 0.05;

    // ── Background arc ──
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      bgPaint,
    );

    // ── Value arc with gradient ──
    final fraction = (rpm / _maxRpm).clamp(0.0, 1.0);
    if (fraction > 0.005) {
      final valueSweep = _sweepAngle * fraction;
      final gradientPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepAngle,
          colors: isDark
              ? [AppColors.lavenderDark, AppColors.coralDark]
              : [AppColors.lavender, AppColors.coral],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        valueSweep,
        false,
        gradientPaint,
      );
    }

    // ── Redline zone indicator ──
    if (!compact) {
      final redlineFraction = _redline / _maxRpm;
      final redlineStart = _startAngle + _sweepAngle * redlineFraction;
      final redlineSweep = _sweepAngle * (1 - redlineFraction);
      final redlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.3
        ..strokeCap = StrokeCap.round
        ..color = (isDark ? AppColors.coralDark : AppColors.coral).withValues(alpha: 0.3);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + strokeWidth * 0.7),
        redlineStart,
        redlineSweep,
        false,
        redlinePaint,
      );
    }

    // ── Tick marks ──
    if (!compact) {
      final tickPaint = Paint()
        ..color = (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i <= 9; i++) {
        final tickFraction = i / 9;
        final angle = _startAngle + _sweepAngle * tickFraction;
        final isMajor = i % 1 == 0;
        final innerR = radius - strokeWidth / 2 - (isMajor ? 10 : 5);
        final outerR = radius - strokeWidth / 2 - 2;

        canvas.drawLine(
          Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
          Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
          tickPaint,
        );

        // Labels at major ticks
        if (!compact) {
          final labelR = radius - strokeWidth / 2 - 20;
          final textSpan = TextSpan(
            text: '$i',
            style: TextStyle(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          );
          final tp = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          )..layout();
          final offset = Offset(
            center.dx + labelR * cos(angle) - tp.width / 2,
            center.dy + labelR * sin(angle) - tp.height / 2,
          );
          tp.paint(canvas, offset);
        }
      }
    }

    // ── Needle ──
    final needleAngle = _startAngle + _sweepAngle * fraction;
    final needleLength = radius * (compact ? 0.65 : 0.75);
    final needlePaint = Paint()
      ..color = rpm > _redline
          ? (isDark ? AppColors.coralDark : AppColors.coral)
          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
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

    // Needle center dot
    canvas.drawCircle(
      center,
      compact ? 3 : 5,
      Paint()
        ..color = isDark ? AppColors.lavenderDark : AppColors.lavender,
    );
  }

  @override
  bool shouldRepaint(covariant _RpmGaugePainter old) =>
      old.rpm != rpm || old.isDark != isDark;
}
