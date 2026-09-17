import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../theme/colors.dart';

/// Pseudo-3D animated single-cylinder engine visualization with Gyro effect.
///
/// Features:
/// - Isometric-style engine block using CustomPainter with metallic gradients.
/// - Holographic 3D tilt using accelerometer data and Matrix4 perspective.
/// - Piston animated in sync with RPM (sinusoidal motion).
/// - Air-cooling fins on the cylinder.
class EngineViz extends StatefulWidget {
  final double rpm;

  const EngineViz({super.key, required this.rpm});

  @override
  State<EngineViz> createState() => _EngineVizState();
}

class _EngineVizState extends State<EngineViz>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // Gyroscope / Accelerometer state
  double _pitch = 0.0;
  double _roll = 0.0;
  double _targetPitch = 0.0;
  double _targetRoll = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _updateAnimSpeed();
    _controller.repeat();

    // Listen to accelerometer for tilt.
    // We use a relatively slow sampling rate since we EMA smooth it.
    _accelSub = accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 30))
        .listen((event) {
      // In landscape, X and Y map to pitch and roll.
      // Scaling down to subtle angles (radians).
      _targetPitch = (event.x * 0.06).clamp(-0.35, 0.35);
      _targetRoll = (event.y * 0.06).clamp(-0.35, 0.35);
    });
  }

  @override
  void didUpdateWidget(EngineViz old) {
    super.didUpdateWidget(old);
    if ((old.rpm - widget.rpm).abs() > 50) {
      _updateAnimSpeed();
    }
  }

  void _updateAnimSpeed() {
    final effectiveRpm = widget.rpm.clamp(100, 9000);
    final cycleDurationMs = (60000 / effectiveRpm).round();
    _controller.duration = Duration(milliseconds: cycleDurationMs.clamp(7, 600));

    if (_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Apply EMA for buttery smooth 3D tilt
            _pitch += (_targetPitch - _pitch) * 0.1;
            _roll += (_targetRoll - _roll) * 0.1;

            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // perspective depth
              ..rotateX(_pitch)
              ..rotateY(_roll);

            return Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: CustomPaint(
                size: size,
                painter: _EnginePainter(
                  crankAngle: _controller.value * 2 * pi,
                  isDark: isDark,
                  pitch: _pitch,
                  roll: _roll,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EnginePainter extends CustomPainter {
  final double crankAngle;
  final bool isDark;
  final double pitch;
  final double roll;

  _EnginePainter({
    required this.crankAngle,
    required this.isDark,
    required this.pitch,
    required this.roll,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = min(w, h);
    final cx = w / 2;
    final cy = h * 0.55;

    final boreW = scale * 0.3;
    final boreH = scale * 0.35;
    final crankR = scale * 0.08;
    final pistonH = scale * 0.08;
    final headH = scale * 0.1;
    final crankcaseW = scale * 0.45;
    final crankcaseH = scale * 0.18;
    final finSpacing = scale * 0.04;
    final skew = scale * 0.04;

    // ── Drop Shadow ──
    // The shadow shifts slightly opposite to the tilt for a parallax effect.
    final shadowX = cx + (roll * scale * 1.5);
    final shadowY = cy + boreH + crankcaseH + (pitch * scale * 1.5) - scale * 0.1;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.6 : 0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale * 0.15);
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shadowX, shadowY),
        width: crankcaseW * 1.2,
        height: crankcaseH * 0.8,
      ),
      shadowPaint,
    );

    // ── Crankcase ──
    final crankcaseTop = cy + boreH / 2;
    _drawPremiumBlock(
      canvas,
      rect: Rect.fromCenter(
        center: Offset(cx, crankcaseTop + crankcaseH / 2),
        width: crankcaseW,
        height: crankcaseH,
      ),
      color: isDark ? AppColors.lavenderDark : AppColors.lavender,
      skew: skew,
      borderRadius: scale * 0.04,
    );

    // ── Cylinder bore ──
    final boreTop = cy - boreH / 2;
    _drawPremiumBlock(
      canvas,
      rect: Rect.fromLTWH(cx - boreW / 2, boreTop, boreW, boreH),
      color: AppColors.engineCylinder,
      skew: skew * 0.7,
      borderRadius: scale * 0.02,
    );

    // ── Cooling fins ──
    final finColor = isDark ? AppColors.lavenderLight : AppColors.engineFin;
    final finPaint = Paint()
      ..strokeWidth = max(1.5, scale * 0.015)
      ..strokeCap = StrokeCap.round;

    for (var fy = boreTop + finSpacing; fy < cy + boreH / 2 - finSpacing; fy += finSpacing) {
      final finW = boreW + scale * 0.14;
      // Add a slight gradient to the fins by drawing two overlapping lines
      finPaint.color = finColor.withValues(alpha: 0.8);
      canvas.drawLine(
        Offset(cx - finW / 2, fy),
        Offset(cx + finW / 2, fy),
        finPaint,
      );
      finPaint.color = Colors.black.withValues(alpha: 0.2);
      canvas.drawLine(
        Offset(cx - finW / 2, fy + 1),
        Offset(cx + finW / 2, fy + 1),
        finPaint,
      );
    }

    // ── Piston ──
    final pistonTravel = boreH * 0.35;
    final pistonY = cy + sin(crankAngle) * pistonTravel * 0.5;
    final pistonRect = Rect.fromCenter(
      center: Offset(cx, pistonY),
      width: boreW * 0.75,
      height: pistonH,
    );

    final pistonColor = isDark ? AppColors.sageDark : AppColors.enginePiston;
    _drawPremiumBlock(
      canvas,
      rect: pistonRect,
      color: pistonColor,
      skew: 0,
      borderRadius: scale * 0.015,
      isMetallic: true,
    );

    // Piston ring lines
    final ringPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = max(1, scale * 0.01);
    canvas.drawLine(
      Offset(pistonRect.left + 4, pistonRect.top + pistonH * 0.25),
      Offset(pistonRect.right - 4, pistonRect.top + pistonH * 0.25),
      ringPaint,
    );
    canvas.drawLine(
      Offset(pistonRect.left + 4, pistonRect.top + pistonH * 0.5),
      Offset(pistonRect.right - 4, pistonRect.top + pistonH * 0.5),
      ringPaint,
    );

    // ── Connecting rod ──
    final crankCenterY = crankcaseTop + crankcaseH * 0.4;
    final crankPinX = cx + cos(crankAngle) * crankR;
    final crankPinY = crankCenterY + sin(crankAngle) * crankR;

    final rodColor = isDark ? AppColors.coralDark : AppColors.engineRod;
    
    // Draw thick shadow for rod
    canvas.drawLine(
      Offset(cx + 2, pistonY + pistonH / 2 + 2),
      Offset(crankPinX + 2, crankPinY + 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = max(3.0, scale * 0.025)
        ..strokeCap = StrokeCap.round,
    );

    // Draw main rod
    canvas.drawLine(
      Offset(cx, pistonY + pistonH / 2),
      Offset(crankPinX, crankPinY),
      Paint()
        ..color = rodColor
        ..strokeWidth = max(2.5, scale * 0.025)
        ..strokeCap = StrokeCap.round,
    );

    // Crankshaft pin dot
    canvas.drawCircle(
      Offset(crankPinX, crankPinY),
      max(4, scale * 0.03),
      Paint()..color = rodColor,
    );
    // Pin highlight
    canvas.drawCircle(
      Offset(crankPinX - 1, crankPinY - 1),
      max(2, scale * 0.01),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    // Center pivot
    canvas.drawCircle(
      Offset(cx, crankCenterY),
      max(3, scale * 0.02),
      Paint()..color = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
    );

    // ── Cylinder head ──
    _drawPremiumBlock(
      canvas,
      rect: Rect.fromLTWH(
        cx - boreW / 2 - scale * 0.03,
        boreTop - headH,
        boreW + scale * 0.06,
        headH,
      ),
      color: isDark ? AppColors.skyBlueDark : AppColors.engineHead,
      skew: skew * 0.5,
      borderRadius: scale * 0.03,
    );

    // ── Valve bumps ──
    final valveColor = (isDark ? AppColors.skyBlueDark : AppColors.skyBlue);
    final valvePaint = Paint()
      ..color = valveColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    final valveR = scale * 0.035;
    
    void drawValve(Offset center) {
      // Base
      canvas.drawOval(
        Rect.fromCenter(center: center, width: valveR * 2.2, height: valveR * 1.4),
        valvePaint,
      );
      // Highlight
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 2), width: valveR * 1.5, height: valveR * 0.8),
        Paint()..color = Colors.white.withValues(alpha: 0.2),
      );
    }

    drawValve(Offset(cx - boreW * 0.2, boreTop - headH * 0.5));
    drawValve(Offset(cx + boreW * 0.2, boreTop - headH * 0.5));
  }

  void _drawPremiumBlock(
    Canvas canvas, {
    required Rect rect,
    required Color color,
    double skew = 0,
    double borderRadius = 8,
    bool isMetallic = false,
  }) {
    final mainRRect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    // Create a rich linear gradient for the main face
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isMetallic
          ? [
              color.withValues(alpha: 0.5), // Lighter metallic reflection
              color,
              color.withValues(alpha: 0.7), // Shadowed side
            ]
          : [
              color.withValues(alpha: 0.8),
              color,
              Color.lerp(color, Colors.black, 0.15) ?? color,
            ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawRRect(mainRRect, Paint()..shader = gradient.createShader(rect));

    // Right side (3D depth)
    if (skew > 0) {
      final sidePath = Path()
        ..moveTo(rect.right, rect.top + borderRadius)
        ..lineTo(rect.right + skew, rect.top + borderRadius - skew * 0.5)
        ..lineTo(rect.right + skew, rect.bottom - borderRadius - skew * 0.5)
        ..lineTo(rect.right, rect.bottom - borderRadius)
        ..close();
      canvas.drawPath(
        sidePath,
        Paint()..color = Color.lerp(color, Colors.black, 0.3)!.withValues(alpha: 0.9),
      );
    }

    // Top face (3D depth)
    if (skew > 0) {
      final topPath = Path()
        ..moveTo(rect.left + borderRadius, rect.top)
        ..lineTo(rect.left + borderRadius + skew, rect.top - skew * 0.5)
        ..lineTo(rect.right + skew, rect.top - skew * 0.5)
        ..lineTo(rect.right, rect.top)
        ..close();
      canvas.drawPath(
        topPath,
        Paint()..color = Color.lerp(color, Colors.white, 0.2)!.withValues(alpha: 0.9),
      );
    }

    // Specular highlight border
    canvas.drawRRect(
      mainRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _EnginePainter old) =>
      old.crankAngle != crankAngle || 
      old.isDark != isDark ||
      old.pitch != pitch ||
      old.roll != roll;
}
