import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/riding_mode.dart';
import '../providers/riding_mode_provider.dart';
import '../theme/colors.dart';

/// Subtle warmup mode indicator — pulsing text with animated ellipsis.
/// Only visible when [RidingMode.warmup] is active, fades out on transition.
class WarmupIndicator extends ConsumerStatefulWidget {
  const WarmupIndicator({super.key});

  @override
  ConsumerState<WarmupIndicator> createState() => _WarmupIndicatorState();
}

class _WarmupIndicatorState extends ConsumerState<WarmupIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(ridingModeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: mode == RidingMode.warmup ? 1.0 : 0.0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final dots = '.' * ((_controller.value * 3).floor() + 1);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (isDark ? AppColors.coralDark : AppColors.coral)
                  .withValues(alpha: 0.08 + 0.06 * _controller.value),
              border: Border.all(
                color: (isDark ? AppColors.coralDark : AppColors.coral)
                    .withValues(alpha: 0.15 + 0.1 * _controller.value),
                width: 1,
              ),
            ),
            child: Text(
              'warming up$dots',
              style: TextStyle(
                color: isDark ? AppColors.coralDark : AppColors.coral,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
