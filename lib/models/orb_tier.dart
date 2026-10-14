import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Specification for all 10 Orb Evolution Tiers in LabDrop: Chain Reaction!
enum OrbTier {
  tier1(
    tierNumber: 1,
    name: 'Static Spark',
    radius: 1.4,
    density: 1.0,
    restitution: 0.50,
    colorHex: 0xFF00E5FF,
    proceduralStyle: 'Cyan core + 4 electric spikes',
    points: 10,
    dropWeight: 45,
  ),
  tier2(
    tierNumber: 2,
    name: 'Copper Gear',
    radius: 2.0,
    density: 1.2,
    restitution: 0.40,
    colorHex: 0xFFFF8A65,
    proceduralStyle: 'Bronze ring + 6 teeth + hollow center',
    points: 25,
    dropWeight: 30,
  ),
  tier3(
    tierNumber: 3,
    name: 'Spring Coil',
    radius: 2.7,
    density: 0.9,
    restitution: 0.75,
    colorHex: 0xFF76FF03,
    proceduralStyle: 'Lime green concentric spiral',
    points: 60,
    dropWeight: 15,
  ),
  tier4(
    tierNumber: 4,
    name: 'Plasma Bulb',
    radius: 3.5,
    density: 1.1,
    restitution: 0.45,
    colorHex: 0xFFE040FB,
    proceduralStyle: 'Violet glass sphere + inner glowing filament',
    points: 150,
    dropWeight: 10,
  ),
  tier5(
    tierNumber: 5,
    name: 'Gyro Core',
    radius: 4.4,
    density: 1.4,
    restitution: 0.35,
    colorHex: 0xFFFFD740,
    proceduralStyle: 'Gold dual-ring counter-rotating gyroscope',
    points: 350,
    dropWeight: 0,
  ),
  tier6(
    tierNumber: 6,
    name: 'Magnet Sphere',
    radius: 5.4,
    density: 1.8,
    restitution: 0.30,
    colorHex: 0xFFFF5252,
    proceduralStyle: 'Red/Blue split sphere; pulls nearest Tier 6 orb within 15 units',
    points: 800,
    dropWeight: 0,
  ),
  tier7(
    tierNumber: 7,
    name: 'Tesla Orb',
    radius: 6.6,
    density: 1.5,
    restitution: 0.40,
    colorHex: 0xFF536DFE,
    proceduralStyle: 'Indigo sphere with animated lightning arcs',
    points: 1800,
    dropWeight: 0,
  ),
  tier8(
    tierNumber: 8,
    name: 'Gravity Lens',
    radius: 7.9,
    density: 2.2,
    restitution: 0.25,
    colorHex: 0xFF00BFA5,
    proceduralStyle: 'Teal warping concentric ripples',
    points: 4000,
    dropWeight: 0,
  ),
  tier9(
    tierNumber: 9,
    name: 'Fusion Reactor',
    radius: 9.4,
    density: 2.8,
    restitution: 0.20,
    colorHex: 0xFFFFAB00,
    proceduralStyle: 'Solar core with 3 atomic electron orbits',
    points: 9000,
    dropWeight: 0,
  ),
  tier10(
    tierNumber: 10,
    name: 'Singularity',
    radius: 11.2,
    density: 4.0,
    restitution: 0.10,
    colorHex: 0xFF212121,
    proceduralStyle: 'Black event horizon + neon orange halo',
    points: 25000,
    dropWeight: 0,
  );

  const OrbTier({
    required this.tierNumber,
    required this.name,
    required this.radius,
    required this.density,
    required this.restitution,
    required this.colorHex,
    required this.proceduralStyle,
    required this.points,
    required this.dropWeight,
  });

  final int tierNumber;
  final String name;
  final double radius;
  final double density;
  final double restitution;
  final int colorHex;
  final String proceduralStyle;
  final int points;
  final int dropWeight;

  Color get color => Color(colorHex);

