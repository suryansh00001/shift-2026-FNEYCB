import 'package:flutter_test/flutter_test.dart';
import 'package:fairload/core/constants/dispatch_demo_data.dart';
import 'package:fairload/core/models/dispatch_models.dart';
import 'package:fairload/engine/battery_care_ledger.dart';
import 'package:fairload/engine/dispatch_optimizer.dart';

void main() {
  group('Dispatch Optimizer & Constraints Unit Tests', () {
    final defaultRider = DispatchDemoData.sampleRiders[1]; // Suresh Kumar (500W Cargo, LFP)

    test('Hard Constraint: Rejects order exceeding vehicle payload limit', () {
      const overweightOrder = DispatchOrder(
        id: 'ORD-OVERWEIGHT',
        customerName: 'Heavy Cargo Customer',
        pickupLocation: 'Dark Store',
        deliveryLocation: 'Godowlia',
        weightKg: 85.0, // Exceeds 65 kg payload rating of Cargo E-Cycle
        deadlineMinutes: 30,
        priority: 'bulk',
        corridorId: 'lanka_flat',
        corridorName: 'Flat Street',
        distanceKm: 2.0,
        inclineGradePercent: 0.5,
      );

      final result = DispatchOptimizer.evaluateCandidate(
        rider: defaultRider,
        order: overweightOrder,
      );

      expect(result.isFeasible, isFalse);
      expect(result.rejectionReason, contains('Overload: Order (85.0 kg) exceeds vehicle payload rating'));
    });

    test('Hard Constraint: Rejects rider below 18% reserve battery SOC', () {
      final lowSocRider = defaultRider.copyWith(currentSocPercent: 14.0);
      final normalOrder = DispatchDemoData.sampleOrders[2]; // 8.5 kg

      final result = DispatchOptimizer.evaluateCandidate(
        rider: lowSocRider,
        order: normalOrder,
      );

      expect(result.isFeasible, isFalse);
      expect(result.rejectionReason, contains('Low SOC: Battery at 14%'));
    });

    test('Hard Constraint: Rejects pack with core temperature exceeding critical limit', () {
      final hotRider = defaultRider.copyWith(currentTempCelsius: 60.5);
      final normalOrder = DispatchDemoData.sampleOrders[2];

      final result = DispatchOptimizer.evaluateCandidate(
        rider: hotRider,
        order: normalOrder,
      );

      expect(result.isFeasible, isFalse);
      expect(result.rejectionReason, contains('Critical Heat'));
    });

    test('Physics Evaluation: LFP absorbs Chowkaghat 4.2% climb with benign wear and zero plating', () {
      final chowkaghatOrder = DispatchDemoData.sampleOrders[0]; // 28.5 kg, 4.2% grade

      final result = DispatchOptimizer.evaluateCandidate(
        rider: defaultRider, // LFP pack
        order: chowkaghatOrder,
      );

      expect(result.isFeasible, isTrue);
      expect(result.isPlatingRisk, isFalse);
      expect(result.electricalPowerWatts, greaterThan(200.0));
      expect(result.tripWearCostInr, greaterThan(0.0));
      expect(result.riderCareBenefitInr, greaterThan(0.0));
      expect(result.justification, contains('LFP thermal resilience'));
    });

    test('Fleet Dispatch Comparison: FairLoad outperforms conventional baseline', () {
      final comparison = DispatchOptimizer.compareDispatchPlans(
        riders: DispatchDemoData.sampleRiders,
        orders: DispatchDemoData.sampleOrders,
      );

      expect(comparison.baselinePlan.assignments.length, equals(DispatchDemoData.sampleOrders.length));
      expect(comparison.fairloadPlan.assignments.length, equals(DispatchDemoData.sampleOrders.length));

      // FairLoad should achieve lower total battery degradation wear cost
      expect(comparison.fairloadPlan.totalFleetWearInr, lessThanOrEqualTo(comparison.baselinePlan.totalFleetWearInr));
      expect(comparison.wearSavingsInr, greaterThanOrEqualTo(0.0));
      expect(comparison.fairloadPlan.totalRiderBenefitsFundedInr, greaterThan(0.0));
    });

    test('Battery Care Benefit Ledger: Transparent non-deducted accrual & redemption', () {
      var wallet = BatteryCareWallet.demoWallet();
      final initialBalance = wallet.availableBalanceInr;

      wallet = wallet.recordTripBenefit(
        orderId: 'ORD-TEST-99',
        corridorName: 'Chowkaghat Flyover',
        payloadKg: 28.0,
        distanceKm: 3.2,
        modeledWearInr: 20.00,
        contributionRate: 0.75,
      );

      expect(wallet.availableBalanceInr, equals(initialBalance + 15.00));
      expect(wallet.transactions.first.orderId, equals('ORD-TEST-99'));

      // Test redemption
      wallet = wallet.redeemBenefit(
        serviceTitle: 'BMS Diagnostic Check',
        amountInr: 25.0,
        category: BenefitCategory.batteryDiagnostic,
      );

      expect(wallet.availableBalanceInr, equals(initialBalance + 15.00 - 25.00));
      expect(wallet.totalRedeemedInr, equals(75.0 + 25.0));
    });
  });
}
