import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/battery_care_ledger.dart';

/// Rider Battery Care Benefit Wallet: Transparent, auditable, platform-funded maintenance credits
class BatteryCareWalletScreen extends StatefulWidget {
  const BatteryCareWalletScreen({super.key});

  @override
  State<BatteryCareWalletScreen> createState() => _BatteryCareWalletScreenState();
}

class _BatteryCareWalletScreenState extends State<BatteryCareWalletScreen> {
  late BatteryCareWallet _wallet;

  @override
  void initState() {
    super.initState();
    _wallet = BatteryCareWallet.demoWallet();
  }

  void _simulateRedemption(String serviceName, double amount, BenefitCategory category) {
    if (_wallet.availableBalanceInr < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance for $serviceName'),
          backgroundColor: AppTheme.dangerCrimson,
        ),
      );
      return;
    }

    setState(() {
      _wallet = _wallet.redeemBenefit(
        serviceTitle: serviceName,
        amountInr: amount,
        category: category,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher issued: $serviceName (₹${amount.toInt()})'),
        backgroundColor: AppTheme.primaryMint,
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
                const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryMint, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'BATTERY CARE WALLET',
                      style: AppTheme.headlineMedium.copyWith(fontSize: 14, letterSpacing: 0.8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'PLATFORM-FUNDED SERVICING & CREDITS',
              style: AppTheme.labelCaps.copyWith(color: AppTheme.cyan, fontSize: 8.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          _buildBalanceHeroCard(),
          const SizedBox(height: 12),
          _buildPolicyCard(),
          const SizedBox(height: 16),
          _buildRedemptionVouchersSection(),
          const SizedBox(height: 16),
          _buildLedgerTransactionsHeader(),
          const SizedBox(height: 8),
          ..._wallet.transactions.map((tx) => _buildTransactionCard(tx)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBalanceHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('REDEEMABLE CARE BALANCE',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('ACTIVE & VERIFIED',
                    style: AppTheme.labelCaps.copyWith(color: AppTheme.primaryMint, fontSize: 8.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹${_wallet.availableBalanceInr.toStringAsFixed(2)}',
                  style: AppTheme.telemetryNumber.copyWith(fontSize: 34, color: AppTheme.primaryMint)),
              const SizedBox(width: 8),
              Text('INR', style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('LIFETIME ACCRUED',
                          style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.5)),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('₹${_wallet.totalAccruedInr.toStringAsFixed(2)}',
                          style: AppTheme.telemetryNumber.copyWith(fontSize: 14, color: AppTheme.cyan)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('SERVICING REDEEMED',
                          style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 8.5)),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('₹${_wallet.totalRedeemedInr.toStringAsFixed(2)}',
                          style: AppTheme.telemetryNumber.copyWith(fontSize: 14, color: AppTheme.accentAmber)),
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

  Widget _buildPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppTheme.cyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EQUITY FORMULA: B_trip = min(₹25, 75% × Modeled Wear)',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.cyan, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Funded 100% by the dark-store platform from avoided pack replacement savings. Never deducted from delivery earnings. Redeemable for verified battery servicing.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionVouchersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTHORIZED WORKSHOP REDEMPTIONS',
          style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildVoucherButton(
                title: 'BMS Diagnostics',
                costInr: 25.0,
                icon: Icons.health_and_safety_outlined,
                onTap: () => _simulateRedemption(
                  'BMS Diagnostics Check',
                  25.0,
                  BenefitCategory.batteryDiagnostic,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildVoucherButton(
                title: 'Cell Balancing',
                costInr: 50.0,
                icon: Icons.tune,
                onTap: () => _simulateRedemption(
                  'Cell Balancing & Reconditioning',
                  50.0,
                  BenefitCategory.preventiveBalancing,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoucherButton({
    required String title,
    required double costInr,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final canAfford = _wallet.availableBalanceInr >= costInr;

    return InkWell(
      onTap: canAfford ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMid,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canAfford ? AppTheme.primaryMint.withValues(alpha: 0.3) : AppTheme.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: canAfford ? AppTheme.primaryMint : AppTheme.textMuted),
            const SizedBox(height: 6),
            Text(title, style: AppTheme.bodyMedium.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Redeem ₹${costInr.toInt()}',
                style: AppTheme.labelCaps.copyWith(
                  color: canAfford ? AppTheme.cyan : AppTheme.textMuted,
                  fontSize: 9,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'AUDITABLE ACCRUAL LEDGER',
          style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.0),
        ),
        Text(
          '${_wallet.transactions.length} ENTRIES',
          style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(BatteryCareTransaction tx) {
    final isCredit = tx.benefitCreditInr >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isCredit
                  ? AppTheme.primaryMint.withValues(alpha: 0.12)
                  : AppTheme.accentAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? AppTheme.primaryMint : AppTheme.accentAmber,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tx.corridorName,
                        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isCredit ? "+" : ""}₹${tx.benefitCreditInr.toStringAsFixed(2)}',
                      style: AppTheme.telemetryNumber.copyWith(
                        fontSize: 13.5,
                        color: isCredit ? AppTheme.primaryMint : AppTheme.accentAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tx.description,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      tx.orderId,
                      style: AppTheme.labelCaps.copyWith(color: AppTheme.cyan, fontSize: 8.5),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMid,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        tx.statusLabel.toUpperCase(),
                        style: AppTheme.labelCaps.copyWith(
                          fontSize: 7.5,
                          color: tx.status == BenefitStatus.verified ? AppTheme.primaryMint : AppTheme.textMuted,
                        ),
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
}
