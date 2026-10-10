import 'dart:math' as math;

/// Fuses barometric pressure altitude changes with GPS horizontal displacement
/// Implements a complementary filter to reject extreme handlebar vibration noise
/// caused by Varanasi potholes, brick roads, and flyover expansion joints.
class SensorFusion {
  // Complementary filter weight (0.92 gives heavy smoothing against high-frequency handlebar vibration)
  static const double filterAlpha = 0.92;

  double _fusedAltitude = 0.0;
  bool _isInitialized = false;

  /// Resets filter state
  void reset(double initialAltitude) {
    _fusedAltitude = initialAltitude;
    _isInitialized = true;
  }

  /// Updates the fused altitude given raw barometric delta and raw GPS altitude
  double updateAltitude({
    required double deltaBarometricAltitude,
    required double rawGpsAltitude,
  }) {
    if (!_isInitialized) {
      reset(rawGpsAltitude);
      return _fusedAltitude;
    }

    // Complementary filter formula:
    // fused(t) = alpha * (fused(t-1) + deltaBaro) + (1 - alpha) * rawGps
    _fusedAltitude = filterAlpha * (_fusedAltitude + deltaBarometricAltitude) +
        (1.0 - filterAlpha) * rawGpsAltitude;

    return _fusedAltitude;
  }

  /// Calculates road grade (percentage) from altitude change and horizontal distance
  /// Clamped to [-20%, +20%] to filter spurious sensor spikes
  static double computeRoadGradePct({
    required double deltaAltitudeMeters,
    required double horizontalDistanceMeters,
  }) {
    if (horizontalDistanceMeters < 0.5) return 0.0;
    final grade = (deltaAltitudeMeters / horizontalDistanceMeters) * 100.0;
    return grade.clamp(-20.0, 20.0);
  }

  /// Converts grade percentage to incline angle in radians: theta = atan(grade / 100)
  static double gradePctToRadians(double gradePct) {
    return math.atan(gradePct / 100.0);
  }
}
