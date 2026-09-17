import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Vertical fill bar for throttle position with sage green accent.
class ThrottleDisplay extends StatelessWidget {
  final double throttle; // 0–100%
  final bool compact;

  const ThrottleDisplay({
    super.key,
    required this.throttle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Row(
          children: [
            // Bar
            Expanded(
              flex: compact ? 1 : 2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: compact ? 4 : 12,
                  horizontal: compact ? 2 : 8,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: throttle / 100.0),
                  duration: AppConstants.gaugeAnimDuration,
                  curve: Curves.easeOutCubic,
                  builder: (context, fraction, _) {
                    return CustomPaint(
                      size: Size(width, height),
                      painter: _ThrottleBarPainter(
                        fraction: fraction,
                        isDark: isDark,
                        compact: compact,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Readout
            if (!compact)
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: throttle),
                      duration: AppConstants.gaugeAnimDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return Text(
                          val.toStringAsFixed(0),
                          style: theme.textTheme.displaySmall,
                        );
                      },
                    ),
                    Text('%', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      'THROTTLE',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.2,
                      ),
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

class _ThrottleBarPainter extends CustomPainter {
  final double fraction; // 0–1
  final bool isDark;
  final bool compact;

  _ThrottleBarPainter({
    required this.fraction,
    required this.isDark,
    required this.compact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = compact ? size.width * 0.6 : size.width * 0.5;
    final barHeight = size.height;
    final left = (size.width - barWidth) / 2;
    final borderRadius = barWidth / 2;

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 0, barWidth, barHeight),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
    );

    // Filled portion (from bottom)
    final fillHeight = barHeight * fraction;
    if (fillHeight > 1) {
      final fillRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, barHeight - fillHeight, barWidth, fillHeight),
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
        topLeft: Radius.circular(fillHeight > barHeight * 0.9 ? borderRadius : 4),
        topRight: Radius.circular(fillHeight > barHeight * 0.9 ? borderRadius : 4),
      );

      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: isDark
            ? [AppColors.sageDark.withValues(alpha: 0.6), AppColors.sageDark]
            : [AppColors.sageMuted, AppColors.sage],
      );

      canvas.drawRRect(
        fillRect,
        Paint()..shader = gradient.createShader(fillRect.outerRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThrottleBarPainter old) =>
      old.fraction != fraction || old.isDark != isDark;
}
