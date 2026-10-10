import 'dart:math' as math;

enum BenefitStatus {
  accrued,
  verified,
  redeemed,
}

enum BenefitCategory {
  tripAccrual,
  batteryDiagnostic,
  preventiveBalancing,
  swapDiscount,
}

/// Ledger entry for an individual platform-funded Battery Care Benefit
class BatteryCareTransaction {
  final String id;
  final String orderId;
  final DateTime timestamp;
  final String corridorName;
  final double payloadKg;
  final double distanceKm;
  final double modeledWearInr;
  final double contributionRate;
  final double benefitCreditInr;
  final BenefitStatus status;
  final BenefitCategory category;
  final String description;

  const BatteryCareTransaction({
    required this.id,
    required this.orderId,
    required this.timestamp,
    required this.corridorName,
    required this.payloadKg,
    required this.distanceKm,
    required this.modeledWearInr,
    required this.contributionRate,
    required this.benefitCreditInr,
    required this.status,
    required this.category,
    required this.description,
  });

  String get statusLabel {
    switch (status) {
      case BenefitStatus.accrued:
        return 'Accrued';
      case BenefitStatus.verified:
        return 'Verified';
      case BenefitStatus.redeemed:
        return 'Redeemed';
    }
  }
}

/// Rider-facing maintenance wallet tracking transparent, platform-funded battery credits
class BatteryCareWallet {
  final String riderId;
  final String riderName;
  final double totalAccruedInr;
  final double availableBalanceInr;
  final double totalRedeemedInr;
  final List<BatteryCareTransaction> transactions;

  const BatteryCareWallet({
    required this.riderId,
    required this.riderName,
    required this.totalAccruedInr,
    required this.availableBalanceInr,
    required this.totalRedeemedInr,
    required this.transactions,
  });

  /// Factory creating an initial demo wallet populated with recent shift deliveries
  factory BatteryCareWallet.demoWallet({
    String riderId = 'RDR-01',
    String riderName = 'Suresh Kumar',
  }) {
    final now = DateTime.now();
    final sampleTx = [
      BatteryCareTransaction(
        id: 'BC-TX-881',
        orderId: 'ORD-388',
        timestamp: now.subtract(const Duration(minutes: 95)),
        corridorName: 'Chowkaghat Flyover (4.2%)',
        payloadKg: 28.5,
        distanceKm: 2.8,
        modeledWearInr: 18.40,
        contributionRate: 0.75,
        benefitCreditInr: 13.80,
        status: BenefitStatus.verified,
        category: BenefitCategory.tripAccrual,
        description: 'Heavy climb co-funding (75% of ₹18.40 wear)',
      ),
      BatteryCareTransaction(
        id: 'BC-TX-882',
        orderId: 'ORD-392',
        timestamp: now.subtract(const Duration(minutes: 50)),
        corridorName: 'Cantt Railway Overbridge (3.8%)',
        payloadKg: 19.0,
        distanceKm: 3.4,
        modeledWearInr: 12.60,
        contributionRate: 0.75,
        benefitCreditInr: 9.45,
        status: BenefitStatus.verified,
        category: BenefitCategory.tripAccrual,
        description: 'Overpass climb benefit (75% of ₹12.60 wear)',
      ),
      BatteryCareTransaction(
        id: 'BC-TX-883',
        orderId: 'ORD-399',
        timestamp: now.subtract(const Duration(minutes: 15)),
        corridorName: 'Lanka Heritage Gallis (Flat)',
        payloadKg: 8.0,
        distanceKm: 1.5,
        modeledWearInr: 1.80,
        contributionRate: 0.75,
        benefitCreditInr: 1.35,
        status: BenefitStatus.accrued,
        category: BenefitCategory.tripAccrual,
        description: 'Eco corridor baseline benefit',
      ),
    ];

    double accrued = 0.0;
    for (final tx in sampleTx) {
      accrued += tx.benefitCreditInr;
    }

    return BatteryCareWallet(
      riderId: riderId,
      riderName: riderName,
      totalAccruedInr: accrued + 120.0, // Existing baseline
      availableBalanceInr: accrued + 45.0,
      totalRedeemedInr: 75.0, // E.g. spent on BMS diagnostic check
      transactions: sampleTx,
    );
  }

  /// Appends a new trip accrual transaction according to the platform policy: B_trip = min(B_max, r_w * D_wear)
  BatteryCareWallet recordTripBenefit({
    required String orderId,
    required String corridorName,
    required double payloadKg,
    required double distanceKm,
    required double modeledWearInr,
    double contributionRate = 0.75,
    double maxBenefitCapInr = 25.0,
  }) {
    final credit = math.min(maxBenefitCapInr, contributionRate * modeledWearInr);
    final tx = BatteryCareTransaction(
      id: 'BC-TX-${DateTime.now().millisecondsSinceEpoch % 10000}',
      orderId: orderId,
      timestamp: DateTime.now(),
      corridorName: corridorName,
      payloadKg: payloadKg,
      distanceKm: distanceKm,
      modeledWearInr: modeledWearInr,
      contributionRate: contributionRate,
      benefitCreditInr: credit,
      status: BenefitStatus.accrued,
      category: BenefitCategory.tripAccrual,
      description: 'Platform benefit: ${(contributionRate * 100).toInt()}% of ₹${modeledWearInr.toStringAsFixed(2)} wear',
    );

    final updatedTx = [tx, ...transactions];
    return BatteryCareWallet(
      riderId: riderId,
      riderName: riderName,
      totalAccruedInr: totalAccruedInr + credit,
      availableBalanceInr: availableBalanceInr + credit,
      totalRedeemedInr: totalRedeemedInr,
      transactions: updatedTx,
    );
  }

  /// Simulates redeeming maintenance balance for approved workshop servicing
  BatteryCareWallet redeemBenefit({
    required String serviceTitle,
    required double amountInr,
    required BenefitCategory category,
  }) {
    if (amountInr > availableBalanceInr) return this;

    final tx = BatteryCareTransaction(
      id: 'BC-RED-${DateTime.now().millisecondsSinceEpoch % 10000}',
      orderId: 'SERVICE-VOUCHER',
      timestamp: DateTime.now(),
      corridorName: 'Varanasi EV Service Hub',
      payloadKg: 0.0,
      distanceKm: 0.0,
      modeledWearInr: 0.0,
      contributionRate: 0.0,
      benefitCreditInr: -amountInr,
      status: BenefitStatus.redeemed,
      category: category,
      description: 'Redeemed for $serviceTitle',
    );

    return BatteryCareWallet(
      riderId: riderId,
      riderName: riderName,
      totalAccruedInr: totalAccruedInr,
      availableBalanceInr: availableBalanceInr - amountInr,
      totalRedeemedInr: totalRedeemedInr + amountInr,
      transactions: [tx, ...transactions],
    );
  }
}
