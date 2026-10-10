import 'trip_record.dart';

class DefenseSlipData {
  final String slipId;
  final String authorityHeader;
  final String riderName;
  final String riderPhone;
  final String darkStoreName;
  final String corridorName;
  final DateTime issueTimestamp;
  final TripRecord trip;
  final String slaDelayMinutes;
  final String justificationClause;
  final String verificationHash;

  const DefenseSlipData({
    required this.slipId,
    required this.authorityHeader,
    required this.riderName,
    required this.riderPhone,
    required this.darkStoreName,
    required this.corridorName,
    required this.issueTimestamp,
    required this.trip,
    required this.slaDelayMinutes,
    required this.justificationClause,
    required this.verificationHash,
  });

  static DefenseSlipData fromTrip({
    required TripRecord trip,
    String riderName = 'Rider #VNS-4491 (Lanka Hub)',
    String riderPhone = '+91 98390 XXXXX',
    String darkStoreName = 'Blinkit Lanka Dark Store #04',
  }) {
    final overloadPct = trip.overloadPercentage.toStringAsFixed(0);
    final peakGrade = trip.peakGradePct.toStringAsFixed(1);
    final peakC = trip.peakCRate.toStringAsFixed(1);
    final peakTemp = trip.peakCellTempCelsius.toStringAsFixed(1);

    final clause = "Vehicle speed on the ${trip.routeName} corridor was physically constrained by BLDC hub motor power-limiting stall under a ${trip.assignedCargoKg.toStringAsFixed(0)} kg cargo load ($overloadPct% above manufacturer rated ceiling). On a $peakGrade% grade, maintaining higher velocity would exceed rated thermal limits (measured peak: $peakTemp°C at ${peakC}C discharge) and cause catastrophic BMS thermal cut-off. The delivery delay was structurally unavoidable due to dispatch payload over-assignment and does not constitute rider negligence.";

    final hash = "FL-VNS-${trip.startTime.millisecondsSinceEpoch.toRadixString(16).toUpperCase()}-${trip.assignedCargoKg.toInt()}KG";

    return DefenseSlipData(
      slipId: "FL-SLIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      authorityHeader: "FAIRLOAD VERIFIED DISPUTE RECORD · IIT (BHU) MICROMOBILITY RESEARCH ENGINE",
      riderName: riderName,
      riderPhone: riderPhone,
      darkStoreName: darkStoreName,
      corridorName: trip.routeName,
      issueTimestamp: DateTime.now(),
      trip: trip,
      slaDelayMinutes: "4m 15s",
      justificationClause: clause,
      verificationHash: hash,
    );
  }
}
