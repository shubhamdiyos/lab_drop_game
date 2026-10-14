import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../lab_drop_game.dart';

class OverloadLaser extends PositionComponent with HasGameReference<LabDropGame> {
  OverloadLaser({
    required this.leftX,
    required this.rightX,
    required this.laserY,
  });

  static const double overloadThresholdSeconds = 3.0;

  final double leftX;
  final double rightX;
  final double laserY;

  double maxOverlapSeconds = 0.0;
  double _animTime = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position.setValues(leftX, laserY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
    if (game.isGameOver) return;

    double currentMax = 0.0;
    for (final orb in game.activeOrbs) {
      if (orb.isMerging) continue;

      final bool isSettled =
          orb.animTime > 0.65 && orb.safeVelocity.length < 4.5;
      final double orbTopY = orb.safePosition.y - orb.tier.radius;
      final double orbBottomY = orb.safePosition.y + orb.tier.radius;
      final bool overlapsLine = orbTopY <= laserY && orbBottomY >= laserY - 4.0;

      if (isSettled && overlapsLine) {
        orb.overloadOverlapSeconds += dt;
      } else {
        orb.overloadOverlapSeconds =
            math.max(0.0, orb.overloadOverlapSeconds - dt * 2.0);
      }

      if (orb.overloadOverlapSeconds > currentMax) {
        currentMax = orb.overloadOverlapSeconds;
      }
    }

    maxOverlapSeconds = currentMax;
    if (maxOverlapSeconds > overloadThresholdSeconds) {
      game.triggerGameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final width = rightX - leftX;
    final warningRatio =
        (maxOverlapSeconds / overloadThresholdSeconds).clamp(0.0, 1.0);
    final pulse = 0.5 + 0.5 * math.sin(_animTime * (6.0 + warningRatio * 14.0));

    final laserColor = Color.lerp(
      const Color(0xFFFF5252),
      const Color(0xFFFF1744),
      warningRatio,
    )!;

    if (warningRatio > 0.05) {
      canvas.drawLine(
        Offset.zero,
        Offset(width, 0),
        Paint()
          ..color = laserColor.withValues(alpha: 0.35 + 0.35 * pulse)
          ..strokeWidth = 0.85
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );
    }

    final dashPaint = Paint()
      ..color = laserColor.withValues(alpha: 0.65 + 0.35 * warningRatio)
      ..strokeWidth = 0.18 + 0.14 * warningRatio
      ..strokeCap = StrokeCap.round;

    const double dashLen = 1.4;
    const double gapLen = 0.8;
    double x = 0.0;
    while (x < width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dashLen, width), 0),
        dashPaint,
      );
      x += dashLen + gapLen;
    }

    final nodePaint = Paint()..color = laserColor;
    canvas.drawCircle(Offset.zero, 0.55, nodePaint);
    canvas.drawCircle(Offset(width, 0), 0.55, nodePaint);
  }
}
