import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../../models/orb_tier.dart';
import '../lab_drop_game.dart';
import 'bumper_peg.dart';

class OrbBody extends BodyComponent<LabDropGame> with ContactCallbacks {
  OrbBody({
    required this.tier,
    required this.initialPosition,
    this.isOmniOrb = false,
    Vector2? initialImpulse,
    bool playMergePop = false,
  })  : _initialImpulse = initialImpulse,
        _squashTimer = playMergePop ? 0.28 : 0.16,
        lastVelocity = initialImpulse?.clone() ?? Vector2.zero(),
        super(renderBody: false);

  final OrbTier tier;
  final Vector2 initialPosition;
  final bool isOmniOrb;
  final Vector2? _initialImpulse;
  final Vector2 lastVelocity;

  bool isMerging = false;
  double overloadOverlapSeconds = 0.0;
  double animTime = 0.0;
  double _squashTimer;

  Vector2 get safePosition => isMounted ? body.position : initialPosition;
  Vector2 get safeVelocity => isMounted ? body.linearVelocity : lastVelocity;

  void applySafeImpulse(Vector2 impulse) {
    lastVelocity.add(impulse);
    if (isMounted) {
      body.applyLinearImpulse(impulse);
    }
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = tier.radius;
    final fixtureDef = FixtureDef(
      shape,
      density: tier.density,
      restitution: tier.restitution,
      friction: 0.28,
    );
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition.clone(),
      bullet: tier.radius <= 2.7,
      userData: this,
    );
    final createdBody = world.createBody(bodyDef)..createFixture(fixtureDef);
    if (_initialImpulse != null) {
      createdBody.applyLinearImpulse(_initialImpulse);
      lastVelocity.setFrom(createdBody.linearVelocity);
    }
    return createdBody;
  }

  @override
  void update(double dt) {
    super.update(dt);
    animTime += dt;
    if (isMounted) {
      lastVelocity.setFrom(body.linearVelocity);
    }
    if (_squashTimer > 0) {
      _squashTimer = math.max(0.0, _squashTimer - dt);
    }

    if (!isMerging && tier == OrbTier.tier6 && isMounted) {
      _applyMagneticAttraction();
    }
  }

  void _applyMagneticAttraction() {
    OrbBody? nearestTarget;
    double nearestDistSq = 15.0 * 15.0;

    for (final other in game.activeOrbs) {
      if (identical(other, this) || other.isMerging) continue;
      if (other.tier != OrbTier.tier6 || !other.isMounted) continue;
      final delta = other.body.position - body.position;
      final distSq = delta.length2;
      if (distSq > 0.001 && distSq <= nearestDistSq) {
        nearestDistSq = distSq;
        nearestTarget = other;
      }
    }

    if (nearestTarget != null) {
      final dir = (nearestTarget.body.position - body.position);
      final dist = dir.length;
      if (dist > 0.01) {
        dir.normalize();
        final strength = (1.0 - (dist / 15.0)).clamp(0.15, 1.0) * 65.0;
        body.applyForce(dir * strength);
      }
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (isMerging) return;

    if (other is OrbBody && !other.isMerging) {
      final canMerge = isOmniOrb || other.isOmniOrb || tier == other.tier;
      if (canMerge) {
        game.enqueueMerge(this, other);
      }
    } else if (other is BumperPeg) {
      other.onOrbHit();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (_squashTimer > 0.0) {
      final phase = (_squashTimer / 0.28) * math.pi * 2;
      final sx = 1.0 + math.sin(phase) * 0.18;
      final sy = 1.0 - math.sin(phase) * 0.18;
      canvas.scale(sx, sy);
    }
    tier.renderProcedural(
      canvas,
      tier.radius,
      animTime: animTime,
      isOmniOrb: isOmniOrb,
    );
    canvas.restore();
  }
}
