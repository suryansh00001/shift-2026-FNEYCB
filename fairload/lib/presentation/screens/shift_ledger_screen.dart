import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/shift_ledger_provider.dart';

class ShiftLedgerScreen extends StatelessWidget {
  const ShiftLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShiftLedgerProvider>(
      builder: (context, ledger, child) {
        final summary = ledger.summary;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceLowest,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ALGORITHMIC EXPLOITATION LEDGER",
                  style: AppTheme.labelCaps.copyWith(
                    color: AppTheme.primaryMint,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "Forensic Asset Extraction Ledger",
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Card: Shift Equity Extraction
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.hudCrimson.withValues(alpha: 0.6), width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "SHIFT EQUITY EXTRACTION",
                            style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.hudCrimson.withValues(alpha: 0.15),
                              border: Border.all(color: AppTheme.hudCrimson, width: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "EQUITY EXTRACTION ALERT",
                              style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.hudCrimson, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _buildLedgerMetric(
                              "DELIVERIES",
                              "${summary.totalDeliveries}",
                              AppTheme.textPrimary,
                            ),
                          ),
                          Expanded(
                            child: _buildLedgerMetric(
                              "GROSS PAYOUT",
                              "+₹${summary.grossEarningsInr.toStringAsFixed(0)}",
                              AppTheme.primaryMint,
                            ),
                          ),
                          Expanded(
                            child: _buildLedgerMetric(
                              "BATTERY WEAR",
                              "-₹${summary.totalBatteryWearInr.toStringAsFixed(0)}",
                              AppTheme.hudCrimson,
                            ),
                          ),
                          Expanded(
                            child: _buildLedgerMetric(
                              "TRUE NET",
                              "₹${summary.netRiderMarginInr.toStringAsFixed(0)}",
                              summary.netRiderMarginInr < 0 ? AppTheme.hudCrimson : AppTheme.primaryMint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.borderLight),
                      const SizedBox(height: 8),

                      // Pack Lifespan Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Projected Pack Lifespan Under This Load:",
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white54),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${summary.estimatedPackLifeMonths.toStringAsFixed(1)} Mo / 24 Mo OEM",
                            style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: AppTheme.hudCrimson, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (summary.estimatedPackLifeMonths / 24.0).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppTheme.surfaceLow,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.hudCrimson),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. The Uncompensated Platform Subsidy Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.hudAmber.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.hudAmber),
                          const SizedBox(width: 6),
                          Text(
                            "UNCOMPENSATED ASSET SUBSIDY",
                            style: AppTheme.labelCaps.copyWith(fontSize: 9, color: AppTheme.hudAmber, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "The platform extracted ₹${summary.platformSubsidyExtractedInr.toStringAsFixed(2)} of uncompensated vehicle equity in this shift alone. Riders are financing 10-minute grocery delivery speed with their personal battery replacement funds.",
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Monthly Rider Balance Sheet (Estimated)
                Text(
                  "MONTHLY GIG WORKER BALANCE SHEET (ESTIMATED)",
                  style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      _buildBalanceRow("Monthly Delivery Earnings (300 orders @ ₹25)", "₹ 7,500.00", AppTheme.primaryMint),
                      const Divider(color: AppTheme.borderLight, height: 1),
                      _buildBalanceRow("Vehicle Lease / Battery Swap Rent", "- ₹ 3,800.00", AppTheme.textSecondary),
                      const Divider(color: AppTheme.borderLight, height: 1),
                      _buildBalanceRow("Accelerated Pack Amortization (4-month death)", "- ₹ 8,000.00", AppTheme.hudCrimson),
                      const Divider(color: AppTheme.borderLight, height: 1),
                      _buildBalanceRow("SLA Docking Penalties (Estimated 6 strikes)", "- ₹ 450.00", AppTheme.hudCrimson),
                      const Divider(color: AppTheme.borderLight, height: 1),
                      _buildBalanceRow("TRUE NET GIG WORKER INCOME", "- ₹ 4,750.00", AppTheme.hudCrimson, isBold: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildLedgerMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38)),
        const SizedBox(height: 3),
        Text(value, style: AppTheme.telemetryDigits.copyWith(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  static Widget _buildBalanceRow(String title, String amount, Color amountColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: isBold ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            amount,
            style: AppTheme.telemetryDigits.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
