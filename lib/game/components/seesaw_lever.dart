import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../lab_drop_game.dart';

class SeesawLever extends BodyComponent<LabDropGame> {
  SeesawLever({
    required this.pivotPosition,
    this.halfWidth = 6.2,
    this.halfHeight = 0.45,
    this.lowerAngleLimit = -0.45,
    this.upperAngleLimit = 0.45,
  }) : super(renderBody: false);

  final Vector2 pivotPosition;
  final double halfWidth;
  final double halfHeight;
  final double lowerAngleLimit;
  final double upperAngleLimit;

  Body? _anchorBody;
  RevoluteJoint? _joint;

  RevoluteJoint? get joint => _joint;

  @override
  Body createBody() {
    final anchorDef = BodyDef(
      type: BodyType.static,
      position: pivotPosition.clone(),
    );
    _anchorBody = world.createBody(anchorDef);

    final plankDef = BodyDef(
      type: BodyType.dynamic,
      position: pivotPosition.clone(),
      angularDamping: 1.8,
      userData: this,
    );
    final plankBody = world.createBody(plankDef);

    final plankShape = PolygonShape()..setAsBoxXY(halfWidth, halfHeight);
    plankBody.createFixture(
      FixtureDef(
        plankShape,
        density: 2.5,
        friction: 0.45,
        restitution: 0.25,
      ),
    );

    final jointDef = RevoluteJointDef()
      ..initialize(_anchorBody!, plankBody, pivotPosition.clone())
      ..enableLimit = true
      ..lowerAngle = lowerAngleLimit
      ..upperAngle = upperAngleLimit;

    final revoluteJoint = RevoluteJoint(jointDef);
    world.createJoint(revoluteJoint);
    _joint = revoluteJoint;

    return plankBody;
  }

  @override
  void onRemove() {
    if (_joint != null) {
      world.destroyJoint(_joint!);
      _joint = null;
    }
    if (_anchorBody != null) {
      world.destroyBody(_anchorBody!);
      _anchorBody = null;
    }
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: halfWidth * 2,
      height: halfHeight * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(0.25));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF455A64)
        ..style = PaintingStyle.fill,
    );

    final stripePaint = Paint()
      ..color = const Color(0xFFFFCA28).withValues(alpha: 0.75)
      ..strokeWidth = 0.22;
    canvas.save();
    canvas.clipRRect(rrect);
    for (double x = -halfWidth; x <= halfWidth; x += 1.6) {
      canvas.drawLine(
        Offset(x - 0.3, -halfHeight),
        Offset(x + 0.3, halfHeight),
        stripePaint,
      );
    }
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFCFD8DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.14,
    );
    canvas.drawCircle(
      Offset.zero,
      halfHeight * 1.45,
      Paint()..color = const Color(0xFF263238),
    );
    canvas.drawCircle(
      Offset.zero,
      halfHeight * 0.75,
      Paint()..color = const Color(0xFFFFCA28),
    );
  }
}
