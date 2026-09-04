# Reusable 2D Brawler Template — Architecture & Interface Guide

This document defines the architecture, data models, contracts, and interfaces of the generic **2D Brawler Template** located in `templates/brawler/`.

---

## 1. Architecture Overview

The Brawler Template decouples universal physics, state management, combat mechanics, and event routing from character-specific assets (artwork, rigs, animations, projectile visuals, and audio mappings).

```
                                  ┌────────────────────────┐
                                  │     BrawlerConfig      │
                                  │   (Resource / .tres)   │
                                  └───────────┬────────────┘
                                              │ configures
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        BRAWLER BASE (CharacterBody2D)                                  │
│                                                                                        │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────────────┐  │
│  │  MovementController  │  │ AnimationController  │  │       AbilityController      │  │
│  │ (Physics/Locomotion) │  │  (State-to-Anim Map) │  │    (Attack / Super / Gadget) │  │
│  └──────────────────────┘  └──────────────────────┘  └──────────────┬───────────────┘  │
│                                                                     │ spawns           │
│  ┌──────────────────────┐  ┌──────────────────────┐                 ▼                  │
│  │     HitReceiver      │  │  FaceControllerBase  │     ┌────────────────────────┐     │
│  │ (Damage / Knockback) │  │ (Expressions & Blink)│     │     ProjectileBase     │     │
│  └──────────────────────┘  └──────────────────────┘     │   (Area2D / HitData)   │     │
│                                                         └────────────────────────┘     │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │                  BrawlerEvents (Standardized Signal / Event Bus)                  │  │
│  └──────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────┘
            │                                              │
            ▼ (maps via BrawlerConfig)                     ▼ (maps via BrawlerConfig)
   ┌──────────────────┐                           ┌──────────────────┐
   │   AudioManager   │                           │    VFXManager    │
   └──────────────────┘                           └──────────────────┘
```

---

## 2. Universal vs. Brawler-Specific Systems

| System | Universal Foundation (`templates/brawler/`) | Brawler-Specific (`brawlers/<name>/`) |
| :--- | :--- | :--- |
| **Locomotion** | Deterministic state machine (`IDLE`, `WALK`, `RUN`, `STOP`, `TURN`, `JUMP`, `FALL`, `LAND`) | Walk/run velocities, acceleration rates, friction |
| **Animation** | State-to-animation contract, fallback mapping, event triggers | Keyframe tracks, poses, timing, character style |
| **Combat / HP** | `HitReceiver`, `HitData` exchange, knockback physics | Max health, knockback resistance, hit reactions |
| **Abilities** | `AbilityController` (burst timers, spread calculation, Super state) | Projectiles per burst, burst interval, spread angles, Super type |
| **Projectiles** | `ProjectileBase` (range, lifetime, collision, Line2D trail) | Projectile sprite, speed, damage, spin, impact effects |
| **Facial System**| `FaceControllerBase` (auto-blinking, expression switching) | Eye/mouth SVG textures, pupil offset coordinates |
| **Audio / VFX** | Standardized `BrawlerEvents` dispatch | Sound IDs in `AudioManager`, particle scenes in `VFXManager` |

---

## 3. Expected Asset Structure

Each new Brawler should structure its assets consistently:

```
assets/<brawler_name>/
├── side/                   # 2D paper-cutout body parts
│   ├── torso.svg
│   ├── head.svg
│   ├── arm_upper.svg
│   ├── arm_lower.svg
│   ├── hand.svg
│   ├── leg_upper.svg
│   ├── leg_lower.svg
│   └── foot.svg
├── face/                   # Facial expression sheets/elements
│   ├── eye_open.svg
│   ├── eye_blink.svg
│   ├── eye_wide.svg
│   ├── mouth_neutral.svg
│   ├── mouth_smile.svg
│   └── mouth_angry.svg
└── projectile/             # Character-specific projectile sprites
    └── projectile.svg
```

---

## 4. Expected Bone Naming Convention

When authoring a `Skeleton2D` / `Bone2D` rig for a Brawler, adhere to standard bone identifiers:

