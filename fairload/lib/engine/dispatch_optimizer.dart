import 'dart:math' as math;
import '../core/constants/battery_specs.dart';
import '../core/models/dispatch_models.dart';
import 'battery_model.dart';
import 'physics_engine.dart';

/// Physics-informed fleet assignment solver and conventional baseline comparator
class DispatchOptimizer {
  /// Evaluates the physical and electrochemical feasibility of assigning an order to a rider
  /// Evaluates the physical and electrochemical feasibility of assigning an order to a rider
  static AssignmentResult evaluateCandidate({
    required FleetRider rider,
    required DispatchOrder order,
    double ambientTempCelsius = 40.0,
    bool enforceHardSafety = true,
  }) {
    // 1. HARD CONSTRAINT: Payload capacity
    final maxPayload = rider.vehicleProfile.ratedCargoCapacityKg;
    final isOverloaded = order.weightKg > maxPayload;
    if (isOverloaded && enforceHardSafety) {
      return _buildRejectedResult(
        rider: rider,
        order: order,
        reason: 'Overload: Order (${order.weightKg} kg) exceeds vehicle payload rating ($maxPayload kg)',
      );
    }

    // 2. HARD CONSTRAINT: Battery minimum reserve SOC
    if (rider.currentSocPercent < 18.0 && enforceHardSafety) {
      return _buildRejectedResult(
        rider: rider,
        order: order,
        reason: 'Low SOC: Battery at ${rider.currentSocPercent.toStringAsFixed(0)}% (min safety reserve 18%)',
      );
    }

    // 3. HARD CONSTRAINT: Thermal runaway safety lockout
    if (rider.currentTempCelsius >= rider.batteryProfile.tempCriticalThreshold && enforceHardSafety) {
      return _buildRejectedResult(
        rider: rider,
        order: order,
        reason: 'Critical Heat: Pack core at ${rider.currentTempCelsius.toStringAsFixed(1)}°C exceeds critical cutoff',
      );
    }

    // 4. Kinematics & Power Balance
    final grossMass = rider.vehicleProfile.tareMassKg +
        rider.vehicleProfile.riderMassKg +
        order.weightKg;

    final inclineRad = math.atan(order.inclineGradePercent / 100.0);

    // Speed target: 17.5 km/h on flat, reduced on steep grades
    double cruiseSpeedMs = order.hasSteepIncline ? 2.36 : 4.86; // 8.5 km/h vs 17.5 km/h
    final pMech = PhysicsEngine.computeMechanicalPowerWatts(
      totalGrossMassKg: grossMass,
      velocityMs: cruiseSpeedMs,
      inclineRadians: inclineRad,
    );

    // Motor efficiency collapse at crawl speeds
    final speedKmh = cruiseSpeedMs * 3.6;
    final motorEfficiency = rider.vehicleProfile.motor.efficiencyAtSpeed(speedKmh);
    double pElec = motorEfficiency > 0.05 ? pMech / motorEfficiency : pMech / 0.50;

    // Check motor power limits
    final isMotorOverloaded = pElec > rider.vehicleProfile.motor.peakPower || isOverloaded;
    if (isMotorOverloaded) {
      // Pinned motor saturation under unmitigated overload
      pElec = math.max(pElec, rider.vehicleProfile.motor.peakPower);
      cruiseSpeedMs = order.hasSteepIncline ? 1.80 : 3.80;
    }

    // 5. Trip Time & SLA
    final distanceMeters = order.distanceKm * 1000.0;
    final travelTimeSeconds = distanceMeters / cruiseSpeedMs;
    final travelTimeMinutes = travelTimeSeconds / 60.0;
    final isWithinDeadline = travelTimeMinutes <= order.deadlineMinutes;

    // 6. Electrochemical Battery Stress
    final stepResult = BatteryModel.step(
      electricalPowerWatts: pElec,
      currentCellTempCelsius: rider.currentTempCelsius,
      ambientTempCelsius: ambientTempCelsius,
      deltaSeconds: math.min(180.0, travelTimeSeconds),
      battery: rider.batteryProfile,
    );

    final energyConsumedWh = pElec * (travelTimeSeconds / 3600.0);
    final totalPackWh = rider.batteryProfile.totalNominalEnergyWh;
    final socDrop = (energyConsumedWh / totalPackWh) * 100.0;
    final arrivalSoc = (rider.currentSocPercent - socDrop).clamp(0.0, 100.0);

    // Projected trip wear cost in INR
    final cycleFraction = energyConsumedWh / totalPackWh;
    double tripWearCostInr = cycleFraction *
        rider.batteryProfile.baseCostPerCycleInr *
        stepResult.wearMultiplier;

    if (isOverloaded && !enforceHardSafety) {
      // Overload penalty: accelerated particle cracking & thermal surge
      tripWearCostInr *= 2.2;
    }

    // Platform-funded Rider Battery Care Benefit (capped at ₹25/trip)
    final riderCareBenefitInr = math.min(25.0, 0.75 * tripWearCostInr);

    // Decision explanation synthesis
    final justification = _generateJustification(
      rider: rider,
      order: order,
      stepResult: stepResult,
      isWithinDeadline: isWithinDeadline,
      arrivalSoc: arrivalSoc,
      tripWearCostInr: tripWearCostInr,
    );

    return AssignmentResult(
      rider: rider,
      order: order,
      isFeasible: true,
      estimatedTravelTimeMinutes: travelTimeMinutes,
      isWithinDeadline: isWithinDeadline,
      mechanicalPowerWatts: pMech,
      electricalPowerWatts: pElec,
      motorEfficiency: motorEfficiency,
      peakCurrentAmps: stepResult.currentAmps,
      peakCRate: stepResult.cRate,
      estimatedTempCelsius: stepResult.cellTempCelsius,
      isPlatingRisk: stepResult.isPlatingRisk,
      wearMultiplier: stepResult.wearMultiplier,
      energyConsumedWh: energyConsumedWh,
      arrivalSocPercent: arrivalSoc,
      tripWearCostInr: tripWearCostInr,
      riderCareBenefitInr: riderCareBenefitInr,
      justification: justification,
    );
  }

