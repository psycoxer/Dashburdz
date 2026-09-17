import 'package:flutter/material.dart';

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

  const MetricTile({
    super.key,
    required this.child,
    this.label,
    this.accentColor,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AppConstants.modeSwitchDuration,
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(AppConstants.tileBorderRadius),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.15) ??
              theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.tileBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.tilePadding),
          child: child,
        ),
      ),
    );
  }
}
