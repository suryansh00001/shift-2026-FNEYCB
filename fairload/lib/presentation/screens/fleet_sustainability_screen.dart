import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Available perspective modes for Fleet ROI and Sustainability analysis
enum FleetRoiPerspective {
  recruitingSavings, // Saved recruiting new rider costs (rider retention & churn CAC)
  batteryHardware,   // Avoided battery pack replacement losses & physical ESG
  combined,          // Combined platform economics (Recruiting + Battery synergies)
}

/// Fleet Economics & Sustainability Dashboard: Platform ROI, Rider Recruiting CAC Savings,
/// Battery longevity, and ESG impact metrics.
class FleetSustainabilityScreen extends StatefulWidget {
  const FleetSustainabilityScreen({super.key});

  @override
  State<FleetSustainabilityScreen> createState() => _FleetSustainabilityScreenState();
}

class _FleetSustainabilityScreenState extends State<FleetSustainabilityScreen> {
  double _fleetSize = 50.0; // 50 delivery bikes default
  FleetRoiPerspective _selectedPerspective = FleetRoiPerspective.recruitingSavings;

  // Unit economics constants (Indian Quick-Commerce Benchmark: Zepto/Blinkit/Zomato/Swiggy)
  static const double kNewRiderCacInr = 6500.0; // Sourcing, KYC, Welcome kit/bags & dark-store training
  static const double kAnnualAvoidedRecruitsPerBike = 1.94; // Avoided replacement recruits per vehicle/yr (from 135% -> 38% churn)
  static const double kAnnualPackSavingsPerBikeInr = 76000.0; // Avoided pack hardware degradation per bike/yr

