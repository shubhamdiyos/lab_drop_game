import 'package:flutter/material.dart';
import '../game/lab_drop_game.dart';
import '../models/player_data.dart';

class ShopModal extends StatelessWidget {
  const ShopModal({
    super.key,
    required this.game,
  });

  final LabDropGame game;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: game.playerData,
      builder: (context, _) {
        final playerData = game.playerData;
        return Material(
          color: Colors.black87,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: playerData.selectedTheme.accentColor,
                      width: 2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'LAB RESEARCH SHOP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${playerData.volts} VOLTS',
                              style: const TextStyle(
                                color: Color(0xFFFFEA00),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextButton(
                              key: const Key('close_shop_button'),
                              onPressed: () {
                                game.overlays.remove(LabDropGame.shopOverlayId);
                              },
                              child: const Text(
                                'CLOSE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A148C), Color(0xFF1A237E)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFFD740),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'VIP LAB PASS',
                                      style: TextStyle(
                                        color: Color(0xFFFFD740),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Unlocks all Lab Themes + 2x Volts + +1,000 bonus Volts!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                key: const Key('buy_vip_pass_button'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD740),
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: playerData.hasVipPass
                                    ? null
                                    : () async {
                                        await game.iapService
                                            .purchaseVipPass(playerData);
                                        await game.storageService
                                            .savePlayerData(playerData);
                                      },
                                child: Text(
                                  playerData.hasVipPass ? 'ACTIVE' : 'UNLOCK VIP',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'LAB THEMES',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final theme in LabTheme.values)
                          _buildThemeCard(theme, playerData),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const Key('watch_ad_volts_button'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00E5FF)),
                          ),
                          onPressed: () {
                            game.adService.showRewardedAd(
                              onRewardEarned: () {
                                playerData.addVolts(100);
                                game.storageService.savePlayerData(playerData);
                              },
                            );
                          },
                          child: const Text(
                            'WATCH AD (+100 VOLTS)',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(LabTheme theme, PlayerData playerData) {
    final bool unlocked = playerData.isThemeUnlocked(theme);
    final bool selected = playerData.selectedTheme == theme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundBottom,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? theme.accentColor : Colors.white24,
          width: selected ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme.displayName,
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  theme.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: Key('theme_button_${theme.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selected ? Colors.white24 : theme.accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              if (unlocked) {
                playerData.selectTheme(theme);
              } else {
                playerData.unlockTheme(theme);
              }
              game.storageService.savePlayerData(playerData);
            },
            child: Text(
              selected
                  ? 'EQUIPPED'
                  : (unlocked ? 'SELECT' : '${theme.costVolts} V'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
