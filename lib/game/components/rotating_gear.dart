import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lab_drop_game.dart';

class RotatingGear extends BodyComponent<LabDropGame> {
  RotatingGear({
    required this.centerPosition,
    required this.angularSpeed,
    this.gearRadius = 3.2,
    this.toothCount = 8,
  }) : super(renderBody: false);

  final Vector2 centerPosition;
  final double angularSpeed;
  final double gearRadius;
  final int toothCount;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.kinematic,
      position: centerPosition.clone(),
      angularVelocity: angularSpeed,
      userData: this,
    );
    final gearBody = world.createBody(bodyDef);

    final coreShape = CircleShape()..radius = gearRadius * 0.78;
    gearBody.createFixture(
      FixtureDef(
        coreShape,
        friction: 0.5,
        restitution: 0.35,
      ),
    );

    for (int i = 0; i < toothCount; i++) {
      final angle = (2 * math.pi * i) / toothCount;
      final toothCenter = Vector2(
        math.cos(angle) * (gearRadius * 0.88),
        math.sin(angle) * (gearRadius * 0.88),
      );
      final toothShape = PolygonShape()
        ..setAsBox(
          gearRadius * 0.18,
          gearRadius * 0.14,
          toothCenter,
          angle,
        );
      gearBody.createFixture(
        FixtureDef(
          toothShape,
          friction: 0.5,
          restitution: 0.35,
        ),
      );
    }

    return gearBody;
  }

  @override
  void render(Canvas canvas) {
    final accentColor = game.playerData.selectedTheme.accentColor;

    final toothPaint = Paint()
      ..color = const Color(0xFF546E7A)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < toothCount; i++) {
      final angle = (2 * math.pi * i) / toothCount;
      canvas.save();
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(gearRadius * 0.86, 0),
            width: gearRadius * 0.38,
            height: gearRadius * 0.28,
          ),
          const Radius.circular(0.15),
        ),
        toothPaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(
      Offset.zero,
      gearRadius * 0.8,
      Paint()
        ..color = const Color(0xFF37474F)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      gearRadius * 0.8,
      Paint()
        ..color = accentColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.2,
    );

    final spokePaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 0.28;
    for (int i = 0; i < 4; i++) {
      final a = i * (math.pi / 2);
      canvas.drawLine(
        Offset(math.cos(a) * gearRadius * 0.72, math.sin(a) * gearRadius * 0.72),
        Offset(-math.cos(a) * gearRadius * 0.72, -math.sin(a) * gearRadius * 0.72),
        spokePaint,
      );
    }

    canvas.drawCircle(
      Offset.zero,
      gearRadius * 0.28,
      Paint()..color = const Color(0xFF101820),
    );
    canvas.drawCircle(
      Offset.zero,
      gearRadius * 0.14,
      Paint()..color = accentColor,
    );
  }
}
