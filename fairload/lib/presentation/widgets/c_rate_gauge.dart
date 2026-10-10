import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CRateGauge extends StatelessWidget {
  final double cRate;
  final double currentAmps;
  final double electricalPowerWatts;
  final bool isPlatingRisk;

  const CRateGauge({
    super.key,
    required this.cRate,
    required this.currentAmps,
    required this.electricalPowerWatts,
    required this.isPlatingRisk,
  });

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    if (cRate < 1.5) {
      gaugeColor = AppTheme.primaryMint;
    } else if (cRate < 2.5) {
      gaugeColor = AppTheme.hudAmber;
    } else {
      gaugeColor = AppTheme.hudCrimson;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Module Header Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SYS.TACHO_C_RATE_01",
                style: AppTheme.labelCaps.copyWith(color: Colors.white38, fontSize: 9),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isPlatingRisk ? AppTheme.hudCrimson : AppTheme.primaryMint,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPlatingRisk ? AppTheme.hudCrimson : AppTheme.primaryMint).withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isPlatingRisk ? "OVER-DISCHARGE PEAK" : "NOMINAL REGIME",
                    style: AppTheme.labelCaps.copyWith(
                      color: isPlatingRisk ? AppTheme.hudCrimson : AppTheme.primaryMint,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Central 270-degree Gauge Canvas
          SizedBox(
            width: 250,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(250, 200),
                  painter: _StitchHypercarGaugePainter(cRate: cRate),
                ),
                Positioned(
                  top: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "DISCHARGE RATE",
                        style: AppTheme.labelCaps.copyWith(color: Colors.white54, fontSize: 9),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            cRate.toStringAsFixed(1),
                            style: AppTheme.telemetryDigits.copyWith(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: gaugeColor,
                              letterSpacing: -2.0,
                              shadows: [
                                Shadow(
                                  color: gaugeColor.withValues(alpha: 0.7),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            " C",
                            style: AppTheme.telemetryUnit.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: gaugeColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${currentAmps.toStringAsFixed(1)}A DRAW · ${electricalPowerWatts.toInt()}W PEAK",
                        style: AppTheme.labelCaps.copyWith(
                          fontSize: 11,
                          color: AppTheme.hudCyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "MAX THRESHOLD 2.2C",
                        style: AppTheme.labelCaps.copyWith(
                          fontSize: 8.5,
                          color: Colors.white30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Pulsing Red Hazard Pill Docked at Base
          if (isPlatingRisk)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.hudCrimson.withValues(alpha: 0.15),
                border: Border.all(color: AppTheme.hudCrimson, width: 1.2),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.hudCrimson.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: AppTheme.hudCrimson, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "LITHIUM PLATING ONSET RISK",
                    style: AppTheme.labelCaps.copyWith(
                      color: AppTheme.hudCrimson,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.hudCrimson, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StitchHypercarGaugePainter extends CustomPainter {
  final double cRate;

  _StitchHypercarGaugePainter({required this.cRate});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    const radius = 88.0;
    const strokeWidth = 12.0;

    const startAngle = 135.0 * (math.pi / 180.0);
    const sweepAngle = 270.0 * (math.pi / 180.0);

    // 1. Background Track
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1B1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // 2. Zone 1: Mint Safe (0 to 1.5C => ~30% of 270 deg)
    final mintPaint = Paint()
      ..color = AppTheme.primaryMint.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * 0.30,
      false,
      mintPaint,
    );

    // 3. Zone 2: Amber Stress (1.5 to 2.5C => next ~20%)
    final amberPaint = Paint()
      ..color = AppTheme.hudAmber.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + sweepAngle * 0.30,
      sweepAngle * 0.20,
      false,
      amberPaint,
    );

    // 4. Zone 3: Crimson Hazard (2.5 to 5.0C => final 50%)
    final crimsonPaint = Paint()
      ..color = AppTheme.hudCrimson.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + sweepAngle * 0.50,
      sweepAngle * 0.50,
      false,
      crimsonPaint,
    );

    // 5. Active Glowing Progress Arc
    final progress = (cRate / 5.0).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * progress;

    Color activeColor;
    if (cRate < 1.5) {
      activeColor = AppTheme.primaryMint;
    } else if (cRate < 2.5) {
      activeColor = AppTheme.hudAmber;
    } else {
      activeColor = AppTheme.hudCrimson;
    }

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round;

    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StitchHypercarGaugePainter oldDelegate) {
    return oldDelegate.cRate != cRate;
  }
}
