import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/riding_mode.dart';
import '../models/vehicle_data.dart';
import '../utils/constants.dart';
import 'obd_provider.dart';

/// Derives the current [RidingMode] from vehicle telemetry.
///
/// Transitions:
/// - warmup → normal: engineOil temp ≥ 60°C
/// - normal → power: RPM > 6000 OR throttle > 70% sustained for 2s
/// - power → normal: conditions below thresholds sustained for 3s
class RidingModeNotifier extends Notifier<RidingMode> {
  DateTime? _powerConditionStart;
  DateTime? _powerCooldownStart;

  @override
  RidingMode build() {
    // React to every vehicle data update
    ref.listen<VehicleData>(latestDataProvider, (_, data) {
      update(data);
    });
    return RidingMode.warmup;
  }

  void update(VehicleData data) {
    switch (state) {
      case RidingMode.warmup:
        if (data.engineOilTemp >= AppConstants.warmupTempThreshold) {
          state = RidingMode.normal;
          _powerConditionStart = null;
          _powerCooldownStart = null;
        }

      case RidingMode.normal:
        // Check if we should go back to warmup (e.g. engine restart)
        if (data.engineOilTemp < AppConstants.warmupTempThreshold - 5) {
          state = RidingMode.warmup;
          _powerConditionStart = null;
          break;
        }

        // Check power mode conditions
        final inPowerZone =
            data.rpm > AppConstants.powerRpmThreshold ||
            data.throttlePosition > AppConstants.powerThrottleThreshold;

        if (inPowerZone) {
          _powerConditionStart ??= DateTime.now();
          final elapsed =
              DateTime.now().difference(_powerConditionStart!).inMilliseconds;
          if (elapsed >= AppConstants.powerSustainMs) {
            state = RidingMode.power;
            _powerConditionStart = null;
            _powerCooldownStart = null;
          }
        } else {
          _powerConditionStart = null;
        }

      case RidingMode.power:
        final inPowerZone =
            data.rpm > AppConstants.powerRpmThreshold ||
            data.throttlePosition > AppConstants.powerThrottleThreshold;

        if (!inPowerZone) {
          _powerCooldownStart ??= DateTime.now();
          final elapsed =
              DateTime.now().difference(_powerCooldownStart!).inMilliseconds;
          if (elapsed >= AppConstants.powerCooldownMs) {
            state = RidingMode.normal;
            _powerCooldownStart = null;
            _powerConditionStart = null;
          }
        } else {
          _powerCooldownStart = null;
        }
    }
  }
}

final ridingModeNotifierProvider =
    NotifierProvider<RidingModeNotifier, RidingMode>(
  RidingModeNotifier.new,
);
