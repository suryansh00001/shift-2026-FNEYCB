import 'telemetry_point.dart';

class TripRecord {
  final String tripId;
  final String routeName;
  final DateTime startTime;
  final double durationSeconds;
  final double distanceMeters;
  final double assignedCargoKg;
  final double ratedCargoLimitKg;
  final double peakGradePct;
  final double peakCRate;
  final double peakCellTempCelsius;
  final double averageSpeedKmh;
  final double totalEnergyConsumedWh;
  final double totalBatteryWearInr;
  final double orderPayoutInr;
  final List<TelemetryPoint> telemetryTrace;

  TripRecord({
    required this.tripId,
    required this.routeName,
    required this.startTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.assignedCargoKg,
    required this.ratedCargoLimitKg,
    required this.peakGradePct,
    required this.peakCRate,
    required this.peakCellTempCelsius,
    required this.averageSpeedKmh,
    required this.totalEnergyConsumedWh,
    required this.totalBatteryWearInr,
    required this.orderPayoutInr,
    required this.telemetryTrace,
  });

  double get netEarningsInr => orderPayoutInr - totalBatteryWearInr;
  double get overloadPercentage => ((assignedCargoKg - ratedCargoLimitKg) / ratedCargoLimitKg) * 100.0;
  bool get isOverloaded => assignedCargoKg > ratedCargoLimitKg;
  bool get hasPlatingDamage => peakCRate > 2.5 && peakCellTempCelsius > 45.0;
}
