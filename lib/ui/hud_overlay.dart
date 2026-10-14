import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/lab_drop_game.dart';
import '../models/orb_tier.dart';

enum ProceduralIconType {
  bolt,
  shop,
  earthquake,
  omniOrb,
  laserZapper,
  trophy,
}

class ProceduralHudIconPainter extends CustomPainter {
  const ProceduralHudIconPainter({
    required this.type,
    required this.color,
  });

  final ProceduralIconType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case ProceduralIconType.bolt:
        final path = Path()
          ..moveTo(w * 0.58, h * 0.1)
          ..lineTo(w * 0.24, h * 0.54)
          ..lineTo(w * 0.50, h * 0.54)
          ..lineTo(w * 0.40, h * 0.9)
          ..lineTo(w * 0.76, h * 0.44)
          ..lineTo(w * 0.50, h * 0.44)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        break;

      case ProceduralIconType.shop:
        final path = Path()
          ..moveTo(w * 0.38, h * 0.18)
          ..lineTo(w * 0.62, h * 0.18)
          ..moveTo(w * 0.43, h * 0.18)
          ..lineTo(w * 0.43, h * 0.42)
          ..lineTo(w * 0.20, h * 0.82)
          ..lineTo(w * 0.80, h * 0.82)
          ..lineTo(w * 0.57, h * 0.42)
          ..lineTo(w * 0.57, h * 0.18);
        canvas.drawPath(path, paint);
        break;

      case ProceduralIconType.earthquake:
        final path = Path()
          ..moveTo(w * 0.08, h * 0.5)
          ..lineTo(w * 0.25, h * 0.5)
          ..lineTo(w * 0.36, h * 0.2)
          ..lineTo(w * 0.50, h * 0.82)
          ..lineTo(w * 0.64, h * 0.28)
          ..lineTo(w * 0.75, h * 0.5)
          ..lineTo(w * 0.92, h * 0.5);
        canvas.drawPath(path, paint);
        break;

      case ProceduralIconType.omniOrb:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        OrbTier.tier1.renderProcedural(
          canvas,
          math.min(w, h) * 0.38,
          isOmniOrb: true,
        );
        canvas.restore();
        break;

      case ProceduralIconType.laserZapper:
        canvas.drawCircle(center, w * 0.32, paint);
        canvas.drawLine(Offset(w * 0.5, h * 0.08), Offset(w * 0.5, h * 0.28), paint);
        canvas.drawLine(Offset(w * 0.5, h * 0.72), Offset(w * 0.5, h * 0.92), paint);
        canvas.drawLine(Offset(w * 0.08, h * 0.5), Offset(w * 0.28, h * 0.5), paint);
        canvas.drawLine(Offset(w * 0.72, h * 0.5), Offset(w * 0.92, h * 0.5), paint);
        break;

      case ProceduralIconType.trophy:
        final path = Path()
          ..moveTo(w * 0.25, h * 0.2)
          ..lineTo(w * 0.75, h * 0.2)
          ..lineTo(w * 0.65, h * 0.55)
          ..lineTo(w * 0.35, h * 0.55)
          ..close()
          ..moveTo(w * 0.5, h * 0.55)
          ..lineTo(w * 0.5, h * 0.8)
          ..moveTo(w * 0.3, h * 0.8)
          ..lineTo(w * 0.7, h * 0.8);
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant ProceduralHudIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}

class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.game,
  });

  final LabDropGame game;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([game.hudTick, game.playerData]),
      builder: (context, _) {
        final theme = game.playerData.selectedTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopBar(context, theme.accentColor),
                if (game.isLaserZapperArmed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCCFF1744),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: const Text(
                      'LASER ZAPPER ARMED — TAP ANY ORB TO VAPORIZE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                _buildPowerUpBar(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC0D1526),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: game.isFeverMode
              ? const Color(0xFFFFEA00)
              : accentColor.withValues(alpha: 0.55),
          width: game.isFeverMode ? 2.0 : 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCORE: ${game.score}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'BEST: ${game.playerData.highScore}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (game.comboMultiplier > 1)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: game.isFeverMode
                    ? const Color(0xFFFF6D00)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFFEA00),
                  width: 1.2,
                ),
              ),
              child: Text(
                game.isFeverMode
                    ? 'FEVER ${game.comboMultiplier}x!'
                    : 'COMBO ${game.comboMultiplier}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF162032),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFEA00).withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CustomPaint(
                    painter: ProceduralHudIconPainter(
                      type: ProceduralIconType.bolt,
                      color: Color(0xFFFFEA00),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${game.playerData.volts}',
                  style: const TextStyle(
                    color: Color(0xFFFFEA00),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NEXT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F1D),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: CustomPaint(
                  painter: OrbPreviewPainter(tier: game.nextTier),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          InkWell(
            key: const Key('open_shop_button'),
            onTap: () {
              game.overlays.add(LabDropGame.shopOverlayId);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CustomPaint(
                      painter: ProceduralHudIconPainter(
                        type: ProceduralIconType.shop,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'SHOP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC0D1526),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _PowerUpButton(
              buttonKey: const Key('powerup_earthquake'),
              label: 'QUAKE',
              costText: '${LabDropGame.earthquakeCostVolts}V / AD',
              iconType: ProceduralIconType.earthquake,
              accentColor: const Color(0xFFFF9100),
              isActive: false,
              onTap: () {
                if (!game.activateEarthquakeShaker()) {
                  game.adService.showRewardedAd(
                    onRewardEarned: () {
                      game.activateEarthquakeShaker(fromAd: true);
                    },
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PowerUpButton(
              buttonKey: const Key('powerup_omni_orb'),
              label: 'OMNI-ORB',
              costText: '${LabDropGame.omniOrbCostVolts}V / AD',
              iconType: ProceduralIconType.omniOrb,
              accentColor: const Color(0xFFE040FB),
              isActive: game.isOmniOrbArmed,
              onTap: () {
                if (!game.activateRainbowOmniOrb()) {
                  game.adService.showRewardedAd(
                    onRewardEarned: () {
                      game.activateRainbowOmniOrb(fromAd: true);
                    },
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PowerUpButton(
              buttonKey: const Key('powerup_laser_zapper'),
              label: 'ZAPPER',
              costText: '${LabDropGame.laserZapperCostVolts}V',
              iconType: ProceduralIconType.laserZapper,
              accentColor: const Color(0xFFFF1744),
              isActive: game.isLaserZapperArmed,
              onTap: () {
                game.armLaserZapper();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  const _PowerUpButton({
    required this.buttonKey,
    required this.label,
    required this.costText,
    required this.iconType,
    required this.accentColor,
    required this.isActive,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final String costText;
  final ProceduralIconType iconType;
  final Color accentColor;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.35)
              : const Color(0xFF162032),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.white : accentColor.withValues(alpha: 0.65),
            width: isActive ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(
                painter: ProceduralHudIconPainter(
                  type: iconType,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    costText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
