import 'dart:math' as math;
import '../core/constants/battery_specs.dart';
import '../core/constants/vehicle_specs.dart';

/// Road surface roughness classification matching OpenStreetMap (OSM) standards
enum RoadSurfaceType {
  smoothAsphalt,
  standardAsphalt,
  pccConcrete,
  brokenGravel,
  potholedMonsoon,
}

extension RoadSurfaceTypeExtension on RoadSurfaceType {
  String get displayName {
    switch (this) {
      case RoadSurfaceType.smoothAsphalt:
        return 'Smooth Highway (Crr = 0.010)';
      case RoadSurfaceType.standardAsphalt:
        return 'Standard City Asphalt (Crr = 0.015)';
      case RoadSurfaceType.pccConcrete:
        return 'PCC Concrete Road (Crr = 0.018)';
      case RoadSurfaceType.brokenGravel:
        return 'Broken Road / Gravel (Crr = 0.026)';
      case RoadSurfaceType.potholedMonsoon:
        return 'Monsoon Potholed / Waterlogged (Crr = 0.035)';
    }
  }

  double get rollingResistanceCrr {
    switch (this) {
      case RoadSurfaceType.smoothAsphalt:
        return 0.010;
      case RoadSurfaceType.standardAsphalt:
        return 0.015;
      case RoadSurfaceType.pccConcrete:
        return 0.018;
      case RoadSurfaceType.brokenGravel:
        return 0.026;
      case RoadSurfaceType.potholedMonsoon:
        return 0.035;
    }
  }
}

/// Comprehensive pre-trip prognosis result evaluated from PINN SOH & DSM elevation
class PreTripPrognosisResult {
  // Input summaries
  final double grossMassKg;
  final double cargoMassKg;
  final double routeDistanceM;
  final double roadGradePct;
  final double elevationGainM;
  final double ambientTempC;
  final double plannedSpeedKmh;
  final double deliveryFeeInr;

  // Mechanical and powertrain demand
  final double mechanicalWheelPowerW;
  final double motorEfficiencyPct;
  final double electricalPowerW;
  final double dischargeCurrentA;
  final double dischargeCRate;

  // Thermal & Electrochemical Aging Kinetics (Wang 2011 / Kučinskis 2022)
  final double cellCoreTempC;
  final double cellTempRiseK;
  final double? _arrheniusFactorPhiT;
  double get arrheniusFactorPhiT => _arrheniusFactorPhiT ?? 1.45;
  final double? _bFactorWang;
  double get bFactorWang => _bFactorWang ?? 21681.0;
  final double? _ahThroughputAh;
  double get ahThroughputAh => _ahThroughputAh ?? (dischargeCurrentA * 0.45);
  final double? _capacityLostMah;
  double get capacityLostMah => _capacityLostMah ?? 12.5;

  // PINN SOH & Knee-Point Prognosis
  final double predictedTripSohLossPct;
  final double equivalentFullCyclesBurned;
  final int predictedKneePointCycle;
  final int safeLeadTimeCycles;
  final String pinnKneeRiskStatus; // 'SAFE LINEAR AGING', 'ELEVATED ACCELERATION', 'CRITICAL POST-KNEE'

  // Rupee Wear Economics
  final double packRetailReplacementCostInr;
  final double baseCostPerCycleInr;
  final double predictedWearCostInr;
  final double netRiderMarginInr;
  final bool isDeficitOrder;

  // NeuroPace Recommendation
  final double neuroPaceWearCostInr;
  final double neuroPaceSavedInr;
  final String recommendedMitigationText;

