import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/battery_specs.dart';
import '../../core/constants/vehicle_specs.dart';
import '../../core/models/telemetry_point.dart';
import '../../core/models/trip_record.dart';
import '../../engine/neuropace_advisor.dart';
import '../../services/live_sensor_service.dart';
import '../../services/simulation_service.dart';
import '../../services/weather_service.dart';

enum TelemetryDataSource {
  simulation,
  liveSensors,
}

class TelemetryProvider extends ChangeNotifier {
  TelemetryDataSource _dataSource = TelemetryDataSource.simulation;
  final LiveSensorService _liveSensorService = LiveSensorService();
  LiveSensorReading? _liveReading;

  SimulationTrace? _currentTrace;
  List<TelemetryPoint> _evaluatedPoints = [];
  int _currentStepIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;

  // Configurable Parameters
  double _cargoMassKg = 138.0; // Typical overloaded quick-commerce bundle
  double _ambientTempCelsius = 29.0; // Varanasi baseline (synced via live GPS Open-Meteo)
  BatteryProfile _selectedBattery = BatterySpecs.defaultProfile;
  VehicleProfile _selectedVehicle = VehicleSpecs.defaultVehicleProfile;
  String _selectedRouteAsset = 'assets/traces/chowkaghat_flyover.json';

  // Weather Sync State
  bool _isWeatherSynced = false;
  bool _isFetchingWeather = false;

  // Last completed trip record
  TripRecord? _lastTripRecord;

  // Getters
  TelemetryDataSource get dataSource => _dataSource;
  bool get isLiveMode => _dataSource == TelemetryDataSource.liveSensors;
  LiveSensorReading? get liveReading => _liveReading;
  SimulationTrace? get currentTrace => _currentTrace;
  List<TelemetryPoint> get evaluatedPoints => _evaluatedPoints;
  int get currentStepIndex => _currentStepIndex;
  bool get isPlaying => _isPlaying;
  double get cargoMassKg => _cargoMassKg;
  double get ambientTempCelsius => _ambientTempCelsius;
  BatteryProfile get selectedBattery => _selectedBattery;
  VehicleProfile get selectedVehicle => _selectedVehicle;
  MotorProfile get selectedMotor => _selectedVehicle.motor;
  String get selectedRouteAsset => _selectedRouteAsset;
  TripRecord? get lastTripRecord => _lastTripRecord;
  bool get isWeatherSynced => _isWeatherSynced || (_liveReading?.isWeatherSynced ?? false);
  bool get isFetchingWeather => _isFetchingWeather;

  TelemetryPoint? get currentPoint {
    if (isLiveMode && _liveReading != null) {
      final lr = _liveReading!;
      return TelemetryPoint(
        timeSeconds: 0,
        distanceMeters: lr.cumulativeDistanceMeters,
        elevationMeters: lr.gpsAltitude,
        inclineGradePct: lr.fusedGradePct,
        speedKmh: lr.currentSpeedKmh,
        mechanicalPowerWatts: lr.calculatedPowerWatts * 0.8,
        electricalPowerWatts: lr.calculatedPowerWatts,
        currentAmps: lr.calculatedPowerWatts / _selectedBattery.nominalVoltage,
        cRate: lr.cRate,
        cellTempCelsius: lr.cellTempCelsius,
        isPlatingRisk: lr.cRate > _selectedBattery.cRateWarningThreshold,
        instantaneousWearRateInrPerKm: lr.instantaneousWearRateInrPerKm,
        cumulativeWearInr: lr.cumulativeWearInr,
        stageName: 'Live Sensor Harness',
      );
    }

    if (_evaluatedPoints.isEmpty) return null;
    if (_currentStepIndex >= _evaluatedPoints.length) return _evaluatedPoints.last;
    return _evaluatedPoints[_currentStepIndex];
  }

  PacingRecommendation get currentPacing {
    final pt = currentPoint;
    if (pt == null) {
      return const PacingRecommendation(
        targetSpeedKmh: 18.0,
        pedalAssistLevel: 'None',
        predictedCellTempCelsius: 38.0,
        predictedTripWearInr: 3.5,
        projectedSavingsInr: 0.0,
        slaDelaySeconds: 0,
        advisoryMessage: 'Ready to dispatch. Select cargo load and start climb.',
        isThermalAlertActive: false,
      );
    }

    return NeuroPaceAdvisor.evaluate(
      currentSpeedKmh: pt.speedKmh,
      roadGradePct: pt.inclineGradePct,
      cargoMassKg: _cargoMassKg,
      currentCellTempCelsius: pt.cellTempCelsius,
      ambientTempCelsius: _ambientTempCelsius,
      motor: _selectedVehicle.motor,
      battery: _selectedBattery,
      tareMassKg: _selectedVehicle.tareMassKg,
      riderMassKg: _selectedVehicle.riderMassKg,
    );
  }

  TelemetryProvider() {
    _initLiveSensors();
    loadRoute(_selectedRouteAsset);
    syncLiveWeather();
  }

