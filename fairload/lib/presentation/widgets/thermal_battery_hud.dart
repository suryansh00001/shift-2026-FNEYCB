import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ThermalBatteryHud extends StatelessWidget {
  final double cellTempCelsius;
  final double wearRateInrPerKm;
  final double cumulativeWearInr;

  const ThermalBatteryHud({
    super.key,
    required this.cellTempCelsius,
    required this.wearRateInrPerKm,
    required this.cumulativeWearInr,
  });

  @override
  Widget build(BuildContext context) {
    Color tempColor;
    String statusText;
    if (cellTempCelsius < 44.0) {
      tempColor = AppTheme.primaryMint;
      statusText = "NOMINAL THERMAL REGIME";
    } else if (cellTempCelsius < 50.0) {
      tempColor = AppTheme.hudAmber;
      statusText = "ELEVATED JOULE RISE";
    } else {
      tempColor = AppTheme.hudCrimson;
      statusText = "SEI LAYER DEGRADATION";
    }

    return Row(
      children: [
        // Card A: Thermal Pack Metric
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CELL TEMP",
                      style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
                    ),
                    Icon(
                      cellTempCelsius >= 48.0 ? Icons.local_fire_department : Icons.battery_charging_full,
                      color: tempColor,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      cellTempCelsius.toStringAsFixed(1),
                      style: AppTheme.telemetryDigits.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: tempColor,
                      ),
                    ),
                    Text(
                      " °C",
                      style: AppTheme.telemetryUnit.copyWith(fontSize: 12, color: tempColor),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: tempColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Card B: Rupee Burn Metric
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TRIP ASSET WEAR",
                      style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
                    ),
                    const Icon(
                      Icons.currency_rupee,
                      color: AppTheme.hudAmber,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "₹ ${cumulativeWearInr.toStringAsFixed(2)}",
                      style: AppTheme.telemetryDigits.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: cumulativeWearInr > 25.0 ? AppTheme.hudCrimson : AppTheme.hudAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  cumulativeWearInr > 25.0 ? "EXCEEDS ₹25 PAYOUT" : "WITHIN ORDER MARGIN",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: cumulativeWearInr > 25.0 ? AppTheme.hudCrimson : AppTheme.primaryMint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
