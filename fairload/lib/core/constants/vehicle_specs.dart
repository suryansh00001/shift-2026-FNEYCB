/// Vehicle specifications and aerodynamic constants for micromobility 2Ws in Varanasi
class VehicleSpecs {
  // Mechanical and gravitational constants
  static const double gravity = 9.80665; // m/s^2
  static const double airDensityVaranasi = 1.205; // kg/m^3 at ~40°C
  static const double dragCoefficientCd = 0.90; // Upright rider with bulky rear grocery stack
  static const double frontalAreaA = 0.58; // m^2
  static const double cdA = dragCoefficientCd * frontalAreaA; // ~0.522 m^2
  static const double rollingResistanceCrr = 0.0085; // Asphalt in Indian urban conditions

  // Default masses (kg)
  static const double defaultBikeTareMass = 34.0; // Lightweight e-cycle / retrofit frame
  static const double defaultRiderMass = 65.0; // Typical rider weight
  static const double defaultRatedCargoCapacity = 65.0; // Safe manufacturer rated cargo limit

  // Motor presets
  static const List<MotorProfile> motorProfiles = [
    MotorProfile(
      name: '250W Pedelec (Hero / Yulu)',
      ratedContinuousPower: 250.0,
      peakPower: 450.0,
      ratedSpeedKmh: 25.0,
      stallTorqueNm: 35.0,
      ratedEfficiency: 0.80,
    ),
    MotorProfile(
      name: '500W Cargo Hub (Standard Delivery)',
      ratedContinuousPower: 500.0,
      peakPower: 750.0,
      ratedSpeedKmh: 25.0,
      stallTorqueNm: 50.0,
      ratedEfficiency: 0.83,
    ),
    MotorProfile(
      name: '750W Heavy Cargo Hub (Retrofit)',
      ratedContinuousPower: 750.0,
      peakPower: 1100.0,
      ratedSpeedKmh: 30.0,
      stallTorqueNm: 70.0,
      ratedEfficiency: 0.85,
    ),
  ];

  // Vehicle Preset Profiles
  static const List<VehicleProfile> vehicleProfiles = [
    VehicleProfile(
      id: 'cargo_ecycle_500w',
      name: 'Cargo E-Cycle (500W Hub)',
      category: 'Purpose-Built E-Cargo',
      tareMassKg: 34.0,
      riderMassKg: 65.0,
      ratedCargoCapacityKg: 65.0,
      motor: MotorProfile(
        name: '500W Cargo Hub (Standard Delivery)',
        ratedContinuousPower: 500.0,
        peakPower: 750.0,
        ratedSpeedKmh: 25.0,
        stallTorqueNm: 50.0,
        ratedEfficiency: 0.83,
      ),
    ),
    VehicleProfile(
      id: 'heavy_trike_750w',
      name: 'Heavy Retrofit E-Loader / Trike (750W)',
      category: 'Retrofit 3-Wheeler / Trike',
      tareMassKg: 54.0,
      riderMassKg: 70.0,
      ratedCargoCapacityKg: 110.0,
      motor: MotorProfile(
        name: '750W Heavy Cargo Hub (Retrofit)',
        ratedContinuousPower: 750.0,
        peakPower: 1100.0,
        ratedSpeedKmh: 30.0,
        stallTorqueNm: 70.0,
        ratedEfficiency: 0.85,
      ),
    ),
    VehicleProfile(
      id: 'light_pedelec_250w',
      name: 'City Pedelec (250W Assist)',
      category: 'Lightweight Commuter',
      tareMassKg: 24.0,
      riderMassKg: 65.0,
      ratedCargoCapacityKg: 35.0,
      motor: MotorProfile(
        name: '250W Pedelec (Hero / Yulu)',
        ratedContinuousPower: 250.0,
        peakPower: 450.0,
        ratedSpeedKmh: 25.0,
        stallTorqueNm: 35.0,
        ratedEfficiency: 0.80,
      ),
    ),
  ];

  static VehicleProfile get defaultVehicleProfile => vehicleProfiles[0];
}

class VehicleProfile {
  final String id;
  final String name;
  final String category;
  final double tareMassKg;
  final double riderMassKg;
  final double ratedCargoCapacityKg;
  final MotorProfile motor;
  final double dragCoefficientCd;
  final double frontalAreaA;

  const VehicleProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.tareMassKg,
    required this.riderMassKg,
    required this.ratedCargoCapacityKg,
    required this.motor,
    this.dragCoefficientCd = 0.90,
    this.frontalAreaA = 0.58,
  });

  double get cdA => dragCoefficientCd * frontalAreaA;
  double get totalKerbMassKg => tareMassKg + riderMassKg;
}

class MotorProfile {
  final String name;
  final double ratedContinuousPower; // Watts
  final double peakPower; // Watts
  final double ratedSpeedKmh;
  final double stallTorqueNm;
  final double ratedEfficiency;

  const MotorProfile({
    required this.name,
    required this.ratedContinuousPower,
    required this.peakPower,
    required this.ratedSpeedKmh,
    required this.stallTorqueNm,
    required this.ratedEfficiency,
  });

  /// Computes motor efficiency at low RPM based on empirical hub motor curves
  /// At low speed climbing during power-limiting stall, single-speed efficiency drops to 45%-50%
  double efficiencyAtSpeed(double speedKmh) {
    if (speedKmh <= 0.5) return 0.35;
    final ratio = speedKmh / ratedSpeedKmh;
    // Exponential approach to peak efficiency with penalty at crawl speeds
    if (ratio >= 0.7) {
      return ratedEfficiency;
    } else {
      // Linear/curved drop from rated down to 0.45 at 5 km/h
      final eff = 0.40 + (ratedEfficiency - 0.40) * (ratio / 0.7);
      return eff.clamp(0.35, ratedEfficiency);
    }
  }
}
