import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class _BurstParticle {
  _BurstParticle({
    required this.velocity,
    required this.radius,
    required this.color,
  });

  final Vector2 position = Vector2.zero();
  final Vector2 velocity;
  final double radius;
  final Color color;
}

class RadialBurstComponent extends PositionComponent {
  RadialBurstComponent({
    required Vector2 origin,
    required this.baseColor,
    this.particleCount = 18,
    this.duration = 0.55,
    this.maxSpeed = 24.0,
  }) : super(position: origin.clone());

  final Color baseColor;
  final int particleCount;
  final double duration;
  final double maxSpeed;

  final List<_BurstParticle> _particles = [];
  double _elapsed = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final rng = math.Random();
    for (int i = 0; i < particleCount; i++) {
      final baseAngle = (2 * math.pi * i) / particleCount;
      final jitter = (rng.nextDouble() - 0.5) * 0.25;
      final speed = maxSpeed * (0.45 + rng.nextDouble() * 0.55);
      final velocity = Vector2(
        math.cos(baseAngle + jitter) * speed,
        math.sin(baseAngle + jitter) * speed,
      );
      final particleColor = i.isEven
          ? baseColor
          : Color.lerp(baseColor, Colors.white, 0.55)!;
      _particles.add(
        _BurstParticle(
          velocity: velocity,
          radius: 0.35 + rng.nextDouble() * 0.35,
          color: particleColor,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }
    for (final p in _particles) {
      p.position.addScaled(p.velocity, dt);
      p.velocity.scale(0.92);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in _particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.position.x, p.position.y),
        p.radius * (1.0 - progress * 0.5),
        paint,
      );
    }
  }
}

class FloatingPopupComponent extends PositionComponent {
  FloatingPopupComponent({
    required Vector2 origin,
    required this.text,
    required this.color,
    this.duration = 0.85,
  }) : super(position: origin.clone());

  final String text;
  final Color color;
  final double duration;
  double _elapsed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position.y -= 6.5 * dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final scale = 0.12 * (1.0 + math.sin(progress * math.pi) * 0.25);

    canvas.save();
    canvas.scale(scale, scale);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: opacity),
        fontSize: 18,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: opacity * 0.85),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }
}

class CameraShakeController {
  final math.Random _rng = math.Random();
  double _remainingTime = 0.0;
  double _intensity = 0.0;
  final Vector2 currentOffset = Vector2.zero();

  bool get isShaking => _remainingTime > 0.0;

  void trigger({double intensity = 0.8, double duration = 0.25}) {
    _intensity = math.max(_intensity, intensity);
    _remainingTime = math.max(_remainingTime, duration);
  }

  Vector2 update(double dt) {
    if (_remainingTime <= 0.0) {
      _remainingTime = 0.0;
      _intensity = 0.0;
      currentOffset.setZero();
      return currentOffset;
    }
    _remainingTime = math.max(0.0, _remainingTime - dt);
    final damper = (_remainingTime / 0.25).clamp(0.0, 1.0);
    currentOffset.setValues(
      (_rng.nextDouble() * 2 - 1) * _intensity * damper,
      (_rng.nextDouble() * 2 - 1) * _intensity * damper,
    );
    return currentOffset;
  }
}
