# LabDrop: Chain Reaction! - Master Specification
- **Tech Stack:** Flutter (Dart) + `flame` + `flame_forge2d` + `shared_preferences` + `google_mobile_ads` + `purchases_flutter`.
- **Zero External Assets Rule:** Do NOT use external `.png`, `.jpg`, or `.mp3` files. Every orb, gear, seesaw, particle effect, and UI icon MUST be drawn procedurally using Flutter `CustomPainter`, `Canvas` APIs, and Flame components. Use `HapticFeedback` + screen shake + squash-and-stretch animations for tactile feedback.

## Directory Structure
lib/
├── main.dart
├── models/
│   ├── orb_tier.dart            # Physics, radius, hex color, and points spec for Tiers 1-10
│   └── player_data.dart         # High score, Volts currency, unlocked Lab Themes & upgrades
├── services/
│   ├── storage_service.dart     # SharedPreferences persistence
│   ├── ad_service.dart          # Rewarded Ad wrapper with instant mock fallback when no API keys exist
│   └── iap_service.dart         # IAP wrapper with instant mock fallback for dev/test environments
├── game/
│   ├── lab_drop_game.dart       # Core Forge2DGame (gravity: Vector2(0, 25.0), bounds, combo state)
│   ├── components/
│   │   ├── dropper_claw.dart    # Top horizontal claw (x: 15% to 85%, y: 12%) with dotted aim line & 0.35s drop cooldown
│   │   ├── orb_body.dart        # BodyComponent with procedural Canvas rendering & ContactCallbacks merge logic
│   │   ├── rotating_gear.dart   # 2 KinematicBody rotating cogs (x: 28% & 72%, y: 35%, angularVelocity: +/-1.8)
│   │   ├── seesaw_lever.dart    # Center DynamicBody plank (x: 50%, y: 46%) pinned via RevoluteJoint (-0.45 to +0.45 rad)
│   │   ├── bumper_peg.dart      # 3 Static high-restitution (0.85) pinball pegs in a triangle; awards +5 Volts & flashes on hit
│   │   ├── overload_laser.dart  # Top danger line at y = 18%; triggers Game Over if a settled orb overlaps for > 3.0s
│   │   └── juice_effects.dart   # 18-particle radial bursts, camera shake, and floating combo/score popups
└── ui/
    ├── hud_overlay.dart         # Score, High Score, Combo Fever badge, Volts, Next Orb preview, Power-up bar
    ├── shop_modal.dart          # Unlockable Lab Themes (Cyber Science, Magma Foundry, Zero-G Space) & VIP Pass
    └── game_over_modal.dart     # "Lab Overload!" screen with Mega Earthquake Revive & Play Again

## 10-Tier Merge Evolution & Fever System
- Claw drops Tiers 1-4 only (Weights: T1: 45%, T2: 30%, T3: 15%, T4: 10%).
- When two identical `OrbBody` tiers collide (`beginContact`), guard with `bool isMerging` so neither double-merges in the same step, remove both on the next update tick, and spawn `Tier[N+1]` at their midpoint `M` with an upward pop impulse.
- **Combo Multiplier:** Merges within 2.0s of the last merge increment `comboMultiplier` (2x up to 10x). At 5x+, trigger Fever Mode (glowing border + 2x Volts).
- **Tier Specs (World Radius | Density | Restitution | Color | Procedural Style | Points):**
  1. Static Spark: r=1.4, d=1.0, rest=0.50, #00E5FF (Cyan core + 4 electric spikes), 10 pts
  2. Copper Gear: r=2.0, d=1.2, rest=0.40, #FF8A65 (Bronze ring + 6 teeth + hollow center), 25 pts
  3. Spring Coil: r=2.7, d=0.9, rest=0.75, #76FF03 (Lime green concentric spiral), 60 pts
  4. Plasma Bulb: r=3.5, d=1.1, rest=0.45, #E040FB (Violet glass sphere + inner glowing filament), 150 pts
  5. Gyro Core: r=4.4, d=1.4, rest=0.35, #FFD740 (Gold dual-ring counter-rotating gyroscope), 350 pts
  6. Magnet Sphere: r=5.4, d=1.8, rest=0.30, #FF5252 (Red/Blue split sphere; pulls nearest Tier 6 orb within 15 units), 800 pts
  7. Tesla Orb: r=6.6, d=1.5, rest=0.40, #536DFE (Indigo sphere with animated lightning arcs), 1800 pts
  8. Gravity Lens: r=7.9, d=2.2, rest=0.25, #00BFA5 (Teal warping concentric ripples), 4000 pts
  9. Fusion Reactor: r=9.4, d=2.8, rest=0.20, #FFAB00 (Solar core with 3 atomic electron orbits), 9000 pts
  10. Singularity: r=11.2, d=4.0, rest=0.10, #212121 (Black event horizon + neon orange halo; merging two Tier 10s triggers Supernova Clear: +25,000 pts, +500 Volts, vaporizes 6 nearest low-tier orbs), 25000 pts

## Power-Ups & Monetization Hooks
1. **Earthquake Shaker (150 Volts or Rewarded Ad):** Applies upward/horizontal impulse `Vector2(rng, -45.0)` to all orbs.
2. **Rainbow Omni-Orb (200 Volts or Rewarded Ad):** Next drop merges with the first orb of ANY tier it touches.
3. **Laser Zapper (100 Volts):** Tap any single orb on screen to vaporize it immediately.
4. **Second-Chance Revive (Game Over Modal):** Watch Ad / Free Revive button vaporizes the top 3 highest orbs, shakes the chamber, and resumes play (once per run).
