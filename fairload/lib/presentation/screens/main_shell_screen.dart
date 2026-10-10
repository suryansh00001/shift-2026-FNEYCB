import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/dispatch_demo_data.dart';
import '../../core/models/defense_slip_data.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/dispatch_optimizer.dart';
import '../providers/telemetry_provider.dart';
import 'battery_care_wallet_screen.dart';
import 'dark_store_dispatch_screen.dart';
import 'defense_slip_screen.dart';
import 'dispatch_comparison_screen.dart';
import 'fleet_sustainability_screen.dart';
import 'hud_screen.dart';
import 'shift_ledger_screen.dart';
import 'simulator_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  bool _isFleetHubMode = false;

  @override
  Widget build(BuildContext context) {
    final telemetry = Provider.of<TelemetryProvider>(context);
    final lastTrip = telemetry.lastTripRecord;
    final defaultSlip = lastTrip != null
        ? DefenseSlipData.fromTrip(trip: lastTrip)
        : null;

    final defaultComparison = DispatchOptimizer.compareDispatchPlans(
      riders: DispatchDemoData.sampleRiders,
      orders: DispatchDemoData.sampleOrders,
    );

    final List<Widget> riderScreens = [
      const HudScreen(),
      const SimulatorScreen(),
      const ShiftLedgerScreen(),
      defaultSlip != null
          ? DefenseSlipScreen(slipData: defaultSlip)
          : const _EmptyDisputePlaceholder(),
    ];

    final List<Widget> fleetScreens = [
      const DarkStoreDispatchScreen(),
      DispatchComparisonScreen(comparison: defaultComparison),
      const BatteryCareWalletScreen(),
      const FleetSustainabilityScreen(),
    ];

    final activeScreens = _isFleetHubMode ? fleetScreens : riderScreens;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _buildPerspectiveToggleBar(),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: activeScreens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLowest,
          border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _isFleetHubMode ? _buildFleetNavRow() : _buildRiderNavRow(),
          ),
        ),
      ),
    );
  }

  Widget _buildPerspectiveToggleBar() {
    return Container(
      color: AppTheme.surfaceLowest,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.surfaceMid,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  if (_isFleetHubMode) {
                    setState(() {
                      _isFleetHubMode = false;
                      _currentIndex = 0;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  decoration: BoxDecoration(
                    color: !_isFleetHubMode ? AppTheme.primaryMint : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.electric_bike,
                              size: 13,
                              color: !_isFleetHubMode ? Colors.black : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'RIDER COCKPIT',
                              style: AppTheme.labelCaps.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: !_isFleetHubMode ? Colors.black : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  if (!_isFleetHubMode) {
                    setState(() {
                      _isFleetHubMode = true;
                      _currentIndex = 0;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isFleetHubMode ? AppTheme.cyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hub_outlined,
                              size: 13,
                              color: _isFleetHubMode ? Colors.black : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'DARK STORE HUB',
                              style: AppTheme.labelCaps.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: _isFleetHubMode ? Colors.black : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderNavRow() {
    return Row(
      children: [
        _buildNavItem(0, "COCKPIT", Icons.speed, AppTheme.primaryMint),
        _buildNavItem(1, "BATTERY", Icons.battery_charging_full, AppTheme.primaryMint),
        _buildNavItem(2, "PAYLOAD", Icons.inventory_2_outlined, AppTheme.primaryMint),
        _buildNavItem(3, "DISPUTE", Icons.shield_outlined, AppTheme.primaryMint),
      ],
    );
  }

  Widget _buildFleetNavRow() {
    return Row(
      children: [
        _buildNavItem(0, "DISPATCH", Icons.hub_outlined, AppTheme.cyan),
        _buildNavItem(1, "COMPARE", Icons.compare_arrows, AppTheme.cyan),
        _buildNavItem(2, "WALLET", Icons.account_balance_wallet_outlined, AppTheme.cyan),
        _buildNavItem(3, "FLEET ESG", Icons.analytics_outlined, AppTheme.cyan),
      ],
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, Color activeColor) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? activeColor : AppTheme.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          decoration: isSelected
              ? BoxDecoration(
                  border: Border(top: BorderSide(color: activeColor, width: 2)),
                  color: activeColor.withValues(alpha: 0.08),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTheme.labelCaps.copyWith(
                    fontSize: 8.0,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDisputePlaceholder extends StatelessWidget {
  const _EmptyDisputePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 48, color: AppTheme.hudCrimson),
              const SizedBox(height: 12),
              Text(
                "NO ACTIVE CLIMB TELEMETRY",
                style: AppTheme.labelCaps.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                "Switch to COCKPIT tab and run a climb simulation to record telemetry and generate your Overload Defense Slip.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