  /// Conventional baseline: Assigns orders via naive proximity/FIFO without battery or incline physics
  static FleetDispatchPlan solveConventionalBaseline({
    required List<FleetRider> riders,
    required List<DispatchOrder> orders,
    double ambientTempCelsius = 40.0,
  }) {
    final availableRiders = List<FleetRider>.from(riders);
    final assignments = <AssignmentResult>[];
    final unserved = <DispatchOrder>[];

    int riderIdx = 0;
    for (final order in orders) {
      if (availableRiders.isEmpty) {
        unserved.add(order);
        continue;
      }

      // Conventional dispatcher assigns cyclically or by proximity without checking physics
      final candidateRider = availableRiders[riderIdx % availableRiders.length];
      riderIdx++;

      final result = evaluateCandidate(
        rider: candidateRider,
        order: order,
        ambientTempCelsius: ambientTempCelsius,
        enforceHardSafety: false,
      );

      assignments.add(result);
    }

    return _aggregatePlan(
      planType: 'Conventional Proximity',
      assignments: assignments,
      unservedOrders: unserved,
    );
  }

  /// FairLoad Physics-Informed Optimizer: Multi-objective assignment respecting constraints & minimizing degradation
  static FleetDispatchPlan solveFairLoadOptimized({
    required List<FleetRider> riders,
    required List<DispatchOrder> orders,
    double ambientTempCelsius = 40.0,
  }) {
    final assignedRiders = <String>{};
    final assignments = <AssignmentResult>[];
    final unserved = <DispatchOrder>[];

    // Sort orders by urgency and physical severity (steep + heavy orders first to reserve optimal hardware)
    final sortedOrders = List<DispatchOrder>.from(orders)..sort((a, b) {
      final aScore = (a.hasSteepIncline ? 2.0 : 0.0) + (a.isHeavy ? 1.5 : 0.0) + (1.0 / a.deadlineMinutes);
      final bScore = (b.hasSteepIncline ? 2.0 : 0.0) + (b.isHeavy ? 1.5 : 0.0) + (1.0 / b.deadlineMinutes);
      return bScore.compareTo(aScore);
    });

    for (final order in sortedOrders) {
      AssignmentResult? bestResult;
      double lowestScore = double.infinity;

      for (final rider in riders) {
        // Enforce max active jobs per rider (1 at a time in snapshot)
        if (assignedRiders.contains(rider.id)) continue;

        final candidate = evaluateCandidate(
          rider: rider,
          order: order,
          ambientTempCelsius: ambientTempCelsius,
        );

        if (!candidate.isFeasible) continue;

        // Multi-objective scoring function J
        // Penalize: wear cost, energy consumption, SLA delay, high-temp risk, and unfairness
        double score = candidate.tripWearCostInr * 1.5 +
            (candidate.energyConsumedWh * 0.08) +
            (candidate.isWithinDeadline ? 0.0 : 45.0) +
            (candidate.isPlatingRisk ? 60.0 : 0.0) +
            (candidate.peakCRate > 2.0 ? 25.0 : 0.0) +
            (rider.shiftHoursActive * 2.0); // Workload fairness term

        // Chemistry bonus: LFP rewarded on high-grade climbs
        if (order.hasSteepIncline && rider.batteryProfile.chemistry == BatteryChemistry.lfp) {
          score -= 15.0;
        }

        if (score < lowestScore) {
          lowestScore = score;
          bestResult = candidate;
        }
      }

      if (bestResult != null) {
        assignments.add(bestResult);
        assignedRiders.add(bestResult.rider.id);
      } else {
        unserved.add(order);
      }
    }

    return _aggregatePlan(
      planType: 'FairLoad Physics-Informed',
      assignments: assignments,
      unservedOrders: unserved,
    );
  }

