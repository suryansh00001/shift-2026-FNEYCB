import 'package:flutter_test/flutter_test.dart';
import 'package:fairload/core/constants/vehicle_specs.dart';
import 'package:fairload/core/constants/battery_specs.dart';
import 'package:fairload/engine/physics_engine.dart';
import 'package:fairload/engine/battery_model.dart';
import 'package:fairload/engine/sensor_fusion.dart';

void main() {
  group('Physics & Incline Equations', () {
    test('Chowkaghat 4.2% Incline Power Balance Test', () {
      final totalGrossMass = VehicleSpecs.defaultBikeTareMass +
          VehicleSpecs.defaultRiderMass +
          140.0; // 140 kg cargo = 239 kg gross mass

      final velocityMs = 8.5 / 3.6; // 8.5 km/h climb crawl
      final inclineRad = SensorFusion.gradePctToRadians(4.2); // 4.2% grade

      final pMech = PhysicsEngine.computeMechanicalPowerWatts(
        totalGrossMassKg: totalGrossMass,
        velocityMs: velocityMs,
        inclineRadians: inclineRad,
      );

      // Verify mechanical power is ~250W - 320W
      expect(pMech, greaterThan(240.0));
      expect(pMech, lessThan(350.0));

      // With motor efficiency dropping during power-limiting stall
      final motor = VehicleSpecs.motorProfiles[1]; // 500W Standard
      final eff = motor.efficiencyAtSpeed(8.5);
      expect(eff, lessThan(0.65)); // Efficiency drops significantly below rated 83% at 8.5 km/h

      final pElec = pMech / eff;
      expect(pElec, greaterThan(450.0)); // Electrical draw > 450W
    });

    test('Battery High-C and Thermal Rise Test', () {
      // 700W draw on 48V pack
      final step = BatteryModel.step(
        electricalPowerWatts: 720.0,
        currentCellTempCelsius: 42.0,
        ambientTempCelsius: 40.0,
        deltaSeconds: 60.0,
      );

      // Current ~ 15A on 20Ah pack -> C-rate ~ 0.75C
      expect(step.currentAmps, closeTo(15.0, 1.0));
      expect(step.cRate, closeTo(0.75, 0.1));
      expect(step.cellTempCelsius, greaterThan(42.0));
    });

    test('LFP vs NMC Chemistry Resilience Test', () {
      final nmc = BatterySpecs.profiles[0];
      final lfp = BatterySpecs.profiles[2];

      final nmcStep = BatteryModel.step(
        electricalPowerWatts: 800.0,
        currentCellTempCelsius: 49.0,
        ambientTempCelsius: 42.0,
        deltaSeconds: 60.0,
        battery: nmc,
      );

      final lfpStep = BatteryModel.step(
        electricalPowerWatts: 800.0,
        currentCellTempCelsius: 49.0,
        ambientTempCelsius: 42.0,
        deltaSeconds: 60.0,
        battery: lfp,
      );

      // LFP has higher thermal threshold and lower wear penalty
      expect(lfpStep.isPlatingRisk, isFalse);
      expect(lfpStep.wearMultiplier, lessThan(nmcStep.wearMultiplier));
    });

    test('Arrhenius Thermal Degradation Factor Validation', () {
      // At baseline reference temperature (25°C), phiThermal = 1.0, baseline wear = 1.0
      final step25 = BatteryModel.step(
        electricalPowerWatts: 100.0,
        currentCellTempCelsius: 25.0,
        ambientTempCelsius: 25.0,
        deltaSeconds: 1.0,
      );
      expect(step25.wearMultiplier, closeTo(1.0, 0.05));

      // At elevated summer temperature (45°C), Arrhenius exponential factor accelerates wear (>2.5x)
      final step45 = BatteryModel.step(
        electricalPowerWatts: 100.0,
        currentCellTempCelsius: 45.0,
        ambientTempCelsius: 40.0,
        deltaSeconds: 1.0,
      );
      expect(step45.wearMultiplier, greaterThan(2.5));
      expect(step45.wearMultiplier, greaterThan(step25.wearMultiplier));
    });
  });
}
