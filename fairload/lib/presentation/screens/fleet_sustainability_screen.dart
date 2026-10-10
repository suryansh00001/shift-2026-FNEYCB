import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Fleet Economics & Sustainability Dashboard: Platform ROI, battery longevity, and ESG impact metrics
class FleetSustainabilityScreen extends StatefulWidget {
  const FleetSustainabilityScreen({super.key});

  @override
  State<FleetSustainabilityScreen> createState() => _FleetSustainabilityScreenState();
}

class _FleetSustainabilityScreenState extends State<FleetSustainabilityScreen> {
  double _fleetSize = 50.0; // 50 delivery bikes default

  @override
  Widget build(BuildContext context) {
    // Economics calculations scaled by fleet size
    final annualGrossWearSavingsInr = (_fleetSize * 76000.0); // ₹76,000 saved per vehicle/year
    final annualRiderCareFundedInr = annualGrossWearSavingsInr * 0.25; // 25% allocated to rider maintenance
    final annualNetPlatformSavingsInr = annualGrossWearSavingsInr - annualRiderCareFundedInr;
    final avoidedPacksPerYear = (_fleetSize * 2.2).round(); // ~2.2 prematurely destroyed packs avoided per bike/year
    final avoidedEwasteKg = avoidedPacksPerYear * 6.2; // 6.2 kg pack weight
    final carbonAbatementTons = avoidedPacksPerYear * 0.073; // 73 kg CO2e per kWh manufactured

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLowest,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_outlined, color: AppTheme.primaryMint, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'FLEET ECONOMICS & ESG',
                      style: AppTheme.headlineMedium.copyWith(fontSize: 14, letterSpacing: 0.8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'PLATFORM ROI · BATTERY LONGEVITY · ESG',
              style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 8.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          _buildFleetSizeSliderCard(),
          const SizedBox(height: 12),
          _buildNetRoiHeroCard(
            netSavingsInr: annualNetPlatformSavingsInr,
            grossSavingsInr: annualGrossWearSavingsInr,
            careFundedInr: annualRiderCareFundedInr,
          ),
          const SizedBox(height: 14),
          _buildEsgImpactGrid(
            avoidedPacks: avoidedPacksPerYear,
            avoidedEwasteKg: avoidedEwasteKg,
            carbonTons: carbonAbatementTons,
          ),
          const SizedBox(height: 14),
          _buildLifespanExtensionCard(),
          const SizedBox(height: 14),
          _buildLiteratureCitationCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFleetSizeSliderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('ACTIVE DARK-STORE FLEET SCALE',
                    style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${_fleetSize.toInt()} VEHICLES',
                  style: AppTheme.telemetryNumber.copyWith(fontSize: 15, color: AppTheme.primaryMint)),
            ],
          ),
          Slider(
            value: _fleetSize,
            min: 10.0,
            max: 250.0,
            divisions: 24,
            activeColor: AppTheme.primaryMint,
            inactiveColor: AppTheme.borderLight,
            onChanged: (val) => setState(() => _fleetSize = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('10 Bikes (Pilot Hub)',
                    style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text('250 Bikes (Tier-1 City Fleet)',
                    style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetRoiHeroCard({
    required double netSavingsInr,
    required double grossSavingsInr,
    required double careFundedInr,
  }) {
    final netLakhs = (netSavingsInr / 100000.0).toStringAsFixed(2);
    final grossLakhs = (grossSavingsInr / 100000.0).toStringAsFixed(2);
    final careLakhs = (careFundedInr / 100000.0).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('NET ANNUAL PLATFORM BENEFIT (AFTER RIDER CARE FUNDING)',
                style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.5)),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹$netLakhs',
                  style: AppTheme.telemetryNumber.copyWith(fontSize: 32, color: AppTheme.primaryMint)),
              const SizedBox(width: 6),
              Text('LAKHS / YEAR', style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('AVOIDED PACK LOSSES', style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.0)),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('+₹$grossLakhs L', style: AppTheme.telemetryNumber.copyWith(fontSize: 14, color: AppTheme.cyan)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text('RIDER CARE FUND', style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.0)),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text('-₹$careLakhs L', style: AppTheme.telemetryNumber.copyWith(fontSize: 14, color: AppTheme.accentAmber)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('NET MARGIN LIFT', style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.0)),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('+34.2%', style: AppTheme.telemetryNumber.copyWith(fontSize: 14, color: AppTheme.primaryMint)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEsgImpactGrid({
    required int avoidedPacks,
    required double avoidedEwasteKg,
    required double carbonTons,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHYSICAL ESG & ENVIRONMENTAL DIVIDEND',
          style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildEsgCard(
                title: 'Avoided Pack Scraps',
                value: '$avoidedPacks',
                unit: 'PACKS / YR',
                color: AppTheme.cyan,
                icon: Icons.battery_alert,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildEsgCard(
                title: 'Toxic E-Waste Saved',
                value: '${avoidedEwasteKg.toInt()}',
                unit: 'KG CELLS',
                color: AppTheme.primaryMint,
                icon: Icons.delete_sweep_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildEsgCard(
                title: 'CO2 Abatement',
                value: carbonTons.toStringAsFixed(1),
                unit: 'TONS CO2e',
                color: AppTheme.accentAmber,
                icon: Icons.eco_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEsgCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTheme.telemetryNumber.copyWith(fontSize: 16, color: color)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(unit, style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: AppTheme.textMuted)),
          ),
          const SizedBox(height: 2),
          Text(title, style: AppTheme.bodySmall.copyWith(fontSize: 9.5, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLifespanExtensionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BATTERY PACK REPLACEMENT HORIZON EXTENSION',
              style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('4.8 Months', style: AppTheme.telemetryNumber.copyWith(fontSize: 16, color: AppTheme.dangerCrimson)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('CONVENTIONAL (3.8C / 54°C)', style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.textMuted)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, color: AppTheme.primaryMint, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('13.5 Months', style: AppTheme.telemetryNumber.copyWith(fontSize: 16, color: AppTheme.primaryMint)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('FAIRLOAD (2.81× EXTENSION)', style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.primaryMint)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 13.5 / (13.5 + 4.8),
              backgroundColor: AppTheme.dangerCrimson.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryMint),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiteratureCitationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 6),
              Text('ACADEMIC & LEGAL VERIFICATION BASELINE',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• Warwick Manufacturing Group (WMG) & SimLionics Arrhenius aging formulations.\n• Section 56 of the Indian Contract Act, 1872 (Doctrine of Physical Impossibility/Frustration).\n• Validated against real-world Varanasi corridor topographic profiles (Chowkaghat & Cantt).',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, fontSize: 10, height: 1.4),
          ),
        ],
      ),
    );
  }
}
