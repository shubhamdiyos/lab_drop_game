import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:labdrop_game/game/lab_drop_game.dart';
import 'package:labdrop_game/main.dart';
import 'package:labdrop_game/models/orb_tier.dart';
import 'package:labdrop_game/models/player_data.dart';
import 'package:labdrop_game/services/ad_service.dart';
import 'package:labdrop_game/services/iap_service.dart';
import 'package:labdrop_game/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('1. OrbTier Specs & Procedural Canvas Renderers', () {
    test('Verifies all 10 OrbTier physics, radius, color, and point specs', () {
      expect(OrbTier.values.length, 10);

      expect(OrbTier.tier1.radius, 1.4);
      expect(OrbTier.tier1.density, 1.0);
      expect(OrbTier.tier1.restitution, 0.50);
      expect(OrbTier.tier1.colorHex, 0xFF00E5FF);
      expect(OrbTier.tier1.points, 10);

      expect(OrbTier.tier2.radius, 2.0);
      expect(OrbTier.tier2.density, 1.2);
      expect(OrbTier.tier2.restitution, 0.40);
      expect(OrbTier.tier2.colorHex, 0xFFFF8A65);
      expect(OrbTier.tier2.points, 25);

      expect(OrbTier.tier3.radius, 2.7);
      expect(OrbTier.tier3.density, 0.9);
      expect(OrbTier.tier3.restitution, 0.75);
      expect(OrbTier.tier3.colorHex, 0xFF76FF03);
      expect(OrbTier.tier3.points, 60);

      expect(OrbTier.tier4.radius, 3.5);
      expect(OrbTier.tier4.density, 1.1);
      expect(OrbTier.tier4.restitution, 0.45);
      expect(OrbTier.tier4.colorHex, 0xFFE040FB);
      expect(OrbTier.tier4.points, 150);

      expect(OrbTier.tier5.radius, 4.4);
      expect(OrbTier.tier5.density, 1.4);
      expect(OrbTier.tier5.restitution, 0.35);
      expect(OrbTier.tier5.colorHex, 0xFFFFD740);
      expect(OrbTier.tier5.points, 350);

      expect(OrbTier.tier6.radius, 5.4);
      expect(OrbTier.tier6.density, 1.8);
      expect(OrbTier.tier6.restitution, 0.30);
      expect(OrbTier.tier6.colorHex, 0xFFFF5252);
      expect(OrbTier.tier6.points, 800);

      expect(OrbTier.tier7.radius, 6.6);
      expect(OrbTier.tier7.density, 1.5);
      expect(OrbTier.tier7.restitution, 0.40);
      expect(OrbTier.tier7.colorHex, 0xFF536DFE);
      expect(OrbTier.tier7.points, 1800);

      expect(OrbTier.tier8.radius, 7.9);
      expect(OrbTier.tier8.density, 2.2);
      expect(OrbTier.tier8.restitution, 0.25);
      expect(OrbTier.tier8.colorHex, 0xFF00BFA5);
      expect(OrbTier.tier8.points, 4000);

      expect(OrbTier.tier9.radius, 9.4);
      expect(OrbTier.tier9.density, 2.8);
      expect(OrbTier.tier9.restitution, 0.20);
      expect(OrbTier.tier9.colorHex, 0xFFFFAB00);
      expect(OrbTier.tier9.points, 9000);

      expect(OrbTier.tier10.radius, 11.2);
      expect(OrbTier.tier10.density, 4.0);
      expect(OrbTier.tier10.restitution, 0.10);
      expect(OrbTier.tier10.colorHex, 0xFF212121);
      expect(OrbTier.tier10.points, 25000);

      final rng = math.Random(42);
      for (int i = 0; i < 200; i++) {
        final rolled = OrbTier.rollSpawnTier(rng);
        expect(rolled.tierNumber, inInclusiveRange(1, 4));
      }
    });

    test('Executes procedural Canvas rendering for all 10 tiers & Omni-Orb without errors', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      for (final tier in OrbTier.values) {
        expect(
          () => tier.renderProcedural(canvas, tier.radius * 10, animTime: 1.25),
          returnsNormally,
        );
        final painter = OrbPreviewPainter(tier: tier, animTime: 0.5);
        expect(
          () => painter.paint(canvas, const Size(64, 64)),
          returnsNormally,
        );
      }

      expect(
        () => OrbTier.tier1.renderProcedural(
          canvas,
          20.0,
          animTime: 0.75,
          isOmniOrb: true,
        ),
        returnsNormally,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('2. OrbBody Merge Evolution, Score & Combo Multiplier', () {
    testWidgets('Merges two identical OrbBody instances into Tier[N+1], increments score & combo',
        (WidgetTester tester) async {
      final game = LabDropGame(
        playerData: PlayerData(volts: 300),
        random: math.Random(7),
      );
      await tester.pumpWidget(LabDropApp(game: game));
      await tester.pump();

      final orbA = game.spawnOrb(
        tier: OrbTier.tier1,
        position: Vector2(20.0, 50.0),
      );
      final orbB = game.spawnOrb(
        tier: OrbTier.tier1,
        position: Vector2(20.5, 50.0),
      );
      await tester.pump(const Duration(milliseconds: 16));

      game.enqueueMerge(orbA, orbB);
      expect(orbA.isMerging, isTrue);
      expect(orbB.isMerging, isTrue);

      await tester.pump(const Duration(milliseconds: 16));

      final tier2Orbs =
          game.activeOrbs.where((o) => o.tier == OrbTier.tier2).toList();
      expect(tier2Orbs.length, 1);
      expect(game.score, greaterThanOrEqualTo(OrbTier.tier2.points));
      expect(game.comboMultiplier, greaterThanOrEqualTo(2));

      final orbC = game.spawnOrb(
        tier: OrbTier.tier2,
        position: Vector2(20.2, 50.0),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final previousCombo = game.comboMultiplier;
      game.enqueueMerge(tier2Orbs.first, orbC);
      await tester.pump(const Duration(milliseconds: 16));

      expect(game.comboMultiplier, greaterThanOrEqualTo(previousCombo));
      expect(
        game.activeOrbs.where((o) => o.tier == OrbTier.tier3).length,
        1,
      );
    });
  });

  group('3. Power-Ups & Shop Theme Unlocking', () {
    testWidgets('Verifies Earthquake impulse, Rainbow Omni-Orb wild merge, and Shop theme unlocking',
        (WidgetTester tester) async {
      final playerData = PlayerData(volts: 1000);
      final game = LabDropGame(
        playerData: playerData,
        storageService: StorageService(),
        adService: AdService(),
        iapService: IapService(),
        random: math.Random(99),
      );
      await tester.pumpWidget(LabDropApp(game: game));
      await tester.pump();

      final targetOrb = game.spawnOrb(
        tier: OrbTier.tier4,
        position: Vector2(20.0, 55.0),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final earthquakeActivated = game.activateEarthquakeShaker();
      expect(earthquakeActivated, isTrue);
      expect(targetOrb.safeVelocity.length, greaterThan(0.0));

      final omniActivated = game.activateRainbowOmniOrb();
      expect(omniActivated, isTrue);
      expect(game.isOmniOrbArmed, isTrue);

      final omniOrb = game.spawnOrb(
        tier: OrbTier.tier1,
        position: Vector2(20.0, 55.0),
        isOmniOrb: true,
      );
      await tester.pump(const Duration(milliseconds: 16));

      game.enqueueMerge(omniOrb, targetOrb);
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        game.activeOrbs.any((o) => o.tier == OrbTier.tier5),
        isTrue,
      );

      expect(playerData.isThemeUnlocked(LabTheme.magmaFoundry), isFalse);
      final unlockedMagma = playerData.unlockTheme(LabTheme.magmaFoundry);
      expect(unlockedMagma, isTrue);
      expect(playerData.isThemeUnlocked(LabTheme.magmaFoundry), isTrue);
      expect(playerData.selectedTheme, LabTheme.magmaFoundry);
    });
  });

  group('4. Full LabDropGame Widget Mount, 120-Frame Pump & Tap-to-Drop', () {
    testWidgets(
      'Mounts LabDropApp, pumps 120 frames, simulates tap-to-drop, and verifies zero layout overflows',
      (WidgetTester tester) async {
        final playerData = PlayerData(volts: 500);
        final game = LabDropGame(
          playerData: playerData,
          storageService: StorageService(),
          adService: AdService(),
          iapService: IapService(),
          random: math.Random(123),
        );

        await tester.pumpWidget(LabDropApp(game: game));
        await tester.pump();

        for (int i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        await tester.tapAt(const Offset(200, 300));
        await tester.pump();

        for (int i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(game.activeOrbs.isNotEmpty, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