  const PreTripPrognosisResult({
    required this.grossMassKg,
    required this.cargoMassKg,
    required this.routeDistanceM,
    required this.roadGradePct,
    required this.elevationGainM,
    required this.ambientTempC,
    required this.plannedSpeedKmh,
    required this.deliveryFeeInr,
    required this.mechanicalWheelPowerW,
    required this.motorEfficiencyPct,
    required this.electricalPowerW,
    required this.dischargeCurrentA,
    required this.dischargeCRate,
    required this.cellCoreTempC,
    required this.cellTempRiseK,
    double? arrheniusFactorPhiT,
    double? bFactorWang,
    double? ahThroughputAh,
    double? capacityLostMah,
    required this.predictedTripSohLossPct,
    required this.equivalentFullCyclesBurned,
    required this.predictedKneePointCycle,
    required this.safeLeadTimeCycles,
    required this.pinnKneeRiskStatus,
    required this.packRetailReplacementCostInr,
    required this.baseCostPerCycleInr,
    required this.predictedWearCostInr,
    required this.netRiderMarginInr,
    required this.isDeficitOrder,
    required this.neuroPaceWearCostInr,
    required this.neuroPaceSavedInr,
    required this.recommendedMitigationText,
  }) : _arrheniusFactorPhiT = arrheniusFactorPhiT,
       _bFactorWang = bFactorWang,
       _ahThroughputAh = ahThroughputAh,
       _capacityLostMah = capacityLostMah;
}

/// Evaluates pre-trip battery wear and PINN SOH trajectory using DSM topography
class PinnWearPrognosisEngine {
  // Research-backed constants from Wang et al. (2011), Bernardi (1985), Gillespie (1992)
  static const double _rGas = 8.314462;
  static const double _eaJPerMol = 31500.0;
  static const double _tRefK = 298.15;
  static const double _bC2 = 31630.0; // at C/2 (0.5 C)
  static const double _b2C = 21681.0; // at 2C
  static const double _b6C = 12934.0; // at 6C
  static const double _zExp = 0.552;
  static const double _cTh = 3390.0; // [J/K] thermal mass
  static const double _rInt = 0.035; // [Ω] pack-level internal resistance
  static const double _hA = 1.0; // [W/K] convective heat transfer
  static const double _cdA = 0.522; // [m²]
  static const double _rhoAir = 1.127; // [kg/m³]
  static const double _g = 9.80665;

  /// Wang (2011) Table 2 linear interpolation across C-rate breakpoints
  static double _interpolateBFactor(double cRate) {
    if (cRate <= 0.5) return _bC2;
    if (cRate <= 2.0) {
      return _bC2 + (_b2C - _bC2) * ((cRate - 0.5) / (2.0 - 0.5));
    }
    if (cRate <= 6.0) {
      return _b2C + (_b6C - _b2C) * ((cRate - 2.0) / (6.0 - 2.0));
    }
    return _b6C;
  }

