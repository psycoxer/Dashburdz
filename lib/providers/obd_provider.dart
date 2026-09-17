import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle_data.dart';
import '../services/obd/ble_obd_service.dart';
import '../services/obd/mock_obd_service.dart';
import '../services/obd/obd_service.dart';

/// Whether to use mock data or real BLE.
class UseMockNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final useMockProvider = NotifierProvider<UseMockNotifier, bool>(
  UseMockNotifier.new,
);

/// The active OBD service instance.
final obdServiceProvider = Provider<ObdService>((ref) {
  final useMock = ref.watch(useMockProvider);
  final service = useMock ? MockObdService() : BleObdService();

  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of smoothed vehicle telemetry data.
///
/// Automatically starts the OBD service and emits [VehicleData] snapshots.
final vehicleDataProvider = StreamProvider<VehicleData>((ref) {
  final service = ref.watch(obdServiceProvider);

  // Start the service on first listen
  service.start();

  return service.vehicleDataStream;
});

/// Latest vehicle data snapshot (non-nullable, falls back to empty).
final latestDataProvider = Provider<VehicleData>((ref) {
  final asyncData = ref.watch(vehicleDataProvider);
  return asyncData.when(
    data: (data) => data,
    loading: () => VehicleData.empty,
    error: (e, _) => VehicleData.empty,
  );
});
