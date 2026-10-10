class TelemetryPoint {
  final double timeSeconds;
  final double distanceMeters;
  final double elevationMeters;
  final double inclineGradePct;
  final double speedKmh;
  final double mechanicalPowerWatts;
  final double electricalPowerWatts;
  final double currentAmps;
  final double cRate;
  final double cellTempCelsius;
  final bool isPlatingRisk;
  final double instantaneousWearRateInrPerKm;
  final double cumulativeWearInr;
  final String stageName;

  const TelemetryPoint({
    required this.timeSeconds,
    required this.distanceMeters,
    required this.elevationMeters,
    required this.inclineGradePct,
    required this.speedKmh,
    required this.mechanicalPowerWatts,
    required this.electricalPowerWatts,
    required this.currentAmps,
    required this.cRate,
    required this.cellTempCelsius,
    required this.isPlatingRisk,
    required this.instantaneousWearRateInrPerKm,
    required this.cumulativeWearInr,
    required this.stageName,
  });
}