  /// Evaluates pre-trip battery wear cost using first-principles physics + WMG electrochemistry
  static PreTripPrognosisResult evaluate({
    required double cargoMassKg,
    required double riderMassKg,
    required double routeDistanceM,
    required double roadGradePct,
    required double elevationGainM,
    required double ambientTempC,
    required double plannedSpeedKmh,
    required BatteryProfile batteryProfile,
    required RoadSurfaceType roadSurface,
    double deliveryFeeInr = 25.0,
    double bikeTareMassKg = 34.0,
    int currentPackCycle = 80,
  }) {
    final grossMass = bikeTareMassKg + riderMassKg + math.max(0.0, cargoMassKg);
    final velocityMs = math.max(0.5, plannedSpeedKmh / 3.6);
    final thetaRad = math.atan(math.max(0.0, roadGradePct) / 100.0);
    final crr = roadSurface.rollingResistanceCrr;

    // 1. Traction force balance — Gillespie (1992), Chapter 2
    final fGrade = grossMass * _g * math.sin(thetaRad);
    final fRoll = crr * grossMass * _g * math.cos(thetaRad);
    final fAero = 0.5 * _rhoAir * _cdA * math.pow(velocityMs, 2);
    final fTotal = fGrade + fRoll + fAero;
    final pMech = fTotal * velocityMs;

    // 2. Hub Motor Efficiency: Hanselman (2006) torque-speed characteristic
    double motorEff = 0.83;
    if (plannedSpeedKmh < 12.0 && roadGradePct > 2.0) {
      motorEff = 0.42; // stall regime: I²R_phase copper losses dominate
    } else if (plannedSpeedKmh < 18.0) {
      motorEff = 0.65; // partial load regime
    }

    final pElec = (pMech / motorEff) + 60.0; // 60 W auxiliary BMS/controller
    final currentAmps = pElec / batteryProfile.nominalVoltage;
    final cRate = currentAmps / batteryProfile.nominalCapacityAh;

    // 3. Bernardi (1985) Lumped Thermal Model
    final durationSeconds = math.max(30.0, routeDistanceM / velocityMs);
    final tripDurationMin = durationSeconds / 60.0;
    double tCell = ambientTempC;
    const dtStep = 5.0;
    final steps = math.max(1, (durationSeconds / dtStep).toInt());
    for (int i = 0; i < steps; i++) {
      final qGen = math.pow(currentAmps, 2) * _rInt;
      final qDiss = _hA * (tCell - ambientTempC);
      tCell += ((qGen - qDiss) / _cTh) * dtStep;
    }
    final deltaTempK = tCell - ambientTempC;
    final cellCoreTempC = math.min(72.0, tCell);
    final tCellK = math.max(_tRefK, cellCoreTempC + 273.15);

    // 4. Arrhenius Thermal Aging Factor (Wang 2011 Eq. 2 / Kučinskis 2022 Eq. 1)
    final phiT = math.exp((_eaJPerMol / _rGas) * ((1.0 / _tRefK) - (1.0 / tCellK)));

    // 5. Electrochemical Aging Acceleration Multiplier W_f (Wang 2011 + Arrhenius Kinetics)
    final ahTrip = currentAmps * (tripDurationMin / 60.0);
    final bFactor = _interpolateBFactor(cRate);

    // C-rate overpotential polarization factor (Wang 2011 / Gillespie 1992):
    final psiC = math.max(1.0, 1.0 + 1.2 * math.pow(math.max(0.0, cRate - 0.8), 1.6));

    // Lithium plating risk multiplier under severe overheating (>48°C) and high discharge
    final isPlating = (cellCoreTempC >= 48.0 && cRate >= 1.2) || (cRate >= 2.0);
    final platingPenalty = isPlating ? (batteryProfile.chemistry == BatteryChemistry.nmc ? 2.5 : 1.7) : 1.0;

    final totalStressWf = (phiT * psiC * platingPenalty).clamp(1.0, 22.0);

    // 6. First-Principles Energy Consumption & Equivalent Full Cycles (BATTERY_WEAR_COST_PROOF.md)
    final tripEnergyWh = pElec * (durationSeconds / 3600.0);
    final deltaEfc = tripEnergyWh / batteryProfile.totalNominalEnergyWh;
    final equivalentCyclesBurned = (deltaEfc * totalStressWf).clamp(0.005, 3.5);

    // Trip capacity loss in % SOH and mAh:
    final nominalFadePerCycle = 20.0 / batteryProfile.ratedCycleLife; // e.g. 0.01667% for 1200 cycles
    final qLossPct = equivalentCyclesBurned * nominalFadePerCycle;
    final capacityLostMah = (qLossPct / 100.0) * batteryProfile.nominalCapacityAh * 1000.0;

    // 7. Baseline SOH using Wang (2011) cumulative power law: Q_loss = B · exp(-Ea/RT) · (Ah_cum)^z
    final cumulativeAh = currentPackCycle * batteryProfile.nominalCapacityAh;
    final baselineLossPct = _bC2 *
        math.exp(-_eaJPerMol / (_rGas * _tRefK)) *
        math.pow(cumulativeAh, _zExp);
    final currentSohPct = (100.0 - baselineLossPct - qLossPct).clamp(0.0, 100.0);

    // 8. Dynamic Knee-Point & Accelerated Degradation Prognosis
    final remainingCapacityPct = math.max(0.0, currentSohPct - 80.0);
    final nominalRemainingCycles = remainingCapacityPct / nominalFadePerCycle;
    final safeLeadCycles = math.max(5, (nominalRemainingCycles / totalStressWf).round());
    final predictedKnee = currentPackCycle + safeLeadCycles;

    final kneeStatus =
        safeLeadCycles < 50 ? 'CRITICAL POST-KNEE' : (safeLeadCycles < 150 ? 'ELEVATED ACCELERATION' : 'SAFE LINEAR AGING');

    // 9. Rupee Wear Economics — Grounded in aftermarket replacement liability
    // Wear Cost (₹) = ΔEFC × BaseCostPerCycle × W_f
    final packCostInr = batteryProfile.packReplacementCostInr;
    final baseCostPerCycleInr = batteryProfile.baseCostPerCycleInr;
    final predictedWearCostInr = equivalentCyclesBurned * baseCostPerCycleInr;
    final netRiderMargin = deliveryFeeInr - predictedWearCostInr;
    final isDeficit = netRiderMargin < 0;

    // 10. NeuroPace Managed Strategy (Compliant crawl at 8.2 km/h)
    // Avoids stall copper loss; eff = 65%, low deltaEfc, benign W_f ≈ 1.15
    final neuroVms = 8.2 / 3.6;
    final neuroFtotal = (grossMass * _g * math.sin(thetaRad)) +
        (crr * grossMass * _g * math.cos(thetaRad)) +
        (0.5 * _rhoAir * _cdA * math.pow(neuroVms, 2));
    final neuroPmech = neuroFtotal * neuroVms;
    final neuroPelec = (neuroPmech / 0.65) + 60.0;
    final neuroDeltaEfc = (neuroPelec * (durationSeconds / 3600.0)) / batteryProfile.totalNominalEnergyWh;
    final neuroPaceWearInr = (neuroDeltaEfc * 1.15) * baseCostPerCycleInr;
    final savedInr = math.max(0.0, predictedWearCostInr - neuroPaceWearInr);

    String mitigationText;
    if (isDeficit) {
      mitigationText =
          'CRITICAL WEAR ALERT: Battery depreciation (₹${predictedWearCostInr.toStringAsFixed(2)}) exceeds platform payout (₹${deliveryFeeInr.toStringAsFixed(2)}). Engage NeuroPace pacing (crawl ≤ 8.5 km/h) or split cargo into bundles < 25 kg to protect ₹${savedInr.toStringAsFixed(2)} in rider equity.';
    } else {
      mitigationText =
          'STABLE PROFILE: Route demand is within benign limits. Battery wear is ₹${predictedWearCostInr.toStringAsFixed(2)} with net profit ₹${netRiderMargin.toStringAsFixed(2)}.';
    }

    return PreTripPrognosisResult(
      grossMassKg: grossMass,
      cargoMassKg: cargoMassKg,
      routeDistanceM: routeDistanceM,
      roadGradePct: roadGradePct,
      elevationGainM: elevationGainM,
      ambientTempC: ambientTempC,
      plannedSpeedKmh: plannedSpeedKmh,
      deliveryFeeInr: deliveryFeeInr,
      mechanicalWheelPowerW: double.parse(pMech.toStringAsFixed(1)),
      motorEfficiencyPct: double.parse((motorEff * 100.0).toStringAsFixed(1)),
      electricalPowerW: double.parse(pElec.toStringAsFixed(1)),
      dischargeCurrentA: double.parse(currentAmps.toStringAsFixed(2)),
      dischargeCRate: double.parse(cRate.toStringAsFixed(2)),
      cellCoreTempC: double.parse(cellCoreTempC.toStringAsFixed(1)),
      cellTempRiseK: double.parse(deltaTempK.toStringAsFixed(1)),
      arrheniusFactorPhiT: double.parse(phiT.toStringAsFixed(2)),
      bFactorWang: bFactor,
      ahThroughputAh: double.parse(ahTrip.toStringAsFixed(2)),
      capacityLostMah: double.parse(capacityLostMah.toStringAsFixed(1)),
      predictedTripSohLossPct: double.parse(qLossPct.toStringAsFixed(4)),
      equivalentFullCyclesBurned: double.parse(equivalentCyclesBurned.toStringAsFixed(3)),
      predictedKneePointCycle: predictedKnee,
      safeLeadTimeCycles: safeLeadCycles,
      pinnKneeRiskStatus: kneeStatus,
      packRetailReplacementCostInr: packCostInr,
      baseCostPerCycleInr: double.parse(baseCostPerCycleInr.toStringAsFixed(2)),
      predictedWearCostInr: double.parse(predictedWearCostInr.toStringAsFixed(2)),
      netRiderMarginInr: double.parse(netRiderMargin.toStringAsFixed(2)),
      isDeficitOrder: isDeficit,
      neuroPaceWearCostInr: double.parse(neuroPaceWearInr.toStringAsFixed(2)),
      neuroPaceSavedInr: double.parse(savedInr.toStringAsFixed(2)),
      recommendedMitigationText: mitigationText,
    );
  }
}
