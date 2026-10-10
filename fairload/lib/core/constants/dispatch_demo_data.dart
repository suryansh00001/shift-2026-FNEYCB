import 'battery_specs.dart';
import 'vehicle_specs.dart';
import '../models/dispatch_models.dart';

/// Deterministic, reproducible test dataset for Lanka Dark Store #102, Varanasi
class DispatchDemoData {
  static const String darkStoreName = 'Lanka Dark Store #102';
  static const String darkStoreLocation = 'Durgakund-Lanka Rd, Varanasi';

  /// 6 Heterogeneous delivery fleet riders with distinct chassis, chemistries, and operational states
  static List<FleetRider> get sampleRiders => [
        FleetRider(
          id: 'RDR-01',
          name: 'Ramesh Yadav',
          currentLocation: 'Dark Store Bay 1 (Front)',
          isAvailable: true,
          vehicleProfile: VehicleSpecs.vehicleProfiles[0], // Cargo E-Cycle (500W, 65 kg payload)
          batteryProfile: BatterySpecs.profiles[0], // 48V 20Ah NMC (Sensitive >45°C)
          currentSocPercent: 68.0,
          currentTempCelsius: 47.4, // Warning heat from previous climb!
          shiftHoursActive: 5.0,
          completedDeliveries: 12,
          accumulatedBenefitInr: 218.00,
        ),
        FleetRider(
          id: 'RDR-02',
          name: 'Suresh Kumar',
          currentLocation: 'Dark Store Bay 2',
          isAvailable: true,
          vehicleProfile: VehicleSpecs.vehicleProfiles[0], // Cargo E-Cycle (500W, 65 kg payload)
          batteryProfile: BatterySpecs.profiles[2], // 51.2V 30Ah LFP (Thermal resilient up to 55°C)
          currentSocPercent: 86.0,
          currentTempCelsius: 37.2,
          shiftHoursActive: 2.5,
          completedDeliveries: 7,
          accumulatedBenefitInr: 142.50,
        ),
        FleetRider(
          id: 'RDR-03',
          name: 'Pooja Verma',
          currentLocation: 'Dark Store Bay 3',
          isAvailable: true,
          vehicleProfile: VehicleSpecs.vehicleProfiles[1], // Heavy Trike (750W, 110 kg payload)
          batteryProfile: BatterySpecs.profiles[1], // 48V 26Ah NMC (1248 Wh)
          currentSocPercent: 92.0,
          currentTempCelsius: 38.1,
          shiftHoursActive: 1.5,
          completedDeliveries: 4,
          accumulatedBenefitInr: 88.00,
        ),
        FleetRider(
          id: 'RDR-04',
          name: 'Amit Patel',
          currentLocation: 'Dark Store Bay 4',
          isAvailable: true,
          vehicleProfile: VehicleSpecs.vehicleProfiles[2], // City Pedelec (250W, 35 kg payload limit)
          batteryProfile: BatterySpecs.profiles[3], // 36V 15Ah NMC (Budget commuter pack)
          currentSocPercent: 74.0,
          currentTempCelsius: 36.8,
          shiftHoursActive: 3.0,
          completedDeliveries: 6,
          accumulatedBenefitInr: 64.00,
        ),
        FleetRider(
          id: 'RDR-05',
          name: 'Deepak Singh',
          currentLocation: 'Dark Store Bay 5',
          isAvailable: true,
          vehicleProfile: VehicleSpecs.vehicleProfiles[0], // Cargo E-Cycle (500W)
          batteryProfile: BatterySpecs.profiles[0], // 48V 20Ah NMC
          currentSocPercent: 21.0, // Low SOC near minimum reserve!
          currentTempCelsius: 42.0,
          shiftHoursActive: 6.8,
          completedDeliveries: 16,
          accumulatedBenefitInr: 310.50,
        ),
        FleetRider(
          id: 'RDR-06',
          name: 'Vikas Dubey',
          currentLocation: 'Dark Store Bay 6',
          isAvailable: true,
          vehicleProfile: VehicleSpecs.vehicleProfiles[0], // Cargo E-Cycle (500W)
          batteryProfile: BatterySpecs.profiles[0], // 48V 20Ah NMC
          currentSocPercent: 94.0,
          currentTempCelsius: 35.5,
          shiftHoursActive: 0.8,
          completedDeliveries: 2,
          accumulatedBenefitInr: 32.00,
        ),
      ];

  /// Realistic incoming delivery orders across Varanasi topographies
  static List<DispatchOrder> get sampleOrders => [
        const DispatchOrder(
          id: 'ORD-501',
          customerName: 'Ananya Sharma',
          pickupLocation: darkStoreName,
          deliveryLocation: 'Chowkaghat Market Complex',
          weightKg: 28.5, // Heavy payload
          deadlineMinutes: 18,
          priority: 'urgent',
          corridorId: 'chowkaghat_flyover',
          corridorName: 'Chowkaghat Flyover Ramp',
          distanceKm: 3.2,
          inclineGradePercent: 4.2, // Sustained steep incline!
        ),
        const DispatchOrder(
          id: 'ORD-502',
          customerName: 'Rohit Keshari',
          pickupLocation: darkStoreName,
          deliveryLocation: 'Cantt Railway Overbridge North',
          weightKg: 24.0,
          deadlineMinutes: 20,
          priority: 'urgent',
          corridorId: 'cantt_overbridge',
          corridorName: 'Cantt Station Overbridge',
          distanceKm: 3.8,
          inclineGradePercent: 3.8,
        ),
        const DispatchOrder(
          id: 'ORD-503',
          customerName: 'Dr. Mukhopadhyay',
          pickupLocation: darkStoreName,
          deliveryLocation: 'BHU Vishwanath Temple Hostels',
          weightKg: 8.5, // Light payload
          deadlineMinutes: 25,
          priority: 'standard',
          corridorId: 'lanka_gallis',
          corridorName: 'Lanka-BHU Internal Roads',
          distanceKm: 1.8,
          inclineGradePercent: 0.2, // Flat
        ),
        const DispatchOrder(
          id: 'ORD-505',
          customerName: 'Kashi Sweets & Wholesale',
          pickupLocation: darkStoreName,
          deliveryLocation: 'Godowlia Chowk Bulk Drop',
          weightKg: 44.0, // High payload requires 750W Trike!
          deadlineMinutes: 35,
          priority: 'bulk',
          corridorId: 'godowlia_gallis',
          corridorName: 'Godowlia Heritage Spine',
          distanceKm: 3.5,
          inclineGradePercent: 1.1,
        ),
        const DispatchOrder(
          id: 'ORD-504',
          customerName: 'Gaurav Agrawal',
          pickupLocation: darkStoreName,
          deliveryLocation: 'Sigra Stadium Road',
          weightKg: 14.0,
          deadlineMinutes: 22,
          priority: 'standard',
          corridorId: 'sigra_main',
          corridorName: 'Sigra-Rathyatra Corridor',
          distanceKm: 2.6,
          inclineGradePercent: 0.8,
        ),
        const DispatchOrder(
          id: 'ORD-506',
          customerName: 'Sneha Srivastava',
          pickupLocation: darkStoreName,
          deliveryLocation: 'Assi Ghat Riverfront Cafes',
          weightKg: 11.0,
          deadlineMinutes: 16,
          priority: 'urgent',
          corridorId: 'assi_gallis',
          corridorName: 'Assi Cobblestone Lanes',
          distanceKm: 2.1,
          inclineGradePercent: 0.3,
        ),
      ];
}
