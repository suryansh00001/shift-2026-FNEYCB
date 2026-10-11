// ==============================================================================
// pinn_dashboard_page.dart
// Ready-to-use Flutter UI Screen for Delivery Fleet Battery Prognosis.
// ==============================================================================

import 'package:flutter/material.dart';
import 'pinn_fleet_pipeline.dart';

class PINNDashboardPage extends StatefulWidget {
  const PINNDashboardPage({super.key});

  @override
  State<PINNDashboardPage> createState() => _PINNDashboardPageState();
}

class _PINNDashboardPageState extends State<PINNDashboardPage> {
  final PINNFleetPipeline _pipeline = PINNFleetPipeline();
  bool _isLoading = false;
  TripPrognosisResult? _result;

  // Manual input controllers
  final TextEditingController _riderWeightCtrl = TextEditingController(text: '70');
  final TextEditingController _cargoWeightCtrl = TextEditingController(text: '140');
  final TextEditingController _durationCtrl = TextEditingController(text: '30');

  // Pre-configured route options for Indian delivery hubs
  String _selectedRoute = 'Varanasi Cantt to Chowkaghat';
  String _selectedSurface = 'potholed';

  final Map<String, Map<String, double>> _routes = {
    'Varanasi Cantt to Chowkaghat': {
      'startLat': 25.3280, 'startLon': 82.9850,
      'endLat': 25.3360, 'endLon': 82.9980,
    },
    'Chowkaghat to Rajghat Flyover': {
      'startLat': 25.3360, 'startLon': 82.9980,
      'endLat': 25.3176, 'endLon': 83.0335,
    },
    'Bengaluru Outer Ring Road Hub': {
      'startLat': 12.9279, 'startLon': 77.6271,
      'endLat': 12.9569, 'endLon': 77.7011,
    },
    'Delhi Janakpuri to Flyover Hub': {
      'startLat': 28.6219, 'startLon': 77.0878,
      'endLat': 28.6415, 'endLon': 77.1209,
    },
  };

  @override
  void initState() {
    super.initState();
    _pipeline.init();
  }

  @override
  void dispose() {
    _pipeline.dispose();
    _riderWeightCtrl.dispose();
    _cargoWeightCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAssessment() async {
    setState(() => _isLoading = true);
    final route = _routes[_selectedRoute]!;
    final riderKg = double.tryParse(_riderWeightCtrl.text) ?? 70.0;
    final cargoKg = double.tryParse(_cargoWeightCtrl.text) ?? 20.0;
    final durationMin = double.tryParse(_durationCtrl.text) ?? 30.0;

    try {
      final res = await _pipeline.assessTrip(
        startLat: route['startLat']!,
        startLon: route['startLon']!,
        endLat: route['endLat']!,
        endLon: route['endLon']!,
        riderWeightKg: riderKg,
        cargoWeightKg: cargoKg,
        tripDurationMin: durationMin,
        roadSurface: _selectedSurface,
      );
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error running pipeline: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PINN4SOH Battery Prognosis'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runAssessment,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bolt),
              label: Text(_isLoading ? 'Fetching Data & Running PINN...' : 'Run Trip Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            if (_result != null) _buildResultsDashboard(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trip & Vehicle Parameters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            DropdownButtonFormField<String>(
              value: _selectedRoute,
              decoration: const InputDecoration(labelText: 'Delivery Route (Live APIs)'),
              items: _routes.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (val) => setState(() => _selectedRoute = val!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSurface,
              decoration: const InputDecoration(labelText: 'Road Surface Condition (C_rr)'),
              items: const [
                DropdownMenuItem(value: 'asphalt', child: Text('Standard Asphalt (Crr=0.015)')),
                DropdownMenuItem(value: 'paved', child: Text('Average Indian City Road (Crr=0.018)')),
                DropdownMenuItem(value: 'unpaved', child: Text('Broken Road / Gravel (Crr=0.028)')),
                DropdownMenuItem(value: 'cobblestone', child: Text('Old City Sett / Cobblestone (Crr=0.032)')),
                DropdownMenuItem(value: 'potholed', child: Text('Monsoon Potholed / Waterlogged (Crr=0.035)')),
              ],
              onChanged: (val) => setState(() => _selectedSurface = val!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _riderWeightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rider Weight (kg)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cargoWeightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cargo Payload (kg)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Trip Time (min)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsDashboard(TripPrognosisResult res) {
    Color statusColor = res.kneeWarningStatus == 'CRITICAL'
        ? Colors.red
        : (res.kneeWarningStatus == 'WARNING' ? Colors.orange : Colors.green);

    return Column(
      children: [
        // Top Health Card
        Card(
          color: Colors.indigo.shade50,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricColumn('Current SOH', '${res.currentSohPct.toStringAsFixed(2)} %', Colors.indigo),
                _metricColumn('Trip Wear', '${res.tripWearPct.toStringAsFixed(4)} %', Colors.red),
                _metricColumn('Cycles Burned', '${res.equivalentCyclesBurned.toStringAsFixed(2)} cyc', Colors.purple),
                _metricColumn('Knee Warning', res.kneeWarningStatus, statusColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Live Environment & Route
        _detailCard('1. Live Weather & Road Incline (Open-Meteo & OSM)', [
          'Live Ambient Temp: ${res.ambientTempC.toStringAsFixed(1)} °C',
          'Live Relative Humidity: ${res.ambientRhPct.toStringAsFixed(0)} %',
          'Route Distance: ${res.routeDistanceKm.toStringAsFixed(2)} km',
          'Elevation Gain: ${res.elevationChangeM.toStringAsFixed(1)} m (Incline: ${res.roadInclinePct.toStringAsFixed(1)} %)',
          'Road Surface: ${res.surfaceDescription} (Crr = ${res.roadCrr})',
        ]),

        // Powertrain & Battery Thermal Surge
        _detailCard('2. Powertrain & Cell Heating (Bernardi Model)', [
          'Total Gross Mass: ${res.grossWeightKg.toStringAsFixed(1)} kg',
          'Motor Electrical Draw: ${res.motorPowerW.toStringAsFixed(0)} Watts',
          'Battery Discharge Current: ${res.dischargeCurrentA.toStringAsFixed(1)} A (${res.cRate.toStringAsFixed(2)} C-rate)',
          'Cell Core Temp: ${res.cellTempC.toStringAsFixed(1)} °C (Surge: +${res.cellTempRiseC.toStringAsFixed(1)} °C)',
          'Arrhenius Aging Acceleration: ${res.arrheniusAgingMult.toStringAsFixed(2)}x faster',
        ]),

        // Knee-Point Early Warning
        _detailCard('3. Knee-Point Prognosis (TFLite PINN4SOH Engine)', [
          'Predicted Failure Knee-Point: Cycle ${res.predictedKneeCycle}',
          'Safe Cycles Remaining: ${res.safeLeadTimeCycles} cycles before rapid collapse',
          'Capacity Lost in Trip: ${res.capacityLostMah.toStringAsFixed(1)} mAh',
        ]),
      ],
    );
  }

  Widget _metricColumn(String title, String val, Color col) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: col)),
      ],
    );
  }

  Widget _detailCard(String title, List<String> items) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
            const Divider(),
            ...items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(it, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
