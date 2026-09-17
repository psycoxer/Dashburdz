import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/obd/ble_obd_service.dart';
import 'obd_provider.dart';

enum BleConnectionState { disconnected, scanning, connecting, connected, error }

class ConnectionNotifier extends Notifier<BleConnectionState> {
  String _deviceName = '';
  String _errorMessage = '';
  StreamSubscription<List<ScanResult>>? _scanSub;

  String get deviceName => _deviceName;
  String get errorMessage => _errorMessage;

  @override
  BleConnectionState build() {
    // If we switch to real BLE (useMock == false), auto-start scan
    ref.listen(useMockProvider, (prev, isMock) {
      if (!isMock) {
        startScan();
      } else {
        disconnect();
      }
    });

    return BleConnectionState.disconnected;
  }

  Future<void> startScan() async {
    if (state == BleConnectionState.scanning ||
        state == BleConnectionState.connecting ||
        state == BleConnectionState.connected) {
      return;
    }

    state = BleConnectionState.scanning;
    _errorMessage = '';

    try {
      // Check if Bluetooth is supported and on
      if (await FlutterBluePlus.isSupported == false) {
        _setError('Bluetooth not supported');
        return;
      }
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        await FlutterBluePlus.adapterState.where((s) => s == BluetoothAdapterState.on).first;
      }

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.advName.toUpperCase();
          // Common ELM327 BLE names
          if (name.contains('OBD') || name.contains('V-LINK') || name.contains('LINK')) {
            _connectToDevice(r.device);
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      
      // If scan finishes and we're still scanning, we didn't find anything
      if (state == BleConnectionState.scanning) {
        _setError('No OBD-II device found');
      }
    } catch (e) {
      _setError('Scan failed: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (state == BleConnectionState.connecting || state == BleConnectionState.connected) return;
    
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();

    state = BleConnectionState.connecting;
    _deviceName = device.advName.isNotEmpty ? device.advName : 'OBD-II Device';

    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        license: License.nonprofit,
      );
      
      // Handoff to the OBD service
      final obdService = ref.read(obdServiceProvider);
      if (obdService is BleObdService) {
        await obdService.attachToDevice(device);
      }

      state = BleConnectionState.connected;

      // Listen for disconnects
      device.connectionState.listen((event) {
        if (event == BluetoothConnectionState.disconnected) {
          _setError('Device disconnected');
        }
      });
    } catch (e) {
      _setError('Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    state = BleConnectionState.disconnected;
  }

  void _setError(String msg) {
    _errorMessage = msg;
    state = BleConnectionState.error;
  }
}

final connectionProvider =
    NotifierProvider<ConnectionNotifier, BleConnectionState>(
  ConnectionNotifier.new,
);
