import 'package:flutter/material.dart';

import '../../models/tile_shape.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Animated wrapper tile for dashboard metrics.
///
/// Smoothly transitions size, position, and opacity when the
/// riding mode changes. Provides a consistent card surface
/// with rounded corners and subtle elevation.
class MetricTile extends StatelessWidget {
  final Widget child;
  final String? label;
  final Color? accentColor;
  final bool showLabel;
  final TileShape shape;

  const MetricTile({
    super.key,
    required this.child,
    this.label,
    this.accentColor,
    this.showLabel = true,
    this.shape = TileShape.square,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Chips get fully rounded pill shapes, others get standard squircle.
    final borderRadius = shape == TileShape.chip 
        ? BorderRadius.circular(100) 
        : BorderRadius.circular(AppConstants.tileBorderRadius);

    return AnimatedContainer(
      duration: AppConstants.modeSwitchDuration,
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: borderRadius,
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.15) ??
              theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.all(shape == TileShape.chip ? 8.0 : AppConstants.tilePadding),
          child: child,
        ),
      ),
    );
  }
}
