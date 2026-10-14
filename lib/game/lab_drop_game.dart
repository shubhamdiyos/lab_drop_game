import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/orb_tier.dart';
import '../models/player_data.dart';
import '../services/ad_service.dart';
import '../services/iap_service.dart';
import '../services/storage_service.dart';
import 'components/bumper_peg.dart';
import 'components/dropper_claw.dart';
import 'components/juice_effects.dart';
import 'components/orb_body.dart';
import 'components/overload_laser.dart';
import 'components/rotating_gear.dart';
import 'components/seesaw_lever.dart';

class _PendingMerge {
  const _PendingMerge(this.orbA, this.orbB);
  final OrbBody orbA;
  final OrbBody orbB;
}

class _ChamberBoundsComponent extends BodyComponent<LabDropGame> {
  _ChamberBoundsComponent({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  }) : super(renderBody: false);

  final double left;
  final double right;
  final double top;
  final double bottom;

  @override
  Body createBody() {
    final bodyDef = BodyDef(type: BodyType.static);
    final wallBody = world.createBody(bodyDef);

    final floorShape = EdgeShape()
      ..set(Vector2(left, bottom), Vector2(right, bottom));
    wallBody.createFixture(
      FixtureDef(floorShape, friction: 0.5, restitution: 0.2),
    );

    final leftShape = EdgeShape()
      ..set(Vector2(left, top), Vector2(left, bottom));
    wallBody.createFixture(
      FixtureDef(leftShape, friction: 0.3, restitution: 0.3),
    );

    final rightShape = EdgeShape()
      ..set(Vector2(right, top), Vector2(right, bottom));
    wallBody.createFixture(
      FixtureDef(rightShape, friction: 0.3, restitution: 0.3),
    );

    return wallBody;
  }

  @override
  void render(Canvas canvas) {
    final theme = game.playerData.selectedTheme;
    final rect = Rect.fromLTRB(left, top, right, bottom);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.backgroundTop, theme.backgroundBottom],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final gridPaint = Paint()
      ..color = theme.gridColor
      ..strokeWidth = 0.08;
    for (double x = left; x <= right; x += 4.0) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }
    for (double y = top; y <= bottom; y += 4.0) {
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final borderColor = game.isFeverMode
        ? const Color(0xFFFFEA00)
        : theme.accentColor.withValues(alpha: 0.75);
    final wallPaint = Paint()
      ..color = borderColor
      ..strokeWidth = game.isFeverMode ? 0.55 : 0.32
      ..style = PaintingStyle.stroke;

    final wallPath = Path()
      ..moveTo(left, top)
      ..lineTo(left, bottom)
      ..lineTo(right, bottom)
      ..lineTo(right, top);
    canvas.drawPath(wallPath, wallPaint);
  }
}

class LabDropGame extends Forge2DGame with TapCallbacks, DragCallbacks {
  LabDropGame({
    PlayerData? playerData,
    StorageService? storageService,
    AdService? adService,
    IapService? iapService,
    math.Random? random,
  })  : playerData = playerData ?? PlayerData(),
        storageService = storageService ?? StorageService(),
        adService = adService ?? AdService(),
        iapService = iapService ?? IapService(),
        _rng = random ?? math.Random(),
        super(
          gravity: Vector2(0, 25.0),
          zoom: 10.0,
        );

  static const String hudOverlayId = 'HudOverlay';
  static const String shopOverlayId = 'ShopModal';
  static const String gameOverOverlayId = 'GameOverModal';

  static const double chamberWidth = 40.0;
  static const double chamberHeight = 70.0;

  static const int earthquakeCostVolts = 150;
  static const int omniOrbCostVolts = 200;
  static const int laserZapperCostVolts = 100;

  final PlayerData playerData;
  final StorageService storageService;
  final AdService adService;
  final IapService iapService;
  final math.Random _rng;

  final ValueNotifier<int> hudTick = ValueNotifier<int>(0);

  final List<OrbBody> activeOrbs = <OrbBody>[];
  final List<_PendingMerge> _pendingMerges = <_PendingMerge>[];
  final CameraShakeController cameraShake = CameraShakeController();

  late DropperClaw dropperClaw;
  late OverloadLaser overloadLaser;
  late RotatingGear leftGear;
  late RotatingGear rightGear;
  late SeesawLever seesawLever;
  final List<BumperPeg> bumperPegs = <BumperPeg>[];

  OrbTier currentTier = OrbTier.tier1;
  OrbTier nextTier = OrbTier.tier2;

  int score = 0;
  int comboMultiplier = 1;
  double timeSinceLastMerge = 999.0;

  bool isOmniOrbArmed = false;
  bool isLaserZapperArmed = false;
  bool isGameOver = false;
  bool hasUsedReviveThisRun = false;

