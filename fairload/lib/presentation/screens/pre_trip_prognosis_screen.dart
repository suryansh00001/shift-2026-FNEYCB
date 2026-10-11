import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/battery_specs.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/pinn_wear_prognosis_engine.dart';
import '../../services/dsm_elevation_service.dart';
import '../../services/weather_service.dart';

class PreTripPrognosisScreen extends StatefulWidget {
  const PreTripPrognosisScreen({super.key});

  @override
  State<PreTripPrognosisScreen> createState() => _PreTripPrognosisScreenState();
}

class _PreTripPrognosisScreenState extends State<PreTripPrognosisScreen> {
  // Route selection
  String _selectedCorridor = 'Chowkaghat Flyover (Varanasi)';
  bool _isCustomRoute = false;
  final TextEditingController _startLatCtrl = TextEditingController(text: '25.3310');
  final TextEditingController _startLonCtrl = TextEditingController(text: '82.9910');
  final TextEditingController _endLatCtrl = TextEditingController(text: '25.3375');
  final TextEditingController _endLonCtrl = TextEditingController(text: '83.0035');

  // Input states
  double _cargoMassKg = 140.0;
  double _riderMassKg = 65.0;
  double _ambientTempC = 40.5;
  double _plannedSpeedKmh = 8.2;
  double _deliveryFeeInr = 25.0;
  bool _isNeuroPaceActive = false;

  BatteryProfile _selectedBattery = BatterySpecs.defaultProfile;
  RoadSurfaceType _selectedSurface = RoadSurfaceType.pccConcrete;

