import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/tile_shape.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Vertical or horizontal bar gauge for throttle position.
class ThrottleDisplay extends StatelessWidget {
  final double throttle;
  final TileShape shape;

  const ThrottleDisplay({
    super.key,
    required this.throttle,
    this.shape = TileShape.square,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (shape == TileShape.chip) {
      return TweenAnimationBuilder<double>(
        tween: Tween(end: throttle),
        duration: AppConstants.gaugeAnimDuration,
        curve: Curves.easeOutCubic,
        builder: (context, val, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gamepad, size: 16, color: AppColors.sage),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${val.toStringAsFixed(0)}%',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    final isWide = shape == TileShape.wide;
    final isHero = shape == TileShape.hero || shape == TileShape.tall;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isWide) {
          // Horizontal layout
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('THR %', style: theme.textTheme.titleSmall),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: throttle),
                      duration: AppConstants.gaugeAnimDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            val.toStringAsFixed(0),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: throttle),
                  duration: AppConstants.gaugeAnimDuration,
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedThrottle, _) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth * 0.9, 20),
                      painter: _ThrottleBarPainter(
                        throttle: animatedThrottle,
                        isDark: isDark,
                        isHorizontal: true,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        // Vertical layout
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: throttle),
                    duration: AppConstants.gaugeAnimDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          val.toStringAsFixed(0),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontSize: isHero ? 42 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  Text('THR %', style: theme.textTheme.titleSmall),
                ],
              ),
            ),
            const SizedBox(width: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(end: throttle),
              duration: AppConstants.gaugeAnimDuration,
              curve: Curves.easeOutCubic,
              builder: (context, animatedThrottle, _) {
                return CustomPaint(
                  size: Size(24, constraints.maxHeight * (isHero ? 0.8 : 0.6)),
                  painter: _ThrottleBarPainter(
                    throttle: animatedThrottle,
                    isDark: isDark,
                    isHorizontal: false,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        );
      },
    );
  }
}

class _ThrottleBarPainter extends CustomPainter {
  final double throttle;
  final bool isDark;
  final bool isHorizontal;

  _ThrottleBarPainter({
    required this.throttle,
    required this.isDark,
    required this.isHorizontal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(isHorizontal ? size.height / 2 : size.width / 2);

    // Background track
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
    );

    // Fill bar
    final progress = (throttle / 100).clamp(0.0, 1.0);
    if (progress > 0) {
      final fillRect = isHorizontal
          ? Rect.fromLTRB(0, 0, size.width * progress, size.height)
          : Rect.fromLTRB(0, size.height - (size.height * progress), size.width, size.height);

      final paint = Paint();
      paint.shader = LinearGradient(
        begin: isHorizontal ? Alignment.centerLeft : Alignment.bottomCenter,
        end: isHorizontal ? Alignment.centerRight : Alignment.topCenter,
        colors: [
          AppColors.sageMuted,
          AppColors.sage,
          Colors.orangeAccent, // High throttle gets orange
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect); // Map gradient to full bar

      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThrottleBarPainter old) =>
      old.throttle != throttle || old.isDark != isDark || old.isHorizontal != isHorizontal;
}
