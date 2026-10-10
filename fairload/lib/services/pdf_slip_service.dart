import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/models/defense_slip_data.dart';

class PdfSlipService {
  /// Generates the official Overload Defense Slip PDF as raw bytes
  static Future<Uint8List> generateSlipPdf(DefenseSlipData slip) async {
    final pdf = pw.Document(
      title: "FairLoad_Dispute_Slip_${slip.slipId}",
      author: "IIT (BHU) Micromobility Research Engine",
    );

    pw.Font fontRegular = pw.Font.helvetica();
    pw.Font fontBold = pw.Font.helveticaBold();
    pw.Font fontMono = pw.Font.courier();

    try {
      fontRegular = await PdfGoogleFonts.interRegular();
      fontBold = await PdfGoogleFonts.interBold();
      fontMono = await PdfGoogleFonts.jetBrainsMonoRegular();
    } catch (_) {
      // Fallback to standard PDF fonts offline or under CORS
    }

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(slip.issueTimestamp);
    final overloadPct = slip.trip.overloadPercentage.toStringAsFixed(0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Top Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey900,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "FAIRLOAD · VEHICLE TELEMETRY & SLA DEFENSE SLIP",
                          style: pw.TextStyle(
                            font: fontBold,
                            color: PdfColors.white,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "IIT (BHU) Sustainable e-Micromobility Research Engine · Case #VNS-8821",
                          style: pw.TextStyle(
                            font: fontRegular,
                            color: PdfColors.grey400,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red800,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        "DISPUTE VERIFIED",
                        style: pw.TextStyle(
                          font: fontBold,
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 2. Metadata Grid
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow("Slip Reference:", slip.slipId, fontBold, fontRegular),
                      _buildMetaRow("Issue Timestamp:", dateStr, fontBold, fontRegular),
                      _buildMetaRow("Dispatch Dark Store:", slip.darkStoreName, fontBold, fontRegular),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow("Rider Identity:", slip.riderName, fontBold, fontRegular),
                      _buildMetaRow("Assigned Corridor:", slip.corridorName, fontBold, fontRegular),
                      _buildMetaRow("SLA Transit Delay:", "${slip.slaDelayMinutes} (Physics Bounded)", fontBold, fontRegular),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 10),

              // 3. Telemetry & Overload Table
              pw.Text(
                "1. MECHANICAL LOAD & DISPATCH AUDIT",
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell("Parameter", isHeader: true, font: fontBold),
                      _buildTableCell("Manufacturer Rating", isHeader: true, font: fontBold),
                      _buildTableCell("Measured Value", isHeader: true, font: fontBold),
                      _buildTableCell("Audit Status", isHeader: true, font: fontBold),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell("Assigned Cargo Payload", font: fontRegular),
                      _buildTableCell("${slip.trip.ratedCargoLimitKg.toStringAsFixed(0)} kg max", font: fontRegular),
                      _buildTableCell("${slip.trip.assignedCargoKg.toStringAsFixed(0)} kg", font: fontBold),
                      _buildTableCell("OVERLOAD (+$overloadPct%)", font: fontBold, color: PdfColors.red700),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell("Peak Corridor Incline", font: fontRegular),
                      _buildTableCell("2.0% Grade ceiling", font: fontRegular),
                      _buildTableCell("${slip.trip.peakGradePct.toStringAsFixed(1)}% Grade", font: fontBold),
                      _buildTableCell("Excess Incline", font: fontRegular),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell("Power Limiting Regime", font: fontRegular),
                      _buildTableCell("500W Continuous", font: fontRegular),
                      _buildTableCell("Power-Limiting Stall (48% Eff)", font: fontBold),
                      _buildTableCell("Thermal Throttling", font: fontBold, color: PdfColors.red700),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 4. Electrochemical Battery Degradation Record
              pw.Text(
                "2. ELECTROCHEMICAL CELL DAMAGE RECORD (WMG / SIMLIONICS MODEL)",
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell("Metric", isHeader: true, font: fontBold),
                      _buildTableCell("Safe Operating Limit", isHeader: true, font: fontBold),
                      _buildTableCell("Measured Peak", isHeader: true, font: fontBold),
                      _buildTableCell("Electrochemical Impact", isHeader: true, font: fontBold),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell("Battery Discharge C-Rate", font: fontRegular),
                      _buildTableCell("< 1.5 C Continuous", font: fontRegular),
                      _buildTableCell("${slip.trip.peakCRate.toStringAsFixed(1)} C Surge", font: fontBold),
                      _buildTableCell(slip.trip.peakCRate > 2.5 ? "Severe Overpotential" : "Elevated", font: fontRegular, color: PdfColors.red700),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell("Battery Cell Surface Temp", font: fontRegular),
                      _buildTableCell("< 45.0 °C", font: fontRegular),
                      _buildTableCell("${slip.trip.peakCellTempCelsius.toStringAsFixed(1)} °C", font: fontBold),
                      _buildTableCell("Rapid SEI Layer Growth", font: fontRegular, color: PdfColors.red700),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell("Lithium Plating Danger", font: fontRegular),
                      _buildTableCell("Negative Overpotential > 0V", font: fontRegular),
                      _buildTableCell(slip.trip.hasPlatingDamage ? "TRIGGERED (Active)" : "Borderline", font: fontBold),
                      _buildTableCell("Irreversible Capacity Loss", font: fontBold, color: PdfColors.red700),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 5. Economic Arbitrage Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber400, width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "ECONOMIC ARBITRAGE BREAKDOWN:",
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.amber900),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "Delivery Order Fee Earned: Rs. ${slip.trip.orderPayoutInr.toStringAsFixed(2)}  |  Realized Battery Pack Wear: Rs. ${slip.trip.totalBatteryWearInr.toStringAsFixed(2)}",
                          style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey900),
                        ),
                      ],
                    ),
                    pw.Text(
                      "NET RIDER MARGIN: Rs. ${slip.trip.netEarningsInr.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: slip.trip.netEarningsInr < 0 ? PdfColors.red800 : PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 6. SLA Defense Justification Clause
              pw.Text(
                "3. STATUTORY SLA DELAY DEFENSE CLAUSE",
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  slip.justificationClause,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8.5,
                    lineSpacing: 1.3,
                    color: PdfColors.grey900,
                  ),
                ),
              ),

              pw.Spacer(),

              // 7. Footer & Verification Hash
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Cryptographic Verification Hash:",
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        slip.verificationHash,
                        style: pw.TextStyle(font: fontMono, fontSize: 8, color: PdfColors.grey900),
                      ),
                    ],
                  ),
                  pw.Text(
                    "Generated via FairLoad Mobile PWA · IIT (BHU) Varanasi · Content CC-BY-4.0",
                    style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetaRow(String label, String value, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Text("$label ", style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
    required pw.Font font,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          color: color ?? (isHeader ? PdfColors.grey900 : PdfColors.grey800),
        ),
      ),
    );
  }
}
