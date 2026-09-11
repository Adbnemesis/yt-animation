# cutenemi — 2D Paper-Cutout Brawler Animation Production System

A Godot 4.7–based 2D animation production system for creating stylized "Brawler" animated videos using reusable paper-cutout puppet characters.

---

## Overview

**cutenemi** is not a conventional playable game. It is an **animated video production environment**: characters, stages, effects, audio, and camera work are assembled in Godot and rendered to deterministic video files.

- **What it creates:** stylized 2D animated videos (Brawler-style characters performing actions in scenes).
- **Why Godot:** Godot provides the runtime, 2D skeletal animation (Skeleton2D/Bone2D), deterministic physics, particles, audio routing, a scene editor, and a fixed-framerate Movie Maker render mode — all in one tool an automated agent can operate headlessly.
- **Role of Antigravity:** Antigravity is the **development agent** that implements, tests, and modifies this repository. It is not part of the shipped product; it is the engineer working inside it.
- **Role of the reusable animation framework:** one generic Brawler foundation (`templates/brawler/`) supplies movement, state, combat, and event infrastructure so each new character only contributes artwork, animation, and ability-specific content.

Division of responsibility: **Godot = runtime/rendering/animation engine. Antigravity = the agent implementing and maintaining the project.**

---

## Current Status

- **Leon is the first completed production Brawler** (reference implementation, built on `scripts/character_controller.gd`).
- A generic **Reusable Brawler Template** (`templates/brawler/`) exists and is covered by gdUnit4 tests.
- A curated **CC0 starter asset library** (189 cataloged assets) is installed.

Completed and verified systems:

| System | Location | Status |
|---|---|---|
| Leon artwork (paper-cutout SVG parts) | `assets/brawlers/leon/` | complete |
| Leon Skeleton2D rig + AnimPlayer animations | `scenes/leon.tscn` | complete |
| Locomotion (idle/walk/run/stop/turn) | `scripts/character_controller.gd` | complete |
| Jump / fall / land | `scripts/character_controller.gd` | complete |
| Basic attack + projectile burst (4-projectile, spread) | controller + `scenes/leon_projectile.tscn`, `scripts/leon_projectile.gd` | complete |
| Hit detection / damage / knockback | `scripts/hit_data.gd`, `scripts/target_dummy.gd` | complete |
| Super (invisibility, 3-phase state layer) | `scripts/character_controller.gd` | complete |
| Facial expressions + auto-blink | `scripts/face_controller.gd` | complete |
| Event-driven audio | `scripts/audio_manager.gd` (autoload) | complete |
| Event-driven VFX | `scripts/vfx_manager.gd` (autoload) + `scenes/vfx/` | complete |
| Camera system | Phantom Camera plugin + `scenes/camera_test.tscn` | installed, smoke-tested |
| Test infrastructure | gdUnit4 + `tests/` | installed, 4 suites |
| Video render pipeline | `tools/render_video.sh` (Movie Maker + FFmpeg) | working |
| Starter asset library | `assets/` + `assets/asset_catalog.json` | complete |
| Reusable Brawler Template | `templates/brawler/` | implemented, unit-tested; **not yet used by a second shipped character** |
| Experimental 2D/2.5D staging lab | `scenes/labs/2_5d_staging_lab.tscn` + `docs/2_5D_STAGING_LAB.md` | experiment complete, isolated — production does not depend on it |
| Multi-view cinematic lab v2 | `scenes/labs/cinematic_2_5d_lab.tscn` + `docs/CINEMATIC_2_5D_LAB.md`, `docs/MULTIVIEW_CHARACTER_SYSTEM.md` | experiment complete, isolated — adds multi-view Leon/Nita/Bo — production untouched |

---

## Technology Stack

