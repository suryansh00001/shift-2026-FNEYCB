import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants/battery_specs.dart';
import '../core/constants/vehicle_specs.dart';
import '../engine/battery_model.dart';
import '../engine/physics_engine.dart';
import '../engine/sensor_fusion.dart';
import 'weather_service.dart';

/// Live sensor reading packet with fused state
class LiveSensorReading {
  final double pitchAngleDegrees;
  final double fusedGradePct;
  final double currentSpeedKmh;
  final double accelerationMs2;
  final double verticalJerkMs3;
  final bool isPotholeDetected;
  final double roadRoughnessIri; // International Roughness Index proxy (m/km)
  final double calculatedPowerWatts;
  final double cRate;
  final double cellTempCelsius;
  final double ambientTempCelsius;
  final bool isWeatherSynced;
  final double cumulativeWearInr;
  final double instantaneousWearRateInrPerKm;
  final double cumulativeDistanceMeters;
  final double reverseEstimatedCargoKg;
  final bool isOverloadFraudDetected;
  final double gpsLatitude;
  final double gpsLongitude;
  final double gpsAltitude;
  final bool isGpsActive;
  final bool isImuActive;
  final BatteryProfile battery;
  final VehicleProfile vehicle;

  const LiveSensorReading({
    required this.pitchAngleDegrees,
    required this.fusedGradePct,
    required this.currentSpeedKmh,
    required this.accelerationMs2,
    required this.verticalJerkMs3,
    required this.isPotholeDetected,
    required this.roadRoughnessIri,
    required this.calculatedPowerWatts,
    required this.cRate,
    required this.cellTempCelsius,
    required this.ambientTempCelsius,
    required this.isWeatherSynced,
    required this.cumulativeWearInr,
    required this.instantaneousWearRateInrPerKm,
    required this.cumulativeDistanceMeters,
    required this.reverseEstimatedCargoKg,
    required this.isOverloadFraudDetected,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.gpsAltitude,
    required this.isGpsActive,
    required this.isImuActive,
    required this.battery,
    required this.vehicle,
  });
}

/// Service that interfaces directly with physical device hardware (IMU + GPS)
/// and implements Madgwick/Complementary filtering, Varanasi pothole rejection,
/// live reverse mass estimation, and real-time GPS weather ambient sync.
class LiveSensorService {
  // Streams subscriptions
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<Position>? _gpsSub;
  Timer? _processingTimer;

  // Raw sensor buffers
  double _rawAx = 0.0;
  double _rawAy = 0.0;
  double _rawAz = 9.81;
  double _lastAz = 9.81;

  double _rawGx = 0.0;

  // Fused attitude & elevation
  double _fusedPitchDeg = 0.0;
  double _fusedGradePct = 0.0;
  double _smoothedGradePct = 0.0;
  double _currentSpeedKmh = 14.5;
  double _lastSpeedMs = 4.0;
  double _accelerationMs2 = 0.0;
  double _verticalJerkMs3 = 0.0;
  bool _potholeDetected = false;
  int _potholeHoldCounter = 0;

  // Roughness buffer (sliding window of Az deviations)
  final List<double> _vertAccelWindow = [];
  double _roadRoughnessIri = 2.4; // Fair condition baseline

  // GPS state
  double _latitude = 25.3217; // Varanasi Chowkaghat default
  double _longitude = 82.9912;
  double _altitude = 76.0;
  bool _isGpsActive = false;
  bool _isImuActive = false;

  // Weather state
  bool _isWeatherSynced = false;
  DateTime? _lastWeatherFetchTime;

  // Thermal state
  double _cellTempCelsius = 29.0;

  // Dynamic wear and distance state
  double _cumulativeDistanceMeters = 0.0;
  double _cumulativeWearInr = 0.0;
  double _instantaneousWearRateInrPerKm = 2.1;

  // Callbacks
  void Function(LiveSensorReading reading)? onReading;

  // Active configurations
  double cargoMassKg = 138.0;
  double ambientTempCelsius = 29.0;
  BatteryProfile battery = BatterySpecs.defaultProfile;
  VehicleProfile vehicle = VehicleSpecs.defaultVehicleProfile;
  MotorProfile get motor => vehicle.motor;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Resets cumulative trip counters (odometer and accumulated ₹ wear)
  void resetTripStats() {
    _cumulativeDistanceMeters = 0.0;
    _cumulativeWearInr = 0.0;
    _instantaneousWearRateInrPerKm = 1.8;
  }

  /// Syncs ambient temperature and resets cold cell temperature if idle
  void syncAmbientAndCellTemp(double temp) {
    ambientTempCelsius = temp;
    _isWeatherSynced = true;
    if (_cumulativeDistanceMeters < 10.0 && _currentSpeedKmh < 1.0) {
      _cellTempCelsius = temp;
    }
  }

  /// Explicitly triggers a live weather fetch
  Future<void> syncWeatherNow() async {
    await _checkFetchWeather(_latitude, _longitude, force: true);
  }

