import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/battery_specs.dart';
import '../../core/models/defense_slip_data.dart';
import '../../core/theme/app_theme.dart';
import '../providers/telemetry_provider.dart';
import '../widgets/c_rate_gauge.dart';
import '../widgets/dynamic_pacing_banner.dart';
import '../widgets/elevation_mini_chart.dart';
import '../widgets/quick_payload_selector.dart';
import '../widgets/thermal_battery_hud.dart';
import '../widgets/vehicle_battery_selector_sheet.dart';
import 'defense_slip_screen.dart';

class HudScreen extends StatelessWidget {
  const HudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetry, child) {
        final pt = telemetry.currentPoint;
        final pacing = telemetry.currentPacing;
        final currentSpeed = pt?.speedKmh ?? 0.0;
        final cRate = pt?.cRate ?? 0.0;
        final currentAmps = pt?.currentAmps ?? 0.0;
        final powerWatts = pt?.electricalPowerWatts ?? 0.0;
        final cellTemp = pt?.cellTempCelsius ?? telemetry.ambientTempCelsius;
        final wearRate = pt?.instantaneousWearRateInrPerKm ?? 0.0;
        final cumulativeWear = pt?.cumulativeWearInr ?? 0.0;
        final isPlating = pt?.isPlatingRisk ?? false;
        final gradePct = pt?.inclineGradePct ?? 0.0;
        final isLive = telemetry.isLiveMode;
        final live = telemetry.liveReading;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceLowest,
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.sensors, color: AppTheme.primaryMint, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLive ? "FAIRLOAD // LIVE SENSORS" : "FAIRLOAD // VNS-CORRIDOR",
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.labelCaps.copyWith(
                      color: AppTheme.primaryMint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Syncing live ambient temperature via Open-Meteo GPS..."),
                      duration: Duration(milliseconds: 1200),
                    ),
                  );
                  await telemetry.syncLiveWeather(force: true);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: telemetry.isWeatherSynced ? AppTheme.primaryMint.withValues(alpha: 0.5) : AppTheme.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        telemetry.isWeatherSynced ? Icons.satellite_alt : Icons.thermostat,
                        color: telemetry.isWeatherSynced ? AppTheme.primaryMint : AppTheme.hudAmber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${telemetry.ambientTempCelsius.toStringAsFixed(1)}°C",
                        style: AppTheme.labelCaps.copyWith(
                          color: telemetry.isWeatherSynced ? AppTheme.primaryMint : AppTheme.hudAmber,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                      ),
                      if (telemetry.isWeatherSynced) ...[
                        const SizedBox(width: 3),
                        Text(
                          "GPS",
                          style: AppTheme.labelCaps.copyWith(
                            color: AppTheme.primaryMint,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: AppTheme.primaryMint, size: 19),
                tooltip: "Vehicle & Battery Hardware Specs",
                onPressed: () => VehicleBatterySelectorSheet.show(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Data Source Toggle Strip (Simulation vs Live Device Sensors)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => telemetry.setDataSource(TelemetryDataSource.simulation),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isLive ? AppTheme.primaryMint.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !isLive ? AppTheme.primaryMint : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.route,
                                      size: 13,
                                      color: !isLive ? AppTheme.primaryMint : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "CORRIDOR TRACE",
                                      style: AppTheme.labelCaps.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: !isLive ? AppTheme.primaryMint : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () => telemetry.setDataSource(TelemetryDataSource.liveSensors),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isLive ? AppTheme.hudCyan.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isLive ? AppTheme.hudCyan : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sensors,
                                      size: 13,
                                      color: isLive ? AppTheme.hudCyan : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "LIVE SENSORS",
                                      style: AppTheme.labelCaps.copyWith(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: isLive ? AppTheme.hudCyan : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hardware Specification Badge (Quick Access to Battery & Vehicle Selector)
                  InkWell(
                    onTap: () => VehicleBatterySelectorSheet.show(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.battery_charging_full,
                                  size: 13,
                                  color: telemetry.selectedBattery.chemistry == BatteryChemistry.lfp
                                      ? AppTheme.primaryMint
                                      : AppTheme.hudCyan,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    telemetry.selectedBattery.shortLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.labelCaps.copyWith(
                                      fontSize: 8.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                const Icon(Icons.electric_bike, size: 13, color: AppTheme.hudAmber),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    telemetry.selectedVehicle.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: AppTheme.labelCaps.copyWith(
                                      fontSize: 8.5,
                                      color: AppTheme.hudAmber,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "CHANGE",
                                style: AppTheme.labelCaps.copyWith(
                                  fontSize: 7.5,
                                  color: AppTheme.primaryMint,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 13, color: AppTheme.primaryMint),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Live Sensor Telemetry Strip & Jerk Pothole Filter (Active in Live Mode)
                  if (isLive && live != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: live.isPotholeDetected ? AppTheme.hudCrimson : AppTheme.hudCyan.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: live.isPotholeDetected ? AppTheme.hudCrimson : AppTheme.hudCyan,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        live.isPotholeDetected
                                            ? "⚠️ POTHOLE SHOCK REJECTED BY FILTER"
                                            : (live.isWeatherSynced ? "MADGWICK FUSION + GPS WEATHER SYNC" : "MADGWICK SENSOR FUSION ACTIVE"),
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.labelCaps.copyWith(
                                          fontSize: 8.0,
                                          fontWeight: FontWeight.w900,
                                          color: live.isPotholeDetected ? AppTheme.hudCrimson : AppTheme.hudCyan,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "IRI: ${live.roadRoughnessIri.toStringAsFixed(1)} m/km",
                                style: AppTheme.labelCaps.copyWith(fontSize: 8.0, color: Colors.white60),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(child: _buildMiniTelemetryCol("IMU PITCH", "${live.pitchAngleDegrees.toStringAsFixed(1)}°")),
                              Expanded(child: _buildMiniTelemetryCol("FUSED GRADE", "${live.fusedGradePct.toStringAsFixed(1)}%")),
                              Expanded(
                                child: _buildMiniTelemetryCol(
                                  "ODOMETER",
                                  "${(live.cumulativeDistanceMeters / 1000).toStringAsFixed(2)} km",
                                  color: AppTheme.hudCyan,
                                ),
                              ),
                              Expanded(
                                child: _buildMiniTelemetryCol(
                                  "GPS FIX",
                                  live.isGpsActive ? (live.isWeatherSynced ? "LIVE+WX" : "LOCKED") : "SIM",
                                  color: live.isGpsActive ? AppTheme.primaryMint : AppTheme.hudAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.hudCrimson,
                                    side: const BorderSide(color: AppTheme.hudCrimson),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                  icon: const Icon(Icons.flash_on, size: 14),
                                  label: const Text(
                                    "INJECT 3.8G POTHOLE",
                                    style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800),
                                  ),
                                  onPressed: () => telemetry.injectSimulatedPothole(),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryMint,
                                    side: const BorderSide(color: AppTheme.primaryMint),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                  icon: const Icon(Icons.replay, size: 14),
                                  label: const Text(
                                    "ZERO TRIP",
                                    style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800),
                                  ),
                                  onPressed: () => telemetry.resetLiveTrip(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 3. Live HUD Mount Status Bar Strip (Simulation Mode)
                  if (!isLive) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // GPS Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.4)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryMint,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "GPS 10Hz",
                                      style: AppTheme.labelCaps.copyWith(
                                        fontSize: 8.0,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primaryMint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Ambient Weather Pill
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    border: Border.all(
                                      color: telemetry.isWeatherSynced ? AppTheme.primaryMint.withValues(alpha: 0.4) : Colors.white12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        telemetry.isWeatherSynced ? Icons.satellite_alt : Icons.wb_sunny_outlined,
                                        size: 11,
                                        color: telemetry.isWeatherSynced ? AppTheme.primaryMint : AppTheme.hudAmber,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          "${telemetry.ambientTempCelsius.toStringAsFixed(1)}°C ${telemetry.isWeatherSynced ? 'GPS AIR' : 'AMBIENT'}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.labelCaps.copyWith(
                                            fontSize: 8.0,
                                            color: telemetry.isWeatherSynced ? AppTheme.primaryMint : AppTheme.hudAmber,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.navigation_outlined, size: 13, color: AppTheme.hudCyan),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "${currentSpeed.toStringAsFixed(1)} km/h · ${telemetry.currentTrace?.name ?? 'Chowkaghat'}",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 13,
                                    color: gradePct > 2.0 ? AppTheme.hudCrimson : AppTheme.primaryMint,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    "${gradePct >= 0 ? '+' : ''}${gradePct.toStringAsFixed(1)}%",
                                    style: AppTheme.labelCaps.copyWith(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: gradePct > 2.0 ? AppTheme.hudCrimson : AppTheme.primaryMint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // 4. Reverse Mass Fraud Alert Banner (USP: Algorithmic Overload Detection)
                  if ((isLive && (live?.isOverloadFraudDetected ?? false)) || telemetry.cargoMassKg > 90.0) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.hudCrimson.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.hudCrimson, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.hudCrimson, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ALGORITHMIC OVERLOAD DETECTED",
                                  style: AppTheme.labelCaps.copyWith(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.hudCrimson,
                                  ),
                                ),
                                Text(
                                  "Platform declared: 5 kg · Physics Reverse Mass: ${isLive ? (live?.reverseEstimatedCargoKg.toStringAsFixed(0) ?? '138') : telemetry.cargoMassKg.toStringAsFixed(0)} kg (+${(((isLive ? (live?.reverseEstimatedCargoKg ?? 138) : telemetry.cargoMassKg) - 65) / 65 * 100).toStringAsFixed(0)}% OEM limit)",
                                  style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 5. Hero 270° Radial C-Rate Tachometer Gauge
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: CRateGauge(
                      cRate: cRate,
                      currentAmps: currentAmps,
                      electricalPowerWatts: powerWatts,
                      isPlatingRisk: isPlating,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 6. Dual Battery Telemetry Cards
                  ThermalBatteryHud(
                    cellTempCelsius: cellTemp,
                    wearRateInrPerKm: wearRate,
                    cumulativeWearInr: cumulativeWear,
                  ),

                  const SizedBox(height: 10),

                  // 7. NeuroPace AI Predictive Advisory Banner
                  DynamicPacingBanner(pacing: pacing),

                  const SizedBox(height: 10),

                  // 8. Flyover Topographic Profile
                  if (!isLive) ...[
                    ElevationMiniChart(
                      points: telemetry.evaluatedPoints,
                      currentIndex: telemetry.currentStepIndex,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 9. 1-Tap Quick Payload Bar
                  QuickPayloadSelector(
                    currentCargoKg: telemetry.cargoMassKg,
                    onCargoChanged: (val) => telemetry.setCargoWeight(val),
                  ),

                  const SizedBox(height: 12),

                  // 10. Simulation Playback Dock (When in simulation mode)
                  if (!isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay, color: AppTheme.textSecondary, size: 20),
                            tooltip: "Reset climb",
                            onPressed: () => telemetry.resetSimulation(),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: telemetry.isPlaying ? AppTheme.hudAmber : AppTheme.primaryMint,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: Icon(telemetry.isPlaying ? Icons.pause : Icons.play_arrow, size: 18),
                            label: Text(
                              telemetry.isPlaying ? "PAUSE SIM" : "RUN CLIMB",
                              style: AppTheme.labelCaps.copyWith(
                                color: Colors.black,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            onPressed: () => telemetry.togglePlayback(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, color: AppTheme.textSecondary, size: 20),
                            tooltip: "Step next",
                            onPressed: () {
                              if (telemetry.currentStepIndex < telemetry.evaluatedPoints.length - 1) {
                                telemetry.seekToIndex(telemetry.currentStepIndex + 1);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 11. Generate Overload Defense Slip Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.hudCrimson,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: Text(
                        "GENERATE OVERLOAD DEFENSE SLIP (PDF)",
                        style: AppTheme.labelCaps.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onPressed: () {
                        final trip = telemetry.lastTripRecord;
                        if (trip != null) {
                          final slip = DefenseSlipData.fromTrip(trip: trip);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DefenseSlipScreen(slipData: slip),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Run climb simulation first to generate telemetry.")),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniTelemetryCol(String label, String value, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.telemetryDigits.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
