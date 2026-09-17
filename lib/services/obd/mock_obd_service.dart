import 'dart:async';
import 'dart:math';

import '../../models/vehicle_data.dart';
import '../../utils/constants.dart';
import 'obd_service.dart';

/// Simulated OBD data source for UI development and testing.
///
/// Generates realistic telemetry that cycles through all three riding
/// modes: starts cold (warmup), transitions to normal cruising, then
/// simulates spirited riding (power mode).
class MockObdService extends ObdService {
  final _controller = StreamController<VehicleData>.broadcast();
  final _rng = Random();

  bool _isPolling = false;
  bool _connected = false;
  double _simTime = 0; // seconds elapsed in simulation

  // Current raw values (before EMA)
  double _rpm = 800;
  double _speed = 0;
  double _engineOil = 25;
  double _throttle = 0;
  double _intakeAir = 30;

  @override
  Stream<VehicleData> get vehicleDataStream => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  String get statusMessage =>
      _connected ? 'Mock data source active' : 'Mock disconnected';

  @override
  Future<void> start() async {
    if (_connected) return;

    _connected = true;
    _isPolling = true;
    _simTime = 0;
    _pollLoop();
  }

  Future<void> _pollLoop() async {
    while (_isPolling && _connected) {
      await Future.delayed(const Duration(milliseconds: 30));
      _tick();
    }
  }

  @override
  Future<void> stop() async {
    _isPolling = false;
    _connected = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  @override
  Future<String> sendRawCommand(String command) async {
    // Simulate ELM327 responses
    await Future.delayed(const Duration(milliseconds: 50));
    final cmd = command.trim().toUpperCase();

    if (cmd == 'ATZ') return 'ELM327 v2.1 (mock)';
    if (cmd == 'ATI') return 'ELM327 v2.1';
    if (cmd.startsWith('AT')) return 'OK';
    if (cmd == '010C') return _fakeHexResponse('rpm');
    if (cmd == '015C') return _fakeHexResponse('engineOil');
    if (cmd == '0111') return _fakeHexResponse('throttle');
    if (cmd == '010D') return _fakeHexResponse('speed');
    if (cmd == '010F') return _fakeHexResponse('intake');

    return 'NO DATA';
  }

  // ── Simulation Logic ──

  void _tick() {
    _simTime += AppConstants.pollingIntervalMs / 1000.0;

    _updateSimValues();
    _addNoise();

    // Emit directly without smoothing
    final data = VehicleData(
      rpm: _rpm,
      speed: _speed,
      engineOilTemp: _engineOil,
      throttlePosition: _throttle,
      intakeAirTemp: _intakeAir,
      timestamp: DateTime.now(),
    );

    _controller.add(data);
  }

  void _updateSimValues() {
    // ── EngineOil warmup: gradual rise from 25°C to ~90°C over ~120s ──
    if (_engineOil < 90) {
      _engineOil += 0.55 * (AppConstants.pollingIntervalMs / 1000.0);
    } else {
      // Fluctuate around operating temp
      _engineOil = 88 + 4 * sin(_simTime * 0.1);
    }

    // ── Intake air: slowly changes with ambient + engine heat ──
    _intakeAir = 30 + 5 * sin(_simTime * 0.05) + (_engineOil > 60 ? 5 : 0);

    // ── Riding pattern: cycles through phases ──
    // Phase repeats every 60 seconds:
    //   0–15s: idle/low RPM (warmup/normal)
    //  15–35s: cruising (normal)
    //  35–50s: spirited (power mode)
    //  50–60s: deceleration back to cruise
    final phase = _simTime % 60;

    if (phase < 15) {
      // Idle / gentle
      _rpm = _lerp(_rpm, 800 + 200 * sin(_simTime * 0.5), 0.05);
      _throttle = _lerp(_throttle, 5 + 3 * sin(_simTime * 0.3), 0.05);
      _speed = _lerp(_speed, 0 + 10 * max(0, sin(_simTime * 0.2)), 0.03);
    } else if (phase < 35) {
      // Cruising
      _rpm = _lerp(_rpm, 3500 + 500 * sin(_simTime * 0.3), 0.04);
      _throttle = _lerp(_throttle, 30 + 10 * sin(_simTime * 0.2), 0.04);
      _speed = _lerp(_speed, 50 + 15 * sin(_simTime * 0.15), 0.03);
    } else if (phase < 50) {
      // Spirited riding — push into power mode
      _rpm = _lerp(_rpm, 7000 + 1000 * sin(_simTime * 0.5), 0.06);
      _throttle = _lerp(_throttle, 80 + 15 * sin(_simTime * 0.4), 0.06);
      _speed = _lerp(_speed, 90 + 20 * sin(_simTime * 0.2), 0.04);
    } else {
      // Decel
      _rpm = _lerp(_rpm, 2500, 0.05);
      _throttle = _lerp(_throttle, 10, 0.05);
      _speed = _lerp(_speed, 30, 0.04);
    }

    // Clamp to valid ranges
    _rpm = _rpm.clamp(600, AppConstants.maxRpm);
    _speed = _speed.clamp(0, AppConstants.maxSpeed);
    _engineOil = _engineOil.clamp(-10, 130);
    _throttle = _throttle.clamp(0, 100);
    _intakeAir = _intakeAir.clamp(-10, 80);
  }

  void _addNoise() {
    // Simulate realistic sensor noise
    _rpm += (_rng.nextDouble() - 0.5) * 80;
    _speed += (_rng.nextDouble() - 0.5) * 3;
    _engineOil += (_rng.nextDouble() - 0.5) * 1.5;
    _throttle += (_rng.nextDouble() - 0.5) * 4;
    _intakeAir += (_rng.nextDouble() - 0.5) * 1;
  }

  double _lerp(double current, double target, double t) {
    return current + (target - current) * t;
  }

  String _fakeHexResponse(String metric) {
    switch (metric) {
      case 'rpm':
        final raw = (_rpm * 4).round();
        final a = (raw >> 8) & 0xFF;
        final b = raw & 0xFF;
        return '410C${_hex(a)}${_hex(b)}';
      case 'engineOil':
        return '415C${_hex((_engineOil + 40).round().clamp(0, 255))}';
      case 'throttle':
        return '4111${_hex((_throttle * 255 / 100).round().clamp(0, 255))}';
      case 'speed':
        return '410D${_hex(_speed.round().clamp(0, 255))}';
      case 'intake':
        return '410F${_hex((_intakeAir + 40).round().clamp(0, 255))}';
      default:
        return 'NO DATA';
    }
  }

  String _hex(int value) => value.toRadixString(16).padLeft(2, '0').toUpperCase();
}