  // Topography state
  RouteTopographyResult? _topography;
  PreTripPrognosisResult? _prognosis;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadTopographyAndRun(forceLive: false);
  }

  @override
  void dispose() {
    _startLatCtrl.dispose();
    _startLonCtrl.dispose();
    _endLatCtrl.dispose();
    _endLonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTopographyAndRun({bool forceLive = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = forceLive
          ? 'Querying Open-Meteo & Open-Elevation DSM...'
          : 'Initializing PINN & DSM corridor models...';
    });

    double sLat, sLon, eLat, eLon;
    if (_isCustomRoute) {
      sLat = double.tryParse(_startLatCtrl.text) ?? 25.3310;
      sLon = double.tryParse(_startLonCtrl.text) ?? 82.9910;
      eLat = double.tryParse(_endLatCtrl.text) ?? 25.3375;
      eLon = double.tryParse(_endLonCtrl.text) ?? 83.0035;
    } else {
      final p = DsmElevationService.presetCorridors[_selectedCorridor]!;
      sLat = p['startLat'] as double;
      sLon = p['startLon'] as double;
      eLat = p['endLat'] as double;
      eLon = p['endLon'] as double;
    }

    if (forceLive) {
      final liveTemp = await WeatherService.fetchAmbientTemperature(
        latitude: sLat,
        longitude: sLon,
        forceRefresh: true,
      );
      if (liveTemp != null) {
        _ambientTempC = liveTemp;
      }
    }

    final topo = await DsmElevationService.fetchRouteTopography(
      startLat: sLat,
      startLon: sLon,
      endLat: eLat,
      endLon: eLon,
      corridorPresetName: _isCustomRoute ? null : _selectedCorridor,
    );

    if (mounted) {
      setState(() {
        _topography = topo;
        _isLoading = false;
        _statusMessage = null;
        _recalculatePrognosis();
      });
    }
  }

  void _recalculatePrognosis() {
    if (_topography == null) return;

    final targetSpeed = _isNeuroPaceActive ? 8.2 : _plannedSpeedKmh;

    final res = PinnWearPrognosisEngine.evaluate(
      cargoMassKg: _cargoMassKg,
      riderMassKg: _riderMassKg,
      routeDistanceM: _topography!.totalDistanceMeters,
      roadGradePct: _topography!.maxInclinePct,
      elevationGainM: _topography!.netElevationGainM,
      ambientTempC: _ambientTempC,
      plannedSpeedKmh: targetSpeed,
      batteryProfile: _selectedBattery,
      roadSurface: _selectedSurface,
      deliveryFeeInr: _deliveryFeeInr,
    );

    setState(() {
      _prognosis = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadTopographyAndRun(forceLive: true),
          color: AppTheme.primaryMint,
          backgroundColor: AppTheme.surfaceLowest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBar(),
                const SizedBox(height: 12),
                _buildHeadlineWearSummaryCard(),
                const SizedBox(height: 12),
                _buildDsmElevationChartCard(),
                const SizedBox(height: 12),
                _buildInputConfigurationSection(),
                const SizedBox(height: 12),
                if (_prognosis != null) ...[
                  _buildPinnKneePrognosisCard(),
                  const SizedBox(height: 12),
                  _buildWmgElectrochemicalStressCard(),
                  const SizedBox(height: 12),
                  _buildMitigationActionCard(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER BAR
  // ============================================================================
  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryMint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.satellite_alt_outlined, color: AppTheme.primaryMint, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PINN & DSM PRE-TRIP PROGNOSIS',
                  style: AppTheme.labelCaps.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _isLoading && _statusMessage != null
                      ? _statusMessage!
                      : (_topography?.dataSourceName ?? 'Connecting DSM elevation API...'),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryMint,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync, color: AppTheme.cyan, size: 20),
              tooltip: 'Sync Live DSM & Weather',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _loadTopographyAndRun(forceLive: true),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADLINE WEAR & NET MARGIN SUMMARY CARD
  // ============================================================================
  Widget _buildHeadlineWearSummaryCard() {
    if (_prognosis == null) return const SizedBox.shrink();

    final p = _prognosis!;
    final isLoss = p.isDeficitOrder;
    final accentColor = isLoss ? AppTheme.hudCrimson : AppTheme.primaryMint;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PRE-CALCULATED ROUTE WEAR',
                  style: AppTheme.labelCaps.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: accentColor),
                ),
                child: Text(
                  isLoss ? '🚨 ARBITRAGE LOSS' : '✅ PROFITABLE',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${p.predictedWearCostInr.toStringAsFixed(2)}',
                        style: AppTheme.telemetryDigits.copyWith(
                          color: accentColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'wear cost',
                        style: AppTheme.telemetryUnit.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Payout: ₹${p.deliveryFeeInr.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Net: ${p.netRiderMarginInr >= 0 ? "+" : ""}₹${p.netRiderMarginInr.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isLoss ? AppTheme.hudCrimson : AppTheme.primaryMint,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLoss ? AppTheme.hudCrimson.withValues(alpha: 0.08) : AppTheme.surfaceMid,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  isLoss ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: accentColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.recommendedMitigationText,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DSM ELEVATION MINI-CHART CARD
  // ============================================================================
  Widget _buildDsmElevationChartCard() {
    if (_topography == null) return const SizedBox.shrink();

    final profile = _topography!.elevationProfile;
    final minElev = profile.map((e) => e.elevationMeters).reduce(math.min);
    final maxElev = profile.map((e) => e.elevationMeters).reduce(math.max);
    final rangeY = math.max(6.0, maxElev - minElev);

    final spots = profile
        .map((p) => FlSpot(p.distanceMeters / 1000.0, p.elevationMeters))
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DSM ELEVATION PROFILE',
                  style: AppTheme.labelCaps.copyWith(
                    color: AppTheme.cyan,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Grade: ${_topography!.maxInclinePct}% | +${_topography!.netElevationGainM.toStringAsFixed(1)}m',
                  style: const TextStyle(
                    color: AppTheme.hudAmber,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: _topography!.totalDistanceMeters / 1000.0,
                minY: minElev - 2.0,
                maxY: minElev + rangeY + 4.0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}m',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 16,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toStringAsFixed(1)}k',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.cyan,
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.cyan.withValues(alpha: 0.22),
                          AppTheme.cyan.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Base: ${_topography!.startElevationM.toStringAsFixed(1)}m',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  'Crest: ${_topography!.crestElevationM.toStringAsFixed(1)}m',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.primaryMint, fontSize: 8.5, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  '${(_topography!.totalDistanceMeters / 1000.0).toStringAsFixed(2)} km',
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // INPUT CONFIGURATION SECTION
  // ============================================================================
  Widget _buildInputConfigurationSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'INPUT PARAMETERS',
                  style: AppTheme.labelCaps.copyWith(
                    color: AppTheme.primaryMint,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Custom GPS', style: TextStyle(color: AppTheme.textMuted, fontSize: 8.5)),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _isCustomRoute,
                      activeThumbColor: AppTheme.cyan,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        setState(() => _isCustomRoute = val);
                        _loadTopographyAndRun(forceLive: val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Corridor Dropdown or GPS Inputs
          if (!_isCustomRoute) ...[
            const Text('Delivery Corridor Profile:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMid,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCorridor,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceContainer,
                  items: DsmElevationService.presetCorridors.keys.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCorridor = val);
                      _loadTopographyAndRun();
                    }
                  },
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildTextField('Start Lat', _startLatCtrl)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField('Start Lon', _startLonCtrl)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildTextField('End Lat', _endLatCtrl)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField('End Lon', _endLonCtrl)),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _loadTopographyAndRun(forceLive: true),
              icon: const Icon(Icons.search, size: 14),
              label: const Text('Lookup DSM Elevation Profile', style: TextStyle(fontSize: 10.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceMid,
                foregroundColor: AppTheme.cyan,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              ),
            ),
          ],

          const Divider(color: AppTheme.borderLight, height: 20),

          // Cargo Mass Slider + Presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cargo Payload: ${_cargoMassKg.toInt()} kg',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                'Gross: ${(_cargoMassKg + _riderMassKg + 34).toInt()} kg',
                style: const TextStyle(color: AppTheme.hudAmber, fontSize: 10),
              ),
            ],
          ),
          Slider(
            value: _cargoMassKg,
            min: 10,
            max: 160,
            divisions: 30,
            activeColor: _cargoMassKg > 80 ? AppTheme.hudCrimson : AppTheme.primaryMint,
            inactiveColor: AppTheme.surfaceHigh,
            onChanged: (val) {
              setState(() => _cargoMassKg = val);
              _recalculatePrognosis();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [20.0, 60.0, 100.0, 140.0].map((mass) {
              final isCur = (_cargoMassKg - mass).abs() < 5;
              return InkWell(
                onTap: () {
                  setState(() => _cargoMassKg = mass);
                  _recalculatePrognosis();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCur ? AppTheme.primaryMint.withValues(alpha: 0.15) : AppTheme.surfaceMid,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: isCur ? AppTheme.primaryMint : AppTheme.borderLight),
                  ),
                  child: Text(
                    '${mass.toInt()} kg',
                    style: TextStyle(
                      color: isCur ? AppTheme.primaryMint : AppTheme.textMuted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Rider Mass and Speed Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rider Mass: ${_riderMassKg.toInt()} kg', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                    const SizedBox(height: 4),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMid,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_riderMassKg.toInt()} kg', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() => _riderMassKg = math.max(50.0, _riderMassKg - 5.0));
                                  _recalculatePrognosis();
                                },
                                child: const Icon(Icons.remove_circle_outline, size: 15, color: AppTheme.textMuted),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  setState(() => _riderMassKg = math.min(110.0, _riderMassKg + 5.0));
                                  _recalculatePrognosis();
                                },
                                child: const Icon(Icons.add_circle_outline, size: 15, color: AppTheme.primaryMint),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Speed: ${_plannedSpeedKmh.toStringAsFixed(1)} km/h', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                    const SizedBox(height: 4),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMid,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_plannedSpeedKmh.toStringAsFixed(1)} km/h', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() => _plannedSpeedKmh = 8.2);
                                  _recalculatePrognosis();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _plannedSpeedKmh == 8.2 ? AppTheme.primaryMint.withValues(alpha: 0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('8.2', style: TextStyle(fontSize: 8.5, color: _plannedSpeedKmh == 8.2 ? AppTheme.primaryMint : AppTheme.textMuted)),
                                ),
                              ),
                              const SizedBox(width: 3),
                              InkWell(
                                onTap: () {
                                  setState(() => _plannedSpeedKmh = 16.0);
                                  _recalculatePrognosis();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _plannedSpeedKmh == 16.0 ? AppTheme.hudCrimson.withValues(alpha: 0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('16', style: TextStyle(fontSize: 8.5, color: _plannedSpeedKmh == 16.0 ? AppTheme.hudCrimson : AppTheme.textMuted)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Battery Pack Profile Dropdown
          const Text('Battery Pack Architecture:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMid,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BatteryProfile>(
                value: _selectedBattery,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceContainer,
                items: BatterySpecs.profiles.map((p) {
                  return DropdownMenuItem<BatteryProfile>(
                    value: p,
                    child: Text(
                      '${p.name} (${p.totalNominalEnergyWh.toInt()}Wh, ${p.ratedCycleLife.toInt()} cycles)',
                      style: const TextStyle(color: Colors.white, fontSize: 10.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBattery = val);
                    _recalculatePrognosis();
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Road Surface & Ambient Heat
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Road Surface (OSM):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMid,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RoadSurfaceType>(
                          value: _selectedSurface,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceContainer,
                          items: RoadSurfaceType.values.map((s) {
                            return DropdownMenuItem<RoadSurfaceType>(
                              value: s,
                              child: Text(
                                s.displayName,
                                style: const TextStyle(color: Colors.white, fontSize: 9.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSurface = val);
                              _recalculatePrognosis();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ambient Temp: ${_ambientTempC.toStringAsFixed(1)}°C', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMid,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_ambientTempC.toStringAsFixed(0)} °C', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _ambientTempC = _ambientTempC >= 45.0 ? 30.0 : _ambientTempC + 5.0;
                              });
                              _recalculatePrognosis();
                            },
                            child: const Text('Toggle ☀️', style: TextStyle(color: AppTheme.hudAmber, fontSize: 9.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Delivery Pay & Mode Toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Pay (₹):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                    const SizedBox(height: 4),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMid,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        controller: TextEditingController(text: _deliveryFeeInr.toStringAsFixed(0)),
                        onChanged: (val) {
                          _deliveryFeeInr = double.tryParse(val) ?? 25.0;
                          _recalculatePrognosis();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pacing Strategy:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        setState(() => _isNeuroPaceActive = !_isNeuroPaceActive);
                        _recalculatePrognosis();
                      },
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _isNeuroPaceActive
                              ? AppTheme.primaryMint.withValues(alpha: 0.2)
                              : AppTheme.surfaceMid,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _isNeuroPaceActive ? AppTheme.primaryMint : AppTheme.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isNeuroPaceActive ? Icons.shield : Icons.speed,
                              size: 13,
                              color: _isNeuroPaceActive ? AppTheme.primaryMint : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _isNeuroPaceActive ? 'PACED 8.2 km/h' : 'SLA UNRESTRICTED',
                                style: TextStyle(
                                  color: _isNeuroPaceActive ? AppTheme.primaryMint : Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8.5)),
        const SizedBox(height: 2),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surfaceMid,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 10.5),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // PINN SOH & KNEE-POINT PROGNOSIS CARD
  // ============================================================================
  Widget _buildPinnKneePrognosisCard() {
    final p = _prognosis!;
    final isCritical = p.pinnKneeRiskStatus == 'CRITICAL POST-KNEE';
    final isElevated = p.pinnKneeRiskStatus == 'ELEVATED ACCELERATION';
    final badgeColor = isCritical
        ? AppTheme.hudCrimson
        : (isElevated ? AppTheme.hudAmber : AppTheme.primaryMint);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PINN4SOH BATTERY PROGNOSIS',
                  style: AppTheme.labelCaps.copyWith(
                    color: AppTheme.cyan,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  p.pinnKneeRiskStatus,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 8.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'PREDICTED KNEE',
                  value: 'Cycle ${p.predictedKneePointCycle}',
                  subtitle: '${p.safeLeadTimeCycles} cyc safe lead',
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  title: 'CYCLES BURNED',
                  value: '${p.equivalentFullCyclesBurned.toStringAsFixed(2)} EFC',
                  subtitle: '${p.predictedTripSohLossPct.toStringAsFixed(3)}% SOH',
                  color: p.equivalentFullCyclesBurned > 0.5 ? AppTheme.hudCrimson : AppTheme.primaryMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'ELECTRICAL DRAW',
                  value: '${p.electricalPowerW.toInt()} W',
                  subtitle: '${p.dischargeCurrentA.toStringAsFixed(1)}A (${p.dischargeCRate.toStringAsFixed(2)}C)',
                  color: p.dischargeCRate > 1.5 ? AppTheme.hudCrimson : Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  title: 'CELL CORE TEMP',
                  value: '${p.cellCoreTempC.toStringAsFixed(1)} °C',
                  subtitle: '+${p.cellTempRiseK.toStringAsFixed(1)}K thermal rise',
                  color: p.cellCoreTempC > 48.0 ? AppTheme.hudCrimson : AppTheme.hudAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WMG ELECTROCHEMICAL STRESS CARD
  // ============================================================================
  Widget _buildWmgElectrochemicalStressCard() {
    final p = _prognosis!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'WARWICK (WMG) STRESS MODEL',
                  style: AppTheme.labelCaps.copyWith(
                    color: AppTheme.hudAmber,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'W_f: ${p.totalStressMultiplierWf.toStringAsFixed(2)}×',
                style: const TextStyle(
                  color: AppTheme.primaryMint,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStressFactorBox(
                  'Arrhenius Φ_T',
                  '${p.arrheniusFactorPhiT.toStringAsFixed(2)}×',
                  'Thermal aging',
                  p.arrheniusFactorPhiT > 3.0 ? AppTheme.hudCrimson : AppTheme.hudAmber,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildStressFactorBox(
                  'Overpotential Ψ_C',
                  '${p.cRateOverpotentialFactorPsiC.toStringAsFixed(2)}×',
                  'High C-rate polarization',
                  p.cRateOverpotentialFactorPsiC > 1.5 ? AppTheme.hudCrimson : AppTheme.cyan,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildStressFactorBox(
                  'Li Plating Factor',
                  '${p.lithiumPlatingMultiplier.toStringAsFixed(1)}×',
                  p.hasLithiumPlatingRisk ? 'Active Plating' : 'Benign regime',
                  p.hasLithiumPlatingRisk ? AppTheme.hudCrimson : AppTheme.primaryMint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStressFactorBox(String title, String val, String sub, Color col) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(val, style: TextStyle(color: col, fontSize: 13, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 1),
          Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 1),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ============================================================================
  // MITIGATION ACTION CARD
  // ============================================================================
  Widget _buildMitigationActionCard() {
    final p = _prognosis!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryMint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppTheme.primaryMint, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'FAIRLOAD DEFENSE INTERVENTION',
                  style: AppTheme.labelCaps.copyWith(
                    color: AppTheme.primaryMint,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'By pre-calculating the DSM incline wear, FairLoad certifies that unmitigated SLA transit causes ₹${p.predictedWearCostInr.toStringAsFixed(2)} damage. Pacing to 8.2 km/h caps wear at ₹${p.neuroPaceWearCostInr.toStringAsFixed(2)}, defending ₹${p.neuroPaceSavedInr.toStringAsFixed(2)} in driver capital under Section 56/74 of the Indian Contract Act.',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isNeuroPaceActive = !_isNeuroPaceActive;
                  _recalculatePrognosis();
                });
              },
              icon: Icon(
                _isNeuroPaceActive ? Icons.lock_open : Icons.speed,
                size: 15,
              ),
              label: Text(
                _isNeuroPaceActive
                    ? 'DISABLE NEUROPACE (SLA RUSH)'
                    : 'ACTIVATE NEUROPACE PACING (PROTECT ASSET)',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isNeuroPaceActive ? AppTheme.surfaceMid : AppTheme.primaryMint,
                foregroundColor: _isNeuroPaceActive ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
