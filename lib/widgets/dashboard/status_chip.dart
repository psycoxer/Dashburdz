import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/riding_mode.dart';
import '../../providers/riding_mode_provider.dart';
import '../../theme/colors.dart';

class StatusChip extends ConsumerWidget {
  const StatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(ridingModeNotifierProvider);
    final theme = Theme.of(context);

    String label;
    IconData icon;
    Color color;

    switch (mode) {
      case RidingMode.warmup:
        label = 'COLD ENGINE';
        icon = Icons.ac_unit;
        color = AppColors.skyBlue;
        break;
      case RidingMode.normal:
        label = 'NORMAL';
        icon = Icons.check_circle;
        color = AppColors.sage;
        break;
      case RidingMode.power:
        label = 'POWER';
        icon = Icons.local_fire_department;
        color = AppColors.coral;
        break;
      case RidingMode.touring:
        label = 'CRUISING';
        icon = Icons.mode_of_travel;
        color = AppColors.lavender;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
