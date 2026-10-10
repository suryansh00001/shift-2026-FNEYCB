import 'dart:math' as math;
import '../core/constants/vehicle_specs.dart';

/// Kinematic power balance and reverse mass solver for micromobility 2Ws
class PhysicsEngine {
  /// Computes mechanical wheel power in Watts required to propel vehicle
  /// P_wheel = [m*g*(sin(theta) + Crr*cos(theta)) + 0.5*rho*CdA*v^2 + m*a] * v
  static double computeMechanicalPowerWatts({
    required double totalGrossMassKg,
    required double velocityMs,
    required double inclineRadians,
    double accelerationMs2 = 0.0,
  }) {
    if (velocityMs <= 0.05) return 0.0;

    // 1. Gravitational gradient resistance: F_grav = m * g * sin(theta)
    final fGravity = totalGrossMassKg * VehicleSpecs.gravity * math.sin(inclineRadians);

    // 2. Rolling resistance: F_roll = m * g * cos(theta) * Crr
    final fRolling = totalGrossMassKg *
        VehicleSpecs.gravity *
        math.cos(inclineRadians) *
        VehicleSpecs.rollingResistanceCrr;

    // 3. Aerodynamic drag resistance: F_aero = 0.5 * rho * CdA * v^2
    final fAero = 0.5 *
        VehicleSpecs.airDensityVaranasi *
        VehicleSpecs.cdA *
        math.pow(velocityMs, 2);

    // 4. Inertial acceleration force: F_inertial = m * a
    final fInertial = totalGrossMassKg * accelerationMs2;

    // Net tractive force at contact patch
    final fTractive = fGravity + fRolling + fAero + fInertial;

    // Mechanical power = Force * velocity (clamped to >= 0 for non-regenerative coasting)
    final pWheel = fTractive * velocityMs;
    return math.max(0.0, pWheel);
  }

  /// Reverse mass estimation on flyover climbs:
  /// When crawling at steady velocity (a ~ 0, v ~ 8-10 km/h) on a steep grade (theta > 3%),
  /// the low-power hub motor runs pinned at peak continuous power.
  /// Solving for total mass:
  /// m_total = (P_mech - 0.5*rho*CdA*v^3) / [g * v * (sin(theta) + Crr*cos(theta))]
  static double reverseEstimateCargoMassKg({
    required double pinnedMotorPowerWatts,
    required double velocityMs,
    required double inclineRadians,
    required MotorProfile motor,
    double bikeTareMass = VehicleSpecs.defaultBikeTareMass,
    double riderMass = VehicleSpecs.defaultRiderMass,
  }) {
    // Only valid on significant positive grades (> 1.5%) and forward movement
    if (inclineRadians < 0.015 || velocityMs < 0.8) return 0.0;

    final efficiency = motor.efficiencyAtSpeed(velocityMs * 3.6);
    final mechanicalPowerAvailable = pinnedMotorPowerWatts * efficiency;

    final aeroLossWatts = 0.5 *
        VehicleSpecs.airDensityVaranasi *
        VehicleSpecs.cdA *
        math.pow(velocityMs, 3);

    final netPowerForGrade = mechanicalPowerAvailable - aeroLossWatts;
    if (netPowerForGrade <= 0) return 0.0;

    final specificResistancePerKg = VehicleSpecs.gravity *
        velocityMs *
        (math.sin(inclineRadians) +
            VehicleSpecs.rollingResistanceCrr * math.cos(inclineRadians));

    if (specificResistancePerKg <= 0.001) return 0.0;

    final estimatedTotalMass = netPowerForGrade / specificResistancePerKg;
    final estimatedCargo = estimatedTotalMass - (bikeTareMass + riderMass);

    return estimatedCargo.clamp(0.0, 220.0);
  }
}
