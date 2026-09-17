/// App-wide constants for mode thresholds, polling, gauge ranges, and animations.
class AppConstants {
  AppConstants._();

  // ── Riding Mode Thresholds ──
  /// EngineOil temp (°C) at which warmup → normal transition occurs.
  static const double warmupTempThreshold = 60.0;

  /// RPM above which power mode may activate.
  static const double powerRpmThreshold = 4000.0;

  /// Throttle position (%) above which power mode may activate.
  static const double powerThrottleThreshold = 50.0;

  /// Sustained duration (ms) required before switching to power mode.
  static const int powerSustainMs = 2000;

  /// Sustained duration (ms) below thresholds before leaving power mode.
  static const int powerCooldownMs = 3000;

  // ── OBD Polling ──
  /// Interval between successive PID requests.
  static const int pollingIntervalMs = 50;

  /// Timeout for a single PID request/response cycle.
  static const int pidTimeoutMs = 1500;

  // ── EMA Smoothing ──
  /// Default smoothing factor (0 = very smooth, 1 = no smoothing).
  static const double emaAlpha = 0.7;

  // ── Gauge Ranges ──
  static const double maxRpm = 9000.0;
  static const double redlineRpm = 7500.0;
  static const double maxSpeed = 160.0;
  static const double minTemp = -10.0;
  static const double maxTemp = 150.0;
  static const double maxThrottle = 100.0;

  // ── Animations ──
  /// Duration for tile layout transitions between modes.
  static const Duration modeSwitchDuration = Duration(milliseconds: 600);

  /// Duration for gauge needle/value animations.
  static const Duration gaugeAnimDuration = Duration(milliseconds: 300);

  /// Duration for theme switch crossfade.
  static const Duration themeSwitchDuration = Duration(milliseconds: 400);

  // ── Layout ──
  /// Gap between tiles in the grid (logical pixels).
  static const double tileGap = 8.0;

  /// Border radius for tile cards.
  static const double tileBorderRadius = 16.0;

  /// Padding inside each tile.
  static const double tilePadding = 12.0;

  // ── BLE ──
  /// Key for storing the last connected BLE device ID.
  static const String prefKeyDeviceId = 'last_ble_device_id';

  /// Key for storing theme mode preference.
  static const String prefKeyThemeMode = 'theme_mode';

  /// Key for storing data source preference (mock vs real).
  static const String prefKeyUseMock = 'use_mock_data';
}
