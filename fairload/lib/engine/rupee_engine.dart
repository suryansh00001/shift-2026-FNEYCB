
class ShiftLedgerSummary {
  final int totalDeliveries;
  final double grossEarningsInr;
  final double totalBatteryWearInr;
  final double netRiderMarginInr;
  final double estimatedPackLifeMonths;
  final double platformSubsidyExtractedInr;

  const ShiftLedgerSummary({
    required this.totalDeliveries,
    required this.grossEarningsInr,
    required this.totalBatteryWearInr,
    required this.netRiderMarginInr,
    required this.estimatedPackLifeMonths,
    required this.platformSubsidyExtractedInr,
  });
}

class RupeeEngine {
  /// Computes cumulative shift economics from a list of completed trips
  static ShiftLedgerSummary computeShiftLedger({
    required int completedTrips,
    required double totalGrossEarnings,
    required double totalBatteryWear,
  }) {
    final netMargin = totalGrossEarnings - totalBatteryWear;

    // Normal pack life: 24 months under gentle 0.5C cycling
    // If average trip wear is 2.5x to 3.5x nominal, pack life drops proportionally
    double avgWearMultiplier = 1.0;
    if (completedTrips > 0) {
      final nominalWearPerTrip = 4.0; // ₹4.00 base nominal wear per trip
      final actualAvgWear = totalBatteryWear / completedTrips;
      avgWearMultiplier = (actualAvgWear / nominalWearPerTrip).clamp(1.0, 6.0);
    }

    final projectedMonths = (24.0 / avgWearMultiplier).clamp(2.5, 24.0);

    // Platform subsidy extracted: total battery asset value consumed that was uncompensated
    final uncompensatedWear = (totalBatteryWear - (completedTrips * 5.0)).clamp(0.0, 10000.0);

    return ShiftLedgerSummary(
      totalDeliveries: completedTrips,
      grossEarningsInr: totalGrossEarnings,
      totalBatteryWearInr: totalBatteryWear,
      netRiderMarginInr: netMargin,
      estimatedPackLifeMonths: projectedMonths,
      platformSubsidyExtractedInr: uncompensatedWear,
    );
  }

  /// Default baseline mock shift for judge demonstration
  static ShiftLedgerSummary getDemoShiftSummary() {
    return const ShiftLedgerSummary(
      totalDeliveries: 12,
      grossEarningsInr: 300.0, // 12 drops * ₹25
      totalBatteryWearInr: 398.50, // High wear due to 4 flyover runs under 140kg load
      netRiderMarginInr: -98.50, // Net loss to rider
      estimatedPackLifeMonths: 3.8, // Collapses from 24 down to 3.8 months
      platformSubsidyExtractedInr: 338.50,
    );
  }
}
