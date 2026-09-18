/// The four implicit riding modes the dashboard transitions between.
///
/// Transitions are fully automatic based on sensor data:
/// - [warmup] → [normal]: EngineOil temp reaches 60°C
/// - [normal] → [power]: RPM > 6000 OR Throttle > 70% (sustained ~2s)
/// - [normal] → [touring]: Speed > 70 km/h AND Throttle < 30% (cruising)
/// - [power] / [touring] → [normal]: Conditions drop below thresholds (sustained ~3s)
enum RidingMode {
  /// Engine is cold. Focus on temperatures, engine viz prominent.
  warmup,

  /// Normal riding. Balanced view of all metrics.
  normal,

  /// Spirited riding. RPM and throttle dominate the layout.
  power,

  /// Highway cruising. Speed and music dominate.
  touring,
}