  /// Starts listening to device sensors
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // 1. Subscribe to Physical IMU (Accelerometer & Gyroscope)
    try {
      _accSub = accelerometerEventStream().listen((event) {
        _isImuActive = true;
        _rawAx = event.x;
        _rawAy = event.y;
        _rawAz = event.z;
      }, onError: (err) {
        if (kDebugMode) print("Accelerometer stream error (desktop/web fallback): $err");
        _isImuActive = false;
      });

      _gyroSub = gyroscopeEventStream().listen((event) {
        _rawGx = event.x;
      }, onError: (_) {});
    } catch (e) {
      if (kDebugMode) print("Sensors API unavailable, running simulated hardware fallback: $e");
      _isImuActive = false;
    }

    // 2. Subscribe to GPS Geolocator
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen((pos) {
        _isGpsActive = true;
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _altitude = pos.altitude;
        if (pos.speed >= 0.1) {
          // Smooth speed updates to avoid single-tick spikes
          final gpsSpeedKmh = pos.speed * 3.6;
          _currentSpeedKmh = (_currentSpeedKmh * 0.35) + (gpsSpeedKmh * 0.65);
        } else if (pos.speed == 0.0) {
          _currentSpeedKmh = _currentSpeedKmh * 0.8;
        }

        // Fetch ambient weather from Open-Meteo using live coordinates
        _checkFetchWeather(pos.latitude, pos.longitude);
      }, onError: (_) {
        _isGpsActive = false;
      });
    } catch (e) {
      _isGpsActive = false;
    }

    // Trigger initial background weather sync using initial/last coordinates
    _checkFetchWeather(_latitude, _longitude);

    // 3. Periodic Fusion Loop (10 Hz for responsive telemetry)
    _processingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _processSensorStep(0.1);
    });
  }

  Future<void> _checkFetchWeather(double lat, double lon, {bool force = false}) async {
    final now = DateTime.now();
    if (force || _lastWeatherFetchTime == null || now.difference(_lastWeatherFetchTime!) > const Duration(minutes: 5)) {
      final liveTemp = await WeatherService.fetchAmbientTemperature(latitude: lat, longitude: lon, forceRefresh: force);
      if (liveTemp != null) {
        _lastWeatherFetchTime = now;
        syncAmbientAndCellTemp(liveTemp);
      } else {
        // If failed, allow retry in 15 seconds instead of locking out for 5 minutes
        _lastWeatherFetchTime = now.subtract(const Duration(minutes: 4, seconds: 45));
      }
    }
  }

  /// Ingests a step and runs sensor fusion
  void _processSensorStep(double dt) {
    // A. Jerk & Shock Detection (Pothole rejection filter)
    _verticalJerkMs3 = ((_rawAz - _lastAz) / dt).abs();
    _lastAz = _rawAz;

    // Varanasi Pothole threshold: jerk > 14 m/s^3
    if (_verticalJerkMs3 > 14.0) {
      _potholeDetected = true;
      _potholeHoldCounter = 8; // Hold indicator for ~800ms
    } else if (_potholeHoldCounter > 0) {
      _potholeHoldCounter--;
      _potholeDetected = _potholeHoldCounter > 0;
    } else {
      _potholeDetected = false;
    }

    // B. Road Roughness Index (IRI proxy)
    _vertAccelWindow.add((_rawAz - 9.81).abs());
    if (_vertAccelWindow.length > 20) _vertAccelWindow.removeAt(0);
    if (_vertAccelWindow.isNotEmpty) {
      final meanDev = _vertAccelWindow.reduce((a, b) => a + b) / _vertAccelWindow.length;
      _roadRoughnessIri = (meanDev * 3.2).clamp(1.2, 12.0);
    }

    // C. Pitch angle estimation (Complementary filter fusing Accelerometer with Gyroscope)
    final accPitchRad = math.atan2(_rawAy, math.sqrt(_rawAx * _rawAx + _rawAz * _rawAz));
    final accPitchDeg = accPitchRad * (180.0 / math.pi);

    if (!_isImuActive) {
      // In desktop/browser mode where hardware IMU isn't physically tilted,
      // generate a realistic baseline testbench reading
      _fusedPitchDeg = 2.4; // 2.4 deg =~ 4.2% incline
    } else {
      // Complementary filter: 95% gyro integration + 5% acc gravity vector
      // If a pothole shock is detected, ignore accelerometer pitch to avoid false spike!
      if (_potholeDetected) {
        _fusedPitchDeg = _fusedPitchDeg + (_rawGx * (180.0 / math.pi) * dt);
      } else {
        _fusedPitchDeg = (0.95 * (_fusedPitchDeg + _rawGx * (180.0 / math.pi) * dt)) + (0.05 * accPitchDeg);
      }
    }

    // Clamp realistic road angles (-15 deg to +15 deg)
    _fusedPitchDeg = _fusedPitchDeg.clamp(-15.0, 15.0);
    _fusedGradePct = math.tan(_fusedPitchDeg * (math.pi / 180.0)) * 100.0;

    // Additional low-pass smoothing on grade to eliminate residual handlebar vibration
    _smoothedGradePct = (_smoothedGradePct * 0.85) + (_fusedGradePct * 0.15);

    // D. Speed and Acceleration with low-pass smoothing
    final speedMs = (_currentSpeedKmh / 3.6).clamp(0.0, 16.0);
    final rawAccel = (speedMs - _lastSpeedMs) / dt;
    _accelerationMs2 = (_accelerationMs2 * 0.70) + (rawAccel.clamp(-3.5, 2.5) * 0.30);
    _lastSpeedMs = speedMs;

    // E. Real Physics Power Calculation using active Vehicle & Motor
    final totalMass = vehicle.tareMassKg + vehicle.riderMassKg + cargoMassKg;
    final inclineRad = SensorFusion.gradePctToRadians(_smoothedGradePct);

    final pMechWatts = PhysicsEngine.computeMechanicalPowerWatts(
      totalGrossMassKg: totalMass,
      velocityMs: speedMs,
      inclineRadians: inclineRad,
      accelerationMs2: _accelerationMs2,
    );

    final eff = motor.efficiencyAtSpeed(_currentSpeedKmh);
    final pElecWatts = pMechWatts / math.max(0.2, eff);

    // F. Battery Thermal & Degradation Step using configured BatteryProfile
    final bResult = BatteryModel.step(
      electricalPowerWatts: pElecWatts,
      currentCellTempCelsius: _cellTempCelsius,
      ambientTempCelsius: ambientTempCelsius,
      deltaSeconds: dt,
      battery: battery,
    );
    _cellTempCelsius = bResult.cellTempCelsius;

    // G. Dynamic Accumulation of Real Distance & INR Wear (Resolving Hardcoded Wear)
    final stepDistMeters = speedMs * dt;
    _cumulativeDistanceMeters += stepDistMeters;
    _cumulativeWearInr += bResult.incrementalWearInr;

    final stepDistKm = stepDistMeters / 1000.0;
    if (stepDistKm > 0.00005) {
      _instantaneousWearRateInrPerKm = (bResult.incrementalWearInr / stepDistKm).clamp(0.1, 40.0);
    } else {
      // Standstill/idle micro-wear rate based on C-rate
      _instantaneousWearRateInrPerKm = (bResult.cRate * 2.2).clamp(0.5, 15.0);
    }

    // H. Reverse Mass Estimation
    final estCargoKg = PhysicsEngine.reverseEstimateCargoMassKg(
      pinnedMotorPowerWatts: motor.peakPower,
      velocityMs: speedMs,
      inclineRadians: inclineRad,
      motor: motor,
      bikeTareMass: vehicle.tareMassKg,
      riderMass: vehicle.riderMassKg,
    );

    // Fraud detection: If actual estimated mass exceeds declared cargo significantly
    final isFraud = estCargoKg > (vehicle.ratedCargoCapacityKg + 20.0) && _smoothedGradePct > 2.0;

    final reading = LiveSensorReading(
      pitchAngleDegrees: _fusedPitchDeg,
      fusedGradePct: _smoothedGradePct,
      currentSpeedKmh: _currentSpeedKmh,
      accelerationMs2: _accelerationMs2,
      verticalJerkMs3: _verticalJerkMs3,
      isPotholeDetected: _potholeDetected,
      roadRoughnessIri: _roadRoughnessIri,
      calculatedPowerWatts: pElecWatts,
      cRate: bResult.cRate,
      cellTempCelsius: _cellTempCelsius,
      ambientTempCelsius: ambientTempCelsius,
      isWeatherSynced: _isWeatherSynced,
      cumulativeWearInr: _cumulativeWearInr,
      instantaneousWearRateInrPerKm: _instantaneousWearRateInrPerKm,
      cumulativeDistanceMeters: _cumulativeDistanceMeters,
      reverseEstimatedCargoKg: estCargoKg > 0 ? estCargoKg : cargoMassKg,
      isOverloadFraudDetected: isFraud,
      gpsLatitude: _latitude,
      gpsLongitude: _longitude,
      gpsAltitude: _altitude,
      isGpsActive: _isGpsActive,
      isImuActive: _isImuActive,
      battery: battery,
      vehicle: vehicle,
    );

    onReading?.call(reading);
  }

  /// Injects a temporary simulated 3.8G pothole shock (for testbench & judges demo)
  void injectSimulatedPothole() {
    _rawAz = 38.2; // 3.8G shock
    _lastAz = 9.81;
    _verticalJerkMs3 = 28.4;
    _potholeDetected = true;
    _potholeHoldCounter = 12;
  }

  /// Updates simulated speed (for manual throttle testing)
  void setManualSpeed(double kmh) {
    _currentSpeedKmh = kmh.clamp(0.0, 45.0);
  }

  /// Stops all listeners
  void stop() {
    _isRunning = false;
    _processingTimer?.cancel();
    _accSub?.cancel();
    _gyroSub?.cancel();
    _gpsSub?.cancel();
  }
}
