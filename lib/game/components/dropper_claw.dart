import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/orb_tier.dart';
import '../lab_drop_game.dart';

class DropperClaw extends PositionComponent with HasGameReference<LabDropGame> {
  DropperClaw({
    required this.minX,
    required this.maxX,
    required this.clawY,
    required this.chamberBottomY,
  }) : currentX = (minX + maxX) / 2.0;

  static const double dropCooldownDuration = 0.35;

  final double minX;
  final double maxX;
  final double clawY;
  final double chamberBottomY;

  double currentX;
  double cooldownRemaining = 0.0;
  double _animTime = 0.0;

  bool get canDrop => cooldownRemaining <= 0.0 && !game.isGameOver;

  void moveToWorldX(double targetX) {
    currentX = targetX.clamp(minX, maxX);
    position.setValues(currentX, clawY);
  }

  void triggerDropCooldown() {
    cooldownRemaining = dropCooldownDuration;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position.setValues(currentX, clawY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
    if (cooldownRemaining > 0.0) {
      cooldownRemaining = (cooldownRemaining - dt).clamp(0.0, dropCooldownDuration);
    }
    position.setValues(currentX, clawY);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final railPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 0.25
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(minX - currentX, -1.2),
      Offset(maxX - currentX, -1.2),
      railPaint,
    );

    final aimColor = game.isOmniOrbArmed
        ? const Color(0xFFFFEA00)
        : game.currentTier.color.withValues(alpha: 0.45);
    final aimPaint = Paint()
      ..color = aimColor
      ..strokeWidth = 0.16
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 0.9;
    const double gapHeight = 0.75;
    double yCursor = 2.0;
    final double maxAimDistance = (chamberBottomY - clawY) - 2.0;
    while (yCursor < maxAimDistance) {
      canvas.drawLine(
        Offset(0, yCursor),
        Offset(0, (yCursor + dashHeight).clamp(0.0, maxAimDistance)),
        aimPaint,
      );
      yCursor += dashHeight + gapHeight;
    }

    final carriagePaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -1.1), width: 2.8, height: 1.1),
        const Radius.circular(0.3),
      ),
      carriagePaint,
    );

    final openSpread = canDrop ? 0.0 : 0.65;
    final pincerPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 0.32
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftPath = Path()
      ..moveTo(-0.9, -0.6)
      ..quadraticBezierTo(-1.7 - openSpread, 0.2, -1.1 - openSpread, 1.1);
    canvas.drawPath(leftPath, pincerPaint);

    final rightPath = Path()
      ..moveTo(0.9, -0.6)
      ..quadraticBezierTo(1.7 + openSpread, 0.2, 1.1 + openSpread, 1.1);
    canvas.drawPath(rightPath, pincerPaint);

    if (canDrop) {
      final OrbTier heldTier = game.currentTier;
      canvas.save();
      canvas.translate(0, 0.55);
      heldTier.renderProcedural(
        canvas,
        heldTier.radius * 0.85,
        animTime: _animTime,
        isOmniOrb: game.isOmniOrbArmed,
      );
      canvas.restore();
    }
  }
}
