import 'package:flutter/material.dart';
import '../../core/constants/dispatch_demo_data.dart';
import '../../core/models/dispatch_models.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/dispatch_optimizer.dart';
import 'dispatch_comparison_screen.dart';

/// Dark-Store Dispatch Control Center: Visualizes orders queue, rider availability, and runs FairLoad optimization
class DarkStoreDispatchScreen extends StatefulWidget {
  const DarkStoreDispatchScreen({super.key});

  @override
  State<DarkStoreDispatchScreen> createState() => _DarkStoreDispatchScreenState();
}

class _DarkStoreDispatchScreenState extends State<DarkStoreDispatchScreen> {
  late List<DispatchOrder> _orders;
  late List<FleetRider> _riders;
  bool _isOptimizing = false;

  @override
  void initState() {
    super.initState();
    _orders = List.from(DispatchDemoData.sampleOrders);
    _riders = List.from(DispatchDemoData.sampleRiders);
  }

  void _runOptimization() async {
    setState(() => _isOptimizing = true);
    await Future.delayed(const Duration(milliseconds: 350)); // Tactile feedback
    if (!mounted) return;

    final comparison = DispatchOptimizer.compareDispatchPlans(
      riders: _riders,
      orders: _orders,
      ambientTempCelsius: 40.0,
    );

    setState(() => _isOptimizing = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DispatchComparisonScreen(comparison: comparison),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLowest,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hub_outlined, color: AppTheme.primaryMint, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DispatchDemoData.darkStoreName.toUpperCase(),
                      style: AppTheme.headlineMedium.copyWith(fontSize: 13, letterSpacing: 0.8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              DispatchDemoData.darkStoreLocation,
              style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryMint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryMint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '40°C AMB',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 8.5),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickMetricsHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                _buildSectionHeader('INCOMING DISPATCH QUEUE (${_orders.length})', Icons.receipt_long),
                const SizedBox(height: 8),
                ..._orders.map((o) => _buildOrderCard(o)),
                const SizedBox(height: 18),
                _buildSectionHeader('ACTIVE DELIVERY FLEET (${_riders.length})', Icons.two_wheeler),
                const SizedBox(height: 8),
                ..._riders.map((r) => _buildRiderCard(r)),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLowest,
          border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isOptimizing ? null : _runOptimization,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMint,
                foregroundColor: Colors.black,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isOptimizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'OPTIMIZE DISPATCH WITH FAIRLOAD',
                          style: AppTheme.labelCaps.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMetricsHeader() {
    final heavyOrders = _orders.where((o) => o.isHeavy).length;
    final steepClimbs = _orders.where((o) => o.hasSteepIncline).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceMid,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          _buildMetricPill('PENDING', '${_orders.length}', AppTheme.textPrimary),
          _buildMetricPill('HEAVY', '$heavyOrders', AppTheme.accentAmber),
          _buildMetricPill('FLYOVER', '$steepClimbs', AppTheme.dangerCrimson),
          _buildMetricPill('RIDERS', '${_riders.length}', AppTheme.primaryMint),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTheme.telemetryNumber.copyWith(fontSize: 16, color: color)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppTheme.labelCaps.copyWith(fontSize: 8.0, color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 15),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.0),
        ),
      ],
    );
  }

  Widget _buildOrderCard(DispatchOrder order) {
    final isSteep = order.hasSteepIncline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSteep ? AppTheme.dangerCrimson.withValues(alpha: 0.35) : AppTheme.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: isSteep
                  ? AppTheme.dangerCrimson.withValues(alpha: 0.15)
                  : AppTheme.surfaceMid,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  order.weightKg.toStringAsFixed(1),
                  style: AppTheme.telemetryNumber.copyWith(
                    fontSize: 16,
                    color: isSteep ? AppTheme.dangerCrimson : AppTheme.textPrimary,
                  ),
                ),
                Text('KG', style: AppTheme.labelCaps.copyWith(fontSize: 8, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.id,
                      style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 10),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.priority == 'urgent'
                            ? AppTheme.dangerCrimson.withValues(alpha: 0.2)
                            : AppTheme.surfaceMid,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${order.deadlineMinutes}m SLA',
                        style: AppTheme.labelCaps.copyWith(
                          fontSize: 9,
                          color: order.priority == 'urgent' ? AppTheme.dangerCrimson : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  order.deliveryLocation,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isSteep ? Icons.terrain : Icons.straighten,
                      color: isSteep ? AppTheme.accentAmber : AppTheme.textMuted,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${order.corridorName} (${order.inclineGradePercent}%)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelCaps.copyWith(
                          color: isSteep ? AppTheme.accentAmber : AppTheme.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${order.distanceKm} km',
                      style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(FleetRider rider) {
    final chem = rider.batteryProfile.chemistryLabel;
    final isLfp = chem == 'LFP';
    final isHot = rider.currentTempCelsius >= 45.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHot ? AppTheme.accentAmber.withValues(alpha: 0.4) : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMid,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              rider.vehicleProfile.id == 'heavy_trike_750w'
                  ? Icons.local_shipping_outlined
                  : Icons.electric_bike,
              color: isLfp ? AppTheme.primaryMint : AppTheme.cyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rider.name,
                        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLfp
                            ? AppTheme.primaryMint.withValues(alpha: 0.15)
                            : AppTheme.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$chem · ${rider.batteryProfile.nominalCapacityAh.toInt()}Ah',
                        style: AppTheme.labelCaps.copyWith(
                          fontSize: 9,
                          color: isLfp ? AppTheme.primaryMint : AppTheme.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${rider.vehicleProfile.name} · Max ${rider.vehicleProfile.ratedCargoCapacityKg.toInt()}kg',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9.5),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _buildMiniBadge(Icons.battery_charging_full, '${rider.currentSocPercent.toInt()}%',
                        rider.currentSocPercent < 30 ? AppTheme.dangerCrimson : AppTheme.primaryMint),
                    const SizedBox(width: 8),
                    _buildMiniBadge(Icons.thermostat, '${rider.currentTempCelsius.toStringAsFixed(1)}°C',
                        isHot ? AppTheme.dangerCrimson : AppTheme.textMuted),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        '₹${rider.accumulatedBenefitInr.toStringAsFixed(0)} Care',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppTheme.labelCaps.copyWith(color: color, fontSize: 9)),
      ],
    );
  }
}
