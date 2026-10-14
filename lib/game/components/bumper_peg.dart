import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lab_drop_game.dart';

class BumperPeg extends BodyComponent<LabDropGame> with ContactCallbacks {
  BumperPeg({
    required this.pegPosition,
    this.radius = 1.35,
  }) : super(renderBody: false);

  static const double pegRestitution = 0.85;
  static const int voltsReward = 5;

  final Vector2 pegPosition;
  final double radius;

  double _flashTimer = 0.0;
  double _hitCooldown = 0.0;

  bool get isFlashing => _flashTimer > 0.0;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(
      shape,
      restitution: pegRestitution,
      friction: 0.1,
    );
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: pegPosition.clone(),
      userData: this,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  void onOrbHit() {
    if (_hitCooldown > 0.0) return;
    _flashTimer = 0.28;
    _hitCooldown = 0.12;
    game.onBumperHit( pegPosition, voltsReward);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0.0) {
      _flashTimer = math.max(0.0, _flashTimer - dt);
    }
    if (_hitCooldown > 0.0) {
      _hitCooldown = math.max(0.0, _hitCooldown - dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final bool flashing = isFlashing;
    final Color coreColor =
        flashing ? Colors.white : const Color(0xFF00E676);
    final Color ringColor =
        flashing ? const Color(0xFFFFEA00) : const Color(0xFF00E5FF);

    final double drawScale = flashing ? 1.22 : 1.0;
    canvas.save();
    canvas.scale(drawScale, drawScale);

    canvas.drawCircle(
      Offset.zero,
      radius * 1.3,
      Paint()
        ..color = ringColor.withValues(alpha: flashing ? 0.55 : 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset.zero,
      radius * 0.85,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.24,
    );

    canvas.drawCircle(
      Offset.zero,
      radius * 0.42,
      Paint()..color = coreColor,
    );

    canvas.restore();
  }
}
