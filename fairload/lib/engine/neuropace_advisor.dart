import 'dart:math' as math;
import '../core/constants/battery_specs.dart';
import '../core/constants/vehicle_specs.dart';
import 'battery_model.dart';
import 'physics_engine.dart';

class PacingRecommendation {
  final double targetSpeedKmh;
  final String pedalAssistLevel; // 'None', 'Light', 'Medium', 'Heavy'
  final double predictedCellTempCelsius;
  final double predictedTripWearInr;
  final double projectedSavingsInr;
  final int slaDelaySeconds;
  final String advisoryMessage;
  final bool isThermalAlertActive;

  const PacingRecommendation({
    required this.targetSpeedKmh,
    required this.pedalAssistLevel,
    required this.predictedCellTempCelsius,
    required this.predictedTripWearInr,
    required this.projectedSavingsInr,
    required this.slaDelaySeconds,
    required this.advisoryMessage,
    required this.isThermalAlertActive,
  });
}

/// Dynamic lookahead pacing advisor
/// Evaluates forward trajectories across upcoming road grade to protect battery health
class NeuroPaceAdvisor {
  static PacingRecommendation evaluate({
    required double currentSpeedKmh,
    required double roadGradePct,
    required double cargoMassKg,
    required double currentCellTempCelsius,
    required double ambientTempCelsius,
    required MotorProfile motor,
    BatteryProfile? battery,
    double tareMassKg = VehicleSpecs.defaultBikeTareMass,
    double riderMassKg = VehicleSpecs.defaultRiderMass,
  }) {
    final battProfile = battery ?? BatterySpecs.defaultProfile;

    // If road is flat or descending, no thermal pacing intervention is needed
    if (roadGradePct < 1.5) {
      final cruiseSpeed = currentSpeedKmh > 0 ? currentSpeedKmh.clamp(12.0, 25.0) : 18.0;
      return PacingRecommendation(
        targetSpeedKmh: cruiseSpeed,
        pedalAssistLevel: 'None',
        predictedCellTempCelsius: currentCellTempCelsius,
        predictedTripWearInr: 3.50,
        projectedSavingsInr: 0.0,
        slaDelaySeconds: 0,
        advisoryMessage: 'Corridor Cruising: Operating within nominal thermal limits.',
        isThermalAlertActive: false,
      );
    }

    // On flyover ascent (grade >= 1.5%):
    final inclineRad = roadGradePct / 100.0;
    final totalMass = tareMassKg + riderMassKg + cargoMassKg;

    // Dynamically calculate recommended eco target speed based on road grade, cargo overload, and cell temperature
    // Steeper grade or heavier payload demands lower motor velocity to prevent power-limiting stall and overheating
    double targetEcoSpeedKmh = 12.0 - (roadGradePct * 0.9) - ((cargoMassKg - 65.0).clamp(0.0, 100.0) * 0.03);

    // If cell temperature is approaching or above warning threshold, dial down target speed further
    final tempOverhead = currentCellTempCelsius - battProfile.tempSafeThreshold;
    if (tempOverhead > 0) {
      targetEcoSpeedKmh -= (tempOverhead * 0.25);
    }
    targetEcoSpeedKmh = targetEcoSpeedKmh.clamp(6.5, 14.0);

    // Assist power required based on grade severity
    double assistWatts = 50.0;
    String assistLevel = 'Light (40-60W)';
    if (roadGradePct > 4.5 || cargoMassKg > 100.0) {
      assistWatts = 90.0;
      assistLevel = 'Heavy (80-100W)';
    } else if (roadGradePct > 2.8) {
      assistWatts = 70.0;
      assistLevel = 'Medium (60-80W)';
    }

    // Trajectory 1: Aggressive Pinned Throttle (e.g. 14-16 km/h)
    final vAggressiveKmh = math.max(targetEcoSpeedKmh + 4.5, 13.5);
    final vAggressiveMs = vAggressiveKmh / 3.6;
    final pWheelAggressive = PhysicsEngine.computeMechanicalPowerWatts(
      totalGrossMassKg: totalMass,
      velocityMs: vAggressiveMs,
      inclineRadians: inclineRad,
    );
    final effAggressive = motor.efficiencyAtSpeed(vAggressiveKmh);
    final pElecAggressive = (pWheelAggressive / effAggressive).clamp(0.0, motor.peakPower);
    final aggSim = BatteryModel.step(
      electricalPowerWatts: pElecAggressive,
      currentCellTempCelsius: currentCellTempCelsius,
      ambientTempCelsius: ambientTempCelsius,
      deltaSeconds: 90.0, // 90s climb projection
      battery: battProfile,
    );
    final aggWearInr = aggSim.incrementalWearInr * 4.0; // Scaled to full ascent

    // Trajectory 2: NeuroPace Dynamic Eco Speed with Human Pedal Assist
    final vEcoMs = targetEcoSpeedKmh / 3.6;
    final pWheelEco = PhysicsEngine.computeMechanicalPowerWatts(
      totalGrossMassKg: totalMass,
      velocityMs: vEcoMs,
      inclineRadians: inclineRad,
    );
    // Rider human pedal assist reduces motor electrical draw
    final netPWheelEco = (pWheelEco - assistWatts).clamp(0.0, 1200.0);
    final effEco = motor.efficiencyAtSpeed(targetEcoSpeedKmh);
    final pElecEco = (netPWheelEco / effEco).clamp(0.0, motor.ratedContinuousPower);
    final ecoSim = BatteryModel.step(
      electricalPowerWatts: pElecEco,
      currentCellTempCelsius: currentCellTempCelsius,
      ambientTempCelsius: ambientTempCelsius,
      deltaSeconds: 90.0,
      battery: battProfile,
    );
    final ecoWearInr = ecoSim.incrementalWearInr * 4.0;

    final savings = (aggWearInr - ecoWearInr).clamp(0.0, 60.0);
    final delaySeconds = ((1000.0 / vEcoMs) - (1000.0 / vAggressiveMs)).round().clamp(0, 140);

    final isSevere = aggSim.isPlatingRisk || aggSim.cellTempCelsius > battProfile.tempWarningThreshold;

    final msg = isSevere
        ? "⚠️ FLYOVER STRESS DETECTED! Drop speed to ${targetEcoSpeedKmh.toStringAsFixed(1)} km/h + $assistLevel pedal assist. Prevents ${battProfile.chemistryLabel} cell plating & saves ₹${savings.toStringAsFixed(1)} wear (+$delaySeconds s SLA impact)."
        : "Moderate Incline (${roadGradePct.toStringAsFixed(1)}%): Maintain steady cadence at ~${targetEcoSpeedKmh.toStringAsFixed(0)} km/h to keep pack temperature below ${battProfile.tempWarningThreshold.toStringAsFixed(0)}°C.";

    return PacingRecommendation(
      targetSpeedKmh: targetEcoSpeedKmh,
      pedalAssistLevel: assistLevel,
      predictedCellTempCelsius: ecoSim.cellTempCelsius,
      predictedTripWearInr: ecoWearInr,
      projectedSavingsInr: savings,
      slaDelaySeconds: delaySeconds,
      advisoryMessage: msg,
      isThermalAlertActive: isSevere,
    );
  }
}
