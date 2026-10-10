/// FairLoad Evidence Harness — reproducible numeric verification of every
/// published claim in ../evidences/.
///
/// Run:  cd fairload && flutter test test/evidence_verification_test.dart
///
/// This file is ORIGINAL EVIDENCE. It does not assert "the model is right";
/// it records exactly what the shipped engine produces, so that each published
/// number in the evidence pack can be traced to a deterministic, re-runnable
/// computation. Every block prints the value it derives.
// ignore_for_file: avoid_print -- printing IS the deliverable of this harness
library;

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

import 'package:fairload/core/constants/battery_specs.dart';
import 'package:fairload/core/constants/vehicle_specs.dart';
import 'package:fairload/engine/battery_model.dart';
import 'package:fairload/engine/physics_engine.dart';
import 'package:fairload/engine/rupee_engine.dart';

String _f(double v, [int d = 2]) => v.toStringAsFixed(d);

void main() {
  group('E-01 Longitudinal power balance (PhysicsEngine)', () {
    // Evidence: VEHICLE_DRIVETRAIN_EVIDENCE.md §3
    final cases = <List<double>>[
      [239, 8.5, 4.2], // Chowkaghat crawl, 140 kg payload, 34 kg tare, 65 kg rider
      [239, 14.0, 4.2], // same grade, "aggressive" NeuroPace baseline
      [241, 8.2, 4.5], // Chowkaghat trace peak grade point
      [234, 8.8, 3.8], // Cantt overbridge crawl, 135 kg payload
      [239, 17.5, 0.2], // Lanka gallis flat
    ];
    for (final c in cases) {
      test('P_wheel @ ${c[0]}kg, ${c[1]}km/h, ${c[2]}%', () {
        final p = PhysicsEngine.computeMechanicalPowerWatts(
          totalGrossMassKg: c[0],
          velocityMs: c[1] / 3.6,
          inclineRadians: math.atan(c[2] / 100.0),
        );
        print('E-01 | m=${c[0]}kg v=${c[1]}km/h grade=${c[2]}% -> P_wheel=${_f(p, 1)} W');
        expect(p, greaterThan(0));
      });
    }

    test('zero-speed dead zone returns 0 W', () {
      expect(
        PhysicsEngine.computeMechanicalPowerWatts(
            totalGrossMassKg: 239, velocityMs: 0.05, inclineRadians: 0.04),
        0.0,
      );
    });
  });

  group('E-02 Motor efficiency curve (MotorProfile.efficiencyAtSpeed)', () {
    for (final m in VehicleSpecs.motorProfiles) {
      for (final v in [6.5, 8.5, 12.0, 14.0, 17.5, 25.0]) {
        test('${m.name} @ $v km/h', () {
          final e = m.efficiencyAtSpeed(v);
          print('E-02 | ${m.name} @ $v km/h -> eta=${_f(e, 4)}');
          expect(e, inInclusiveRange(0.35, m.ratedEfficiency));
        });
      }
    }
  });

  group('E-03 Battery current / C-rate / Joule heating (BatteryModel.step)', () {
    // Reproduces test/physics_battery_test.dart "Battery High-C and Thermal Rise"
    test('720 W on 48V 20Ah NMC, T_cell 42, T_amb 40, dt 60 s', () {
      final r = BatteryModel.step(
        electricalPowerWatts: 720,
        currentCellTempCelsius: 42,
        ambientTempCelsius: 40,
        deltaSeconds: 60,
        battery: BatterySpecs.profiles[0],
      );
      print('E-03 | 720W/48V20Ah -> I=${_f(r.currentAmps)} A, C=${_f(r.cRate, 3)} C, '
          'T_new=${_f(r.cellTempCelsius, 4)} C, plating=${r.isPlatingRisk}, W_f=${_f(r.wearMultiplier, 3)}');
      expect(r.currentAmps, closeTo(15.0, 1.0));
      expect(r.cRate, closeTo(0.75, 0.1));
      expect(r.cellTempCelsius, greaterThan(42.0));
    });

    // The headline "54 C in 80 s" claim from FAIRLOAD_CASE_STUDY.md §1.1
    test('15 A on 48V 20Ah NMC for 80 s starting at T_amb', () {
      final r = BatteryModel.step(
        electricalPowerWatts: 15 * 48,
        currentCellTempCelsius: 40,
        ambientTempCelsius: 40,
        deltaSeconds: 80,
        battery: BatterySpecs.profiles[0],
      );
      print('E-03 | 720W for 80 s from 40 C -> T_new=${_f(r.cellTempCelsius, 4)} C');
      expect(r.cellTempCelsius, greaterThan(40));
    });

    // Full thermal time constant, printed so the case-study claim is auditable.
    test('pack thermal time constant tau = m*Cp/(hA)', () {
      for (final b in BatterySpecs.profiles) {
        final tau = (b.packMassKg * b.specificHeatCapacityCp) /
            b.convectiveHeatTransferHA;
        print('E-03 | ${b.shortLabel}: mCp=${_f(b.packMassKg * b.specificHeatCapacityCp, 0)} J/K, '
            'hA=${_f(b.convectiveHeatTransferHA)} W/K, tau=${_f(tau / 60.0, 1)} min');
      }
    });

    // Steady-state temperature ceiling for each pack at a 20 A draw.
    test('steady-state T_ceiling at 20 A, T_amb 40 C', () {
      for (final b in BatterySpecs.profiles) {
        final q = math.pow(20.0, 2) * b.internalResistanceOhms;
        final tInf = 40 + q / b.convectiveHeatTransferHA;
        print('E-03 | ${b.shortLabel}: I2R@20A=${_f(q, 2)} W -> T_ss=${_f(tInf, 1)} C');
      }
    });

    test('controller current clamp at 35 A', () {
      final r = BatteryModel.step(
        electricalPowerWatts: 3000,
        currentCellTempCelsius: 40,
        ambientTempCelsius: 40,
        deltaSeconds: 1,
        battery: BatterySpecs.profiles[0],
      );
      print('E-03 | 3000 W request -> clamped I=${_f(r.currentAmps)} A');
      expect(r.currentAmps, 35.0);
    });
  });

  group('E-04 Wear factor surface W_f(C, T, plating)', () {
    test('NMC vs LFP at identical 800 W / 49 C load', () {
      for (final b in [BatterySpecs.profiles[0], BatterySpecs.profiles[2]]) {
        final r = BatteryModel.step(
          electricalPowerWatts: 800,
          currentCellTempCelsius: 49,
          ambientTempCelsius: 42,
          deltaSeconds: 60,
          battery: b,
        );
        print('E-04 | ${b.shortLabel}: I=${_f(r.currentAmps)} A, C=${_f(r.cRate, 3)} C, '
            'W_f=${_f(r.wearMultiplier, 3)}, plating=${r.isPlatingRisk}');
      }
    });

    test('W_f sweep over C-rate at T=40 C (NMC 48V20Ah)', () {
      for (final w in [100, 300, 500, 700, 900, 1100]) {
        final r = BatteryModel.step(
          electricalPowerWatts: w.toDouble(),
          currentCellTempCelsius: 40,
          ambientTempCelsius: 40,
          deltaSeconds: 1,
          battery: BatterySpecs.profiles[0],
        );
        print('E-04 | P=${w}W -> C=${_f(r.cRate, 3)} C, W_f=${_f(r.wearMultiplier, 3)}, '
            'plating=${r.isPlatingRisk}');
      }
    });

    test('W_f sweep over C-rate at T=40 C (LFP 51.2V 30Ah)', () {
      for (final w in [100, 300, 500, 700, 900, 1100]) {
        final r = BatteryModel.step(
          electricalPowerWatts: w.toDouble(),
          currentCellTempCelsius: 40,
          ambientTempCelsius: 40,
          deltaSeconds: 1,
          battery: BatterySpecs.profiles[2],
        );
        print('E-04 | LFP P=${w}W -> C=${_f(r.cRate, 3)} C, W_f=${_f(r.wearMultiplier, 3)}, '
            'plating=${r.isPlatingRisk}');
      }
    });

    test('rupee wear for one nominal equivalent full cycle', () {
      for (final b in BatterySpecs.profiles) {
        print('E-04 | ${b.shortLabel}: E_nom=${_f(b.totalNominalEnergyWh, 0)} Wh, '
            'Rs/cycle=${_f(b.baseCostPerCycleInr)}');
        expect(b.baseCostPerCycleInr,
            closeTo(b.packReplacementCostInr / b.ratedCycleLife, 1e-9));
      }
    });
  });

  group('E-05 Reverse payload mass solver', () {
    test('500 W motor pinned at 750 W, 8.5 km/h, 4.2% grade', () {
      final m = PhysicsEngine.reverseEstimateCargoMassKg(
        pinnedMotorPowerWatts: 750,
        velocityMs: 8.5 / 3.6,
        inclineRadians: math.atan(4.2 / 100),
        motor: VehicleSpecs.motorProfiles[1],
      );
      print('E-05 | est cargo = ${_f(m, 1)} kg');
      expect(m, inInclusiveRange(0, 220));
    });

    test('returns 0 below the 0.015 rad gate', () {
      expect(
        PhysicsEngine.reverseEstimateCargoMassKg(
          pinnedMotorPowerWatts: 750,
          velocityMs: 8.5 / 3.6,
          inclineRadians: 0.010,
          motor: VehicleSpecs.motorProfiles[1],
        ),
        0.0,
      );
    });
  });

  group('E-06 Pack specification register', () {
    test('prints derived pack quantities', () {
      for (final b in BatterySpecs.profiles) {
        print('E-06 | ${b.id} | ${b.chemistryLabel} | ${b.nominalVoltage}V '
            '${b.nominalCapacityAh}Ah | ${_f(b.totalNominalEnergyWh, 0)}Wh | '
            '${b.packMassKg}kg | ${_f(b.totalNominalEnergyWh / b.packMassKg, 1)} Wh/kg | '
            'R=${b.internalResistanceOhms}Ohm | ${b.ratedCycleLife.toInt()} cyc | '
            'Rs${b.packReplacementCostInr.toInt()}');
      }
    });

    test('prints derived vehicle quantities', () {
      for (final v in VehicleSpecs.vehicleProfiles) {
        print('E-06 | ${v.id} | tare=${v.tareMassKg}kg rider=${v.riderMassKg}kg '
            'kerb=${_f(v.totalKerbMassKg)}kg cargoLimit=${v.ratedCargoCapacityKg}kg '
            'motor=${v.motor.ratedContinuousPower.toInt()}W/${v.motor.stallTorqueNm}Nm '
            'peak=${v.motor.peakPower.toInt()}W');
      }
    });
  });

  group('E-07 Economics', () {
    test('demo shift ledger as shipped', () {
      final s = RupeeEngine.getDemoShiftSummary();
      print('E-07 | deliveries=${s.totalDeliveries} earnings=Rs${_f(s.grossEarningsInr)} '
          'wear=Rs${_f(s.totalBatteryWearInr)} net=Rs${_f(s.netRiderMarginInr)} '
          'packLife=${_f(s.estimatedPackLifeMonths, 2)} mo '
          'extracted=Rs${_f(s.platformSubsidyExtractedInr)}');
      expect(s.netRiderMarginInr,
          closeTo(s.grossEarningsInr - s.totalBatteryWearInr, 1e-9));
    });
  });
}