  @override
  Widget build(BuildContext context) {
    // 1. Rider Recruiting Perspective Economics
    final avoidedRiderRecruitments = (_fleetSize * kAnnualAvoidedRecruitsPerBike).round();
    final grossRecruitingSavingsInr = avoidedRiderRecruitments * kNewRiderCacInr;
    final careFundFromRecruitingInr = grossRecruitingSavingsInr * 0.25;
    final netRecruitingSavingsInr = grossRecruitingSavingsInr - careFundFromRecruitingInr;

    // 2. Battery Hardware Perspective Economics
    final annualGrossPackSavingsInr = (_fleetSize * kAnnualPackSavingsPerBikeInr);
    final careFundFromPacksInr = annualGrossPackSavingsInr * 0.25;
    final netPackSavingsInr = annualGrossPackSavingsInr - careFundFromPacksInr;
    final avoidedPacksPerYear = (_fleetSize * 2.2).round();
    final avoidedEwasteKg = avoidedPacksPerYear * 6.2;
    final carbonAbatementTons = avoidedPacksPerYear * 0.073;

    // 3. Combined Perspective Economics
    final grossCombinedSavingsInr = grossRecruitingSavingsInr + annualGrossPackSavingsInr;
    final careFundCombinedInr = grossCombinedSavingsInr * 0.25;
    final netCombinedSavingsInr = grossCombinedSavingsInr - careFundCombinedInr;

    // Active metrics according to selected perspective
    final double activeGrossSavings;
    final double activeCareFund;
    final double activeNetSavings;
    final String heroGrossLabel;
    final String heroMarginLift;

    switch (_selectedPerspective) {
      case FleetRoiPerspective.recruitingSavings:
        activeGrossSavings = grossRecruitingSavingsInr;
        activeCareFund = careFundFromRecruitingInr;
        activeNetSavings = netRecruitingSavingsInr;
        heroGrossLabel = 'SAVED RECRUITING NEW RIDER COST';
        heroMarginLift = '+75.0%';
        break;
      case FleetRoiPerspective.batteryHardware:
        activeGrossSavings = annualGrossPackSavingsInr;
        activeCareFund = careFundFromPacksInr;
        activeNetSavings = netPackSavingsInr;
        heroGrossLabel = 'AVOIDED PACK LOSSES';
        heroMarginLift = '+34.2%';
        break;
      case FleetRoiPerspective.combined:
        activeGrossSavings = grossCombinedSavingsInr;
        activeCareFund = careFundCombinedInr;
        activeNetSavings = netCombinedSavingsInr;
        heroGrossLabel = 'SAVED RECRUITING + PACKS';
        heroMarginLift = '+109.2%';
        break;
    }

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
              'RECRUITING CAC SAVINGS · BATTERY LONGEVITY · ESG',
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
          const SizedBox(height: 10),
          _buildPerspectiveSelectorBar(),
          const SizedBox(height: 12),
          _buildNetRoiHeroCard(
            netSavingsInr: activeNetSavings,
            grossSavingsInr: activeGrossSavings,
            careFundedInr: activeCareFund,
            grossLabel: heroGrossLabel,
            marginLiftText: heroMarginLift,
          ),
          const SizedBox(height: 14),

          // Render perspective-specific section views
          if (_selectedPerspective == FleetRoiPerspective.recruitingSavings) ...[
            _buildRecruitingImpactGrid(
              avoidedRecruits: avoidedRiderRecruitments,
              cacPerRiderInr: kNewRiderCacInr,
            ),
            const SizedBox(height: 14),
            _buildRecruitingCostDecompositionCard(),
            const SizedBox(height: 14),
            _buildRiderTenureRetentionCard(),
            const SizedBox(height: 14),
            _buildRecruitingWhyItWorksCard(),
          ] else if (_selectedPerspective == FleetRoiPerspective.batteryHardware) ...[
            _buildEsgImpactGrid(
              avoidedPacks: avoidedPacksPerYear,
              avoidedEwasteKg: avoidedEwasteKg,
              carbonTons: carbonAbatementTons,
            ),
            const SizedBox(height: 14),
            _buildLifespanExtensionCard(),
            const SizedBox(height: 14),
            _buildLiteratureCitationCard(),
          ] else ...[
            _buildCombinedSynergyCard(
              recruitingNetLakhs: (netRecruitingSavingsInr / 100000.0).toStringAsFixed(2),
              hardwareNetLakhs: (netPackSavingsInr / 100000.0).toStringAsFixed(2),
              avoidedRecruits: avoidedRiderRecruitments,
              avoidedPacks: avoidedPacksPerYear,
            ),
            const SizedBox(height: 14),
            _buildRecruitingImpactGrid(
              avoidedRecruits: avoidedRiderRecruitments,
              cacPerRiderInr: kNewRiderCacInr,
            ),
            const SizedBox(height: 14),
            _buildEsgImpactGrid(
              avoidedPacks: avoidedPacksPerYear,
              avoidedEwasteKg: avoidedEwasteKg,
              carbonTons: carbonAbatementTons,
            ),
          ],
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

  Widget _buildPerspectiveSelectorBar() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          _buildPerspectiveTab(
            title: 'RIDER RECRUITING',
            icon: Icons.people_outline,
            perspective: FleetRoiPerspective.recruitingSavings,
          ),
          _buildPerspectiveTab(
            title: 'BATTERY HARDWARE',
            icon: Icons.battery_alert_outlined,
            perspective: FleetRoiPerspective.batteryHardware,
          ),
          _buildPerspectiveTab(
            title: 'COMBINED ROI',
            icon: Icons.layers_outlined,
            perspective: FleetRoiPerspective.combined,
          ),
        ],
      ),
    );
  }

  Widget _buildPerspectiveTab({
    required String title,
    required IconData icon,
    required FleetRoiPerspective perspective,
  }) {
    final isSelected = _selectedPerspective == perspective;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPerspective = perspective),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cyan.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: AppTheme.cyan, width: 1.2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? AppTheme.cyan : AppTheme.textMuted,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: AppTheme.labelCaps.copyWith(
                    fontSize: 8.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? AppTheme.cyan : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetRoiHeroCard({
    required double netSavingsInr,
    required double grossSavingsInr,
    required double careFundedInr,
    required String grossLabel,
    required String marginLiftText,
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
                      child: Text(grossLabel, style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.0)),
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
                      child: Text(marginLiftText, style: AppTheme.telemetryNumber.copyWith(fontSize: 14, color: AppTheme.primaryMint)),
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

  // --- RIDER RECRUITMENT & RETENTION PERSPECTIVE WIDGETS ---

  Widget _buildRecruitingImpactGrid({
    required int avoidedRecruits,
    required double cacPerRiderInr,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'RIDER ATTRITION & RECRUITMENT ROI METRICS',
                style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.0),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
              ),
              child: Text('CAC @ ₹${cacPerRiderInr.toInt()}',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.cyan, fontSize: 8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildEsgCard(
                title: 'Avoided New Recruits',
                value: '$avoidedRecruits',
                unit: 'RIDERS / YR',
                color: AppTheme.cyan,
                icon: Icons.person_add_disabled_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildEsgCard(
                title: 'New Rider CAC Saved',
                value: '₹${(cacPerRiderInr / 1000).toStringAsFixed(1)}K',
                unit: 'PER RIDER',
                color: AppTheme.primaryMint,
                icon: Icons.savings_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildEsgCard(
                title: 'Annual Churn Slashed',
                value: '-72%',
                unit: '135% ➔ 38%',
                color: AppTheme.accentAmber,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecruitingCostDecompositionCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NEW RIDER RECRUITMENT COST BREAKDOWN (₹6,500 CAC)',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9)),
              Text('TIER-1/2 QUICK COMMERCE',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.cyan, fontSize: 8)),
            ],
          ),
          const SizedBox(height: 12),
          _buildCacRow(label: 'Sourcing, Job Ads & Referral Bonus', inr: '₹2,200', percent: '34%', progress: 0.34, color: AppTheme.cyan),
          const SizedBox(height: 8),
          _buildCacRow(label: 'Delivery Kit, Uniform & Thermal Bag', inr: '₹1,800', percent: '28%', progress: 0.28, color: AppTheme.primaryMint),
          const SizedBox(height: 8),
          _buildCacRow(label: 'Dark-Store SOP & Shadow Shift Training', inr: '₹1,500', percent: '23%', progress: 0.23, color: AppTheme.accentAmber),
          const SizedBox(height: 8),
          _buildCacRow(label: 'KYC, Background Verification & Banking', inr: '₹1,000', percent: '15%', progress: 0.15, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildCacRow({
    required String label,
    required String inr,
    required String percent,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: AppTheme.bodySmall.copyWith(fontSize: 10, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            Text('$inr ($percent)',
                style: AppTheme.telemetryNumber.copyWith(fontSize: 11, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceMid,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildRiderTenureRetentionCard() {
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
          Text('AVERAGE RIDER RETENTION HORIZON EXTENSION',
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
                      child: Text('4.2 Months', style: AppTheme.telemetryNumber.copyWith(fontSize: 16, color: AppTheme.dangerCrimson)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('CONVENTIONAL (BATTERY BURNOUT)', style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.textMuted)),
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
                      child: Text('14.8 Months', style: AppTheme.telemetryNumber.copyWith(fontSize: 16, color: AppTheme.primaryMint)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('FAIRLOAD (3.52× RETENTION)', style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.primaryMint)),
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
              value: 14.8 / (14.8 + 4.2),
              backgroundColor: AppTheme.dangerCrimson.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryMint),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitingWhyItWorksCard() {
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
              const Icon(Icons.psychology_outlined, color: AppTheme.cyan, size: 14),
              const SizedBox(width: 6),
              Text('HOW FAIRLOAD ELIMINATES RIDER RECRUITMENT CHURN',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.cyan, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• Hidden Churn Vector: Battery capacity fade is the #1 driver of quick-commerce gig quit rates. Overloaded steep climbs destroy pack range, docking daily rider take-home earnings by ₹300-₹500/day.\n• FairLoad Prevention: Equitable payload matching caps cell overheating, while the transparent non-deducted Rider Care Wallet (₹25/trip) pays for proactive servicing.\n• Economic Dividend: Eliminating battery frustration extends rider tenure 3.5×, saving dark stores ₹6,500 in onboarding CAC per retained rider.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, fontSize: 10, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- HARDWARE BATTERY ASSET PERSPECTIVE WIDGETS ---

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

  // --- COMBINED PERSPECTIVE WIDGETS ---

  Widget _buildCombinedSynergyCard({
    required String recruitingNetLakhs,
    required String hardwareNetLakhs,
    required int avoidedRecruits,
    required int avoidedPacks,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DUAL PLATFORM SYNERGIES: HR RECRUITING + HARDWARE ASSET ROI',
              style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 9.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMid,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SAVED RECRUITING CAC', style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.textMuted)),
                      const SizedBox(height: 2),
                      Text('₹$recruitingNetLakhs L', style: AppTheme.telemetryNumber.copyWith(fontSize: 16, color: AppTheme.cyan)),
                      Text('$avoidedRecruits riders retained', style: AppTheme.bodySmall.copyWith(fontSize: 9, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMid,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AVOIDED PACK LOSSES', style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.textMuted)),
                      const SizedBox(height: 2),
                      Text('₹$hardwareNetLakhs L', style: AppTheme.telemetryNumber.copyWith(fontSize: 16, color: AppTheme.primaryMint)),
                      Text('$avoidedPacks pack scraps avoided', style: AppTheme.bodySmall.copyWith(fontSize: 9, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- REUSABLE MINI STAT CARD ---

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
}
