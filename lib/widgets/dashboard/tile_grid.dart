import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/riding_mode.dart';
import '../../models/vehicle_data.dart';
import '../../providers/obd_provider.dart';
import '../../providers/riding_mode_provider.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import 'engine_viz.dart';
import 'metric_tile.dart';
import 'rpm_gauge.dart';
import 'speed_gauge.dart';
import 'temp_ring.dart';
import 'throttle_display.dart';

/// The 6 dashboard tile types.
enum _Tile { rpm, speed, engineOil, intakeAir, throttle, engine }

/// Layout spec for a single tile: position and size as fractions of container.
class _TileLayout {
  final double left, top, width, height;
  const _TileLayout(this.left, this.top, this.width, this.height);
}

/// Animated grid that repositions and resizes tiles based on [RidingMode].
///
/// Each tile smoothly moves to its new position/size when the mode changes
/// using [AnimatedPositioned] with easeInOutCubic curves.
class TileGrid extends ConsumerWidget {
  const TileGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(latestDataProvider);
    final mode = ref.watch(ridingModeNotifierProvider);
    final gap = AppConstants.tileGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final layouts = _layoutsForMode(mode);

        return Stack(
          children: _Tile.values.map((tile) {
            final layout = layouts[tile]!;
            return AnimatedPositioned(
              key: ValueKey(tile),
              duration: AppConstants.modeSwitchDuration,
              curve: Curves.easeInOutCubic,
              left: layout.left * w + gap / 2,
              top: layout.top * h + gap / 2,
              width: layout.width * w - gap,
              height: layout.height * h - gap,
              child: AnimatedOpacity(
                duration: AppConstants.modeSwitchDuration,
                opacity: 1.0,
                child: _buildTile(tile, data, mode),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTile(_Tile tile, VehicleData data, RidingMode mode) {
    final compact = _isCompact(tile, mode);

    switch (tile) {
      case _Tile.rpm:
        return MetricTile(
          accentColor: AppColors.lavender,
          child: RpmGauge(rpm: data.rpm, compact: compact),
        );
      case _Tile.speed:
        return MetricTile(
          accentColor: AppColors.sage,
          child: SpeedGauge(speed: data.speed, compact: compact),
        );
      case _Tile.engineOil:
        return MetricTile(
          accentColor: AppColors.coral,
          child: TempRing(
            temperature: data.engineOilTemp,
            label: 'OIL TEMP',
            isEngineOil: true,
            compact: compact,
          ),
        );
      case _Tile.intakeAir:
        return MetricTile(
          accentColor: AppColors.skyBlue,
          child: TempRing(
            temperature: data.intakeAirTemp,
            label: 'INTAKE',
            isEngineOil: false,
            compact: compact,
          ),
        );
      case _Tile.throttle:
        return MetricTile(
          accentColor: AppColors.sage,
          child: ThrottleDisplay(throttle: data.throttlePosition, compact: compact),
        );
      case _Tile.engine:
        return MetricTile(
          accentColor: AppColors.lavender,
          child: EngineViz(rpm: data.rpm),
        );
    }
  }

  bool _isCompact(_Tile tile, RidingMode mode) {
    switch (mode) {
      case RidingMode.warmup:
        return tile == _Tile.rpm ||
            tile == _Tile.speed ||
            tile == _Tile.throttle;
      case RidingMode.normal:
        return tile == _Tile.intakeAir;
      case RidingMode.power:
        return tile == _Tile.speed ||
            tile == _Tile.engineOil ||
            tile == _Tile.intakeAir ||
            tile == _Tile.engine;
    }
  }

  /// Layout definitions per mode. Values are fractions (0–1) of container.
  Map<_Tile, _TileLayout> _layoutsForMode(RidingMode mode) {
    switch (mode) {
      case RidingMode.warmup:
        return {
          // Engine viz: left, full height
          _Tile.engine:   const _TileLayout(0.0,  0.0,  0.38, 1.0),
          // EngineOil: right-top, large
          _Tile.engineOil:  const _TileLayout(0.39, 0.0,  0.30, 0.58),
          // Intake air: far right top
          _Tile.intakeAir:const _TileLayout(0.70, 0.0,  0.30, 0.58),
          // RPM: bottom-left of right area
          _Tile.rpm:      const _TileLayout(0.39, 0.60, 0.20, 0.40),
          // Speed: bottom-center
          _Tile.speed:    const _TileLayout(0.60, 0.60, 0.20, 0.40),
          // Throttle: bottom-right
          _Tile.throttle: const _TileLayout(0.81, 0.60, 0.19, 0.40),
        };

      case RidingMode.normal:
        return {
          // RPM: left, large
          _Tile.rpm:      const _TileLayout(0.0,  0.0,  0.30, 0.58),
          // Speed: center-left, large
          _Tile.speed:    const _TileLayout(0.31, 0.0,  0.30, 0.58),
          // EngineOil: center-right
          _Tile.engineOil:  const _TileLayout(0.62, 0.0,  0.22, 0.58),
          // Intake air: far-right chip
          _Tile.intakeAir:const _TileLayout(0.85, 0.0,  0.15, 0.40),
          // Engine viz: bottom-left
          _Tile.engine:   const _TileLayout(0.0,  0.60, 0.30, 0.40),
          // Throttle: bottom-center
          _Tile.throttle: const _TileLayout(0.31, 0.60, 0.30, 0.40),
        };

      case RidingMode.power:
        return {
          // RPM: hero, left
          _Tile.rpm:      const _TileLayout(0.0,  0.0,  0.48, 0.66),
          // Throttle: hero, right
          _Tile.throttle: const _TileLayout(0.49, 0.0,  0.51, 0.66),
          // Speed: chip bottom-left
          _Tile.speed:    const _TileLayout(0.0,  0.68, 0.18, 0.32),
          // EngineOil: chip
          _Tile.engineOil:  const _TileLayout(0.19, 0.68, 0.15, 0.32),
          // Engine: small bottom
          _Tile.engine:   const _TileLayout(0.35, 0.68, 0.30, 0.32),
          // Intake air: chip bottom-right
          _Tile.intakeAir:const _TileLayout(0.66, 0.68, 0.15, 0.32),
        };
    }
  }
}