  /// Runs both dispatchers and compiles comparative performance metrics
  static FleetDispatchComparison compareDispatchPlans({
    required List<FleetRider> riders,
    required List<DispatchOrder> orders,
    double ambientTempCelsius = 40.0,
  }) {
    final baseline = solveConventionalBaseline(
      riders: riders,
      orders: orders,
      ambientTempCelsius: ambientTempCelsius,
    );

    final optimized = solveFairLoadOptimized(
      riders: riders,
      orders: orders,
      ambientTempCelsius: ambientTempCelsius,
    );

    return FleetDispatchComparison(
      baselinePlan: baseline,
      fairloadPlan: optimized,
    );
  }

  static AssignmentResult _buildRejectedResult({
    required FleetRider rider,
    required DispatchOrder order,
    required String reason,
  }) {
    return AssignmentResult(
      rider: rider,
      order: order,
      isFeasible: false,
      rejectionReason: reason,
      estimatedTravelTimeMinutes: 0.0,
      isWithinDeadline: false,
      mechanicalPowerWatts: 0.0,
      electricalPowerWatts: 0.0,
      motorEfficiency: 0.0,
      peakCurrentAmps: 0.0,
      peakCRate: 0.0,
      estimatedTempCelsius: rider.currentTempCelsius,
      isPlatingRisk: false,
      wearMultiplier: 1.0,
      energyConsumedWh: 0.0,
      arrivalSocPercent: rider.currentSocPercent,
      tripWearCostInr: 0.0,
      riderCareBenefitInr: 0.0,
      justification: 'REJECTED: $reason',
    );
  }

  static String _generateJustification({
    required FleetRider rider,
    required DispatchOrder order,
    required BatteryStepResult stepResult,
    required bool isWithinDeadline,
    required double arrivalSoc,
    required double tripWearCostInr,
  }) {
    final chem = rider.batteryProfile.chemistryLabel;
    final payloadRatio = (order.weightKg / rider.vehicleProfile.ratedCargoCapacityKg * 100).toStringAsFixed(0);

    if (order.hasSteepIncline) {
      if (chem == 'LFP') {
        return 'Selected for ${order.corridorName} (grade ${order.inclineGradePercent}%). LFP thermal resilience up to 55°C absorbs low-RPM crawl without plating risk. Wear: ₹${tripWearCostInr.toStringAsFixed(2)}. Arrival SOC: ${arrivalSoc.toStringAsFixed(0)}%.';
      } else {
        return 'Matched to ${order.corridorName}. Payload at $payloadRatio% capacity. Managed C-rate (${stepResult.cRate.toStringAsFixed(2)}C) maintains cell temp below critical ceiling.';
      }
    } else {
      return 'Flat corridor assignment (${order.distanceKm} km). Low draw (${stepResult.cRate.toStringAsFixed(2)}C) yields benign wear ₹${tripWearCostInr.toStringAsFixed(2)}. SLA on-time: ${isWithinDeadline ? "YES" : "TIGHT"}.';
    }
  }

  static FleetDispatchPlan _aggregatePlan({
    required String planType,
    required List<AssignmentResult> assignments,
    required List<DispatchOrder> unservedOrders,
  }) {
    final feasible = assignments.where((a) => a.isFeasible).toList();

    double totalWear = 0.0;
    double totalEnergyWh = 0.0;
    int onTimeCount = 0;
    int highStressCount = 0;
    double totalBenefits = 0.0;

    for (final a in feasible) {
      totalWear += a.tripWearCostInr;
      totalEnergyWh += a.energyConsumedWh;
      if (a.isWithinDeadline) onTimeCount++;
      if (a.isPlatingRisk || a.peakCRate > 2.0 || a.estimatedTempCelsius > 48.0) {
        highStressCount++;
      }
      totalBenefits += a.riderCareBenefitInr;
    }

    final onTimeRate = feasible.isNotEmpty ? (onTimeCount / feasible.length) * 100.0 : 0.0;

    return FleetDispatchPlan(
      planType: planType,
      assignments: assignments,
      unservedOrders: unservedOrders,
      totalFleetWearInr: totalWear,
      totalEnergyKwh: totalEnergyWh / 1000.0,
      onTimeRatePercent: onTimeRate,
      highStressTripCount: highStressCount,
      totalRiderBenefitsFundedInr: totalBenefits,
    );
  }
}
