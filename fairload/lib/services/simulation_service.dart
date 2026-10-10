import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/constants/battery_specs.dart';
import '../core/constants/vehicle_specs.dart';
import '../core/models/telemetry_point.dart';
import '../core/models/trip_record.dart';
import '../engine/battery_model.dart';
import '../engine/physics_engine.dart';
import '../engine/sensor_fusion.dart';

class SimulationTrace {
  final String routeId;
  final String name;
  final String description;
  final double lengthMeters;
  final int durationSeconds;
  final double defaultAmbientTemp;
  final List<TracePointRaw> points;

  const SimulationTrace({
    required this.routeId,
    required this.name,
    required this.description,
    required this.lengthMeters,
    required this.durationSeconds,
    required this.defaultAmbientTemp,
    required this.points,
  });

  factory SimulationTrace.fromJson(Map<String, dynamic> json) {
    return SimulationTrace(
      routeId: json['route_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      lengthMeters: (json['length_meters'] as num?)?.toDouble() ?? 1000.0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 120,
      defaultAmbientTemp: (json['default_ambient_temp'] as num?)?.toDouble() ?? 40.0,
      points: (json['points'] as List? ?? [])
          .map((p) => TracePointRaw.fromJson(p))
          .toList(),
    );
  }
}

class TracePointRaw {
  final int timeSeconds;
  final double distanceMeters;
  final double elevationMeters;
  final double gradePct;
  final double speedKmh;
  final String stage;

  const TracePointRaw({
    required this.timeSeconds,
    required this.distanceMeters,
    required this.elevationMeters,
    required this.gradePct,
    required this.speedKmh,
    required this.stage,
  });

  factory TracePointRaw.fromJson(Map<String, dynamic> json) {
    return TracePointRaw(
      timeSeconds: (json['time_s'] as num?)?.toInt() ?? 0,
      distanceMeters: (json['dist_m'] as num?)?.toDouble() ?? 0.0,
      elevationMeters: (json['elev_m'] as num?)?.toDouble() ?? 0.0,
      gradePct: (json['grade_pct'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      stage: json['stage'] ?? '',
    );
  }
}

class SimulationService {
  static Future<SimulationTrace> loadTrace(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final data = json.decode(jsonString);
    return SimulationTrace.fromJson(data);
  }

  /// Evaluates an entire raw trace given user-configured parameters
  /// (Cargo Weight, Ambient Temp, Motor Profile, Battery Profile, Vehicle Profile)
  static List<TelemetryPoint> evaluateFullTrace({
    required SimulationTrace trace,
    required double cargoMassKg,
    required double ambientTempCelsius,
    required MotorProfile motor,
    BatteryProfile? battery,
    VehicleProfile? vehicle,
  }) {
    final battProfile = battery ?? BatterySpecs.defaultProfile;
    final vehProfile = vehicle ?? VehicleSpecs.defaultVehicleProfile;
    final List<TelemetryPoint> evaluatedPoints = [];
    double currentCellTemp = ambientTempCelsius;
    double cumulativeWear = 0.0;
    final totalMass = vehProfile.tareMassKg + vehProfile.riderMassKg + cargoMassKg;

    for (int i = 0; i < trace.points.length; i++) {
      final p = trace.points[i];
      final deltaSec = i == 0 ? 1.0 : (p.timeSeconds - trace.points[i - 1].timeSeconds).toDouble();
      final velocityMs = p.speedKmh / 3.6;
      final inclineRad = SensorFusion.gradePctToRadians(p.gradePct);

      // Compute mechanical wheel power
      final pMech = PhysicsEngine.computeMechanicalPowerWatts(
        totalGrossMassKg: totalMass,
        velocityMs: velocityMs,
        inclineRadians: inclineRad,
      );

      // Motor efficiency at this speed
      final efficiency = motor.efficiencyAtSpeed(p.speedKmh);
      final pElec = (pMech / efficiency).clamp(0.0, motor.peakPower);

      // Battery step
      final battResult = BatteryModel.step(
        electricalPowerWatts: pElec,
        currentCellTempCelsius: currentCellTemp,
        ambientTempCelsius: ambientTempCelsius,
        deltaSeconds: deltaSec,
        battery: battProfile,
      );

      currentCellTemp = battResult.cellTempCelsius;
      cumulativeWear += battResult.incrementalWearInr;

      final kmh = p.speedKmh > 0 ? p.speedKmh : 0.1;
      final wearRatePerKm = (battResult.incrementalWearInr / (kmh * (deltaSec / 3600.0))).clamp(0.0, 50.0);

      evaluatedPoints.add(TelemetryPoint(
        timeSeconds: p.timeSeconds.toDouble(),
        distanceMeters: p.distanceMeters,
        elevationMeters: p.elevationMeters,
        inclineGradePct: p.gradePct,
        speedKmh: p.speedKmh,
        mechanicalPowerWatts: pMech,
        electricalPowerWatts: pElec,
        currentAmps: battResult.currentAmps,
        cRate: battResult.cRate,
        cellTempCelsius: currentCellTemp,
        isPlatingRisk: battResult.isPlatingRisk,
        instantaneousWearRateInrPerKm: wearRatePerKm,
        cumulativeWearInr: cumulativeWear,
        stageName: p.stage,
      ));
    }

    return evaluatedPoints;
  }

  /// Aggregates evaluated points into a complete TripRecord
  static TripRecord buildTripRecord({
    required SimulationTrace trace,
    required List<TelemetryPoint> points,
    required double cargoMassKg,
    VehicleProfile? vehicle,
  }) {
    final veh = vehicle ?? VehicleSpecs.defaultVehicleProfile;
    double peakGrade = 0.0;
    double peakC = 0.0;
    double peakTemp = 0.0;
    double totalSpeed = 0.0;
    double totalEnergyWh = 0.0;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (pt.inclineGradePct > peakGrade) peakGrade = pt.inclineGradePct;
      if (pt.cRate > peakC) peakC = pt.cRate;
      if (pt.cellTempCelsius > peakTemp) peakTemp = pt.cellTempCelsius;
      totalSpeed += pt.speedKmh;

      final dt = i == 0 ? 1.0 : (pt.timeSeconds - points[i - 1].timeSeconds);
      totalEnergyWh += pt.electricalPowerWatts * (dt / 3600.0);
    }

    final avgSpeed = points.isNotEmpty ? totalSpeed / points.length : 15.0;
    final totalWear = points.isNotEmpty ? points.last.cumulativeWearInr : 0.0;
    final lastPt = points.isNotEmpty ? points.last : null;

    return TripRecord(
      tripId: "TRIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      routeName: trace.name,
      startTime: DateTime.now().subtract(Duration(seconds: trace.durationSeconds)),
      durationSeconds: trace.durationSeconds.toDouble(),
      distanceMeters: lastPt?.distanceMeters ?? trace.lengthMeters,
      assignedCargoKg: cargoMassKg,
      ratedCargoLimitKg: veh.ratedCargoCapacityKg,
      peakGradePct: peakGrade,
      peakCRate: peakC,
      peakCellTempCelsius: peakTemp,
      averageSpeedKmh: avgSpeed,
      totalEnergyConsumedWh: totalEnergyWh,
      totalBatteryWearInr: totalWear,
      orderPayoutInr: BatterySpecs.averageOrderDeliveryPayoutInr,
      telemetryTrace: points,
    );
  }
}
