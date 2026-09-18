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
/// - normal → touring: Speed > 70 AND Throttle < 30% sustained for 2s
/// - power/touring → normal: conditions below thresholds sustained for 3s
class RidingModeNotifier extends Notifier<RidingMode> {
  DateTime? _powerConditionStart;
  DateTime? _powerCooldownStart;
  
  DateTime? _touringConditionStart;
  DateTime? _touringCooldownStart;

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
          _resetTimers();
        }

      case RidingMode.normal:
        // Check if we should go back to warmup (e.g. engine restart)
        if (data.engineOilTemp < AppConstants.warmupTempThreshold - 5) {
          state = RidingMode.warmup;
          _resetTimers();
          break;
        }

        // Check power mode conditions
        final inPowerZone =
            data.rpm > AppConstants.powerRpmThreshold ||
            data.throttlePosition > AppConstants.powerThrottleThreshold;

        // Check touring mode conditions (cruising)
        final inTouringZone =
            data.speed > 70 && data.throttlePosition < 30;

        if (inPowerZone) {
          _powerConditionStart ??= DateTime.now();
          final elapsed =
              DateTime.now().difference(_powerConditionStart!).inMilliseconds;
          if (elapsed >= AppConstants.powerSustainMs) {
            state = RidingMode.power;
            _resetTimers();
          }
        } else {
          _powerConditionStart = null;
        }

        if (inTouringZone && !inPowerZone) {
          _touringConditionStart ??= DateTime.now();
          final elapsed =
              DateTime.now().difference(_touringConditionStart!).inMilliseconds;
          if (elapsed >= AppConstants.powerSustainMs) {
            state = RidingMode.touring;
            _resetTimers();
          }
        } else {
          _touringConditionStart = null;
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
            _resetTimers();
          }
        } else {
          _powerCooldownStart = null;
        }

      case RidingMode.touring:
        // Exit touring if speed drops or throttle spikes
        final exitTouring = data.speed < 60 || data.throttlePosition > 50;

        if (exitTouring) {
          _touringCooldownStart ??= DateTime.now();
          final elapsed =
              DateTime.now().difference(_touringCooldownStart!).inMilliseconds;
          if (elapsed >= AppConstants.powerCooldownMs) {
            state = RidingMode.normal;
            _resetTimers();
          }
        } else {
          _touringCooldownStart = null;
        }
    }
  }

  void _resetTimers() {
    _powerConditionStart = null;
    _powerCooldownStart = null;
    _touringConditionStart = null;
    _touringCooldownStart = null;
  }
}

final ridingModeNotifierProvider =
    NotifierProvider<RidingModeNotifier, RidingMode>(
  RidingModeNotifier.new,
);