  /// Returns the next tier in the merge chain, or null if already Tier 10.
  OrbTier? get nextTier {
    final nextIndex = index + 1;
    if (nextIndex >= OrbTier.values.length) {
      return null;
    }
    return OrbTier.values[nextIndex];
  }

  /// Looks up an [OrbTier] by 1-based tier number (1..10).
  static OrbTier fromNumber(int number) {
    return OrbTier.values[(number - 1).clamp(0, OrbTier.values.length - 1)];
  }

  /// Weighted random selection for claw spawns (Tiers 1-4 only: 45%, 30%, 15%, 10%).
  static OrbTier rollSpawnTier([math.Random? random]) {
    final rng = random ?? math.Random();
    final roll = rng.nextInt(100);
    if (roll < 45) return OrbTier.tier1;
    if (roll < 75) return OrbTier.tier2;
    if (roll < 90) return OrbTier.tier3;
    return OrbTier.tier4;
  }

  /// Procedurally renders the orb onto a [Canvas] centered at [Offset.zero] with radius [drawRadius].
  void renderProcedural(
    Canvas canvas,
    double drawRadius, {
    double animTime = 0.0,
    bool isOmniOrb = false,
  }) {
    if (isOmniOrb) {
      _renderOmniOrb(canvas, drawRadius, animTime);
      return;
    }

    final glowPaint = Paint()
      ..color = (this == OrbTier.tier10
              ? const Color(0xFFFF6D00)
              : color)
          .withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(Offset.zero, drawRadius * 1.12, glowPaint);

    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.95,
        colors: [
          Color.lerp(color, Colors.white, 0.35)!,
          color,
          Color.lerp(color, Colors.black, 0.45)!,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: drawRadius));
    canvas.drawCircle(Offset.zero, drawRadius, basePaint);

