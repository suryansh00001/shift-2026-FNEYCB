import '../constants/battery_specs.dart';
import '../constants/vehicle_specs.dart';

/// Single customer delivery order originating from a dark store
class DispatchOrder {
  final String id;
  final String customerName;
  final String pickupLocation;
  final String deliveryLocation;
  final double weightKg;
  final int deadlineMinutes;
  final String priority; // 'urgent' | 'standard' | 'bulk'
  final String corridorId;
  final String corridorName;
  final double distanceKm;
  final double inclineGradePercent;

  const DispatchOrder({
    required this.id,
    required this.customerName,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.weightKg,
    required this.deadlineMinutes,
    required this.priority,
    required this.corridorId,
    required this.corridorName,
    required this.distanceKm,
    required this.inclineGradePercent,
  });

  bool get isHeavy => weightKg > 20.0;
  bool get hasSteepIncline => inclineGradePercent >= 3.0;
}

/// Delivery fleet rider with real-time hardware, battery, and state telemetry
class FleetRider {
  final String id;
  final String name;
  final String currentLocation;
  final bool isAvailable;
  final VehicleProfile vehicleProfile;
  final BatteryProfile batteryProfile;
  final double currentSocPercent;
  final double currentTempCelsius;
  final double shiftHoursActive;
  final int completedDeliveries;
  final double accumulatedBenefitInr;

  const FleetRider({
    required this.id,
    required this.name,
    required this.currentLocation,
    required this.isAvailable,
    required this.vehicleProfile,
    required this.batteryProfile,
    required this.currentSocPercent,
    required this.currentTempCelsius,
    required this.shiftHoursActive,
    required this.completedDeliveries,
    required this.accumulatedBenefitInr,
  });

  FleetRider copyWith({
    String? id,
    String? name,
    String? currentLocation,
    bool? isAvailable,
    VehicleProfile? vehicleProfile,
    BatteryProfile? batteryProfile,
    double? currentSocPercent,
    double? currentTempCelsius,
    double? shiftHoursActive,
    int? completedDeliveries,
    double? accumulatedBenefitInr,
  }) {
    return FleetRider(
      id: id ?? this.id,
      name: name ?? this.name,
      currentLocation: currentLocation ?? this.currentLocation,
      isAvailable: isAvailable ?? this.isAvailable,
      vehicleProfile: vehicleProfile ?? this.vehicleProfile,
      batteryProfile: batteryProfile ?? this.batteryProfile,
      currentSocPercent: currentSocPercent ?? this.currentSocPercent,
      currentTempCelsius: currentTempCelsius ?? this.currentTempCelsius,
      shiftHoursActive: shiftHoursActive ?? this.shiftHoursActive,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      accumulatedBenefitInr: accumulatedBenefitInr ?? this.accumulatedBenefitInr,
    );
  }
}

/// Evaluated assignment candidate linking a rider to a specific order
class AssignmentResult {
  final FleetRider rider;
  final DispatchOrder order;
  final bool isFeasible;
  final String? rejectionReason;
  final double estimatedTravelTimeMinutes;
  final bool isWithinDeadline;
  final double mechanicalPowerWatts;
  final double electricalPowerWatts;
  final double motorEfficiency;
  final double peakCurrentAmps;
  final double peakCRate;
  final double estimatedTempCelsius;
  final bool isPlatingRisk;
  final double wearMultiplier;
  final double energyConsumedWh;
  final double arrivalSocPercent;
  final double tripWearCostInr;
  final double riderCareBenefitInr;
  final String justification;

  const AssignmentResult({
    required this.rider,
    required this.order,
    required this.isFeasible,
    this.rejectionReason,
    required this.estimatedTravelTimeMinutes,
    required this.isWithinDeadline,
    required this.mechanicalPowerWatts,
    required this.electricalPowerWatts,
    required this.motorEfficiency,
    required this.peakCurrentAmps,
    required this.peakCRate,
    required this.estimatedTempCelsius,
    required this.isPlatingRisk,
    required this.wearMultiplier,
    required this.energyConsumedWh,
    required this.arrivalSocPercent,
    required this.tripWearCostInr,
    required this.riderCareBenefitInr,
    required this.justification,
  });
}

/// Fleet-wide dispatch execution plan
class FleetDispatchPlan {
  final String planType; // 'Conventional Proximity' | 'FairLoad Physics-Informed'
  final List<AssignmentResult> assignments;
  final List<DispatchOrder> unservedOrders;
  final double totalFleetWearInr;
  final double totalEnergyKwh;
  final double onTimeRatePercent;
  final int highStressTripCount;
  final double totalRiderBenefitsFundedInr;

  const FleetDispatchPlan({
    required this.planType,
    required this.assignments,
    required this.unservedOrders,
    required this.totalFleetWearInr,
    required this.totalEnergyKwh,
    required this.onTimeRatePercent,
    required this.highStressTripCount,
    required this.totalRiderBenefitsFundedInr,
  });

  int get assignedCount => assignments.where((a) => a.isFeasible).length;
}

/// Head-to-head comparison between Conventional and FairLoad dispatch
class FleetDispatchComparison {
  final FleetDispatchPlan baselinePlan;
  final FleetDispatchPlan fairloadPlan;

  const FleetDispatchComparison({
    required this.baselinePlan,
    required this.fairloadPlan,
  });

  double get wearSavingsInr =>
      (baselinePlan.totalFleetWearInr - fairloadPlan.totalFleetWearInr).clamp(0.0, 9999.0);

  double get wearReductionPercent {
    if (baselinePlan.totalFleetWearInr <= 0.0) return 0.0;
    return (wearSavingsInr / baselinePlan.totalFleetWearInr) * 100.0;
  }

  int get highStressTripsAvoided =>
      (baselinePlan.highStressTripCount - fairloadPlan.highStressTripCount).clamp(0, 99);

  double get netPlatformBenefitInr =>
      wearSavingsInr - fairloadPlan.totalRiderBenefitsFundedInr;

  /// Projected annual savings for a 50-bike quick-commerce dark-store hub (300 trips/day)
  double get projectedAnnualFleetSavingsInr {
    final dailySavings = wearSavingsInr * (300.0 / (fairloadPlan.assignedCount > 0 ? fairloadPlan.assignedCount : 1));
    return dailySavings * 365.0;
  }
}