| Component | Version / Value | Source of truth |
|---|---|---|
| Godot | **4.7** (`config/features=PackedStringArray("4.7", "GL Compatibility")`) | `project.godot` |
| Renderer | **GL Compatibility** (`gl_compatibility`, incl. mobile) | `project.godot` |
| Language | GDScript (no C#) | repo |
| Animation | Skeleton2D / Bone2D rigs + `AnimationPlayer`, `CPUParticles2D` for VFX | repo |
| Physics | Built-in 2D `CharacterBody2D` / `Area2D` (project also sets Jolt for 3D — unused by gameplay) | `project.godot` |
| Phantom Camera | **v0.11.0.3** (enabled plugin + `PhantomCameraManager` autoload) | `addons/phantom_camera/` |
| gdUnit4 | **v6.2.1** (CLI runner, not an enabled editor plugin) | `addons/gdUnit4/` |
| Kenney Particle Pack | **v1.1**, CC0 1.0 | `assets/vfx/kenney_particles/` |
| gdtoolkit (gdformat/gdlint/gdparse) | **4.5.0**, venv at `tools/.venv/` | `tools/gdformat.sh`, `tools/gdlint.sh`, `tools/gdparse.sh` |
| FFmpeg | **8.1.2** (`/opt/homebrew/bin/ffmpeg`) — external encode step | `tools/render_video.sh` |

---

## Architecture

Systems are intentionally separated: characters do not play sounds or spawn particles directly — they emit **events**, and manager autoloads consume them.

```
STORY / SCENE                     (scenes/demo.tscn, future per-video scenes)
      ↓
SCENE DIRECTOR                    (DemoDirector AutoStep sequencer today;
      ↓                            data-driven SceneDirector: roadmap)
BRAWLER COMMANDS                  (input / scripted wants_* flags, attack(), super)
      ↓
STATE / MOVEMENT / ANIMATION      (character_controller.gd or templates/brawler/*)
      ↓
EVENTS                            (state_changed, attack_impact, projectile_spawned,
      ↓                            super_event, hit_received, ... )
AUDIO / VFX / PROJECTILES / OTHER (AudioManager, VFXManager, leon_projectile.gd,
                                   Phantom Camera — all event consumers)
```

- **Autoloads:** `AudioManager`, `VFXManager`, `PhantomCameraManager` (see `project.godot`).
- Managers bind to characters via `bind_character()` — zero coupling in character code.

## Brawler Architecture

A production Brawler combines **universal systems** with **brawler-specific content**:

| Layer | Universal | Brawler-specific |
|---|---|---|
| State machine / locomotion | physics constants, state transitions, deterministic guards | tuned speeds, timings |
| Rig | bone naming convention (see `docs/BRAWLER_TEMPLATE.md`) | part artwork (SVG), bone layout |
| Animation | state→animation contract, AnimPlayer | keyframe tracks, style |
| Facial system | expression switching, auto-blink | eye/mouth SVG textures |
| Abilities | burst timers, spread, Super 3-phase layer | projectile count/spread, Super type |
| Projectile | spawn/collision/trail base | sprite, speed, damage |
| Hit system | `HitData`, hit receiver, knockback | HP, hit reactions |
| Audio / VFX | event dispatch, managers | event mappings, sound files, particle scenes |

Two implementations exist:

1. **`scripts/character_controller.gd` (Leon)** — the proven production controller; the reference implementation.
2. **`templates/brawler/` (Brawler Template)** — the generalized framework (`brawler_base.tscn`, `movement_controller.gd`, `animation_controller.gd`, `ability_controller.gd`, `hit_receiver.gd`, `face_controller_base.gd`, `projectile_base.gd`, `brawler_config.gd`, `brawler_builder.gd`) that future Brawlers inherit from, configured via a `BrawlerConfig` `.tres` resource. Details: `docs/BRAWLER_TEMPLATE.md`, `docs/NEW_BRAWLER_WORKFLOW.md`.

## Leon

First production Brawler. Reference implementation: `scenes/leon.tscn` + `scripts/character_controller.gd`.

Verified capabilities:

- **States (12):** `IDLE`, `WALK`, `RUN`, `STOP`, `TURN`, `JUMP_ANTICIPATION`, `JUMP_AIRBORNE`, `FALL`, `JUMP_LAND`, `ATTACK`, `HIT`, `KNOCKBACK` (see `State` enum / `STATE_NAMES`).
- **Super layer:** `SuperState` = `NONE → SUPER_START → SUPER_ACTIVE → SUPER_END` (invisibility, ~5 s, fade transitions, deterministic once-only event guards).
- **Basic attack:** 4-projectile burst, 0.030 s interval, spread angles `[-0.05, -0.015, 0.015, 0.05]` rad; spawn point on the right hand bone (`ProjectileSpawnPoint` Marker2D).
- **Projectile:** `scenes/leon_projectile.tscn` (Area2D + Line2D trail); hits registered through `HitData`.
- **Hit / knockback:** `HIT` and `KNOCKBACK` states, driven by `HitData` (damage, direction, force) from `target_dummy.gd` (`hit_received` signal, elastic recoil return).
- **Facial expressions:** expression switching + auto-blink (`scripts/face_controller.gd`), with manual override (`locked_expression`).
- **Audio:** event-driven VO/SFX including deterministic variant rotation.

**Not implemented for Leon:** a `DEATH` state/animation (a DEATH audio VO event exists) and Gadgets. Do not present these as working.

## Animation Philosophy

- **Simple, readable, expressive.** Large silhouettes and strong poses read at video resolution.
- **Strong key poses, anticipation, follow-through** — timing lives in a small number of polished clips, not freeform motion.
- **Limited but intentional movement** — every state has a defined purpose.
- **Deterministic behavior** — fixed input → fixed result. Required for reproducible renders and automated regression tests (gdUnit4 simulates input frame-by-frame).
- **Reusable animation states** — one state/animation contract is intended to work for every future Brawler.

The project deliberately uses a **controlled 2D puppet system** (rig + state machine + events) rather than AI-generated freeform animation, because it is reproducible, testable, editable by an automated agent, and visually consistent across videos.

## Art Direction

- Paper-cutout construction: characters are separate flat SVG parts on a Skeleton2D rig.
- Flat colors, minimal shading, bold readable outlines.
- Large head / compact body proportions; simple facial features.
- Layered body parts (torso/arms/legs/head/face) built for animation.
- Environment assets follow the same flat, clean-silhouette style (see `docs/ASSET_LIBRARY.md`).

## Asset Structure

| Content | Location |
|---|---|
| Character parts / rigs / expressions | `assets/<brawler>/` (currently `assets/brawlers/leon/`, incl. `side/`, `projectile/`, `sheets/`) |
| Backgrounds / parallax | `assets/backgrounds/` |
| Modular terrain pieces | `assets/environments/` |
| Foreground layers | `assets/foreground/` |
| Props | `assets/props/` |
| Nature | `assets/nature/` |
| Architecture | `assets/architecture/` |
| VFX textures | `assets/vfx/` (+ `assets/vfx/kenney_particles/`) |
| World utilities (shadows, light masks, overlays) | `assets/world_utils/` |
| Licenses & references | `assets/references/` |
| Machine-readable asset catalog | `assets/asset_catalog.json` |
| Audio | `assets/audio/` (`sfx/`, `voices/`) |
| Scenes | `scenes/` |
| Scripts | `scripts/` (+ `scripts/vfx/`) |
| Tests | `tests/` |
| Tooling | `tools/` |
| Documentation | `docs/` |
| Render output (gitignored) | `renders/` |
| Test reports (generated) | `reports/` |

## Animation System

Implemented states in `character_controller.gd`:

```
IDLE  WALK  RUN  STOP  TURN
JUMP_ANTICIPATION → JUMP_AIRBORNE → FALL → JUMP_LAND
ATTACK   HIT   KNOCKBACK
+ SuperState: SUPER_START → SUPER_ACTIVE → SUPER_END
```

Animation and physics are separated: `CharacterBody2D` owns velocity/gravity/collision; the state machine selects animations and emits events; `AnimationPlayer` ("AnimPlayer") plays clips keyed to states. States carry deterministic once-only event guards (e.g. `super_has_started`) so each event fires exactly once per state entry.

## Event System

Events are plain Godot signals. Verified character signals (`character_controller.gd`):

`state_changed`, `attack_started`, `attack_released`, `attack_follow_through`, `attack_ended`, `attack_impact(hit_position)`, `projectile_spawned(spawn_position, direction)`, `attack_event`, `super_event`, `super_state_changed`.

Consumer events:

- **Audio** (`AudioManager.trigger_event()`): `ATTACK_RELEASE`, `RELOAD`, `ATTACK_END`, `SUPER_START`, `SUPER_END`, `JUMP`, `LAND`; VO variants: `SUPER_START_VO`, `CHARACTER_HIT`, `KNOCKBACK_START`, `DEATH`, `KILL`, `START`.
- **VFX** (`VFXManager.spawn_vfx()`): `HIT_IMPACT`, `DUST_PUFF`, `SPAWN_FLASH`, `SMOKE_BOMB` — bound automatically via `VFXManager.bind_character()` (e.g. `state_changed → "JUMP_LAND"` triggers `DUST_PUFF`).
- **Combat:** `target_dummy.gd` emits `hit_received(hit_data)`; its KO path calls `AudioManager.trigger_event("DEATH")`.

Audio must be synchronized through these deterministic events — **not** through arbitrary delays.

## Audio System

`scripts/audio_manager.gd` (autoload `AudioManager`):

- Event-driven playback via `trigger_event(event_name)`; characters attach with `bind_character()`.
- 16-player pool, volume controls (master/SFX/voice/music), mute.
- Deterministic VO **variant rotation** for multi-file events (e.g. two hurt VO files alternate predictably).
- Telemetry (`last_audio_event`, `event_counts`, …) usable by automated tests; emits `audio_event_triggered`.
- Audio files: `assets/audio/` (SFX: `sfx/leon/`, `sfx/common/`; VO: `voices/leon/`). **These are authentic Supercell "Brawl Stars" recordings** — see Asset/Licensing Notes before publishing any video.

## VFX System

- `scripts/vfx_manager.gd` (autoload `VFXManager`): event-driven spawning of reusable one-shot `CPUParticles2D` scenes via `spawn_vfx(name, global_pos)`, plus `bind_character()` auto-wiring and spawn telemetry.
- Reusable scenes in `scenes/vfx/`: `vfx_hit_impact.tscn`, `vfx_dust_puff.tscn`, `vfx_spawn_flash.tscn`, `vfx_smoke_bomb.tscn` (plain one-shot `CPUParticles2D`, textures from `assets/vfx/`), and `vfx_small_explosion.tscn` (composite flash+smoke+debris driven by `scripts/vfx/vfx_one_shot.gd`).
- `CPUParticles2D` is preferred over `GPUParticles2D` for deterministic Movie Maker capture.
- **Note:** `vfx_small_explosion.tscn` is a `Node2D` composite and is **not** registered in `VFXManager.VFX_SCENES` (which casts to `CPUParticles2D`). Integrate it there before triggering it by name. Status: verify.

## Camera System

Phantom Camera v0.11.0.3 (enabled plugin, `PhantomCameraManager` autoload):

- Purpose: follow/framing, damping, zoom, and shot switching for video scenes.
- Verified setup: `scenes/camera_test.tscn` — 3 cameras (`PCamFollow`, `PCamWide`, `PCamCloseUp`) with a `PhantomCameraHost` on `Camera2D`, covered by `tests/test_phantom_camera.gd`.
- Complex cinematic shot sequencing is **not** built — choreography is per-scene. Status: verify per video.

## Production Toolkit

Installed tools only:

| Tool | Version | Purpose | Status | Notes |
|---|---|---|---|---|
| Godot | 4.7 (GL Compatibility) | Engine / editor / Movie Maker | installed | `project.godot` |
| Phantom Camera | v0.11.0.3 | 2D camera follow/zoom/damping/switching | enabled plugin + autoload | `addons/phantom_camera/` |
| gdUnit4 | v6.2.1 | Headless unit/scene regression tests | installed (CLI runner) | `addons/gdUnit4/runtest.sh` |
| Kenney Particle Pack | v1.1 (CC0) | VFX source textures | installed | `assets/vfx/kenney_particles/` |
| Starter asset library | 189 assets (CC0) | Backgrounds/env/props/nature/arch/VFX/world utils | installed | `assets/asset_catalog.json` |
| gdtoolkit | 4.5.0 | gdformat / gdlint / gdparse | installed | `tools/gdformat.sh`, `tools/gdlint.sh`, `tools/gdparse.sh` |
| FFmpeg | 8.1.2 | H.264/AAC MP4 encode | external CLI | `/opt/homebrew/bin/ffmpeg` |

## Rendering / Video Pipeline

```
Godot Movie Maker (--write-movie, fixed 60 FPS AVI)
      → tools/render_video.sh
      → FFmpeg (libx264, yuv420p, CRF 18, preset slow + AAC 48 kHz)
      → renders/<name>.mp4  (faststart MP4; intermediate AVI deleted)
```

Verified usage (`tools/render_video.sh`):

```bash
export GODOT_BIN="/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot"
tools/render_video.sh --scene res://scenes/walk_test.tscn --duration 5 --fps 60 --output-name my_test
# other options: --output-dir, --format avi|png, --crf, --keep-intermediate, --extra-args
```

Run the test suite **before** rendering; renders land in `renders/` (gitignored).

## Testing

gdUnit4 v6.2.1, suites in `tests/`:

| Suite | Covers |
|---|---|
| `test_leon_state_smoke.gd` | Real Leon locomotion regression: `IDLE → WALK → STOP → IDLE` via simulated input |
| `test_bo_brawler.gd` | Bo integration: rig, sockets, locomotion, expressions, hit/knockback/death |
| `test_bo_attack.gd` | Bo basic attack: event sequence, 3-arrow volley, both directions, projectile causality (arrow reaches target before hit), one hit per arrow, attack-while-moving, repeated attacks |
| `test_phantom_camera.gd` | Camera follow/zoom/priority switching |
| `test_vfx_events.gd` | Event-driven VFX triggering via `VFXManager` |
| `test_brawler_template.gd` | Brawler Template (base/config/face controller) |

Verified commands (`docs/TOOLKIT_USAGE.md`):

```bash
export GODOT_BIN="/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot"
./addons/gdUnit4/runtest.sh -a tests/                       # all suites
./addons/gdUnit4/runtest.sh -a tests/test_leon_state_smoke.gd   # one suite
```

HTML/JUnit reports are written to `reports/`. The latest recorded full run passes; an earlier run surfaced a `Polygon2D`/`Sprite2D` type error in `templates/brawler/face_controller_base.gd` — re-run the suite after any template change. Also lint changed scripts with `./tools/gdlint.sh <file>`.

**Test before rendering:** run at least the Leon state smoke test plus any suite covering systems you touched.

## Repository Structure

```
cutenemi/
├── project.godot            # Godot 4.7, GL Compatibility, autoloads
├── scenes/
│   ├── demo.tscn            # MAIN SCENE (DemoDirector scripted demo)
│   ├── leon.tscn            # Leon production character
│   ├── walk_test.tscn       # Interactive locomotion harness (gdUnit4 uses this)
│   ├── camera_test.tscn     # Phantom Camera test stage
│   ├── target_dummy.tscn    # Hit/knockback practice target
│   ├── leon_projectile.tscn # Leon projectile
│   └── vfx/                 # Reusable one-shot VFX emitters
├── scripts/
│   ├── character_controller.gd  # Leon state machine (reference Brawler controller)
│   ├── face_controller.gd       # Expressions + auto-blink
│   ├── audio_manager.gd         # AUTOLOAD: event-driven audio
│   ├── vfx_manager.gd           # AUTOLOAD: event-driven VFX
│   ├── demo_director.gd         # Scripted demo sequencer
│   ├── hit_data.gd              # HitData resource (damage/direction/force)
│   ├── target_dummy.gd          # HitReceiver implementation
│   ├── leon_projectile.gd       # Leon projectile behavior
│   └── vfx/vfx_one_shot.gd      # Composite one-shot emitter helper
├── templates/brawler/       # Reusable Brawler framework (base scene + controllers)
├── assets/                  # leon/, audio/, vfx/, backgrounds/, environments/,
│   │                        # foreground/, props/, nature/, architecture/,
│   │                        # world_utils/, references/, asset_catalog.json
├── tests/                   # gdUnit4 suites
├── tools/                   # render_video.sh, gdformat/gdlint wrappers, .venv
├── docs/                    # TOOLKIT.md, TOOLKIT_USAGE.md, BRAWLER_TEMPLATE.md,
│   │                        # NEW_BRAWLER_WORKFLOW.md, ASSET_LIBRARY.md,
│   │                        # TOOLS_RECOMMENDATIONS.md, TOOLS_CANDIDATES.json,
│   │                        # brawler_audio_and_assets_guide.md
├── addons/                  # phantom_camera/, gdUnit4/ (installed plugins)
├── renders/                 # video output (gitignored)
└── reports/                 # gdUnit4 HTML/JUnit reports
```

## Adding a New Brawler

Full guide: `docs/NEW_BRAWLER_WORKFLOW.md`; interface contract: `docs/BRAWLER_TEMPLATE.md`. Summary:

1. **Prepare artwork** — flat paper-cutout parts (head/torso/arms/hands/legs/feet + expressions) as separate SVGs.
2. **Separate animation parts** — organize under `assets/<brawler_name>/` (`side/`, face parts, `projectile/`).
3. **Configure character** — create a `BrawlerConfig` `.tres` (speeds, HP, burst params, Super type, audio/VFX maps) in `brawlers/<brawler_name>/`.
4. **Use the reusable framework** — inherit `templates/brawler/brawler_base.tscn`; the template supplies movement, states, combat, events.
5. **Add unique animations** — keyframe the state-contract clips in the character's `AnimPlayer`.
6. **Add unique abilities** — burst/super parameters via config; extend `AbilityController`/`ProjectileBase` only when needed.
7. **Add projectile/VFX/audio** — register projectile scene, VFX scenes in `VFXManager`, sounds in `AudioManager` mappings.
8. **Run tests** — `./addons/gdUnit4/runtest.sh -a tests/`.
9. **Validate** — use `BrawlerBuilder.validate_brawler()` and check rig sockets (bones, `ProjectileSpawnPoint`, VFX points).
10. **Mark ready for production.**

The template handles reusable infrastructure; artwork, animation, and ability flavor remain character-specific.

## Creating a New Video

High-level production workflow (no fixed content or timings):

1. **Story** — define what happens and why.
2. **Scene requirements** — location(s), characters, actions, mood.
3. **Assets** — pick from the starter library (`docs/ASSET_LIBRARY.md`); add only what is missing.
4. **Scene construction** — assemble backgrounds/ground/props/camera in a new scene.
5. **Character actions** — script Brawler commands (DemoDirector pattern today).
6. **Animation** — verify states/poses sell the story beats.
7. **VFX** — trigger reusable emitters from events.
8. **Audio** — map events to sounds/VO.
9. **Rendering** — `tools/render_video.sh` for the scene.
10. **Review** — watch the MP4; fix issues in the smallest affected system.
11. **Final export** — re-render once approved.

## Rules for Antigravity

1. **Preserve working systems.** Leon and his pipeline are production-proven.
2. **Do not rebuild existing systems** without a strong, documented reason.
3. **Prefer small additive changes** over refactors.
4. **Reuse existing Brawler infrastructure** (controllers, managers, events, template).
5. **Do not duplicate universal systems per Brawler** — extend the shared framework.
6. **Keep animation deterministic** — no uncontrolled randomness in gameplay/replay paths.
7. **Keep physics and animation separated** — controller owns physics; AnimPlayer owns poses.
8. **Use existing event systems** (`state_changed`, `attack_*`, `super_*`, `trigger_event()`, `spawn_vfx()`).
9. **Test changes before final renders** — run the relevant gdUnit4 suites.
10. **Do not add unnecessary plugins** — every dependency needs license + maintenance review.
11. **Verify licensing of external assets** — record it in the asset catalog / license docs.
12. **Do not silently delete working files** — removals are explicit and reviewable.
13. **Do not change approved character artwork** without explicit instruction.
14. **When fixing a bug, modify the smallest affected subsystem.**
15. **Do not invent features or claim unverified functionality** — mark uncertain items "Status: verify".

## Development Principles

- Reuse over duplication.
- Deterministic behavior over randomness.
- Simple architecture over unnecessary abstraction.
- Production reliability over experimentation.
- Visual quality through controlled animation, not volume of motion.
- Reusable systems over one-off scene hacks.

## Known Limitations

Verified limitations only:

- **No playable game** — the project runs a scripted demo (`scenes/demo.tscn`) and test harnesses.
- **No Leon DEATH state/animation** — a DEATH VO audio event exists; no death state in the controller.
- **`vfx_small_explosion.tscn` is not wired into `VFXManager`** (composite root type vs. `CPUParticles2D` cast). Status: verify.
- **Brawler Template is unit-tested but not yet proven by a shipped second character**; an earlier gdUnit4 run exposed a `Polygon2D`/`Sprite2D` type error in `face_controller_base.gd` (latest recorded run passes).
- **Sequencing is hardcoded** — `demo_director.gd` uses a scripted `AutoStep` sequence; no data-driven SceneDirector yet.
- **Supercell audio** in `assets/audio/` is copyrighted material with fan-content-policy constraints (below).
- **3D physics engine is set to Jolt** in `project.godot`; unused by 2D gameplay.
- Machine has no `godot` CLI on PATH — renders/tests require `GODOT_BIN` (tooling default: `/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot`).

## Roadmap

- **COMPLETED** — Leon (art, rig, all listed states, attack/projectile, hit/knockback, Super, expressions), AudioManager, VFXManager, Phantom Camera install, gdUnit4 suites, render pipeline, starter asset library, Brawler Template (first pass).
- **CURRENT** — validating the Brawler Template end-to-end; wiring `vfx_small_explosion` into `VFXManager`.
- **NEXT** — first data-driven scene sequencer (generalize `DemoDirector`); first video production using the toolkit; `docs/ASSET_LICENSES.md` inventory + fan-content disclaimer.
- **FUTURE** — second Brawler via the template; replacement (CC0/original) audio for monetized publishing; richer camera choreography. No timelines or specific characters assumed.

## Asset / Licensing Notes

- **Project-created assets** — Leon SVG artwork/rig, generated world-util overlays: project original.
- **Third-party assets** — Kenney packs (particle textures + 189-asset starter library): **CC0 1.0**, commercial use allowed, no attribution required. Per-asset license catalog: `assets/asset_catalog.json`; human guide: `docs/ASSET_LIBRARY.md`; original license files: `assets/references/licenses/`.
- **External audio** — `assets/audio/` contains authentic **Supercell "Brawl Stars" SFX/VO** (documented in `docs/brawler_audio_and_assets_guide.md`). This is **copyrighted material**: publishing requires Supercell Fan Content Policy compliance (non-commercial use, mandatory "unofficial, not endorsed by Supercell" disclaimer, no implied endorsement). Plan original/CC0 replacement audio for monetized content. `docs/ASSET_LICENSES.md` does **not** exist yet.
- **Plugins** — Phantom Camera (MIT), gdUnit4 (MIT), gdtoolkit (MIT): commercial use permitted; check their licenses before redistributing plugin sources outside the repo.

## Getting Started

1. Open the repository in Antigravity (VS Code).
2. Open the project in **Godot 4.7** — the first open imports all assets; confirm zero import errors.
3. Run the main scene (`scenes/demo.tscn`, F5) to see the scripted Leon demo.
4. Run tests headlessly:
   ```bash
   export GODOT_BIN="/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot"
   ./addons/gdUnit4/runtest.sh -a tests/
   ```
5. Render when ready:
   ```bash
   tools/render_video.sh --scene res://scenes/walk_test.tscn --duration 5
   ```

## Troubleshooting

- **Godot version mismatch** — the project requires the `4.7` feature tag (`project.godot`); older editors warn or break. Use Godot 4.7.
- **"Godot binary not found"** from render/test scripts — set `GODOT_BIN` to the Godot executable (tooling default: `/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot`).
- **Missing plugin errors** — `addons/phantom_camera/` must exist (enabled plugin + `PhantomCameraManager` autoload). gdUnit4 is CLI-only and should not appear in `editor_plugins/enabled`.
- **Failed asset import** — let the first editor import finish and check the Output dock. New PNG/SVG assets need no special import settings; verify transparency/dimensions against `assets/asset_catalog.json`.
- **Failed tests** — read the HTML output under `reports/`. A `Polygon2D`/`Sprite2D` error in `face_controller_base.gd` has occurred historically (see Testing). The benign `Remote Debugger: Unable to connect` warning during headless runs is expected (`docs/TOOLKIT_USAGE.md`).
- **Render failure** — FFmpeg errors surface with exit code; check `renders/` and disk space. The intermediate AVI is kept when the encode step fails for diagnosis.






