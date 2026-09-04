# New Brawler Production Workflow

This guide details the step-by-step production pipeline for bringing a new 2D Brawler from artwork to a fully validated character using the **Reusable Brawler Template**.

---

## Production Pipeline Overview

```
   1. ARTWORK
        ↓  (Export SVG parts & expression sheets)
   2. PREPARE PARTS
        ↓  (Organize assets/ & define pivot offsets)
   3. CONFIGURE BRAWLER
        ↓  (Create brawler_config_<name>.tres)
   4. RUN BUILDER / ASSEMBLE SCENE
        ↓  (Inherit templates/brawler/brawler_base.tscn)
   5. VERIFY RIG & SOCKETS
        ↓  (Skeleton2D bones, ProjectileSpawnPoint, VFX points)
   6. ADD UNIQUE ANIMATIONS
        ↓  (Keyframe AnimPlayer: idle, walk, run, jump, attack, hit)
   7. ADD UNIQUE ABILITIES
        ↓  (Configure burst projectiles, custom Super, Gadget)
   8. RUN TESTS
        ↓  (gdUnit4 automated verification)
   9. READY FOR PRODUCTION
```

---

## Step 1 — Artwork Preparation
- Author 2D paper-cutout vector artwork in Inkscape, Illustrator, or Figma.
- Design body parts as separate layers:
  - `head`, `torso`, `arm_upper`, `arm_lower`, `hand`, `leg_upper`, `leg_lower`, `foot`
  - Accessories: `hair`, `hat`, `cape`, `weapon`
  - Expressions: `eyes_open`, `eyes_blink`, `eyes_wide`, `mouth_neutral`, `mouth_smile`, `mouth_angry`
- Export parts as optimized `.svg` files with consistent scale.

---

## Step 2 — Organize Assets & Pivots
Place assets under:
```
assets/<brawler_name>/
├── side/
├── face/
└── projectile/
```
In Godot, inspect each Sprite2D texture and establish the correct rotational pivot using `offset`.

---

## Step 3 — Create Brawler Configuration
1. In the Godot FileSystem dock, right-click $\rightarrow$ **New Resource** $\rightarrow$ select `BrawlerConfig`.
2. Save as `brawlers/<brawler_name>/brawler_config_<brawler_name>.tres`.
3. Fill out the character parameters:
   - **Walk / Run Speeds:** (e.g. 160 / 300 px/s)
   - **Jump Force & Gravity:** (e.g. -460 px/s, 1200 px/s²)
   - **Health & Knockback Resistance:** (e.g. 1000 HP, 1.0)
   - **Attack Burst & Projectile:** Select custom projectile scene and burst interval.
   - **Audio & VFX Maps:** Map `BrawlerEvents` to sound IDs and particle names.

---

## Step 4 — Assemble Character Scene
1. Create a new inherited scene from `res://templates/brawler/brawler_base.tscn`.
2. Save as `brawlers/<brawler_name>/<brawler_name>.tscn`.
3. Assign your `brawler_config_<brawler_name>.tres` to the root `config` export property.
4. Under `Visuals/SkeletonSlot`:
   - Add `Skeleton2D`.
   - Add the bone hierarchy (`root`, `torso`, `neck`, `head`, arms, legs).
   - Attach Sprite2D parts to each respective `Bone2D`.
   - Attach `FaceControllerBase` under `head` bone.

---

## Step 5 — Verify Rig & Sockets
1. Verify `ProjectileSpawnPoint` (`Marker2D`) is parented under the character's weapon or throwing hand (`hand_R`).
2. Verify `VFXAttachmentPoints` contains:
   - `HitPoint` (center of torso)
   - `HeadPoint` (top of head/hat)
   - `ProjectileSpawn` (aligned with hand spawn point)
3. Run the automated validator in Godot:
   ```gdscript
   var report = BrawlerBuilder.validate_brawler(my_brawler)
   assert(report["valid"])
   ```

---

## Step 6 — Author Character Animations
In `AnimPlayer`, author keyframes for the standard animation set:
- `idle` (1.0–2.0s loop)
- `walk` (0.6–0.8s loop)
- `run` (0.4–0.5s loop)
- `stop` & `turn` (0.2–0.3s)
- `jump_anticipation`, `jump_airborne`, `fall`, `jump_land`
- `attack` (0.30–0.40s with windup, release, and follow-through)
- `hit` & `knockback` (0.2–0.4s)
- `death`

*Rule:* Never copy another character's keyframes directly; adjust bone angles to reflect the character's unique personality and silhouette.

---

## Step 7 — Add Unique Abilities & Projectiles
1. If the character throws or shoots a unique projectile:
   - Create a scene inheriting `res://templates/brawler/projectile_base.gd`.
   - Set damage, speed, range, and custom visuals.
   - Assign to `config.projectile_scene`.
2. If the character has a custom Super (e.g. dash or shockwave):
   - Override `_step_super()` in a script extending `BrawlerAbilityController`.

---

## Step 8 — Automated Testing
Run the gdUnit4 test suite:
```bash
export GODOT_BIN="/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot"
./addons/gdUnit4/runtest.sh -a tests/
```
Verify that all states (`IDLE`, `WALK`, `RUN`, `JUMP`, `ATTACK`, `HIT`, `SUPER`) pass deterministically.

---

## Step 9 — Production Ready!
The new Brawler is now fully compatible with:
- `PhantomCamera2D` tracking and framing.
- `VFXManager` event-driven particle spawning.
- `AudioManager` event-driven SFX and voice lines.
- Headless `tools/render_video.sh` Movie Maker capture pipeline.
