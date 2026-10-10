import 'package:flutter/foundation.dart';
import '../../core/models/trip_record.dart';
import '../../engine/rupee_engine.dart';

class ShiftLedgerProvider extends ChangeNotifier {
  final List<TripRecord> _completedTrips = [];
  double _cumulativeGrossEarnings = 0.0;
  double _cumulativeBatteryWear = 0.0;

  List<TripRecord> get completedTrips => _completedTrips;

  ShiftLedgerSummary get summary {
    if (_completedTrips.isEmpty) {
      // Default to demo shift summary for live pitch presentation
      return RupeeEngine.getDemoShiftSummary();
    }

    return RupeeEngine.computeShiftLedger(
      completedTrips: _completedTrips.length,
      totalGrossEarnings: _cumulativeGrossEarnings,
      totalBatteryWear: _cumulativeBatteryWear,
    );
  }

  void addTrip(TripRecord trip) {
    _completedTrips.add(trip);
    _cumulativeGrossEarnings += trip.orderPayoutInr;
    _cumulativeBatteryWear += trip.totalBatteryWearInr;
    notifyListeners();
  }

  void clearTrips() {
    _completedTrips.clear();
    _cumulativeGrossEarnings = 0.0;
    _cumulativeBatteryWear = 0.0;
    notifyListeners();
  }
}
