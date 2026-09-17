import '../../models/vehicle_data.dart';

/// Abstract interface for OBD-II data sources.
///
/// Implemented by [BleObdService] for real hardware and
/// [MockObdService] for simulated dev data.
abstract class ObdService {
  /// Continuous stream of vehicle telemetry snapshots.
  Stream<VehicleData> get vehicleDataStream;

  /// Whether the service is currently connected and streaming.
  bool get isConnected;

  /// Human-readable connection status (e.g. "Connected to OBDLink MX+").
  String get statusMessage;

  /// Start the data source (connect BLE / start simulation).
  Future<void> start();

  /// Stop and clean up resources.
  Future<void> stop();

  /// Dispose all resources permanently.
  Future<void> dispose();

  /// Send a raw AT command and return the raw response.
  /// Used by the debug panel.
  Future<String> sendRawCommand(String command);
}
