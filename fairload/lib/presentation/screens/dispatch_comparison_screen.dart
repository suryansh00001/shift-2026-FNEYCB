import 'package:flutter/material.dart';
import '../../core/models/dispatch_models.dart';
import '../../core/theme/app_theme.dart';

/// Dispatch Comparison Lab: Side-by-side verification of Conventional vs FairLoad Physics-Informed dispatch
class DispatchComparisonScreen extends StatefulWidget {
  final FleetDispatchComparison comparison;

  const DispatchComparisonScreen({super.key, required this.comparison});

  @override
  State<DispatchComparisonScreen> createState() => _DispatchComparisonScreenState();
}

class _DispatchComparisonScreenState extends State<DispatchComparisonScreen> {
  bool _showFairload = true;

  @override
  Widget build(BuildContext context) {
    final comparison = widget.comparison;
    final activePlan = _showFairload ? comparison.fairloadPlan : comparison.baselinePlan;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLowest,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'DISPATCH COMPARISON LAB',
                style: AppTheme.headlineMedium.copyWith(fontSize: 14, letterSpacing: 0.8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'CONVENTIONAL VS. FAIRLOAD PHYSICS',
              style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 8.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildImpactComparisonBanner(comparison),
          _buildModeToggle(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: activePlan.assignments.length,
              itemBuilder: (context, index) {
                final assignment = activePlan.assignments[index];
                return _buildAssignmentCard(assignment);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactComparisonBanner(FleetDispatchComparison comparison) {
    final wearSavings = comparison.wearSavingsInr;
    final percentReduction = comparison.wearReductionPercent;
    final highStressAvoided = comparison.highStressTripsAvoided;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AVOIDABLE BATTERY WEAR SAVED',
                        style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.5)),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('₹${wearSavings.toStringAsFixed(2)}',
                              style: AppTheme.telemetryNumber.copyWith(fontSize: 22, color: AppTheme.primaryMint)),
                          const SizedBox(width: 6),
                          Text('(${percentReduction.toStringAsFixed(0)}% REDUCTION)',
                              style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryMint),
                ),
                child: Column(
                  children: [
                    Text('$highStressAvoided',
                        style: AppTheme.telemetryNumber.copyWith(fontSize: 17, color: AppTheme.primaryMint)),
                    Text('STRESS AVOIDED',
                        style: AppTheme.labelCaps.copyWith(fontSize: 7.0, color: AppTheme.primaryMint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniComparisonMetric(
                'CONVENTIONAL',
                '₹${comparison.baselinePlan.totalFleetWearInr.toStringAsFixed(2)}',
                AppTheme.dangerCrimson,
              ),
              _buildMiniComparisonMetric(
                'FAIRLOAD',
                '₹${comparison.fairloadPlan.totalFleetWearInr.toStringAsFixed(2)}',
                AppTheme.primaryMint,
              ),
              _buildMiniComparisonMetric(
                'CARE FUNDED',
                '₹${comparison.fairloadPlan.totalRiderBenefitsFundedInr.toStringAsFixed(2)}',
                AppTheme.cyan,
              ),
              _buildMiniComparisonMetric(
                'ANNUAL ROI',
                '₹${(comparison.projectedAnnualFleetSavingsInr / 100000).toStringAsFixed(1)}L',
                AppTheme.accentAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniComparisonMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTheme.telemetryNumber.copyWith(fontSize: 13, color: color)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showFairload = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _showFairload ? AppTheme.primaryMint : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    'FAIRLOAD PLAN (PHYSICS-INFORMED)',
                    style: AppTheme.labelCaps.copyWith(
                      color: _showFairload ? Colors.black : AppTheme.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showFairload = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !_showFairload ? AppTheme.dangerCrimson : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    'CONVENTIONAL (PROXIMITY ONLY)',
                    style: AppTheme.labelCaps.copyWith(
                      color: !_showFairload ? Colors.white : AppTheme.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentResult a) {
    final isFairload = _showFairload;
    final isCritical = a.isPlatingRisk || a.peakCRate > 2.0 || a.estimatedTempCelsius > 48.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical
              ? AppTheme.dangerCrimson.withValues(alpha: 0.45)
              : (isFairload ? AppTheme.borderLight : AppTheme.accentAmber.withValues(alpha: 0.3)),
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
                      Icons.account_circle,
                      color: isFairload ? AppTheme.primaryMint : AppTheme.accentAmber,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        a.rider.name,
                        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${a.rider.batteryProfile.chemistryLabel})',
                      style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCritical
                      ? AppTheme.dangerCrimson.withValues(alpha: 0.2)
                      : AppTheme.surfaceMid,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCritical ? 'CRITICAL STRESS' : (a.isWithinDeadline ? 'ON-TIME SLA' : 'DELAY RISK'),
                  style: AppTheme.labelCaps.copyWith(
                    fontSize: 8.5,
                    color: isCritical ? AppTheme.dangerCrimson : AppTheme.primaryMint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_forward, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${a.order.id} · ${a.order.deliveryLocation} (${a.order.weightKg.toStringAsFixed(1)} kg)',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${a.order.inclineGradePercent}% grade',
                style: AppTheme.labelCaps.copyWith(
                  color: a.order.hasSteepIncline ? AppTheme.accentAmber : AppTheme.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMid,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _buildTelemetryPill('POWER', '${a.electricalPowerWatts.toInt()}W', AppTheme.textPrimary),
                _buildTelemetryPill('C-RATE', '${a.peakCRate.toStringAsFixed(2)}C',
                    a.peakCRate > 1.8 ? AppTheme.dangerCrimson : AppTheme.primaryMint),
                _buildTelemetryPill('PACK TEMP', '${a.estimatedTempCelsius.toStringAsFixed(1)}°C',
                    a.estimatedTempCelsius > 48.0 ? AppTheme.dangerCrimson : AppTheme.textPrimary),
                _buildTelemetryPill('TRIP WEAR', '₹${a.tripWearCostInr.toStringAsFixed(2)}',
                    a.tripWearCostInr > 8.0 ? AppTheme.dangerCrimson : AppTheme.primaryMint),
                _buildTelemetryPill('CARE CREDIT', '₹${a.riderCareBenefitInr.toStringAsFixed(2)}', AppTheme.cyan),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  a.justification,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryPill(String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTheme.telemetryNumber.copyWith(fontSize: 12.0, color: color)),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppTheme.labelCaps.copyWith(fontSize: 7.0, color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }
}
