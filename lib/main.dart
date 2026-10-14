import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/lab_drop_game.dart';
import 'models/player_data.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';
import 'services/storage_service.dart';
import 'ui/game_over_modal.dart';
import 'ui/hud_overlay.dart';
import 'ui/shop_modal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storageService = StorageService();
  await storageService.init();
  final PlayerData playerData = await storageService.loadPlayerData();

  final adService = AdService();
  await adService.initialize();

  final iapService = IapService();
  await iapService.initialize();

  final game = LabDropGame(
    playerData: playerData,
    storageService: storageService,
    adService: adService,
    iapService: iapService,
  );

  runApp(LabDropApp(game: game));
}

class LabDropApp extends StatelessWidget {
  const LabDropApp({
    super.key,
    required this.game,
  });

  final LabDropGame game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LabDrop: Chain Reaction!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: GameWidget<LabDropGame>(
          game: game,
          initialActiveOverlays: const [
            LabDropGame.hudOverlayId,
          ],
          overlayBuilderMap: {
            LabDropGame.hudOverlayId: (context, LabDropGame g) =>
                HudOverlay(game: g),
            LabDropGame.shopOverlayId: (context, LabDropGame g) =>
                ShopModal(game: g),
            LabDropGame.gameOverOverlayId: (context, LabDropGame g) =>
                GameOverModal(game: g),
          },
        ),
      ),
    );
  }
}