```
root
└── torso
    ├── neck
    │   └── head
    │       └── Face (FaceControllerBase)
    ├── arm_L_upper
    │   └── arm_L_lower
    │       └── hand_L
    ├── arm_R_upper
    │   └── arm_R_lower
    │       └── hand_R
    │           └── ProjectileSpawnPoint (Marker2D)
    ├── leg_L_upper
    │   └── leg_L_lower
    │       └── foot_L
    └── leg_R_upper
        └── leg_R_lower
            └── foot_R
```

*Note:* Brawlers may include extra accessory bones (e.g. `tail`, `cape`, `hair`, `weapon_holster`) without breaking template compatibility.

---

## 5. Animation Interface

The `BrawlerAnimationController` expects the following animation clip names in `AnimPlayer`:

1. `idle` (Looping) — Neutral stance, breathing, subtle squash/stretch.
2. `walk` (Looping) — Ground contact cycle, arm swing, upright posture.
3. `run` (Looping) — High-velocity athletic sprint, forward torso pitch.
4. `stop` — Braking skid / momentum recovery back to `idle`.
5. `turn` — Directional pivot when switching facing orientation.
6. `jump_anticipation` — Grounded crouch before launch (or fallback to `jump`).
7. `jump_airborne` — Ascent phase with straightened legs.
8. `fall` (Looping) — Descent phase with tucked knees and forward pitch.
9. `jump_land` — Ground impact compression and recovery.
10. `attack` — Basic attack anticipation, whip throw / strike, and follow-through.
11. `hit` — Reactive hit flinch / recoil.
12. `knockback` — Sustained airborne displacement recovery.
13. `death` — Knockout / collapse sequence.

---

## 6. Ability & Projectile Interface

### Triggering Abilities
- `brawler.attack() -> bool` — Triggers basic attack burst based on `config.projectiles_per_burst`.
- `brawler.activate_super() -> bool` — Initiates Super sequence (`SUPER_START` $\rightarrow$ `SUPER_ACTIVE` $\rightarrow$ `SUPER_END`).
- `brawler.activate_gadget() -> bool` — Consumes one gadget charge and emits `EVENT_GADGET_ACTIVATED`.

### Custom Projectiles
Inherit from `ProjectileBase` (`templates/brawler/projectile_base.gd`):
- Assign `speed`, `max_range`, `max_lifetime`, `damage`, `knockback_force`.
- Customize child nodes under `Visuals` and optional `Trail` (`Line2D`).

---

## 7. Facial Expression Interface

Managed by `FaceControllerBase` (`templates/brawler/face_controller_base.gd`):
- `brawler.set_expression("neutral" | "happy" | "angry" | "sad" | "hurt" | ...)`
- `brawler.set_eye_state("open" | "blink" | "wide" | "closed")`
- Automatically manages randomized eye blinks (every 2.2–4.5 seconds) with 0.12s blink duration.

---

## 8. Configuration Format (`BrawlerConfig`)

Saved as `.tres` resource (e.g. `templates/brawler/brawler_config_leon.tres`):

```gdscript
[gd_resource type="Resource" script_class="BrawlerConfig" format=3]

[resource]
script = ExtResource("1_cfg")
character_name = "Leon"
character_id = "brawler_leon"
walk_speed = 160.0
run_speed = 300.0
jump_velocity = -460.0
gravity = 1200.0
acceleration = 1800.0
friction = 2000.0
max_health = 1000.0
knockback_resistance = 1.0
attack_duration = 0.36
projectiles_per_burst = 4
burst_interval = 0.030
spread_angles = Array[float]([-0.05, -0.015, 0.015, 0.05])
projectile_scene = ExtResource("2_proj")
super_duration = 5.0
super_type = "invisibility"
audio_event_map = { ... }
vfx_event_map = { ... }
```

---

## 9. Validation & Pipeline Verification

Use `BrawlerBuilder.validate_brawler(node)` to inspect any Brawler scene programmatically:

```gdscript
var report = BrawlerBuilder.validate_brawler(brawler_instance)
if not report["valid"]:
    print("Errors: ", report["missing_nodes"])
    print("Missing Animations: ", report["missing_animations"])
```