    switch (this) {
      case OrbTier.tier1:
        final spikePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = drawRadius * 0.16
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        for (int i = 0; i < 4; i++) {
          final angle = (i * math.pi / 2) + animTime * 2.5;
          final inner = Offset(
            math.cos(angle) * drawRadius * 0.35,
            math.sin(angle) * drawRadius * 0.35,
          );
          final mid = Offset(
            math.cos(angle + 0.2) * drawRadius * 0.72,
            math.sin(angle + 0.2) * drawRadius * 0.72,
          );
          final outer = Offset(
            math.cos(angle) * drawRadius * 1.08,
            math.sin(angle) * drawRadius * 1.08,
          );
          final path = Path()
            ..moveTo(inner.dx, inner.dy)
            ..lineTo(mid.dx, mid.dy)
            ..lineTo(outer.dx, outer.dy);
          canvas.drawPath(path, spikePaint);
        }
        canvas.drawCircle(
          Offset.zero,
          drawRadius * 0.42,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
        break;

      case OrbTier.tier2:
        final toothPaint = Paint()
          ..color = const Color(0xFFFFAB91)
          ..style = PaintingStyle.fill;
        for (int i = 0; i < 6; i++) {
          final angle = i * (math.pi / 3) + animTime;
          canvas.save();
          canvas.rotate(angle);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(drawRadius * 0.82, 0),
                width: drawRadius * 0.36,
                height: drawRadius * 0.28,
              ),
              Radius.circular(drawRadius * 0.06),
            ),
            toothPaint,
          );
          canvas.restore();
        }
        canvas.drawCircle(
          Offset.zero,
          drawRadius * 0.65,
          Paint()
            ..color = const Color(0xFFD84315)
            ..style = PaintingStyle.stroke
            ..strokeWidth = drawRadius * 0.18,
        );
        canvas.drawCircle(
          Offset.zero,
          drawRadius * 0.32,
          Paint()..color = const Color(0xFF1A1D2E),
        );
        break;

      case OrbTier.tier3:
        final spiralPaint = Paint()
          ..color = const Color(0xFFCCFF90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawRadius * 0.12
          ..strokeCap = StrokeCap.round;
        final spiralPath = Path();
        const int steps = 40;
        for (int i = 0; i <= steps; i++) {
          final t = i / steps;
          final angle = t * 5.0 * math.pi + animTime * 2.0;
          final r = t * drawRadius * 0.82;
          final pt = Offset(math.cos(angle) * r, math.sin(angle) * r);
          if (i == 0) {
            spiralPath.moveTo(pt.dx, pt.dy);
          } else {
            spiralPath.lineTo(pt.dx, pt.dy);
          }
        }
        canvas.drawPath(spiralPath, spiralPaint);
        break;

      case OrbTier.tier4:
        final filamentPaint = Paint()
          ..color = const Color(0xFFFF80AB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawRadius * 0.1
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 * math.pi / 5) + math.sin(animTime * 3 + i) * 0.3;
          final path = Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(
              math.cos(angle + 0.4) * drawRadius * 0.5,
              math.sin(angle + 0.4) * drawRadius * 0.5,
              math.cos(angle) * drawRadius * 0.85,
              math.sin(angle) * drawRadius * 0.85,
            );
          canvas.drawPath(path, filamentPaint);
        }
        canvas.drawCircle(
          Offset.zero,
          drawRadius * 0.28,
          Paint()..color = Colors.white,
        );
        break;

      case OrbTier.tier5:
        final ringPaint = Paint()
          ..color = const Color(0xFFFFF59D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawRadius * 0.12;
        canvas.save();
        canvas.rotate(animTime * 1.8);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: drawRadius * 1.65,
            height: drawRadius * 0.75,
          ),
          ringPaint,
        );
        canvas.restore();

        canvas.save();
        canvas.rotate(-animTime * 1.8 + math.pi / 3);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: drawRadius * 1.65,
            height: drawRadius * 0.75,
          ),
          ringPaint,
        );
        canvas.restore();

        canvas.drawCircle(
          Offset.zero,
          drawRadius * 0.3,
          Paint()..color = const Color(0xFFFFFDE7),
        );
        break;

      case OrbTier.tier6:
        final clipRectLeft = Rect.fromLTRB(-drawRadius, -drawRadius, 0, drawRadius);
        final clipRectRight = Rect.fromLTRB(0, -drawRadius, drawRadius, drawRadius);
        final circlePath = Path()
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: drawRadius * 0.92));

        canvas.save();
        canvas.clipPath(circlePath);
        canvas.drawRect(
          clipRectLeft,
          Paint()..color = const Color(0xFFFF1744),
        );
        canvas.drawRect(
          clipRectRight,
          Paint()..color = const Color(0xFF2979FF),
        );
        canvas.restore();

        canvas.drawLine(
          Offset(0, -drawRadius * 0.92),
          Offset(0, drawRadius * 0.92),
          Paint()
            ..color = Colors.white
            ..strokeWidth = drawRadius * 0.08,
        );
        break;

      case OrbTier.tier7:
        final arcPaint = Paint()
          ..color = const Color(0xFF82B1FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawRadius * 0.09;
        for (int i = 0; i < 6; i++) {
          final a = (i * math.pi / 3) + animTime * 2.2;
          final p1 = Offset(math.cos(a) * drawRadius * 0.25, math.sin(a) * drawRadius * 0.25);
          final p2 = Offset(
            math.cos(a + 0.25) * drawRadius * 0.6,
            math.sin(a - 0.25) * drawRadius * 0.6,
          );
          final p3 = Offset(math.cos(a) * drawRadius * 0.92, math.sin(a) * drawRadius * 0.92);
          final path = Path()
            ..moveTo(p1.dx, p1.dy)
            ..lineTo(p2.dx, p2.dy)
            ..lineTo(p3.dx, p3.dy);
          canvas.drawPath(path, arcPaint);
        }
        canvas.drawCircle(
          Offset.zero,
          drawRadius * 0.3,
          Paint()..color = const Color(0xFFE8EAF6),
        );
        break;

      case OrbTier.tier8:
        for (int i = 1; i <= 3; i++) {
          final rippleFraction = ((i / 3.0) + (animTime * 0.4)) % 1.0;
          final r = drawRadius * (0.2 + 0.72 * rippleFraction);
          canvas.drawCircle(
            Offset.zero,
            r,
            Paint()
              ..color = const Color(0xFFA7FFEB).withValues(alpha: 1.0 - rippleFraction * 0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = drawRadius * 0.08,
          );
        }
        break;

      case OrbTier.tier9:
        final orbitPaint = Paint()
          ..color = const Color(0xFFFFE57F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawRadius * 0.07;
        for (int i = 0; i < 3; i++) {
          final rot = i * (math.pi / 3) + animTime * 1.2;
          canvas.save();
          canvas.rotate(rot);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: drawRadius * 1.75,
              height: drawRadius * 0.62,
            ),
            orbitPaint,
          );
          final electronAngle = animTime * 3.5 + i * 2.0;
          final ex = math.cos(electronAngle) * drawRadius * 0.875;
          final ey = math.sin(electronAngle) * drawRadius * 0.31;
          canvas.drawCircle(
            Offset(ex, ey),
            drawRadius * 0.11,
            Paint()..color = Colors.white,
          );
          canvas.restore();
        }
        canvas.drawCircle(
          Offset.zero,
          drawRadius * 0.34,
          Paint()..color = const Color(0xFFFFF8E1),
        );
        break;

      case OrbTier.tier10:
        final haloPaint = Paint()
          ..color = const Color(0xFFFF6D00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawRadius * 0.16;
        canvas.drawCircle(Offset.zero, drawRadius * 0.88, haloPaint);

        final swirlPaint = Paint()
          ..color = const Color(0xFFFFAB40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawRadius * 0.08;
        for (int i = 0; i < 4; i++) {
          final startAngle = animTime * 2.0 + i * (math.pi / 2);
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: drawRadius * 0.72),
            startAngle,
            math.pi / 3,
            false,
            swirlPaint,
          );
        }
        canvas.drawCircle(
          Offset.zero,
          drawRadius * 0.58,
          Paint()..color = const Color(0xFF0A0A0F),
        );
        break;
    }

    canvas.drawCircle(
      Offset.zero,
      drawRadius,
      Paint()
        ..color = (this == OrbTier.tier10
                ? const Color(0xFFFF9100)
                : Colors.white.withValues(alpha: 0.55))
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawRadius * 0.06,
    );
  }

  static void _renderOmniOrb(Canvas canvas, double drawRadius, double animTime) {
    const sweepColors = [
      Color(0xFFFF1744),
      Color(0xFFFF9100),
      Color(0xFFFFEA00),
      Color(0xFF00E676),
      Color(0xFF00E5FF),
      Color(0xFFD500F9),
      Color(0xFFFF1744),
    ];
    canvas.save();
    canvas.rotate(animTime * 2.5);
    final rainbowPaint = Paint()
      ..shader = SweepGradient(colors: sweepColors).createShader(
        Rect.fromCircle(center: Offset.zero, radius: drawRadius),
      );
    canvas.drawCircle(Offset.zero, drawRadius, rainbowPaint);
    canvas.restore();

    canvas.drawCircle(
      Offset.zero,
      drawRadius * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset.zero,
      drawRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawRadius * 0.1,
    );
  }
}

class OrbPreviewPainter extends CustomPainter {
  OrbPreviewPainter({
    required this.tier,
    this.isOmniOrb = false,
    this.animTime = 0.0,
  });

  final OrbTier tier;
  final bool isOmniOrb;
  final double animTime;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    tier.renderProcedural(
      canvas,
      radius,
      animTime: animTime,
      isOmniOrb: isOmniOrb,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbPreviewPainter oldDelegate) {
    return oldDelegate.tier != tier ||
        oldDelegate.isOmniOrb != isOmniOrb ||
        oldDelegate.animTime != animTime;
  }
}
