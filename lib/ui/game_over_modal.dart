import 'package:flutter/material.dart';
import '../game/lab_drop_game.dart';

class GameOverModal extends StatelessWidget {
  const GameOverModal({
    super.key,
    required this.game,
  });

  final LabDropGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF141B2D),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFF1744),
                  width: 2.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'LAB OVERLOAD!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFF1744),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Containment field breached at the top laser line.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1021),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'FINAL SCORE: ${game.score}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'HIGH SCORE: ${game.playerData.highScore}',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!game.hasUsedReviveThisRun) ...[
                    ElevatedButton(
                      key: const Key('mega_earthquake_revive_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        game.adService.showRewardedAd(
                          onRewardEarned: () {
                            game.reviveFromOverload();
                          },
                        );
                      },
                      child: const Text(
                        'MEGA EARTHQUAKE REVIVE (WATCH AD)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton(
                    key: const Key('play_again_button'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      game.resetGame();
                    },
                    child: const Text(
                      'PLAY AGAIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
