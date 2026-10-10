import 'dart:math' as math;
import '../core/constants/battery_specs.dart';

class BatteryStepResult {
  final double currentAmps;
  final double cRate;
  final double cellTempCelsius;
  final bool isPlatingRisk;
  final double wearMultiplier;
  final double incrementalWearInr;

  const BatteryStepResult({
    required this.currentAmps,
    required this.cRate,
    required this.cellTempCelsius,
    required this.isPlatingRisk,
    required this.wearMultiplier,
    required this.incrementalWearInr,
  });
}

/// Models electrochemical cell degradation, thermal rise, and plating overpotential
/// Aligned with Warwick Manufacturing Group (WMG) and SimLionics research
class BatteryModel {
  /// Computes instantaneous battery metrics and thermal step over deltaSeconds
  static BatteryStepResult step({
    required double electricalPowerWatts,
    required double currentCellTempCelsius,
    required double ambientTempCelsius,
    required double deltaSeconds,
    BatteryProfile? battery,
    double? nominalVoltage,
    double? capacityAh,
  }) {
    final profile = battery ?? BatterySpecs.defaultProfile;
    final effVoltage = nominalVoltage ?? profile.nominalVoltage;
    final effCapacityAh = capacityAh ?? profile.nominalCapacityAh;

    // 1. Current draw (clamped to realistic controller current ceiling: 35A)
    final current = (electricalPowerWatts / effVoltage).clamp(0.0, 35.0);

    // 2. Discharge C-rate
    final cRate = current / effCapacityAh;

    // 3. Joule Heating & Thermal dissipation:
    // dT = [I^2 * R_int - hA*(T_cell - T_amb)] / (m_pack * Cp) * dt
    final qGenJoule = math.pow(current, 2) * profile.internalResistanceOhms;
    final qLossDissipated = profile.convectiveHeatTransferHA *
        (currentCellTempCelsius - ambientTempCelsius);
    final netThermalWatts = qGenJoule - qLossDissipated;

    final thermalMass = profile.packMassKg * profile.specificHeatCapacityCp; // J/K
    final deltaTemp = (netThermalWatts / thermalMass) * deltaSeconds;
    final newTemp = (currentCellTempCelsius + deltaTemp).clamp(ambientTempCelsius - 2.0, 75.0);

    // 4. Lithium plating risk threshold:
    // High C-rate combined with high heat triggers SEI fracture and metallic Li deposition
    final isPlating = (cRate >= profile.cRateWarningThreshold &&
            newTemp >= profile.tempWarningThreshold) ||
        (cRate >= profile.cRateCriticalThreshold);

    // 5. Arrhenius Degradation Law & Chemical Kinetics:
    // Aligned with Waldmann et al. (2022) and Sandia National Labs (2002)
    // Φ_T = exp[(E_a / R) * (1/T_ref - 1/T_cell)]
    final isLfp = profile.chemistry == BatteryChemistry.lfp;
    const double universalGasConstantR = 8.314462; // J/(mol·K)
    // Activation energy: LFP olivine lattice ~35 kJ/mol; NMC layered oxide ~50 kJ/mol
    final double eaJPerMol = isLfp ? 35000.0 : 50000.0;
    const double referenceTemperatureKelvin = 298.15; // 25.0 °C (298.15 K) standard laboratory baseline

    final cellTempKelvin = newTemp + 273.15;
    final phiThermal = math.max(
      1.0,
      math.exp((eaJPerMol / universalGasConstantR) * ((1.0 / referenceTemperatureKelvin) - (1.0 / cellTempKelvin))),
    );

    // C-Rate Overpotential Factor (Ψ_C):
    double psiCRate = 1.0;
    if (cRate > profile.cRateSafeThreshold) {
      final cScale = isLfp ? 1.2 : 1.8;
      psiCRate += math.pow(cRate - profile.cRateSafeThreshold, 1.8) * cScale;
    }

    // Lithium Plating Step Factor (metallic lithium dendrite deposition & SEI cracking):
    final platingMultiplier = isPlating ? (isLfp ? 1.7 : 2.5) : 1.0;

    final wearFactor = phiThermal * psiCRate * platingMultiplier;

    // 6. Micro-cycle wear cost:
    // Energy drawn in this step in Wh
    final deltaEnergyWh = electricalPowerWatts * (deltaSeconds / 3600.0);
    final cycleFraction = deltaEnergyWh / profile.totalNominalEnergyWh;
    final stepWearCostInr = cycleFraction * profile.baseCostPerCycleInr * wearFactor;

    return BatteryStepResult(
      currentAmps: current,
      cRate: cRate,
      cellTempCelsius: newTemp,
      isPlatingRisk: isPlating,
      wearMultiplier: wearFactor,
      incrementalWearInr: stepWearCostInr,
    );
  }
}
