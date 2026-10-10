/// FairLoad Evidence Harness — PART B: corridor trace re-simulation.
///
/// This reproduces the exact inner loop of
/// lib/services/simulation_service.dart (lines 98-128) against the shipped
/// trace JSON, so that every number in the results table of
/// FAIRLOAD_CASE_STUDY.md §3 can be independently checked.
///
/// Run:  cd fairload && flutter test test/evidence_trace_audit_test.dart
// ignore_for_file: avoid_print -- printing IS the deliverable of this harness
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fairload/core/constants/battery_specs.dart';
import 'package:fairload/core/constants/vehicle_specs.dart';
import 'package:fairload/engine/battery_model.dart';
import 'package:fairload/engine/physics_engine.dart';

String _f(double v, [int d = 2]) => v.toStringAsFixed(d);

class Row {
  Row(this.t, this.dist, this.elev, this.grade, this.kmh, this.stage);
  final double t, dist, elev, grade, kmh;
  final String stage;
}

Map<String, dynamic> _load(String name) => jsonDecode(
    File('assets/traces/$name').readAsStringSync()) as Map<String, dynamic>;

List<Row> _rows(Map<String, dynamic> j) => (j['points'] as List)
    .cast<Map<String, dynamic>>()
    .map((p) => Row(
          (p['time_s'] as num).toDouble(),
          (p['dist_m'] as num).toDouble(),
          (p['elev_m'] as num).toDouble(),
          (p['grade_pct'] as num).toDouble(),
          (p['speed_kmh'] as num).toDouble(),
          (p['stage'] as String),
        ))
    .toList();

/// Peak-C-rate upper bound imposed by the 35 A controller clamp in
/// BatteryModel.step line 40, for a given pack.
double maxAchievableCRate(BatteryProfile b) => 35.0 / b.nominalCapacityAh;

