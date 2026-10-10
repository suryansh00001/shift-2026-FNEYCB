/// FairLoad Evidence Harness — PART C: geometric consistency of the corridor
/// traces, and power-limited (not torque-limited) climb capability.
///
/// Run:  cd fairload && flutter test test/evidence_geometric_test.dart
// ignore_for_file: avoid_print -- printing IS the deliverable of this harness
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fairload/core/constants/battery_specs.dart';
import 'package:fairload/core/constants/vehicle_specs.dart';

import 'package:fairload/engine/physics_engine.dart';

String _f(double v, [int d = 2]) => v.toStringAsFixed(d);

class P {
  P(this.t, this.dist, this.elev, this.grade, this.kmh);
  final double t, dist, elev, grade, kmh;
}

List<P> _pts(String name) {
  final decoded =
      jsonDecode(File('assets/traces/$name').readAsStringSync()) as Map<String, dynamic>;
  final raw = decoded['points'] as List<dynamic>;
  return raw.cast<Map<String, dynamic>>().map((p) {
    return P(
      (p['time_s'] as num).toDouble(),
      (p['dist_m'] as num).toDouble(),
      (p['elev_m'] as num).toDouble(),
      (p['grade_pct'] as num).toDouble(),
      (p['speed_kmh'] as num).toDouble(),
    );
  }).toList();
}

