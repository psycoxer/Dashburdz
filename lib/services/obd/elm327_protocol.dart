/// ELM327 AT command sequences and SAE J1979 PID parsing.
///
/// Protocol: ISO 15765-4 CAN (29-bit, 500 kbps) — matches Honda CB 350.
class Elm327Protocol {
  Elm327Protocol._();

  // ── AT Initialization Sequence ──

  /// Commands sent after connecting, in order.
  static const List<String> initCommands = [
    'ATZ',    // Reset
    'ATE0',   // Echo off
    'ATL0',   // Linefeeds off
    'ATH0',   // Headers off
    'ATS0',   // Spaces off (compact responses)
    'ATSP7',  // ISO 15765-4 CAN (29-bit, 500 kbps)
    'ATAT1',  // Adaptive timing on
  ];

  // ── PID Definitions (Service 01) ──

  static const String pidRpm = '010C';
  static const String pidEngineOilTemp = '015C';
  static const String pidThrottlePos = '0111';
  static const String pidSpeed = '010D';
  static const String pidIntakeAirTemp = '010F';

  /// Ordered list of PIDs to poll in round-robin.
  /// We prioritize RPM and Speed for smooth gauge sweeps.
  static const List<String> pollSequence = [
    pidRpm,
    pidSpeed,
    pidRpm,
    pidThrottlePos,
    pidRpm,
    pidEngineOilTemp,
    pidRpm,
    pidSpeed,
    pidRpm,
    pidThrottlePos,
    pidRpm,
    pidIntakeAirTemp,
  ];

  /// PID labels for the debug panel.
  static const Map<String, String> pidNames = {
    pidRpm: 'Engine RPM',
    pidEngineOilTemp: 'EngineOil Temperature',
    pidThrottlePos: 'Throttle Position',
    pidSpeed: 'Vehicle Speed',
    pidIntakeAirTemp: 'Intake Air Temperature',
  };

  // ── Response Parsing ──

  /// Carriage return terminator for ELM327 commands.
  static const String cr = '\r';

  /// ELM327 prompt character.
  static const String prompt = '>';

  /// Build a command string with CR terminator.
  static String buildCommand(String cmd) => '$cmd$cr';

  /// Parse a raw ELM327 response for a specific PID.
  ///
  /// Returns the decoded numeric value, or null if the response is invalid.
  /// Response format (with spaces off): "41XX..." where XX is the PID.
  static double? parseResponse(String pid, String rawResponse) {
    // Clean up the response
    final cleaned = rawResponse
        .replaceAll(prompt, '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll(' ', '')
        .trim()
        .toUpperCase();

    if (cleaned.isEmpty ||
        cleaned.contains('NODATA') ||
        cleaned.contains('ERROR') ||
        cleaned.contains('UNABLE') ||
        cleaned.contains('?')) {
      return null;
    }

    // Extract the expected response prefix: "41" + PID byte
    // PID "010C" → response prefix "410C"
    final pidByte = pid.substring(2);
    final expectedPrefix = '41$pidByte';

    // Find the response segment starting with the expected prefix
    final startIndex = cleaned.indexOf(expectedPrefix);
    if (startIndex == -1) return null;

    final dataStart = startIndex + expectedPrefix.length;
    final remaining = cleaned.substring(dataStart);

    try {
      switch (pid) {
        case pidRpm:
          // Formula: ((A * 256) + B) / 4
          if (remaining.length < 4) return null;
          final a = int.parse(remaining.substring(0, 2), radix: 16);
          final b = int.parse(remaining.substring(2, 4), radix: 16);
          return ((a * 256) + b) / 4.0;

        case pidEngineOilTemp:
          // Formula: A - 40
          if (remaining.length < 2) return null;
          final a = int.parse(remaining.substring(0, 2), radix: 16);
          return a - 40.0;

        case pidThrottlePos:
          // Formula: (A * 100) / 255
          if (remaining.length < 2) return null;
          final a = int.parse(remaining.substring(0, 2), radix: 16);
          return (a * 100.0) / 255.0;

        case pidSpeed:
          // Formula: A (km/h)
          if (remaining.length < 2) return null;
          final a = int.parse(remaining.substring(0, 2), radix: 16);
          return a.toDouble();

        case pidIntakeAirTemp:
          // Formula: A - 40
          if (remaining.length < 2) return null;
          final a = int.parse(remaining.substring(0, 2), radix: 16);
          return a - 40.0;

        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Encode a value back to hex response (for testing/debug display).
  static String encodeResponse(String pid, double value) {
    switch (pid) {
      case pidRpm:
        final raw = (value * 4).round();
        final a = (raw >> 8) & 0xFF;
        final b = raw & 0xFF;
        return '410C${a.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      case pidEngineOilTemp:
        final a = (value + 40).round().clamp(0, 255);
        return '415C${a.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      case pidThrottlePos:
        final a = (value * 255 / 100).round().clamp(0, 255);
        return '4111${a.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      case pidSpeed:
        final a = value.round().clamp(0, 255);
        return '410D${a.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      case pidIntakeAirTemp:
        final a = (value + 40).round().clamp(0, 255);
        return '410F${a.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      default:
        return '';
    }
  }
}
