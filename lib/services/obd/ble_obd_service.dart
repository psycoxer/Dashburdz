import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../models/vehicle_data.dart';
import '../../utils/constants.dart';
import 'elm327_protocol.dart';
import 'obd_service.dart';

/// Real BLE-based OBD-II data service using flutter_blue_plus.
///
/// Connects to an ELM327 BLE adapter, initializes the CAN protocol,
/// and polls PIDs in round-robin at 200ms intervals.
class BleObdService extends ObdService {
  final _controller = StreamController<VehicleData>.broadcast();
  final _rawLog = <Map<String, String>>[];

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _readChar;
  StreamSubscription? _notifySub;

  bool _connected = false;
  String _status = 'Disconnected';
  int _currentPidIndex = 0;

  // Buffer for accumulating partial BLE responses
  final _responseBuffer = StringBuffer();
  Completer<String>? _responseCompleter;

  // Live values before smoothing
  double _rpm = 0;
  double _speed = 0;
  double _engineOilTemp = 25;
  double _throttlePos = 0;
  double _intakeAirTemp = 25;
  double _engineLoad = 0;

  /// Raw PID log for the debug panel.
  List<Map<String, String>> get rawLog => List.unmodifiable(_rawLog);

  @override
  Stream<VehicleData> get vehicleDataStream => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  String get statusMessage => _status;

  @override
  Future<void> start() async {
    // Scanning and connection handled by ConnectionProvider.
    // This method is called after a device is already connected.
    _status = 'Waiting for device...';
  }

  /// Attach to an already-connected BLE device and begin streaming.
  Future<void> attachToDevice(BluetoothDevice device) async {
    _device = device;
    _status = 'Discovering services...';

    try {
      final services = await device.discoverServices();
      _findCharacteristics(services);

      if (_writeChar == null || _readChar == null) {
        _status = 'Error: Could not find ELM327 characteristics';
        return;
      }

      // Enable notifications on the read characteristic
      await _readChar!.setNotifyValue(true);
      _notifySub = _readChar!.onValueReceived.listen(_onDataReceived);

      // Initialize ELM327
      _status = 'Initializing ELM327...';
      await _initElm327();

      _connected = true;
      _status = 'Connected — streaming data';

      // Start polling
      _startPolling();
    } catch (e) {
      _status = 'Error: $e';
      _connected = false;
    }
  }

  /// Find the writable and notifiable characteristics for the ELM327.
  void _findCharacteristics(List<BluetoothService> services) {
    for (final service in services) {
      for (final char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          _writeChar ??= char;
        }
        if (char.properties.notify) {
          _readChar ??= char;
        }
      }
    }
  }

  /// Send all AT init commands in sequence.
  Future<void> _initElm327() async {
    for (final cmd in Elm327Protocol.initCommands) {
      final response = await _sendCommandInternal(cmd);
      _logRaw(cmd, response);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  bool _isPolling = false;

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _currentPidIndex = 0;
    _pollLoop();
  }

  Future<void> _pollLoop() async {
    while (_isPolling && _connected && _writeChar != null) {
      final pid = Elm327Protocol.pollSequence[_currentPidIndex];
      _currentPidIndex = (_currentPidIndex + 1) % Elm327Protocol.pollSequence.length;

      try {
        final response = await _sendCommandInternal(pid);
        _logRaw(pid, response);
        final value = Elm327Protocol.parseResponse(pid, response);

        if (value != null) {
          switch (pid) {
            case Elm327Protocol.pidRpm:
              _rpm = value;
            case Elm327Protocol.pidEngineOilTemp:
              _engineOilTemp = value;
            case Elm327Protocol.pidThrottlePos:
              _throttlePos = value;
            case Elm327Protocol.pidSpeed:
              _speed = value;
            case Elm327Protocol.pidIntakeAirTemp:
              _intakeAirTemp = value;
            case Elm327Protocol.pidEngineLoad:
              _engineLoad = value;
          }

          // Emit raw data directly (UI handles smoothing via TweenAnimationBuilder)
          _controller.add(VehicleData(
            rpm: _rpm,
            speed: _speed,
            engineOilTemp: _engineOilTemp,
            throttlePosition: _throttlePos,
            intakeAirTemp: _intakeAirTemp,
            engineLoad: _engineLoad,
            timestamp: DateTime.now(),
          ));
        }
      } catch (e) {
        // Silently continue polling — transient BLE errors are expected.
      }
      
      // Zero artificial delay; immediately loop to next PID
    }
  }

  /// Low-level: send a command and wait for the ELM327 prompt ('>').
  Future<String> _sendCommandInternal(String command) async {
    if (_writeChar == null) return 'ERROR: No write characteristic';

    _responseBuffer.clear();
    _responseCompleter = Completer<String>();

    final bytes = utf8.encode(Elm327Protocol.buildCommand(command));
    await _writeChar!.write(bytes, withoutResponse: false);

    // Wait for response with timeout
    try {
      return await _responseCompleter!.future.timeout(
        const Duration(milliseconds: AppConstants.pidTimeoutMs),
        onTimeout: () => 'TIMEOUT',
      );
    } catch (_) {
      return 'ERROR';
    }
  }

  /// Handle incoming BLE notification data.
  void _onDataReceived(List<int> data) {
    final chunk = utf8.decode(data, allowMalformed: true);
    _responseBuffer.write(chunk);

    // ELM327 terminates responses with '>'
    if (chunk.contains('>')) {
      _responseCompleter?.complete(_responseBuffer.toString());
    }
  }

  void _logRaw(String command, String response) {
    _rawLog.add({
      'time': DateTime.now().toIso8601String(),
      'cmd': command,
      'response': response.trim(),
    });
    // Keep log bounded
    if (_rawLog.length > 500) {
      _rawLog.removeRange(0, _rawLog.length - 500);
    }
  }

  @override
  Future<void> stop() async {
    _isPolling = false;
    _notifySub?.cancel();
    _notifySub = null;
    _connected = false;
    _status = 'Disconnected';
  }

  @override
  Future<void> dispose() async {
    await stop();
    try {
      await _device?.disconnect();
    } catch (_) {}
    await _controller.close();
  }

  @override
  Future<String> sendRawCommand(String command) async {
    if (!_connected) return 'ERROR: Not connected';
    final response = await _sendCommandInternal(command.trim());
    _logRaw(command.trim(), response);
    return response;
  }
}
