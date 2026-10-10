import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/neuropace_advisor.dart';

class DynamicPacingBanner extends StatelessWidget {
  final PacingRecommendation pacing;

  const DynamicPacingBanner({
    super.key,
    required this.pacing,
  });

  @override
  Widget build(BuildContext context) {
    final isAlert = pacing.isThermalAlertActive;
    final accentColor = isAlert ? AppTheme.hudCrimson : AppTheme.hudCyan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        border: Border.all(color: accentColor.withValues(alpha: isAlert ? 0.8 : 0.4), width: 1.2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isAlert
            ? [
                BoxShadow(
                  color: AppTheme.hudCrimson.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAlert ? Icons.warning_amber_rounded : Icons.assistant_navigation,
                color: accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isAlert ? "NEUROPACE INTERVENTION" : "NEUROPACE PREDICTIVE ADVISORY",
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps.copyWith(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (pacing.projectedSavingsInr > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMint.withValues(alpha: 0.15),
                    border: Border.all(color: AppTheme.primaryMint, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "SAVES ₹${pacing.projectedSavingsInr.toStringAsFixed(1)}",
                    style: AppTheme.labelCaps.copyWith(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryMint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pacing.advisoryMessage,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: isAlert ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