  /// Syncs real-time ambient temperature via GPS & Open-Meteo API
  Future<void> syncLiveWeather({bool force = false}) async {
    _isFetchingWeather = true;
    notifyListeners();
    try {
      double lat = 25.3217;
      double lon = 82.9912;
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          lat = pos.latitude;
          lon = pos.longitude;
        } else {
          final p = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(timeLimit: Duration(seconds: 4)),
          );
          lat = p.latitude;
          lon = p.longitude;
        }
      } catch (_) {
        // Fallback to Varanasi coordinates
      }

      final temp = await WeatherService.fetchAmbientTemperature(
        latitude: lat,
        longitude: lon,
        forceRefresh: force,
      );

      if (temp != null) {
        _ambientTempCelsius = temp;
        _isWeatherSynced = true;
        _liveSensorService.syncAmbientAndCellTemp(temp);
        _recalculateTrace();
      }
    } catch (e) {
      if (kDebugMode) print("Error in syncLiveWeather: $e");
    } finally {
      _isFetchingWeather = false;
      notifyListeners();
    }
  }

  void _initLiveSensors() {
    _liveSensorService.cargoMassKg = _cargoMassKg;
    _liveSensorService.ambientTempCelsius = _ambientTempCelsius;
    _liveSensorService.battery = _selectedBattery;
    _liveSensorService.vehicle = _selectedVehicle;
    _liveSensorService.onReading = (reading) {
      _liveReading = reading;
      if (reading.isWeatherSynced && (_ambientTempCelsius - reading.ambientTempCelsius).abs() > 0.4) {
        _ambientTempCelsius = reading.ambientTempCelsius;
        _isWeatherSynced = true;
        _recalculateTrace();
      }
      notifyListeners();
    };
  }

  void setDataSource(TelemetryDataSource source) {
    _dataSource = source;
    if (source == TelemetryDataSource.liveSensors) {
      _pause();
      _liveSensorService.start();
    } else {
      _liveSensorService.stop();
    }
    notifyListeners();
  }

  void injectSimulatedPothole() {
    _liveSensorService.injectSimulatedPothole();
    notifyListeners();
  }

  void setLiveSpeed(double speedKmh) {
    _liveSensorService.setManualSpeed(speedKmh);
    notifyListeners();
  }

  void resetLiveTrip() {
    _liveSensorService.resetTripStats();
    _liveSensorService.syncAmbientAndCellTemp(_ambientTempCelsius);
    notifyListeners();
  }

  Future<void> loadRoute(String assetPath) async {
    _selectedRouteAsset = assetPath;
    _pause();
    try {
      _currentTrace = await SimulationService.loadTrace(assetPath);
      _recalculateTrace();
      _currentStepIndex = 0;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error loading route trace: $e");
    }
  }

  void setCargoWeight(double kg) {
    _cargoMassKg = kg.clamp(20.0, 200.0);
    _liveSensorService.cargoMassKg = _cargoMassKg;
    _recalculateTrace();
    notifyListeners();
  }

  void setAmbientTemp(double temp) {
    _ambientTempCelsius = temp.clamp(20.0, 52.0);
    _liveSensorService.ambientTempCelsius = _ambientTempCelsius;
    _recalculateTrace();
    notifyListeners();
  }

  void setBatteryProfile(BatteryProfile profile) {
    _selectedBattery = profile;
    _liveSensorService.battery = profile;
    _recalculateTrace();
    notifyListeners();
  }

  void setVehicleProfile(VehicleProfile profile) {
    _selectedVehicle = profile;
    _liveSensorService.vehicle = profile;
    _recalculateTrace();
    notifyListeners();
  }

  void setMotorProfile(MotorProfile motor) {
    // Updates the current vehicle profile's motor
    _selectedVehicle = VehicleProfile(
      id: _selectedVehicle.id,
      name: _selectedVehicle.name,
      category: _selectedVehicle.category,
      tareMassKg: _selectedVehicle.tareMassKg,
      riderMassKg: _selectedVehicle.riderMassKg,
      ratedCargoCapacityKg: _selectedVehicle.ratedCargoCapacityKg,
      motor: motor,
      dragCoefficientCd: _selectedVehicle.dragCoefficientCd,
      frontalAreaA: _selectedVehicle.frontalAreaA,
    );
    _liveSensorService.vehicle = _selectedVehicle;
    _recalculateTrace();
    notifyListeners();
  }

  void _recalculateTrace() {
    if (_currentTrace == null) return;
    _evaluatedPoints = SimulationService.evaluateFullTrace(
      trace: _currentTrace!,
      cargoMassKg: _cargoMassKg,
      ambientTempCelsius: _ambientTempCelsius,
      motor: _selectedVehicle.motor,
      battery: _selectedBattery,
      vehicle: _selectedVehicle,
    );
    if (_currentStepIndex >= _evaluatedPoints.length) {
      _currentStepIndex = _evaluatedPoints.isNotEmpty ? _evaluatedPoints.length - 1 : 0;
    }
    _buildCompletedTripRecord();
  }

  void _buildCompletedTripRecord() {
    if (_currentTrace == null || _evaluatedPoints.isEmpty) return;
    _lastTripRecord = SimulationService.buildTripRecord(
      trace: _currentTrace!,
      points: _evaluatedPoints,
      cargoMassKg: _cargoMassKg,
      vehicle: _selectedVehicle,
    );
  }

  void togglePlayback() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    _isPlaying = true;
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (_currentStepIndex < _evaluatedPoints.length - 1) {
        _currentStepIndex++;
        notifyListeners();
      } else {
        _pause();
      }
    });
    notifyListeners();
  }

  void _pause() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    notifyListeners();
  }

  void resetSimulation() {
    _pause();
    _currentStepIndex = 0;
    notifyListeners();
  }

  void seekToIndex(int index) {
    if (index >= 0 && index < _evaluatedPoints.length) {
      _currentStepIndex = index;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _liveSensorService.stop();
    super.dispose();
  }
}
