/// Immutable snapshot of all vehicle telemetry values.
class VehicleData {
  final double rpm;
  final double speed; // km/h
  final double engineOilTemp; // °C
  final double throttlePosition; // 0–100 %
  final double intakeAirTemp; // °C
  final DateTime timestamp;

  const VehicleData({
    required this.rpm,
    required this.speed,
    required this.engineOilTemp,
    required this.throttlePosition,
    required this.intakeAirTemp,
    required this.timestamp,
  });

  /// Empty/default state before any data is received.
  static final VehicleData empty = VehicleData(
    rpm: 0,
    speed: 0,
    engineOilTemp: 25,
    throttlePosition: 0,
    intakeAirTemp: 25,
    timestamp: DateTime.now(),
  );

  VehicleData copyWith({
    double? rpm,
    double? speed,
    double? engineOilTemp,
    double? throttlePosition,
    double? intakeAirTemp,
    DateTime? timestamp,
  }) {
    return VehicleData(
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      engineOilTemp: engineOilTemp ?? this.engineOilTemp,
      throttlePosition: throttlePosition ?? this.throttlePosition,
      intakeAirTemp: intakeAirTemp ?? this.intakeAirTemp,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rpm': rpm,
      'speed': speed,
      'engine_oil_temp': engineOilTemp,
      'throttle_position': throttlePosition,
      'intake_air_temp': intakeAirTemp,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory VehicleData.fromMap(Map<String, dynamic> map) {
    return VehicleData(
      rpm: (map['rpm'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      engineOilTemp: (map['engine_oil_temp'] as num).toDouble(),
      throttlePosition: (map['throttle_position'] as num).toDouble(),
      intakeAirTemp: (map['intake_air_temp'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'VehicleData(rpm: ${rpm.toStringAsFixed(0)}, speed: ${speed.toStringAsFixed(0)}, '
      'engineOil: ${engineOilTemp.toStringAsFixed(1)}°C, throttle: ${throttlePosition.toStringAsFixed(1)}%, '
      'intake: ${intakeAirTemp.toStringAsFixed(1)}°C)';
}
