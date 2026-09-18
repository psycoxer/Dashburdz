import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/riding_mode.dart';
import '../../models/tile_shape.dart';
import '../../models/vehicle_data.dart';
import '../../providers/obd_provider.dart';
import '../../providers/riding_mode_provider.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import 'clock_tile.dart';
import 'engine_viz.dart';
import 'metric_tile.dart';
import 'music_tile.dart';
import 'rpm_gauge.dart';
import 'speed_gauge.dart';
import 'status_chip.dart';
import 'temp_ring.dart';
import 'throttle_display.dart';

enum _Tile { rpm, speed, engineOil, intakeAir, throttle, engine, status, clock, music }

class _TileLayout {
  final double left, top, width, height;
  final TileShape shape;
  const _TileLayout(this.left, this.top, this.width, this.height, this.shape);
}

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
            final layout = layouts[tile];
            if (layout == null) return const SizedBox.shrink();

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
                // Hide tile if width/height is 0
                opacity: (layout.width == 0 || layout.height == 0) ? 0.0 : 1.0,
                child: _buildTile(tile, data, layout.shape),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTile(_Tile tile, VehicleData data, TileShape shape) {
    switch (tile) {
      case _Tile.rpm:
        return MetricTile(
          shape: shape,
          accentColor: AppColors.lavender,
          child: RpmGauge(rpm: data.rpm, shape: shape),
        );
      case _Tile.speed:
        return MetricTile(
          shape: shape,
          accentColor: AppColors.sage,
          child: SpeedGauge(speed: data.speed, shape: shape),
        );
      case _Tile.engineOil:
        return MetricTile(
          shape: shape,
          accentColor: AppColors.coral,
          child: TempRing(
            temperature: data.engineOilTemp,
            label: 'OIL TEMP',
            isEngineOil: true,
            shape: shape,
          ),
        );
      case _Tile.intakeAir:
        return MetricTile(
          shape: shape,
          accentColor: AppColors.skyBlue,
          child: TempRing(
            temperature: data.intakeAirTemp,
            label: 'INTAKE',
            isEngineOil: false,
            shape: shape,
          ),
        );
      case _Tile.throttle:
        return MetricTile(
          shape: shape,
          accentColor: AppColors.sage,
          child: ThrottleDisplay(throttle: data.throttlePosition, shape: shape),
        );
      case _Tile.engine:
        return MetricTile(
          shape: shape,
          accentColor: AppColors.lavender,
          child: EngineViz(rpm: data.rpm, engineLoad: data.engineLoad, shape: shape),
        );
      case _Tile.status:
        // Status chip does not need a MetricTile wrapper since it's already a chip
        return const Align(alignment: Alignment.topLeft, child: StatusChip());
      case _Tile.clock:
        return MetricTile(
          shape: shape,
          accentColor: AppColors.skyBlue,
          child: ClockTile(shape: shape),
        );
      case _Tile.music:
        return MetricTile(
          shape: shape,
          accentColor: AppColors.lavender,
          child: MusicTile(shape: shape),
        );
    }
  }

  /// Layout definitions per mode. Values are fractions (0–1) of container.
  Map<_Tile, _TileLayout> _layoutsForMode(RidingMode mode) {
    switch (mode) {
      case RidingMode.warmup:
        return {
          _Tile.status:    const _TileLayout(0.00, 0.00, 0.25, 0.10, TileShape.chip),
          _Tile.clock:     const _TileLayout(0.25, 0.00, 0.25, 0.10, TileShape.chip),
          _Tile.engine:    const _TileLayout(0.00, 0.10, 0.30, 0.90, TileShape.tall),
          
          _Tile.engineOil: const _TileLayout(0.30, 0.10, 0.25, 0.45, TileShape.square),
          _Tile.intakeAir: const _TileLayout(0.55, 0.10, 0.25, 0.45, TileShape.square),
          _Tile.throttle:  const _TileLayout(0.80, 0.10, 0.20, 0.45, TileShape.tall),
          
          _Tile.rpm:       const _TileLayout(0.30, 0.55, 0.35, 0.45, TileShape.square),
          _Tile.speed:     const _TileLayout(0.65, 0.55, 0.35, 0.45, TileShape.square),
          
          _Tile.music:     const _TileLayout(0.00, 0.00, 0.00, 0.00, TileShape.chip), // hidden
        };

      case RidingMode.normal:
        return {
          _Tile.status:    const _TileLayout(0.00, 0.00, 0.30, 0.10, TileShape.chip),
          _Tile.clock:     const _TileLayout(0.30, 0.00, 0.30, 0.10, TileShape.chip),
          _Tile.rpm:       const _TileLayout(0.00, 0.10, 0.30, 0.50, TileShape.square),
          _Tile.speed:     const _TileLayout(0.30, 0.10, 0.30, 0.50, TileShape.square),
          _Tile.music:     const _TileLayout(0.60, 0.10, 0.40, 0.25, TileShape.wide),
          _Tile.engineOil: const _TileLayout(0.60, 0.35, 0.20, 0.25, TileShape.square),
          _Tile.intakeAir: const _TileLayout(0.80, 0.35, 0.20, 0.25, TileShape.square),
          _Tile.engine:    const _TileLayout(0.00, 0.60, 0.30, 0.40, TileShape.square),
          _Tile.throttle:  const _TileLayout(0.30, 0.60, 0.70, 0.40, TileShape.wide),
        };

      case RidingMode.power:
        return {
          _Tile.status:    const _TileLayout(0.00, 0.00, 0.30, 0.10, TileShape.chip),
          _Tile.clock:     const _TileLayout(0.30, 0.00, 0.30, 0.10, TileShape.chip),
          _Tile.rpm:       const _TileLayout(0.00, 0.10, 0.50, 0.70, TileShape.hero),
          _Tile.throttle:  const _TileLayout(0.50, 0.10, 0.50, 0.35, TileShape.wide),
          _Tile.speed:     const _TileLayout(0.50, 0.45, 0.25, 0.35, TileShape.square),
          _Tile.music:     const _TileLayout(0.75, 0.45, 0.25, 0.35, TileShape.wide),
          _Tile.engineOil: const _TileLayout(0.00, 0.80, 0.33, 0.20, TileShape.chip),
          _Tile.intakeAir: const _TileLayout(0.33, 0.80, 0.33, 0.20, TileShape.chip),
          _Tile.engine:    const _TileLayout(0.66, 0.80, 0.34, 0.20, TileShape.chip),
        };

      case RidingMode.touring:
        return {
          _Tile.status:    const _TileLayout(0.00, 0.00, 0.30, 0.10, TileShape.chip),
          _Tile.rpm:       const _TileLayout(0.00, 0.10, 0.15, 0.15, TileShape.chip),
          _Tile.throttle:  const _TileLayout(0.00, 0.25, 0.15, 0.15, TileShape.chip),
          _Tile.engineOil: const _TileLayout(0.00, 0.40, 0.15, 0.15, TileShape.chip),
          _Tile.intakeAir: const _TileLayout(0.00, 0.55, 0.15, 0.15, TileShape.chip),
          _Tile.engine:    const _TileLayout(0.00, 0.70, 0.15, 0.30, TileShape.tall),
          
          _Tile.speed:     const _TileLayout(0.15, 0.00, 0.55, 1.00, TileShape.hero),
          
          _Tile.clock:     const _TileLayout(0.70, 0.00, 0.30, 0.35, TileShape.square),
          _Tile.music:     const _TileLayout(0.70, 0.35, 0.30, 0.65, TileShape.tall),
        };
    }
  }
}