  bool get isFeverMode => comboMultiplier >= 5;

  double pctX(double pct) => chamberWidth * pct;
  double pctY(double pct) => chamberHeight * pct;

  @override
  Color backgroundColor() => playerData.selectedTheme.backgroundTop;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(chamberWidth / 2, chamberHeight / 2);

    currentTier = OrbTier.rollSpawnTier(_rng);
    nextTier = OrbTier.rollSpawnTier(_rng);

    await world.add(
      _ChamberBoundsComponent(
        left: 0.0,
        right: chamberWidth,
        top: 0.0,
        bottom: chamberHeight - 1.5,
      ),
    );

    dropperClaw = DropperClaw(
      minX: pctX(0.15),
      maxX: pctX(0.85),
      clawY: pctY(0.12),
      chamberBottomY: chamberHeight - 1.5,
    );
    await world.add(dropperClaw);

    overloadLaser = OverloadLaser(
      leftX: 0.0,
      rightX: chamberWidth,
      laserY: pctY(0.18),
    );
    await world.add(overloadLaser);

    leftGear = RotatingGear(
      centerPosition: Vector2(pctX(0.28), pctY(0.35)),
      angularSpeed: 1.8,
    );
    rightGear = RotatingGear(
      centerPosition: Vector2(pctX(0.72), pctY(0.35)),
      angularSpeed: -1.8,
    );
    await world.add(leftGear);
    await world.add(rightGear);

    seesawLever = SeesawLever(
      pivotPosition: Vector2(pctX(0.50), pctY(0.46)),
    );
    await world.add(seesawLever);

    final pegPositions = <Vector2>[
      Vector2(pctX(0.50), pctY(0.58)),
      Vector2(pctX(0.33), pctY(0.68)),
      Vector2(pctX(0.67), pctY(0.68)),
    ];
    for (final pos in pegPositions) {
      final peg = BumperPeg(pegPosition: pos);
      bumperPegs.add(peg);
      await world.add(peg);
    }

