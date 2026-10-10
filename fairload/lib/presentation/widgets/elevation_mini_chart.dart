import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/telemetry_point.dart';
import '../../core/theme/app_theme.dart';

class ElevationMiniChart extends StatelessWidget {
  final List<TelemetryPoint> points;
  final int currentIndex;

  const ElevationMiniChart({
    super.key,
    required this.points,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final currentPt = currentIndex < points.length ? points[currentIndex] : points.last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Text(
                "TOPOGRAPHIC PROFILE",
                style: AppTheme.labelCaps.copyWith(fontSize: 8.5, color: Colors.white38),
              ),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 13,
                    color: currentPt.inclineGradePct > 2.0 ? AppTheme.hudCrimson : AppTheme.hudCyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${currentPt.inclineGradePct >= 0 ? '+' : ''}${currentPt.inclineGradePct.toStringAsFixed(1)}% GRADE",
                    style: AppTheme.labelCaps.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: currentPt.inclineGradePct > 2.0 ? AppTheme.hudCrimson : AppTheme.hudCyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _StitchElevationPainter(
                points: points,
                currentIndex: currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchElevationPainter extends CustomPainter {
  final List<TelemetryPoint> points;
  final int currentIndex;

  _StitchElevationPainter({required this.points, required this.currentIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minElev = points.first.elevationMeters;
    double maxElev = points.first.elevationMeters;
    for (final p in points) {
      if (p.elevationMeters < minElev) minElev = p.elevationMeters;
      if (p.elevationMeters > maxElev) maxElev = p.elevationMeters;
    }
    final range = math.max(1.0, maxElev - minElev);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normElev = (points[i].elevationMeters - minElev) / range;
      final y = size.height - (normElev * (size.height - 8)) - 4;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // 1. Shaded gradient under slope
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.hudCyan.withValues(alpha: 0.22),
          AppTheme.hudCyan.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // 2. Stroke profile line
    final strokePaint = Paint()
      ..color = AppTheme.hudCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);

    // 3. Current active vehicle dot
    if (currentIndex >= 0 && currentIndex < points.length) {
      final curX = (currentIndex / (points.length - 1)) * size.width;
      final curNorm = (points[currentIndex].elevationMeters - minElev) / range;
      final curY = size.height - (curNorm * (size.height - 8)) - 4;

      final glowPaint = Paint()..color = AppTheme.hudAmber.withValues(alpha: 0.35);
      canvas.drawCircle(Offset(curX, curY), 8, glowPaint);

      final dotPaint = Paint()..color = AppTheme.hudAmber;
      canvas.drawCircle(Offset(curX, curY), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StitchElevationPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex || oldDelegate.points.length != points.length;
  }
}
