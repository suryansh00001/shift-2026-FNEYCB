import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/models/defense_slip_data.dart';
import '../../core/theme/app_theme.dart';
import '../../services/pdf_slip_service.dart';

class DefenseSlipScreen extends StatelessWidget {
  final DefenseSlipData slipData;

  const DefenseSlipScreen({
    super.key,
    required this.slipData,
  });

  @override
  Widget build(BuildContext context) {
    final trip = slipData.trip;
    final overloadPct = trip.overloadPercentage.toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLowest,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.sensors, color: AppTheme.primaryMint, size: 18),
            const SizedBox(width: 8),
            Text(
              "FAIRLOAD // VNS-CORRIDOR",
              style: AppTheme.labelCaps.copyWith(
                color: AppTheme.primaryMint,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.hudCyan, size: 20),
            tooltip: "Download PDF",
            onPressed: () async {
              final pdfBytes = await PdfSlipService.generateSlipPdf(slipData);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: "FairLoad_Slip_${slipData.slipId}.pdf",
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Official Legal Record Header Card
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
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.primaryMint, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "OFFICIAL LEGAL RECORD",
                        style: AppTheme.labelCaps.copyWith(
                          fontSize: 8.5,
                          color: AppTheme.primaryMint,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "FAIRLOAD VERIFIED DISPUTE RECORD",
                    style: AppTheme.labelCaps.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.hudCrimson, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppTheme.hudCrimson, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  "DISPUTE VERIFIED · POWER LIMITING STALL",
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: AppTheme.hudCrimson, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "REC# 8821",
                          style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: AppTheme.hudCrimson, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "IIT (BHU) Sustainable e-Micromobility Research Engine · Case #VNS-8821",
                    style: TextStyle(fontSize: 9, color: Colors.white38),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 2. Telemetry Dispatch Context Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "TELEMETRY DISPATCH CONTEXT",
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.labelCaps.copyWith(fontSize: 8, color: Colors.white38),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text("GPS LOCK 25.28° N, 82.99° E", style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: AppTheme.hudCyan, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("OPERATOR", style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38)),
                            const SizedBox(height: 2),
                            Text("Rider #VNS-4491", style: AppTheme.labelCaps.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text("Lanka Hub Fleet", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("DARK STORE DISPATCH", style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38)),
                            const SizedBox(height: 2),
                            Text("Blinkit Hub #04", style: AppTheme.labelCaps.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text("Durgakund Facility", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("TRANSIT CORRIDOR", style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38)),
                            const SizedBox(height: 2),
                            Text("Chowkaghat Overbridge", style: AppTheme.labelCaps.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.hudCyan)),
                            Text("4.2% Sustained Grade", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("SLA DELAY ATTRIBUTION", style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38)),
                            const SizedBox(height: 2),
                            Text("4m 15s", style: AppTheme.telemetryDigits.copyWith(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryMint)),
                            Text("Physics Bounded", style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.hudCrimson, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. Hardware Telemetry Audit Grid
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("HARDWARE TELEMETRY AUDIT", style: AppTheme.labelCaps.copyWith(fontSize: 8, color: Colors.white38)),
                      Text("5 SENSORS LOGGED", style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.primaryMint, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildAuditTableRow("PARAMETER", "VEHICLE OEM", "SENSOR VAL", "STATUS", isHeader: true),
                  const Divider(color: AppTheme.borderLight, height: 8),
                  _buildAuditTableRow("Cargo Payload", "65 kg Max", "${trip.assignedCargoKg.toInt()} kg", "OVERLOAD (+$overloadPct%)", valColor: AppTheme.hudCrimson, statusColor: AppTheme.hudCrimson),
                  const Divider(color: AppTheme.borderLight, height: 8),
                  _buildAuditTableRow("Peak Grade", "2.0% Max", "${trip.peakGradePct.toStringAsFixed(1)}%", "Severe Incline", valColor: AppTheme.hudAmber, statusColor: AppTheme.hudAmber),
                  const Divider(color: AppTheme.borderLight, height: 8),
                  _buildAuditTableRow("Power Limiting Stall", "500W Continuous", "Power-Limited Stall\n48% Eff", "Thermal Throttling", valColor: AppTheme.hudCrimson, statusColor: AppTheme.hudCrimson),
                  const Divider(color: AppTheme.borderLight, height: 8),
                  _buildAuditTableRow("Discharge C-Rate", "<1.5C", "${trip.peakCRate.toStringAsFixed(1)}C Surge", "Severe Overpotential", valColor: AppTheme.hudCrimson, statusColor: AppTheme.hudCrimson),
                  const Divider(color: AppTheme.borderLight, height: 8),
                  _buildAuditTableRow("Plating Risk", "> 0V", "TRIGGERED", "Irreversible SEI Wear", valColor: AppTheme.hudCrimson, statusColor: AppTheme.hudCrimson),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 4. Non-Fault Affidavit Box (Indian Contract Act § 56)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.hudCyan.withValues(alpha: 0.5), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gavel, color: AppTheme.hudCyan, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "PHYSICS-BOUNDED NON-FAULT AFFIDAVIT",
                        style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: AppTheme.hudCyan, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "\"${slipData.justificationClause}\"",
                    style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary, height: 1.4, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "INDIAN CONTRACT ACT § 56 (FRUSTRATION)",
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text("AFFIRMED", style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: AppTheme.primaryMint, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 5. Financial Arbitrage Exposure
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.hudAmber.withValues(alpha: 0.4)),
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
                            const Icon(Icons.currency_rupee, color: AppTheme.hudAmber, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "FINANCIAL ARBITRAGE EXPOSURE",
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.labelCaps.copyWith(fontSize: 8.0, color: AppTheme.hudAmber, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.hudAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                        child: Text("STORE LIABILITY", style: AppTheme.labelCaps.copyWith(fontSize: 7.5, color: AppTheme.hudAmber, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildArbitrageStat("Order Payout", "₹${trip.orderPayoutInr.toStringAsFixed(2)}", Colors.white),
                      Container(width: 1, height: 24, color: AppTheme.borderLight),
                      _buildArbitrageStat("Asset Deprec.", "₹${trip.totalBatteryWearInr.toStringAsFixed(2)}", AppTheme.hudAmber),
                      Container(width: 1, height: 24, color: AppTheme.borderLight),
                      _buildArbitrageStat("Net Rider Loss", "₹${trip.netEarningsInr.toStringAsFixed(2)}", AppTheme.hudCrimson),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 6. Cryptographic Sensor Enclave
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.qr_code, color: AppTheme.primaryMint, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_outline, size: 10, color: AppTheme.primaryMint),
                            const SizedBox(width: 4),
                            Text("IIT-BHU SENSOR ENCLAVE", style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.primaryMint, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            slipData.verificationHash,
                            style: AppTheme.telemetryDigits.copyWith(fontSize: 9.0, color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text("• SHA-256 Verified Ledger Block", style: TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 7. Hero Primary Button: Share via WhatsApp
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMint,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(
                  "Share via WhatsApp",
                  style: AppTheme.labelCaps.copyWith(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onPressed: () async {
                  final pdfBytes = await PdfSlipService.generateSlipPdf(slipData);
                  await Printing.sharePdf(
                    bytes: pdfBytes,
                    filename: "FairLoad_Slip_${slipData.slipId}.pdf",
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildAuditTableRow(String col1, String col2, String col3, String col4, {bool isHeader = false, Color? valColor, Color? statusColor}) {
    final style = isHeader
        ? AppTheme.labelCaps.copyWith(fontSize: 7.5, color: Colors.white38)
        : const TextStyle(fontSize: 8.5, color: Colors.white70);

    return Row(
      children: [
        Expanded(flex: 3, child: Text(col1, overflow: TextOverflow.ellipsis, style: style)),
        Expanded(flex: 3, child: Text(col2, overflow: TextOverflow.ellipsis, style: style)),
        Expanded(flex: 3, child: Text(col3, overflow: TextOverflow.ellipsis, style: isHeader ? style : AppTheme.telemetryDigits.copyWith(fontSize: 8.5, fontWeight: FontWeight.w800, color: valColor ?? Colors.white))),
        Expanded(flex: 4, child: Text(col4, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: isHeader ? style : AppTheme.labelCaps.copyWith(fontSize: 7.5, fontWeight: FontWeight.w900, color: statusColor ?? Colors.white))),
      ],
    );
  }

  static Widget _buildArbitrageStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelCaps.copyWith(fontSize: 8, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.telemetryDigits.copyWith(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
