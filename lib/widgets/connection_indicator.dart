import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connection_provider.dart';
import '../providers/obd_provider.dart';
import '../theme/colors.dart';

/// Subtle BLE connection status indicator — a small colored dot
/// with an animated pulse when connected.
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(connectionProvider);
    final useMock = ref.watch(useMockProvider);

    Color color = AppColors.lightTextTertiary;
    String tooltip = 'Disconnected';

    if (useMock) {
      color = AppColors.sage;
      tooltip = 'Mock data active';
    } else {
      switch (connState) {
        case BleConnectionState.connected:
          color = AppColors.sage;
          tooltip = 'Connected';
        case BleConnectionState.connecting:
          color = AppColors.warning;
          tooltip = 'Connecting...';
        case BleConnectionState.scanning:
          color = AppColors.warning;
          tooltip = 'Scanning...';
        case BleConnectionState.error:
          color = AppColors.error;
          tooltip = 'Connection error';
        case BleConnectionState.disconnected:
          color = AppColors.lightTextTertiary;
          tooltip = 'Disconnected';
      }
    }

    return Tooltip(
      message: tooltip,
      child: _PulsingDot(
        color: color,
        shouldPulse: useMock ||
            connState == BleConnectionState.connecting ||
            connState == BleConnectionState.scanning,
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool shouldPulse;

  const _PulsingDot({required this.color, required this.shouldPulse});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.shouldPulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.shouldPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.5 + 0.5 * _controller.value,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 * _controller.value),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
