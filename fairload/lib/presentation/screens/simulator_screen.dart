import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/battery_specs.dart';
import '../../core/constants/vehicle_specs.dart';
import '../../core/theme/app_theme.dart';
import '../providers/telemetry_provider.dart';
import '../widgets/vehicle_battery_selector_sheet.dart';

class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetry, child) {
        final points = telemetry.evaluatedPoints;
        final lastTrip = telemetry.lastTripRecord;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceLowest,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CORRIDOR STRESS SIMULATOR",
                  style: AppTheme.labelCaps.copyWith(
                    color: AppTheme.primaryMint,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "Physics-Grounded Benchmark Engine",
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune, color: AppTheme.primaryMint, size: 20),
                tooltip: "Vehicle & Battery Hardware Specs",
                onPressed: () => VehicleBatterySelectorSheet.show(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Corridor Selector Chips
                Text(
                  "SELECT CORRIDOR TRACE",
                  style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRouteChip(
                      context,
                      title: "Chowkaghat Flyover (4.2%)",
                      asset: "assets/traces/chowkaghat_flyover.json",
                      selectedAsset: telemetry.selectedRouteAsset,
                      onSelect: (a) => telemetry.loadRoute(a),
                    ),
                    _buildRouteChip(
                      context,
                      title: "Cantt Overbridge (3.8%)",
                      asset: "assets/traces/cantt_overbridge.json",
                      selectedAsset: telemetry.selectedRouteAsset,
                      onSelect: (a) => telemetry.loadRoute(a),
                    ),
                    _buildRouteChip(
                      context,
                      title: "Lanka Gallis (Stop & Go)",
                      asset: "assets/traces/lanka_gallis.json",
                      selectedAsset: telemetry.selectedRouteAsset,
                      onSelect: (a) => telemetry.loadRoute(a),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. Interactive Tactical Sliders
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cargo Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              "Assigned Cargo Payload",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (telemetry.cargoMassKg > 65 ? AppTheme.hudCrimson : AppTheme.primaryMint)
                                  .withValues(alpha: 0.15),
                              border: Border.all(
                                color: telemetry.cargoMassKg > 65 ? AppTheme.hudCrimson : AppTheme.primaryMint,
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${telemetry.cargoMassKg.toInt()} kg (${telemetry.cargoMassKg > 65 ? '+${((telemetry.cargoMassKg - 65) / 65 * 100).toInt()}%' : 'Safe'})",
                              style: AppTheme.labelCaps.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: telemetry.cargoMassKg > 65 ? AppTheme.hudCrimson : AppTheme.primaryMint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: telemetry.cargoMassKg,
                        min: 25.0,
                        max: 180.0,
                        divisions: 31,
                        activeColor: telemetry.cargoMassKg > 65 ? AppTheme.hudCrimson : AppTheme.primaryMint,
                        inactiveColor: AppTheme.surfaceLow,
                        onChanged: (val) => telemetry.setCargoWeight(val),
                      ),

                      const SizedBox(height: 6),

                      // Ambient Temp Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Ambient Air Temperature",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              if (telemetry.isWeatherSynced) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryMint.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "LIVE GPS",
                                    style: AppTheme.labelCaps.copyWith(
                                      fontSize: 7.5,
                                      color: AppTheme.primaryMint,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            "${telemetry.ambientTempCelsius.toStringAsFixed(1)} °C",
                            style: AppTheme.labelCaps.copyWith(
                              fontSize: 11,
                              color: telemetry.isWeatherSynced ? AppTheme.primaryMint : AppTheme.hudAmber,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: telemetry.ambientTempCelsius.clamp(20.0, 50.0),
                        min: 20.0,
                        max: 50.0,
                        divisions: 30,
                        activeColor: telemetry.isWeatherSynced ? AppTheme.primaryMint : AppTheme.hudAmber,
                        inactiveColor: AppTheme.surfaceLow,
                        onChanged: (val) => telemetry.setAmbientTemp(val),
                      ),

                      const SizedBox(height: 6),

                      // Battery Pack Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Battery Pack Specification",
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMint.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  telemetry.selectedBattery.chemistryLabel,
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppTheme.primaryMint),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<BatteryProfile>(
                                value: telemetry.selectedBattery,
                                dropdownColor: AppTheme.surfaceLowest,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryMint, size: 20),
                                style: AppTheme.labelCaps.copyWith(fontSize: 9.5, color: AppTheme.primaryMint, fontWeight: FontWeight.w800),
                                items: BatterySpecs.profiles.map((b) {
                                  return DropdownMenuItem<BatteryProfile>(
                                    value: b,
                                    child: Text(
                                      "${b.name} (${b.totalNominalEnergyWh.toInt()}Wh)",
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (b) {
                                  if (b != null) telemetry.setBatteryProfile(b);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Vehicle Chassis Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Vehicle Chassis Specification",
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.hudCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${telemetry.selectedVehicle.tareMassKg.toInt()}kg Tare",
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppTheme.hudCyan),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<VehicleProfile>(
                                value: telemetry.selectedVehicle,
                                dropdownColor: AppTheme.surfaceLowest,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.hudCyan, size: 20),
                                style: AppTheme.labelCaps.copyWith(fontSize: 9.5, color: AppTheme.hudCyan, fontWeight: FontWeight.w800),
                                items: VehicleSpecs.vehicleProfiles.map((v) {
                                  return DropdownMenuItem<VehicleProfile>(
                                    value: v,
                                    child: Text(
                                      v.name,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) telemetry.setVehicleProfile(v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Motor Rating Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Hub Motor Specification",
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.hudAmber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${telemetry.selectedMotor.peakPower.toInt()}W Peak",
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppTheme.hudAmber),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<MotorProfile>(
                                value: telemetry.selectedMotor,
                                dropdownColor: AppTheme.surfaceLowest,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.hudAmber, size: 20),
                                style: AppTheme.labelCaps.copyWith(fontSize: 9.5, color: AppTheme.hudAmber, fontWeight: FontWeight.w800),
                                items: VehicleSpecs.motorProfiles.map((m) {
                                  return DropdownMenuItem<MotorProfile>(
                                    value: m,
                                    child: Text(
                                      m.name,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (m) {
                                  if (m != null) telemetry.setMotorProfile(m);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Electrochemical Impact Matrix (4 Metric Cards)
                if (lastTrip != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: lastTrip.hasPlatingDamage ? AppTheme.hudCrimson : AppTheme.borderLight,
                        width: lastTrip.hasPlatingDamage ? 1.2 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "ELECTROCHEMICAL IMPACT",
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (lastTrip.hasPlatingDamage ? AppTheme.hudCrimson : AppTheme.primaryMint)
                                    .withValues(alpha: 0.15),
                                border: Border.all(
                                  color: lastTrip.hasPlatingDamage ? AppTheme.hudCrimson : AppTheme.primaryMint,
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lastTrip.hasPlatingDamage ? "⚠️ PLATING ONSET" : "SAFE OPERATION",
                                style: AppTheme.labelCaps.copyWith(
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w900,
                                  color: lastTrip.hasPlatingDamage ? AppTheme.hudCrimson : AppTheme.primaryMint,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(child: _buildAuditStat("INCLINE", "${lastTrip.peakGradePct.toStringAsFixed(1)}%", AppTheme.hudCyan)),
                            Expanded(child: _buildAuditStat("C-RATE", "${lastTrip.peakCRate.toStringAsFixed(1)} C", AppTheme.hudCrimson)),
                            Expanded(child: _buildAuditStat("TEMP", "${lastTrip.peakCellTempCelsius.toStringAsFixed(1)} °C", AppTheme.hudAmber)),
                            Expanded(child: _buildAuditStat("NET MARGIN", "₹${lastTrip.netEarningsInr.toStringAsFixed(1)}", lastTrip.netEarningsInr < 0 ? AppTheme.hudCrimson : AppTheme.primaryMint)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3B. Reverse Mass Estimator Sandbox (Algorithmic Overload Detection)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.hudCyan.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.fitness_center, size: 14, color: AppTheme.hudCyan),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "REVERSE MASS ESTIMATOR",
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.labelCaps.copyWith(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.hudCyan,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.hudCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "NEWTON-EULER",
                                style: AppTheme.labelCaps.copyWith(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.hudCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("APP DECLARED CARGO", style: AppTheme.labelCaps.copyWith(fontSize: 7, color: Colors.white38)),
                                    const SizedBox(height: 2),
                                    Text("5.0 kg", style: AppTheme.telemetryDigits.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white60)),
                                    Text("Dark Store Claim", style: TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.hudCrimson.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.hudCrimson),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("PHYSICS DERIVED MASS", style: AppTheme.labelCaps.copyWith(fontSize: 7, color: AppTheme.hudCrimson)),
                                    const SizedBox(height: 2),
                                    Text("${telemetry.cargoMassKg.toInt()} kg", style: AppTheme.telemetryDigits.copyWith(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.hudCrimson)),
                                    Text("+${(telemetry.cargoMassKg - 5.0).toInt()} kg Fraud Unmasked", style: TextStyle(fontSize: 8, color: AppTheme.hudCrimson, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Algorithm: Solves steady-state power balance at continuous motor power limits during flyover climb to deduce actual gross mass independently of platform dark store reporting.",
                          style: TextStyle(fontSize: 9, color: Colors.white54, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 4. Dual Live Waveform Chart
                if (points.isNotEmpty) ...[
                  Text(
                    "DUAL TELEMETRY WAVEFORM (C-RATE vs INCLINE)",
                    style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.only(top: 14, right: 14, bottom: 6, left: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // C-Rate Line (Crimson)
                          LineChartBarData(
                            spots: points.map((p) => FlSpot(p.timeSeconds, p.cRate)).toList(),
                            isCurved: true,
                            color: AppTheme.hudCrimson,
                            barWidth: 2.2,
                            dotData: const FlDotData(show: false),
                          ),
                          // Grade Line (Cyan)
                          LineChartBarData(
                            spots: points.map((p) => FlSpot(p.timeSeconds, p.inclineGradePct)).toList(),
                            isCurved: true,
                            color: AppTheme.hudCyan,
                            barWidth: 1.5,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(AppTheme.hudCrimson, "Discharge C-Rate"),
                      const SizedBox(width: 16),
                      _buildLegend(AppTheme.hudCyan, "Road Incline (%)"),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildRouteChip(
    BuildContext context, {
    required String title,
    required String asset,
    required String selectedAsset,
    required ValueChanged<String> onSelect,
  }) {
    final isSelected = asset == selectedAsset;
    return ChoiceChip(
      label: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? Colors.black : Colors.white70,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryMint,
      backgroundColor: AppTheme.surfaceLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: isSelected ? AppTheme.primaryMint : AppTheme.borderLight),
      ),
      onSelected: (_) => onSelect(asset),
    );
  }

  static Widget _buildAuditStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38)),
        const SizedBox(height: 3),
        Text(value, style: AppTheme.telemetryDigits.copyWith(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  static Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white54)),
      ],
    );
  }
}
