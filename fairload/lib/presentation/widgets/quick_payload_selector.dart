import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QuickPayloadSelector extends StatelessWidget {
  final double currentCargoKg;
  final ValueChanged<double> onCargoChanged;

  const QuickPayloadSelector({
    super.key,
    required this.currentCargoKg,
    required this.onCargoChanged,
  });

  static const List<PayloadPreset> presets = [
    PayloadPreset(label: "1 Bag", weightKg: 25.0, icon: Icons.shopping_bag_outlined),
    PayloadPreset(label: "2 Bags", weightKg: 50.0, icon: Icons.backpack_outlined),
    PayloadPreset(label: "4 Bags", weightKg: 100.0, icon: Icons.inventory_2_outlined),
    PayloadPreset(label: "4 Bags + Crates", weightKg: 140.0, icon: Icons.layers_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isOverloaded = currentCargoKg > 65.0;
    final overloadPct = isOverloaded ? (((currentCargoKg - 65.0) / 65.0) * 100.0).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "DISPATCH CARGO BATCHING",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isOverloaded ? AppTheme.hudCrimson : AppTheme.primaryMint).withValues(alpha: 0.15),
                  border: Border.all(
                    color: isOverloaded ? AppTheme.hudCrimson : AppTheme.primaryMint,
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOverloaded ? "+$overloadPct% OVERLOAD (${currentCargoKg.toInt()}kg)" : "SAFE (${currentCargoKg.toInt()}kg)",
                  style: AppTheme.labelCaps.copyWith(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: isOverloaded ? AppTheme.hudCrimson : AppTheme.primaryMint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: presets.map((p) {
              final isSelected = (currentCargoKg - p.weightKg).abs() < 5.0;
              final activeColor = p.weightKg > 65.0 ? AppTheme.hudCrimson : AppTheme.hudAmber;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: InkWell(
                    onTap: () => onCargoChanged(p.weightKg),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor.withValues(alpha: 0.18) : AppTheme.surfaceLow,
                        border: Border.all(
                          color: isSelected ? activeColor : AppTheme.borderLight,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            p.icon,
                            size: 16,
                            color: isSelected ? activeColor : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            "${p.weightKg.toInt()}kg",
                            style: AppTheme.labelCaps.copyWith(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? activeColor : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class PayloadPreset {
  final String label;
  final double weightKg;
  final IconData icon;

  const PayloadPreset({
    required this.label,
    required this.weightKg,
    required this.icon,
  });
}
