/// Electrochemical battery chemistry types
enum BatteryChemistry {
  nmc, // Nickel Manganese Cobalt (Higher energy density, vulnerable to high C-rate plating & heat > 45°C)
  lfp, // Lithium Iron Phosphate (Higher thermal stability up to 55°C, 2x cycle life, heavier)
}

/// Rich Battery Pack Specification & Degradation Model Profile
class BatteryProfile {
  final String id;
  final String name;
  final String shortLabel;
  final BatteryChemistry chemistry;
  final double nominalVoltage; // Volts
  final double nominalCapacityAh; // Ah
  final double internalResistanceOhms; // Pack internal resistance
  final double packMassKg; // kg
  final double specificHeatCapacityCp; // J / (kg * K)
  final double convectiveHeatTransferHA; // W / K
  final double cRateSafeThreshold; // C
  final double cRateWarningThreshold; // C
  final double cRateCriticalThreshold; // C
  final double tempSafeThreshold; // °C
  final double tempWarningThreshold; // °C
  final double tempCriticalThreshold; // °C
  final double packReplacementCostInr; // ₹ replacement cost
  final double ratedCycleLife; // cycles at nominal discharge
  final String description;

  const BatteryProfile({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.chemistry,
    required this.nominalVoltage,
    required this.nominalCapacityAh,
    required this.internalResistanceOhms,
    required this.packMassKg,
    this.specificHeatCapacityCp = 850.0,
    this.convectiveHeatTransferHA = 1.35,
    required this.cRateSafeThreshold,
    required this.cRateWarningThreshold,
    required this.cRateCriticalThreshold,
    required this.tempSafeThreshold,
    required this.tempWarningThreshold,
    required this.tempCriticalThreshold,
    required this.packReplacementCostInr,
    required this.ratedCycleLife,
    required this.description,
  });

  double get totalNominalEnergyWh => nominalVoltage * nominalCapacityAh;
  double get baseCostPerCycleInr => packReplacementCostInr / ratedCycleLife;

  String get chemistryLabel => chemistry == BatteryChemistry.lfp ? 'LFP' : 'NMC';
}

/// Electrochemical battery constants and economic degradation rates
/// Grounded in WMG (Warwick) and SimLionics literature on lithium-ion cell degradation
class BatterySpecs {
  // Battery Preset Profiles
  static const List<BatteryProfile> profiles = [
    BatteryProfile(
      id: 'std_48v_20ah_nmc',
      name: '48V 20Ah NMC (Standard Delivery)',
      shortLabel: '48V 20Ah NMC',
      chemistry: BatteryChemistry.nmc,
      nominalVoltage: 48.0,
      nominalCapacityAh: 20.0,
      internalResistanceOhms: 0.045,
      packMassKg: 6.2,
      cRateSafeThreshold: 1.5,
      cRateWarningThreshold: 2.5,
      cRateCriticalThreshold: 3.5,
      tempSafeThreshold: 42.0,
      tempWarningThreshold: 48.0,
      tempCriticalThreshold: 54.0,
      packReplacementCostInr: 32000.0,
      ratedCycleLife: 1000.0,
      description: 'Standard quick-commerce delivery pack. High volumetric energy, sensitive to high ambient heat & C-rate plating.',
    ),
    BatteryProfile(
      id: 'heavy_48v_26ah_nmc',
      name: '48V 26Ah NMC (Heavy Long-Range)',
      shortLabel: '48V 26Ah NMC',
      chemistry: BatteryChemistry.nmc,
      nominalVoltage: 48.0,
      nominalCapacityAh: 26.0,
      internalResistanceOhms: 0.038,
      packMassKg: 7.8,
      cRateSafeThreshold: 1.5,
      cRateWarningThreshold: 2.5,
      cRateCriticalThreshold: 3.5,
      tempSafeThreshold: 42.0,
      tempWarningThreshold: 48.0,
      tempCriticalThreshold: 54.0,
      packReplacementCostInr: 39000.0,
      ratedCycleLife: 1000.0,
      description: 'Larger NMC pack for high-payload couriers. Lower C-rate stress under equivalent motor power draws.',
    ),
    BatteryProfile(
      id: 'swappable_51v_30ah_lfp',
      name: '51.2V 30Ah LFP (Commercial Swappable)',
      shortLabel: '51.2V 30Ah LFP',
      chemistry: BatteryChemistry.lfp,
      nominalVoltage: 51.2,
      nominalCapacityAh: 30.0,
      internalResistanceOhms: 0.040,
      packMassKg: 12.5,
      cRateSafeThreshold: 2.0,
      cRateWarningThreshold: 3.0,
      cRateCriticalThreshold: 4.2,
      tempSafeThreshold: 46.0,
      tempWarningThreshold: 52.0,
      tempCriticalThreshold: 58.0,
      packReplacementCostInr: 45000.0,
      ratedCycleLife: 2000.0,
      description: 'Heavy LFP chemistry with exceptional thermal resilience up to 55°C and 2000 cycle lifespan.',
    ),
    BatteryProfile(
      id: 'budget_36v_15ah_nmc',
      name: '36V 15Ah NMC (Lightweight Pedelec)',
      shortLabel: '36V 15Ah NMC',
      chemistry: BatteryChemistry.nmc,
      nominalVoltage: 36.0,
      nominalCapacityAh: 15.0,
      internalResistanceOhms: 0.055,
      packMassKg: 4.2,
      cRateSafeThreshold: 1.2,
      cRateWarningThreshold: 2.0,
      cRateCriticalThreshold: 3.0,
      tempSafeThreshold: 40.0,
      tempWarningThreshold: 46.0,
      tempCriticalThreshold: 52.0,
      packReplacementCostInr: 22000.0,
      ratedCycleLife: 800.0,
      description: 'Entry-level conversion pack. Prone to severe voltage sag and thermal stress on steep climbs under payload.',
    ),
  ];

  static BatteryProfile get defaultProfile => profiles[0];

  // Default pack specs (delegated to default profile for full backward compatibility)
  static const double nominalVoltage = 48.0; // Volts
  static const double nominalCapacityAh = 20.0; // Ah
  static const double totalNominalEnergyWh = nominalVoltage * nominalCapacityAh; // 960 Wh

  // Thermal properties
  static const double internalResistanceOhms = 0.045; // 45 mOhm pack internal resistance
  static const double packMassKg = 6.2; // kg
  static const double specificHeatCapacityCp = 850.0; // J / (kg * K)
  static const double convectiveHeatTransferHA = 1.35; // W / K

  // Critical electrochemical thresholds
  static const double cRateSafeThreshold = 1.5; // C
  static const double cRateWarningThreshold = 2.5; // C
  static const double cRateCriticalThreshold = 3.5; // C
  static const double tempSafeThreshold = 42.0; // °C
  static const double tempWarningThreshold = 48.0; // °C
  static const double tempCriticalThreshold = 54.0; // °C

  // Economic replacement and degradation constants
  static const double packReplacementCostInr = 32000.0; // ₹32,000 for replacement pack
  static const double ratedCycleLife = 1000.0; // Cycles at 0.5C gentle discharge
  static const double baseCostPerCycleInr = packReplacementCostInr / ratedCycleLife; // ₹32.00 / cycle
  static const double averageOrderDeliveryPayoutInr = 25.0; // Typical Blinkit/Zepto pay per order in Varanasi
}