void main() {
  for (final f in [
    'chowkaghat_flyover.json',
    'cantt_overbridge.json',
    'lanka_gallis.json',
  ]) {
    test('E-12 ascent geometry: $f', () {
      final pts = _pts(f);
      // integrate ONLY the ascent leg (grade > 0.5%), using each segment's own span
      var riseImplied = 0.0;
      var riseStated = 0.0;
      var ascentDist = 0.0;
      var ascentStartElev = 0.0;
      var ascentEndElev = 0.0;
      var captured = false;
      for (var i = 1; i < pts.length; i++) {
        if (pts[i].grade > 0.5 && pts[i - 1].grade > 0.5) {
          final dd = pts[i].dist - pts[i - 1].dist;
          riseImplied += pts[i].grade / 100.0 * dd;
          ascentDist += dd;
          if (!captured) {
            ascentStartElev = pts[i - 1].elev;
            captured = true;
          }
          ascentEndElev = pts[i].elev;
        }
      }
      riseStated = ascentEndElev - ascentStartElev;
      print('E-12 | $f: ascent horizontal=${_f(ascentDist, 0)} m, '
          'grade-integrated rise=${_f(riseImplied, 2)} m, stated rise=${_f(riseStated, 2)} m, '
          'ratio=${_f(riseStated / riseImplied, 2)}x');
      if (ascentDist > 0) {
        // Traces are internally geometrically consistent on the ascent leg.
        expect(riseStated / riseImplied, inInclusiveRange(0.85, 1.15));
      } else {
        print('E-12 | $f: FLAT corridor, no ascent leg — nothing to cross-check.');
      }
    });
  }

  test('E-13 power-limited vs torque-limited maximum grade (239 kg gross)', () {
    final motor = VehicleSpecs.motorProfiles[1];
    final m = 34.0 + 65.0 + 140.0;
    const wheelR = 0.2794; // 22 inch wheel + tyre

    // TORQUE limit: F_wheel <= T_stall / R
    final fTorqueMax = motor.stallTorqueNm / wheelR;
    final torqueGrade = (fTorqueMax / (m * 9.80665)) * 100.0; // small-angle %
      print('E-13 | 500W/50Nm, wheel r=${_f(wheelR, 4)} m: F_wheel_max=${_f(fTorqueMax, 1)} N '
        '-> torque-limited grade (small-angle) = ${_f(torqueGrade, 1)} %');

    // POWER limit: solve P_elec_available(v) * eta(v) == P_wheel(m, v, grade)
    for (final vKmh in [8.0, 8.5, 10.0, 12.0, 14.0, 17.5, 20.0, 25.0]) {
      final v = vKmh / 3.6;
      final pMechAvail = motor.peakPower * motor.efficiencyAtSpeed(vKmh);
      // m*g*v*(sin t + Crr cos t) + 0.5*rho*CdA*v^3 = P_mech_avail
      final aeroPower = 0.5 * VehicleSpecs.airDensityVaranasi * VehicleSpecs.cdA * math.pow(v, 3);
      final gradePowerAvail = pMechAvail - aeroPower;
      final denom = m * 9.80665 * v;
      final s = gradePowerAvail / denom; // sin(theta) + Crr*cos(theta)
      // solve sin t + Crr cos t = s  -> t = atan-ish; invert numerically
      double lo = -1.5, hi = 1.5;
      for (var k = 0; k < 60; k++) {
        final mid = (lo + hi) / 2;
        final f = math.sin(mid) + VehicleSpecs.rollingResistanceCrr * math.cos(mid) - s;
        if (f < 0) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      final theta = (lo + hi) / 2;
      final gradePct = math.tan(theta) * 100;
      print('E-13 | v=${_f(vKmh, 1)} km/h: P_mech_avail=${_f(pMechAvail, 1)} W '
        '(peak ${_f(motor.peakPower, 0)}W x eta ${_f(motor.efficiencyAtSpeed(vKmh), 3)}) '
        '-> power-limited max grade=${_f(gradePct, 2)} %');
      expect(gradePct, greaterThan(-20));
    }
      print('E-13 | torque-limited grade (${_f(torqueGrade, 1)} %) is far above any '
      'Varanasi corridor grade, so the limit is POWER, not torque.');
  });

  test('E-13b CONTINUOUS-power-limited max grade at 239 kg gross', () {
    // The realistic bound is the 500 W CONTINUOUS rating, not the 750 W peak,
    // because a flyover ascent lasts far longer than any peak window.
    final motor = VehicleSpecs.motorProfiles[1];
    final m = 34.0 + 65.0 + 140.0;
    for (final vKmh in [8.0, 8.2, 8.5, 10.0, 12.0, 14.0, 17.5, 20.0]) {
      final v = vKmh / 3.6;
      final pMechAvail = motor.ratedContinuousPower * motor.efficiencyAtSpeed(vKmh);
      final aeroPower =
          0.5 * VehicleSpecs.airDensityVaranasi * VehicleSpecs.cdA * math.pow(v, 3);
      final denom = m * 9.80665 * v;
      final s = (pMechAvail - aeroPower) / denom;
      double lo = -1.5, hi = 1.5;
      for (var k = 0; k < 60; k++) {
        final mid = (lo + hi) / 2;
        final f = math.sin(mid) + VehicleSpecs.rollingResistanceCrr * math.cos(mid) - s;
        if (f < 0) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      final gradePct = math.tan((lo + hi) / 2) * 100;
      print('E-13b | v=${_f(vKmh, 1)} km/h: P_mech_avail(cont 500W)=${_f(pMechAvail, 1)} W '
        '-> max sustainable grade=${_f(gradePct, 2)} %');
      expect(gradePct, greaterThan(-20));
    }
    // The crawl mechanism: on a 4.2% grade the continuous rating caps the bike
    // well below the 14 km/h "aggressive" target used by NeuroPace.
  });

  test('E-13c required continuous power at 4.2% grade vs speed', () {
    final motor = VehicleSpecs.motorProfiles[1];
    final m = 34.0 + 65.0 + 140.0;
    for (final vKmh in [8.0, 8.5, 10.0, 12.0, 14.0, 17.5]) {
      final pMech = PhysicsEngine.computeMechanicalPowerWatts(
        totalGrossMassKg: m,
        velocityMs: vKmh / 3.6,
        inclineRadians: math.atan(4.2 / 100),
      );
      final pElec = pMech / motor.efficiencyAtSpeed(vKmh);
      final over = pElec / motor.ratedContinuousPower;
      print('E-13c | v=${_f(vKmh, 1)} km/h: P_elec needed=${_f(pElec, 1)} W '
        '= ${_f(over, 2)}x the 500 W continuous rating '
        '(${over > 1 ? 'NOT sustainable on motor alone' : 'sustainable'})');
      expect(pElec, greaterThan(0));
    }
  });

  test('E-14 minimum electrical power to hold 8.5 km/h at each corridor grade', () {
    final motor = VehicleSpecs.motorProfiles[1];
    final m = 34.0 + 65.0 + 140.0;
    for (final grade in [0.2, 2.1, 3.2, 3.8, 3.9, 4.2, 4.4, 4.5, 4.8]) {
      final pMech = PhysicsEngine.computeMechanicalPowerWatts(
        totalGrossMassKg: m,
        velocityMs: 8.5 / 3.6,
        inclineRadians: math.atan(grade / 100),
      );
      final eff = motor.efficiencyAtSpeed(8.5);
      final pElec = pMech / eff;
      final I = pElec / 48.0;
      final c = I / 20.0;
      print('E-14 | grade=${_f(grade, 1)}% -> P_wheel=${_f(pMech, 1)} W, eta=${_f(eff, 3)}, '
        'P_elec=${_f(pElec, 1)} W, I=${_f(I, 2)} A, C=${_f(c, 3)} C');
      expect(pElec, greaterThan(0));
    }
  });

  test('E-15 Joule heat power vs pack mass: is 850 J/(kg.K) defensible?', () {
    // Sanity: to move a 6.2 kg pack from 40 C to 54 C against a 1.35 W/K sink
    // requires 18.9 W sustained. How long at various currents?
    for (final b in BatterySpecs.profiles) {
      final thermalMass = b.packMassKg * b.specificHeatCapacityCp;
      final tau = thermalMass / b.convectiveHeatTransferHA;
      print('E-15 | ${b.shortLabel}: thermalMass=${_f(thermalMass, 0)} J/K, '
        'tau=${_f(tau, 0)} s (${_f(tau / 60, 1)} min)');
    }
    // 14 K rise target for the standard pack
    const target = 14.0;
    final pack = BatterySpecs.profiles[0];
    final qNeeded = target * pack.convectiveHeatTransferHA;
    print('E-15 | +14 K above 40 C needs ${_f(qNeeded, 1)} W of net Joule heat '
      '=> I=${_f(math.sqrt(qNeeded / pack.internalResistanceOhms), 1)} A '
      '(= ${_f(math.sqrt(qNeeded / pack.internalResistanceOhms) / pack.nominalCapacityAh, 2)} C)');
  });
}
