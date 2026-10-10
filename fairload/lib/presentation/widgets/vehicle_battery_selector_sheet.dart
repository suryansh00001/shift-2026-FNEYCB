import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/battery_specs.dart';
import '../../core/constants/vehicle_specs.dart';
import '../../core/theme/app_theme.dart';
import '../providers/telemetry_provider.dart';

class VehicleBatterySelectorSheet extends StatelessWidget {
  const VehicleBatterySelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.border, width: 1),
      ),
      builder: (_) => const VehicleBatterySelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = Provider.of<TelemetryProvider>(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Grab Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "HARDWARE & PACK SPECS",
                          style: AppTheme.labelCaps.copyWith(
                            color: AppTheme.primaryMint,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Configure Vehicle Frame, Motor & Battery Chemistry",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // SECTION 1: BATTERY PACK SELECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "1. BATTERY PACK & CHEMISTRY",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.labelCaps.copyWith(fontSize: 9.5, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLow,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      telemetry.selectedBattery.chemistryLabel,
                      style: AppTheme.labelCaps.copyWith(
                        fontSize: 9,
                        color: telemetry.selectedBattery.chemistry == BatteryChemistry.lfp
                            ? AppTheme.primaryMint
                            : AppTheme.hudCyan,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...BatterySpecs.profiles.map((profile) {
                final isSelected = profile.id == telemetry.selectedBattery.id;
                final isLfp = profile.chemistry == BatteryChemistry.lfp;

                return InkWell(
                  onTap: () => telemetry.setBatteryProfile(profile),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.surfaceLow : AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryMint : AppTheme.borderLight,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 16,
                              color: isSelected ? AppTheme.primaryMint : Colors.white38,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isLfp ? AppTheme.primaryMint : AppTheme.hudCyan).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                profile.chemistryLabel,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: isLfp ? AppTheme.primaryMint : AppTheme.hudCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile.description,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildSpecMiniPill("ENERGY", "${profile.totalNominalEnergyWh.toInt()} Wh")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildSpecMiniPill("PACK WT", "${profile.packMassKg} kg")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildSpecMiniPill("SAFE TEMP", "<${profile.tempSafeThreshold.toInt()}°C")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildSpecMiniPill("COST", "₹${(profile.packReplacementCostInr / 1000).toStringAsFixed(0)}k")),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // SECTION 2: VEHICLE & MOTOR SELECTION
              Text(
                "2. VEHICLE CHASSIS & HUB MOTOR",
                style: AppTheme.labelCaps.copyWith(fontSize: 9.5, color: Colors.white70),
              ),
              const SizedBox(height: 8),

              ...VehicleSpecs.vehicleProfiles.map((vProfile) {
                final isSelected = vProfile.id == telemetry.selectedVehicle.id;

                return InkWell(
                  onTap: () => telemetry.setVehicleProfile(vProfile),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.surfaceLow : AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.hudCyan : AppTheme.borderLight,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_off,
                              size: 16,
                              color: isSelected ? AppTheme.hudCyan : Colors.white38,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vProfile.name,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              "${vProfile.motor.peakPower.toInt()}W PEAK",
                              style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: AppTheme.hudAmber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildSpecMiniPill("CHASSIS", "${vProfile.tareMassKg.toInt()} kg")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildSpecMiniPill("RIDER WT", "${vProfile.riderMassKg.toInt()} kg")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildSpecMiniPill("MAX CARGO", "${vProfile.ratedCargoCapacityKg.toInt()} kg")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildSpecMiniPill("RATED SPD", "${vProfile.motor.ratedSpeedKmh.toInt()} km/h")),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // SECTION 3: LIVE GPS WEATHER STATUS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: telemetry.isWeatherSynced ? AppTheme.primaryMint.withValues(alpha: 0.4) : AppTheme.borderLight,
                  ),
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
                              Icon(
                                Icons.satellite_alt,
                                size: 14,
                                color: telemetry.isWeatherSynced ? AppTheme.primaryMint : AppTheme.hudAmber,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  telemetry.isWeatherSynced
                                      ? "GPS OPEN-METEO SYNC"
                                      : "AMBIENT OVERRIDE",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.labelCaps.copyWith(
                                    fontSize: 8.5,
                                    color: telemetry.isWeatherSynced ? AppTheme.primaryMint : AppTheme.hudAmber,
                                    fontWeight: FontWeight.w900,
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
                              "${telemetry.ambientTempCelsius.toStringAsFixed(1)} °C",
                              style: AppTheme.telemetryDigits.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.hudAmber,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => telemetry.syncLiveWeather(force: true),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLow,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.refresh, size: 10, color: AppTheme.primaryMint),
                                    const SizedBox(width: 2),
                                    Text(
                                      "SYNC",
                                      style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: AppTheme.primaryMint, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      telemetry.isWeatherSynced
                          ? "Real-time outdoor air temperature is automatically fetched via GPS coordinates to seed the convective cooling model."
                          : "Manual ambient temperature override. Changes reflect immediately in Joule heat dissipation models.",
                      style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: telemetry.ambientTempCelsius,
                      min: 20.0,
                      max: 50.0,
                      divisions: 30,
                      activeColor: AppTheme.hudAmber,
                      inactiveColor: AppTheme.surfaceLow,
                      onChanged: (val) => telemetry.setAmbientTemp(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Close / Done button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMint,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "SAVE & APPLY HARDWARE PROFILE",
                    style: AppTheme.labelCaps.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecMiniPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.labelCaps.copyWith(fontSize: 7, color: Colors.white38),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