    _notifyHud();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) {
      final scaleX = size.x / (chamberWidth + 3.0);
      final scaleY = size.y / (chamberHeight + 6.0);
      camera.viewfinder.zoom = math.min(scaleX, scaleY).clamp(4.0, 40.0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (comboMultiplier > 1) {
      timeSinceLastMerge += dt;
      if (timeSinceLastMerge > 2.0) {
        comboMultiplier = 1;
        _notifyHud();
      }
    } else {
      timeSinceLastMerge += dt;
    }

    if (_pendingMerges.isNotEmpty) {
      _processPendingMerges();
    }

    final shakeOffset = cameraShake.update(dt);
    camera.viewfinder.position = Vector2(
      chamberWidth / 2 + shakeOffset.x,
      chamberHeight / 2 + shakeOffset.y,
    );
  }

  OrbBody? dropOrbAt({double? worldX, bool ignoreCooldown = false}) {
    if (isGameOver) return null;
    if (!ignoreCooldown && !dropperClaw.canDrop) return null;

    if (worldX != null) {
      dropperClaw.moveToWorldX(worldX);
    }

    final spawnPos = Vector2(
      dropperClaw.currentX,
      dropperClaw.clawY + 1.5,
    );
    final bool omniDrop = isOmniOrbArmed;
    final OrbTier spawnedTier = currentTier;

    isOmniOrbArmed = false;
    currentTier = nextTier;
    nextTier = OrbTier.rollSpawnTier(_rng);
    dropperClaw.triggerDropCooldown();

    final orb = OrbBody(
      tier: spawnedTier,
      initialPosition: spawnPos,
      isOmniOrb: omniDrop,
    );
    activeOrbs.add(orb);
    world.add(orb);

    _triggerHapticLight();
    _notifyHud();
    return orb;
  }

  OrbBody spawnOrb({
    required OrbTier tier,
    required Vector2 position,
    bool isOmniOrb = false,
    Vector2? impulse,
    bool playMergePop = false,
  }) {
    final orb = OrbBody(
      tier: tier,
      initialPosition: position.clone(),
      isOmniOrb: isOmniOrb,
      initialImpulse: impulse,
      playMergePop: playMergePop,
    );
    activeOrbs.add(orb);
    world.add(orb);
    return orb;
  }

  void enqueueMerge(OrbBody orbA, OrbBody orbB) {
    if (orbA.isMerging || orbB.isMerging || identical(orbA, orbB)) return;
    orbA.isMerging = true;
    orbB.isMerging = true;
    _pendingMerges.add(_PendingMerge(orbA, orbB));
  }

  void _processPendingMerges() {
    final merges = List<_PendingMerge>.from(_pendingMerges);
    _pendingMerges.clear();

    for (final merge in merges) {
      final a = merge.orbA;
      final b = merge.orbB;

      final Vector2 posA = a.safePosition.clone();
      final Vector2 posB = b.safePosition.clone();
      final Vector2 midpoint = (posA + posB)..scale(0.5);

      _removeOrb(a);
      _removeOrb(b);

      final OrbTier baseTier =
          a.tier.tierNumber >= b.tier.tierNumber ? a.tier : b.tier;

      if (timeSinceLastMerge <= 2.0) {
        comboMultiplier = math.min(10, comboMultiplier + 1);
      } else {
        comboMultiplier =
            comboMultiplier < 2 ? 2 : math.min(10, comboMultiplier + 1);
      }
      timeSinceLastMerge = 0.0;

      if (baseTier == OrbTier.tier10 && !a.isOmniOrb && !b.isOmniOrb) {
        _triggerSupernovaClear(midpoint);
      } else {
        final OrbTier evolvedTier = baseTier.nextTier ?? OrbTier.tier10;
        final int pointsEarned = evolvedTier.points * comboMultiplier;
        final int voltsEarned =
            (evolvedTier.tierNumber * (isFeverMode ? 2 : 1));

        _addScore(pointsEarned);
        playerData.addVolts(voltsEarned);

        spawnOrb(
          tier: evolvedTier,
          position: midpoint,
          impulse: Vector2(0.0, -18.0 * evolvedTier.density),
          playMergePop: true,
        );

        world.add(
          RadialBurstComponent(
            origin: midpoint,
            baseColor: evolvedTier.color,
            particleCount: 18,
          ),
        );
        final popupLabel = comboMultiplier > 1
            ? '+$pointsEarned (${comboMultiplier}x!)'
            : '+$pointsEarned';
        world.add(
          FloatingPopupComponent(
            origin: midpoint,
            text: popupLabel,
            color: isFeverMode ? const Color(0xFFFFEA00) : evolvedTier.color,
          ),
        );

        cameraShake.trigger(
          intensity: 0.35 + evolvedTier.tierNumber * 0.08,
          duration: 0.22,
        );
        _triggerHapticMedium();
      }

      storageService.savePlayerData(playerData);
      _notifyHud();
    }
  }

  void _triggerSupernovaClear(Vector2 midpoint) {
    _addScore(25000);
    playerData.addVolts(500);

    final candidates = activeOrbs
        .where((o) => !o.isMerging)
        .toList()
      ..sort((a, b) {
        final tierCompare = a.tier.tierNumber.compareTo(b.tier.tierNumber);
        if (tierCompare != 0) return tierCompare;
        final distA = (a.safePosition - midpoint).length2;
        final distB = (b.safePosition - midpoint).length2;
        return distA.compareTo(distB);
      });

    final toVaporize = candidates.take(6).toList();
    for (final orb in toVaporize) {
      final pos = orb.safePosition.clone();
      _removeOrb(orb);
      world.add(
        RadialBurstComponent(
          origin: pos,
          baseColor: const Color(0xFFFF6D00),
          particleCount: 18,
        ),
      );
    }

    world.add(
      RadialBurstComponent(
        origin: midpoint,
        baseColor: const Color(0xFFFF9100),
        particleCount: 18,
        maxSpeed: 36.0,
      ),
    );
    world.add(
      FloatingPopupComponent(
        origin: midpoint,
        text: 'SUPERNOVA! +25,000',
        color: const Color(0xFFFF6D00),
      ),
    );
    cameraShake.trigger(intensity: 1.8, duration: 0.45);
    _triggerHapticHeavy();
  }

  void onBumperHit(Vector2 pegPos, int baseVolts) {
    final earnedVolts = baseVolts * (isFeverMode ? 2 : 1);
    playerData.addVolts(earnedVolts);
    world.add(
      RadialBurstComponent(
        origin: pegPos,
        baseColor: const Color(0xFF00E676),
        particleCount: 18,
        maxSpeed: 16.0,
      ),
    );
    world.add(
      FloatingPopupComponent(
        origin: pegPos,
        text: '+$earnedVolts V',
        color: const Color(0xFF00E676),
      ),
    );
    _triggerHapticLight();
    _notifyHud();
  }

  bool activateEarthquakeShaker({bool fromAd = false}) {
    if (!fromAd && !playerData.spendVolts(earthquakeCostVolts)) {
      return false;
    }

    for (final orb in activeOrbs) {
      if (orb.isMerging) continue;
      final double horizontalRng = (_rng.nextDouble() * 30.0) - 15.0;
      final impulse = Vector2(horizontalRng, -45.0);
      orb.applySafeImpulse(impulse);
    }

    cameraShake.trigger(intensity: 1.5, duration: 0.4);
    _triggerHapticHeavy();
    storageService.savePlayerData(playerData);
    _notifyHud();
    return true;
  }

  bool activateRainbowOmniOrb({bool fromAd = false}) {
    if (isOmniOrbArmed) return true;
    if (!fromAd && !playerData.spendVolts(omniOrbCostVolts)) {
      return false;
    }
    isOmniOrbArmed = true;
    _triggerHapticMedium();
    storageService.savePlayerData(playerData);
    _notifyHud();
    return true;
  }

  bool armLaserZapper() {
    if (isLaserZapperArmed) return true;
    if (!playerData.spendVolts(laserZapperCostVolts)) {
      return false;
    }
    isLaserZapperArmed = true;
    _triggerHapticLight();
    storageService.savePlayerData(playerData);
    _notifyHud();
    return true;
  }

  bool zapOrb(OrbBody orb) {
    if (!activeOrbs.contains(orb)) return false;
    final pos = orb.safePosition.clone();
    _removeOrb(orb);
    isLaserZapperArmed = false;

    world.add(
      RadialBurstComponent(
        origin: pos,
        baseColor: const Color(0xFFFF1744),
        particleCount: 18,
      ),
    );
    world.add(
      FloatingPopupComponent(
        origin: pos,
        text: 'ZAPPED!',
        color: const Color(0xFFFF1744),
      ),
    );
    cameraShake.trigger(intensity: 0.7, duration: 0.2);
    _triggerHapticMedium();
    _notifyHud();
    return true;
  }

  void triggerGameOver() {
    if (isGameOver) return;
    isGameOver = true;
    _triggerHapticHeavy();
    storageService.savePlayerData(playerData);
    if (overlays.isActive(hudOverlayId)) {
      overlays.add(gameOverOverlayId);
    }
    _notifyHud();
  }

  bool reviveFromOverload() {
    if (hasUsedReviveThisRun) return false;
    hasUsedReviveThisRun = true;
    isGameOver = false;
    overloadLaser.maxOverlapSeconds = 0.0;

    final sortedByHeight = activeOrbs
        .where((o) => !o.isMerging)
        .toList()
      ..sort((a, b) => a.safePosition.y.compareTo(b.safePosition.y));

    for (final orb in sortedByHeight.take(3)) {
      final pos = orb.safePosition.clone();
      _removeOrb(orb);
      world.add(
        RadialBurstComponent(
          origin: pos,
          baseColor: const Color(0xFF00E5FF),
          particleCount: 18,
        ),
      );
    }

    for (final orb in activeOrbs) {
      orb.overloadOverlapSeconds = 0.0;
      final double horizontalRng = (_rng.nextDouble() * 24.0) - 12.0;
      orb.applySafeImpulse(Vector2(horizontalRng, -35.0));
    }

    cameraShake.trigger(intensity: 1.5, duration: 0.4);
    overlays.remove(gameOverOverlayId);
    _notifyHud();
    return true;
  }

  void resetGame() {
    final existing = List<OrbBody>.from(activeOrbs);
    for (final orb in existing) {
      _removeOrb(orb);
    }
    _pendingMerges.clear();

    score = 0;
    comboMultiplier = 1;
    timeSinceLastMerge = 999.0;
    isOmniOrbArmed = false;
    isLaserZapperArmed = false;
    isGameOver = false;
    hasUsedReviveThisRun = false;
    overloadLaser.maxOverlapSeconds = 0.0;

    currentTier = OrbTier.rollSpawnTier(_rng);
    nextTier = OrbTier.rollSpawnTier(_rng);

    overlays.remove(gameOverOverlayId);
    _notifyHud();
  }

  void _removeOrb(OrbBody orb) {
    orb.isMerging = true;
    activeOrbs.remove(orb);
    orb.removeFromParent();
  }

  void _addScore(int delta) {
    score += delta;
    playerData.updateHighScore(score);
  }

  void _notifyHud() {
    hudTick.value++;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (isGameOver) return;

    final worldPoint = screenToWorld(event.localPosition);

    if (isLaserZapperArmed && activeOrbs.isNotEmpty) {
      OrbBody? tappedOrb;
      double closestDist = double.infinity;
      for (final orb in activeOrbs) {
        if (orb.isMerging) continue;
        final pos = orb.safePosition;
        final dist = (pos - worldPoint).length;
        if (dist <= orb.tier.radius * 2.2 && dist < closestDist) {
          closestDist = dist;
          tappedOrb = orb;
        }
      }
      tappedOrb ??= activeOrbs.first;
      zapOrb(tappedOrb);
      return;
    }

    dropOrbAt(worldX: worldPoint.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (isGameOver) return;
    final worldPoint = screenToWorld(event.localEndPosition);
    dropperClaw.moveToWorldX(worldPoint.x);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (isGameOver || isLaserZapperArmed) return;
    dropOrbAt();
  }

  void _triggerHapticLight() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _triggerHapticMedium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void _triggerHapticHeavy() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