void main() {
  test('E-08 controller clamp bounds the maximum reachable C-rate', () {
    for (final b in BatterySpecs.profiles) {
      print('E-08 | ${b.shortLabel}: I_clamp=35 A / ${b.nominalCapacityAh} Ah '
          '=> C_max=${_f(maxAchievableCRate(b), 2)} C');
    }
    // The 48 V 20 Ah pack physically cannot exceed 1.75 C in this engine.
    expect(maxAchievableCRate(BatterySpecs.profiles[0]), closeTo(1.75, 1e-9));
  });

  test('E-08b minimum motor power to reach 3.5 C on 48V 20Ah', () {
    // 3.5 C * 20 Ah = 70 A -> * 48 V = 3360 W, far above the 35 A clamp.
    final neededA = 3.5 * 20.0;
    print('E-08b | 3.5 C on 48V20Ah requires ${_f(neededA, 0)} A '
        '(= ${_f(neededA * 48, 0)} W); clamp is 35 A');
    expect(neededA, greaterThan(35.0));
  });

  for (final traceFile in [
    'chowkaghat_flyover.json',
    'cantt_overbridge.json',
    'lanka_gallis.json',
  ]) {
    test('E-09 trace audit: $traceFile', () {
      final j = _load(traceFile);
      final rows = _rows(j);
      final declaredLen = (j['length_meters'] as num).toDouble();
      final ambient = (j['default_ambient_temp'] as num).toDouble();
      final metaDuration = (j['duration_seconds'] as num).toDouble();
      final lastDist = rows.last.dist;
      print('E-09 | === $traceFile ===');
      print('E-09 | meta length=${_f(declaredLen, 0)}m, last dist_m=${_f(lastDist, 0)}m, '
          'delta=${_f(declaredLen - lastDist, 0)}m | meta duration=${_f(metaDuration, 0)}s, '
          'last t=${_f(rows.last.t, 0)}s | ambient=${_f(ambient, 1)}C');

      // Geometric self-consistency of the trace: does elevation integrate grade?
      var gradeImpliedRise = 0.0;
      for (var i = 1; i < rows.length; i++) {
        final dd = rows[i].dist - rows[i - 1].dist;
        gradeImpliedRise += (rows[i].grade / 100.0) * dd;
      }
      final statedRise = rows.last.elev - rows.first.elev;
      print('E-09 | rise from stated grades=${_f(gradeImpliedRise, 2)}m, '
          'stated elev delta=${_f(statedRise, 2)}m');

      for (final cargo in [140.0]) {
        final veh = VehicleSpecs.vehicleProfiles[0];
        final motor = VehicleSpecs.motorProfiles[1];
        final batt = BatterySpecs.profiles[0];
        final totalMass = veh.tareMassKg + veh.riderMassKg + cargo;

        double cellT = ambient;
        double wear = 0.0;
        double peakC = 0.0;
        double peakI = 0.0;
        double peakT = ambient;
        double peakP = 0.0;
        double peakGrade = 0.0;
        double energyWh = 0.0;
        double wearAscent = 0.0;
        double maxGradeSeen = rows.map((r) => r.grade).reduce(math.max);
        double energyAscent = 0.0;

        for (var i = 0; i < rows.length; i++) {
          final p = rows[i];
          final dt = i == 0 ? 1.0 : p.t - rows[i - 1].t;
          final pMech = PhysicsEngine.computeMechanicalPowerWatts(
            totalGrossMassKg: totalMass,
            velocityMs: p.kmh / 3.6,
            inclineRadians: math.atan(p.grade / 100.0),
          );
          final eff = motor.efficiencyAtSpeed(p.kmh);
          final pElec = (pMech / eff).clamp(0.0, motor.peakPower);
          final r = BatteryModel.step(
            electricalPowerWatts: pElec,
            currentCellTempCelsius: cellT,
            ambientTempCelsius: ambient,
            deltaSeconds: dt,
            battery: batt,
          );
          cellT = r.cellTempCelsius;
          wear += r.incrementalWearInr;
          energyWh += pElec * dt / 3600.0;
          if (r.cRate > peakC) peakC = r.cRate;
          if (r.currentAmps > peakI) peakI = r.currentAmps;
          if (r.cellTempCelsius > peakT) peakT = r.cellTempCelsius;
          if (pElec > peakP) peakP = pElec;
          if (p.grade.abs() > peakGrade) peakGrade = p.grade.abs();
          if (p.grade > 0.5) {
            wearAscent += r.incrementalWearInr;
            energyAscent += pElec * dt / 3600.0;
          }
        }
        print('E-09 | cargo=${_f(cargo, 0)}kg gross=${_f(totalMass, 0)}kg -> '
            'peakP_elec=${_f(peakP, 1)}W, peakI=${_f(peakI, 2)}A, peakC=${_f(peakC, 3)} C, '
            'peakT=${_f(peakT, 2)}C, maxGrade=${_f(maxGradeSeen, 1)}%');
        print('E-09 | E_draw=${_f(energyWh, 1)}Wh (${_f(energyWh / batt.totalNominalEnergyWh * 100, 2)}% of pack), '
            'E_ascent=${_f(energyAscent, 1)}Wh');
        print('E-09 | WEAR total=Rs${_f(wear)}, ascent-only=Rs${_f(wearAscent)} '
            '(nominal Rs${_f(batt.baseCostPerCycleInr)}/EFC)');
        print('E-09 | W_f_effective = ${_f(wear / (energyWh / batt.totalNominalEnergyWh * batt.baseCostPerCycleInr), 3)}');

        expect(peakC, lessThanOrEqualTo(1.75));
      }
    });
  }

  test('E-10 NeuroPace pair: 14 km/h aggressive vs 8.5 km/h eco, 140 kg, 4.2%', () {
    final veh = VehicleSpecs.vehicleProfiles[0];
    final motor = VehicleSpecs.motorProfiles[1];
    final batt = BatterySpecs.profiles[0];
    final m = veh.tareMassKg + veh.riderMassKg + 140.0;

    for (final scenario in <String, double>{
      'aggressive_14kmh_noAssist': 14.0,
      'eco_8.5kmh_70W_assist': 8.5,
    }.entries) {
      const assistW = 70.0;
      final pMech = PhysicsEngine.computeMechanicalPowerWatts(
        totalGrossMassKg: m,
        velocityMs: scenario.value / 3.6,
        inclineRadians: math.atan(4.2 / 100),
      );
      final eff = motor.efficiencyAtSpeed(scenario.value);
      final pNet = (pMech - (scenario.key.startsWith('eco') ? assistW : 0.0))
          .clamp(0.0, 1200.0);
      final pElec = (pNet / eff).clamp(0.0, motor.ratedContinuousPower);
      final I = (pElec / batt.nominalVoltage).clamp(0.0, 35.0);
      final cRate = I / batt.nominalCapacityAh;

      // time to climb the 680 m ascent span quoted in README, and time for the
      // 190 m of the Chowkaghat trace that is steeper than 3%.
      final t190 = 190.0 / (scenario.value / 3.6);
      final t680 = 680.0 / (scenario.value / 3.6);
      print('E-10 | ${scenario.key}: v=${_f(scenario.value, 1)} km/h, eta=${_f(eff, 4)}, '
          'P_wheel=${_f(pMech, 1)} W, P_elec=${_f(pElec, 1)} W, I=${_f(I, 2)} A, C=${_f(cRate, 3)} C');
      print('E-10 | ${scenario.key}: t(190m)=${_f(t190, 1)}s, t(680m)=${_f(t680, 1)}s, '
          'energy over 190m=${_f(pElec * t190 / 3600.0, 2)} Wh');
    }
  });

  test('E-11 stall-torque check: max grade climbable at a given torque', () {
    final motor = VehicleSpecs.motorProfiles[1];
    final wheelRadius = 0.2794; // 22" wheel incl. tyre
    for (final grade in [2.0, 3.0, 4.2, 4.8, 6.0, 8.0]) {
      // m_max = F_wheel / (g*sin(theta) + g*Crr*cos(theta))
      final theta = math.atan(grade / 100.0);
      final fWheel = motor.stallTorqueNm / wheelRadius;
      final denom = 9.80665 *
          (math.sin(theta) + VehicleSpecs.rollingResistanceCrr * math.cos(theta));
      final mMax = fWheel / denom;
      print('E-11 | 500W/50Nm @ ${_f(grade, 1)}% grade -> m_max=${_f(mMax, 1)} kg '
          '(cargo=${_f(mMax - 99.0, 1)} kg)');
      expect(mMax, greaterThan(0));
    }
  });
}
