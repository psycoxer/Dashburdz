import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/tile_shape.dart';
import '../../theme/app_theme.dart';

class ClockTile extends StatefulWidget {
  final TileShape shape;

  const ClockTile({super.key, required this.shape});

  @override
  State<ClockTile> createState() => _ClockTileState();
}

class _ClockTileState extends State<ClockTile> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.jm().format(_now); // e.g. "4:30 PM"
    final dateStr = DateFormat.MMMEd().format(_now); // e.g. "Thu, Sep 18"
    final theme = Theme.of(context);

    if (widget.shape == TileShape.chip) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_filled, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Larger shapes (square, tall, etc)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time_filled, size: 32, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dateStr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
