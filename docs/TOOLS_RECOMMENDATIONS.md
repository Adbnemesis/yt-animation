# Godot Production Toolkit — Research & Recommendations

**Project:** cutenemi (2D Brawler-style animation production in Godot)
**Date of research:** 2026-09-04
**Engine:** Godot 4.7 (GL Compatibility renderer, `project.godot` `config/features = 4.7`)
**Scope:** Reusable tools/plugins/assets for future 2D animation videos. This document makes **zero changes** to Leon or any existing working system.

> Companion structured data: `TOOLS_CANDIDATES.json` (same folder).

---

## 1. Executive Summary — Final Decisions

| Category | Decision | Tool / Approach |
|---|---|---|
| A. Character animation / IK | **KEEP CURRENT** (+ use engine built-ins) | Skeleton2D/Bone2D rig + built-in `SkeletonModifier2D` family (`LookAtModifier2D`, `TwoBoneIKModifier2D`) |
| B. Physics / knockback | **KEEP CURRENT** | `CharacterBody2D` + custom knockback (already deterministic) |
| C. Sequencing / cutscenes | **BUILD OURSELVES** now → **Dialogic 2 later** | Generalize `DemoDirector` into data-driven `SceneDirector`; adopt Dialogic 2 when videos become dialogue-driven |
| D. VFX / particles | **INSTALL NOW** | Built-in `GPUParticles2D`/`CPUParticles2D` + Kenney Particle Pack (CC0) |
| E. Camera | **INSTALL NOW** | Phantom Camera 2D (MIT) |
| F. Audio | **KEEP CURRENT** | Existing event-driven `AudioManager` autoload |
| G. Environment / parallax | **USE BUILT-IN** | `Parallax2D` (Godot 4.3+) |
| H. Production / debugging | **INSTALL NOW** | gdUnit4 (MIT) + gdtoolkit/gdlint (MIT, CLI) |
| Video / export | **USE BUILT-IN** | Movie Maker mode (`--write-movie`) + ffmpeg (external) |

**Net result:** 2 editor plugins (Phantom Camera, gdUnit4), 1 CC0 asset pack, 1 external CLI (ffmpeg), everything else is engine built-in or custom. Nothing touches Leon's animation system.

---

## 2. Project Baseline (verified by inspection)

- Godot **4.7** stable; GL Compatibility renderer (movie-friendly); **no `addons/` folder exists yet**.
- Existing working systems (all to be preserved):
  - `scripts/character_controller.gd` — custom enum state machine (`State`, `SuperState`), deterministic event guards, hit-stop, signal-driven (`state_changed`, `attack_event`, `super_event`).
  - `scripts/audio_manager.gd` — autoload; event-driven playback, 16-player pool, VO variant rotation, telemetry, `bind_character()`.
  - `scripts/demo_director.gd` — hardcoded `AutoStep` scripted demo sequencer.
  - `scripts/face_controller.gd` — facial expressions + auto-blink.
  - `scripts/leon_projectile.gd` — Area2D projectile with hand-rolled `Line2D` trail.
  - `scripts/hit_data.gd`, `scripts/target_dummy.gd` — hit detection / knockback.
  - Build scripts (`build_*.gd`) that construct scenes programmatically; `verify_*.gd` ad-hoc validation scripts.
- Gaps found: **no camera node anywhere**, **no particles/VFX**, **no IK**, **no test framework**, **no data-driven sequencer**, AVI output only (no H.264/YouTube pipeline), no lint/format tooling.

---

## 3. Architecture Analysis

### 3.1 What we already have (do NOT replace)
| System | Status | Plugin overlap to avoid |
|---|---|---|
| State machine | Healthy, deterministic, signal-driven | godot-statecharts would duplicate it |
| Audio events | Superior fit to our pipeline vs any generic manager | Generic audio manager plugins |
| Hit/knockback | Working, deterministic | Ragdoll/physics plugins |
| Cutout rig + AnimationPlayer | Approved pipeline (`build_leon_side_scene.gd` etc.) | Spine / DragonBones / rigging plugins |
| Sequencing | Works but hardcoded per-demo | Replace with our own thin data-driven layer first |

### 3.2 Genuine capability gaps (justifying additions)
1. **Camera** — no camera node exists; the demo clamps the character position instead. A camera layer is required for cinematic videos (follow, zoom, shake, shot transitions).
2. **VFX** — zero particles. Impact/dust/smoke/flash effects are core to brawler video quality.
3. **IK** — head look-at and hand-aim would visibly improve production value; Godot 4.7 ships 2D skeleton modifiers natively, so no plugin is needed.
4. **Regression testing** — 10+ ad-hoc `verify_*.gd` scripts are not repeatable/headless; an AI agent editing 9k+ lines of scripts needs a real test runner.
5. **Sequencing** — future videos are "sequences of actions"; the current AutoStep enum must be generalized.
6. **Video pipeline** — AVI (MJPEG) output exists; needs an ffmpeg step for YouTube (H.264/AAC MP4).

### 3.3 Principle applied
> **EXISTING SYSTEM + SMALL HIGH-VALUE TOOL** over **REBUILD AROUND A PLUGIN**.

---

## 4. Candidate Evaluations

Recommendation values: **ESSENTIAL / USEFUL / OPTIONAL / DO NOT USE**.
Maintenance = last verified push/release date (researched 2026-09-04).

---

### 4.1 Phantom Camera — ESSENTIAL (camera)

- **NAME:** Phantom Camera
- **CATEGORY:** E — Camera
- **URL:** https://github.com/ramokz/phantom-camera (docs: phantom-camera.dev)
- **GODOT VERSION:** Godot 4.x; latest release v0.11.0.3 (published 2026-07-19) explicitly fixes a Godot **4.7.1** integration issue → confirmed compatible with our 4.7 project.
- **LICENSE:** MIT (commercial use allowed, attribution via license file required, redistribution allowed). Safe for YouTube production.
- **MAINTENANCE STATUS:** Very active — 3.5k★, 639 commits, release 6 weeks before research date, responsive issue tracking.
- **WHAT IT DOES:** Cinemachine-style camera layering for Camera2D. Node-based: `PhantomCameraHost` (one per Camera2D) + multiple `PhantomCamera2D` nodes with follow modes (Glued, Simple w/ damping, Group, Path, Framed dead-zones), zoom, limits, tweened transitions between active cameras, and noise-based shake.
- **WHY IT HELPS OUR PROJECT:** The project has **no camera at all**. Videos need shot framing, follow with damping, impact shake on hits/knockback, zoom punch on Super, and cut transitions between shots — all programmatically controllable (critical for our scripted pipeline).
- **HOW IT WOULD INTEGRATE:** Purely additive. Copy `addons/phantom_camera/` into project root, enable plugin, add `PhantomCameraHost` under a `Camera2D` in each video scene, add `PhantomCamera2D` nodes per shot. `SceneDirector`/`DemoDirector` can set `priority` or call `make_current()` to cut/tween between shots. Leon's scene is untouched.
- **RISKS / LIMITATIONS:** Adds a plugin-managed autoload (`PhantomCameraManager`); the v0.11.0.3 notes mention an upstream Godot quirk pending an engine PR — pin to the stable release, do not track `main`. Shake/damping are sim-like (not frame-deterministic); for fully deterministic shots use Glued mode + manual tweens.
- **RECOMMENDATION:** **ESSENTIAL**

### 4.2 gdUnit4 — ESSENTIAL (testing/debug)

- **NAME:** GdUnit4
- **CATEGORY:** H — Production/Debugging (test framework)
- **URL:** https://github.com/godot-gdunit-labs/gdUnit4 (docs: godot-gdunit-labs.github.io/gdUnit4)
- **GODOT VERSION:** Godot 4.x; v6.2.1 (published 2026-08-20) officially targets 4.5+ per its compatibility table. **Verify the 4.7 row in that table before install** (risk is low; addon is release-tracked).
- **LICENSE:** MIT (commercial use, attribution, redistribution all allowed).
- **MAINTENANCE STATUS:** Very active — monthly releases, CI on every PR, 1.2k★. Used by Dialogic 2's own test suite (ecosystem credibility).
- **WHAT IT DOES:** Embedded unit/scene test framework for GDScript (and C#): `GdUnitTestSuite`, fluent `assert_*` API, scene runner (simulated input/frames), signal awaiting, mocking/spying, orphan-node detection, HTML + JUnit XML reports, headless CLI runner for CI.
- **WHY IT HELPS OUR PROJECT:** Converts our `verify_leon_*.gd` culture into repeatable, headless regression tests (locomotion states, attack event ordering, audio event mapping, super state guards). This directly enables an AI agent to modify production scripts safely across many videos — every change is validated deterministically.
- **HOW IT WOULD INTEGRATE:** Addon install; tests live in `tests/` and never touch shipped scenes. Existing `verify_*.gd` scripts keep working; migration to test suites is incremental and optional.
- **RISKS / LIMITATIONS:** Editor plugin UI adds some editor startup weight (CLI runs headless regardless). Mocking API has a learning curve. Verify 4.7 compat row at install time.
- **RECOMMENDATION:** **ESSENTIAL**

### 4.3 Kenney Particle Pack + built-in GPUParticles2D — ESSENTIAL (VFX)

- **NAME:** Kenney Particle Pack (with Godot built-in `GPUParticles2D`/`CPUParticles2D`)
- **CATEGORY:** D — VFX
- **URL:** https://kenney.nl/assets/particle-pack
- **GODOT VERSION:** Not engine-dependent (textures only) → works in 4.7. Particle systems use built-in nodes.
- **LICENSE:** **CC0 1.0** — commercial use allowed, **no attribution required**, redistribution allowed. Zero-risk for the YouTube pipeline.
- **MAINTENANCE STATUS:** Static sprite pack (v1.0, 2018, 80 files, 512×512, 2D·VFX). No maintenance risk for CC0 textures; the particle *systems* are core engine features, permanently maintained by Godot.
- **WHAT IT DOES:** 80 smoke/glow/spark/flash sprites usable as particle textures. Combined with built-in particles we build reusable emitter scenes: hit impacts, run/land dust, attack spawn flashes, super-reveal smoke, knockback streaks.
- **WHY IT HELPS OUR PROJECT:** The project has **zero VFX** today (only a `Line2D` trail on the projectile). Stylized cartoon VFX is essential for brawler video production — and we need reusable emitter scenes, not one-off effect packs.
- **HOW IT WOULD INTEGRATE:** New `assets/vfx/kenney_particles/` (textures) + `scenes/vfx/*.tscn` (reusable emitters: `vfx_hit_impact.tscn`, `vfx_dust_puff.tscn`, `vfx_spawn_flash.tscn` …). Triggered via existing `VFXAttachmentPoints` markers and `attack_impact`/`state_changed` signals. No Leon scene rewrite required.
- **RISKS / LIMITATIONS:** GL Compatibility renderer limits advanced particle materials — stick to standard blend modes (add/mix). For frame-deterministic recording prefer `CPUParticles2D` (GPU particles can vary slightly per run); verify in Movie Maker output.
- **RECOMMENDATION:** **ESSENTIAL** (texture source now; emitter scenes built incrementally per video)

### 4.4 Dialogic 2 — USEFUL (sequencing/dialogue, adopt later)

- **NAME:** Dialogic 2
- **CATEGORY:** C — Sequencing/Cutscenes & Dialogue
- **URL:** https://github.com/dialogic-godot/dialogic (docs: dialogic.pro; the `coppolaemilio/dialogic` URL is a personal fork/mirror — use the org repo)
- **GODOT VERSION:** Godot 4.2.2+ → compatible with 4.7.
- **LICENSE:** MIT (bundles Roboto font under Apache 2.0). Commercial use allowed, attribution required (LICENSE file), redistribution allowed.
- **MAINTENANCE STATUS:** Very active — 5.9k★, pushed 2026-08-30, dedicated org + docs site + Discord.
- **WHAT IT DOES:** Timeline-based event editor: characters, dialogue, signals, scene changes, waits, conditions, custom events. Timelines are reusable `.dtl` resources playable at runtime.
- **WHY IT HELPS OUR PROJECT:** Future videos are "sequences of actions". A visual/data timeline beats our hardcoded `AutoStep` enum for scripting full videos, and its signal events can drive existing character signals and `AudioManager.trigger_event()`.
- **HOW IT WOULD INTEGRATE:** As an authoring layer only: timelines emit events → a thin adapter maps Dialogic events to `character.wants_*` flags, `AudioManager.trigger_event()`, and Phantom Camera shot switches. Our state machine and audio system remain authoritative.
- **RISKS / LIMITATIONS:** Large, editor-heavy plugin. Designed for dialogue/visual-novel flow, not frame-precise animation choreography — precise-timing steps still belong in custom `SceneDirector` code or `AnimationPlayer` tracks. Only adopt when a video is genuinely dialogue-driven.
- **RECOMMENDATION:** **USEFUL** (optional now; revisit when scripting dialogue-heavy videos). Alternative evaluated: **Dialogue Manager 4** (Nathan Hoad, MIT, Godot 4.6+, active, 3.8k★) — equally good; pick only ONE dialogue tool if/when needed.

---

### 4.5 godot-statecharts — OPTIONAL (state machines)

- **NAME:** Godot State Charts
- **CATEGORY:** H/A — State machines
- **URL:** https://github.com/derkork/godot-statecharts (docs: derkork.github.io/godot-statecharts)
- **GODOT VERSION:** Godot 4.x → compatible with 4.7.
- **LICENSE:** MIT.
- **MAINTENANCE STATUS:** Active — 1.6k★, pushed 2026-06-26, only 14 open issues, documentation site.
- **WHAT IT DOES:** UML state-chart nodes: `StateChart`, `AtomicState`, `CompoundState`, `ParallelState`, transitions (signal/property/timeout/event), plus an in-editor transition debugger.
- **WHY IT HELPS OUR PROJECT:** Only if character behavior grows beyond the current enum machine (e.g., many characters with layered states) — gives visual debugging of state flow.
- **HOW IT WOULD INTEGRATE:** Would wrap/replace `character_controller.gd`'s `change_state()` — i.e., a rewrite of working code.
- **RISKS / LIMITATIONS:** Direct conflict with our "do not redesign Leon" rule. The current enum SM with deterministic guards is simpler, faster to edit programmatically, and battle-tested in this repo.
- **RECOMMENDATION:** **OPTIONAL** — for future characters with complex behavior only. Do NOT retrofit onto Leon.

### 4.6 gdtoolkit (gdformat / gdlint) — USEFUL (production hygiene)

- **NAME:** gdtoolkit — GDScript parser/linter/formatter
- **CATEGORY:** H — Production/Debugging (external CLI, not an editor plugin)
- **URL:** https://github.com/Scony/godot-gdscript-toolkit
- **GODOT VERSION:** Engine-independent (parses GDScript source; supports Godot 4 syntax) → works with 4.7 code.
- **LICENSE:** MIT.
- **MAINTENANCE STATUS:** Active — 1.6k★, pushed 2025-10-09, widely used (recommended by gdUnit4's own contributing guide).
- **WHAT IT DOES:** `gdformat` (consistent formatting) + `gdlint` (style/max-line-width checks) + `gdparse` (syntax validation without opening the editor).
- **WHY IT HELPS OUR PROJECT:** Keeps 9k+ lines of scripts consistent across AI-agent edits; `gdparse` gives fast syntax validation in CI or before commit.
- **HOW IT WOULD INTEGRATE:** `pip install gdtoolkit`; run `gdformat scripts/ tests/` and `gdlint scripts/` pre-commit or pre-render.
- **RISKS / LIMITATIONS:** Formatting a whole repo creates a large one-time diff — run once on a dedicated commit.
- **RECOMMENDATION:** **USEFUL**

---

### 4.7 Godot built-in: 2D skeleton IK modifiers — USE NOW (no install)

- **NAME:** `SkeletonModifier2D` family — `LookAtModifier2D`, `TwoBoneIKModifier2D`
- **CATEGORY:** A — 2D IK / constraints
- **URL:** https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons/index.html
- **GODOT VERSION:** Shipped in Godot 4.4+ (2D skeleton modifier system); present in **4.7**. *(Exact minor-version split between 4.4/4.5/4.6 for each class should be confirmed in the editor's Create Node dialog / class reference at build time.)*
- **LICENSE:** Godot Engine license (MIT) — core feature.
- **MAINTENANCE STATUS:** Core engine — maintained by Godot itself.
- **WHAT IT DOES:** Runtime 2D bone modifiers on `Skeleton2D`: look-at rotation targeting (head/eyes/aim) and two-bone IK (arm/leg chain solving).
- **WHY IT HELPS OUR PROJECT:** Adds head look-at toward camera/targets and hand aim toward the projectile direction without rebuilding the rig — pure polish on the existing FK cutout rig.
- **HOW IT WOULD INTEGRATE:** Add modifier nodes as children of the relevant `Bone2D` chains inside Leon's existing skeleton; enable/disable per state via `character_controller` signals. Entirely optional per-animation; the base FK animations stay authoritative.
- **RISKS / LIMITATIONS:** Modifiers run every frame — gate them per state to avoid fighting authored keyframes. Verify exact class availability in 4.7 editor before designing around them.
- **RECOMMENDATION:** **USEFUL** — build-in when a shot needs it; no dependency, no install.

---

### 4.8 Godot built-in: Movie Maker mode + ffmpeg — ESSENTIAL (video pipeline, no install)

- **NAME:** Godot Movie Maker mode + ffmpeg (external)
- **CATEGORY:** Video / rendering / export; deterministic animation control
- **URL:** https://docs.godotengine.org/en/stable/tutorials/output/movie_writer.html
- **GODOT VERSION:** Core since Godot 4.0 → present in 4.7.
- **LICENSE:** Core engine (MIT); ffmpeg is LGPL/GPL depending on build — **as an external encode step invoked via CLI it does not infect project licensing** (we do not link or redistribute ffmpeg).
- **MAINTENANCE STATUS:** Core engine feature.
- **WHAT IT DOES:** `godot --write-movie out.avi --fixed-fps 60` renders deterministic, frame-locked AVI (MJPEG+PCM WAV) or PNG image sequences with WAV audio — offline rendering, not real-time. ffmpeg then converts to H.264/AAC MP4 for YouTube.
- **WHY IT HELPS OUR PROJECT:** The project already produces `.avi` demos; this formalizes the pipeline: deterministic fixed-fps capture (no dropped frames, audio in sync) + a repeatable encode step for YouTube delivery. Also enables 2D physics interpolation settings for smooth motion capture.
- **HOW IT WOULD INTEGRATE:** A small shell/Python script: (1) run Godot headless with `--write-movie`, (2) run ffmpeg `-crf 18 -preset slow` encode. Deterministic control pairs with our event-guard pattern and `--fixed-fps`.
- **RISKS / LIMITATIONS:** MJPEG AVI files are large (use PNG sequence for max quality if needed). Movie Maker disables vsync/real-time constraints — scenes relying on real-time timing may play slightly differently, which is actually desirable for determinism.
- **RECOMMENDATION:** **ESSENTIAL** (workflow documentation + encode script; nothing to install into Godot)

### 4.9 Godot built-in nodes covering remaining categories — USE NOW (no install)

| Built-in | Category | Purpose in our pipeline |
|---|---|---|
| `GPUParticles2D` / `CPUParticles2D` + `ParticleProcessMaterial` | D — VFX | All emitter scenes; CPUParticles2D for deterministic capture |
| `Parallax2D` (4.3+) | G — Environment | Multi-layer scrolling backgrounds; replaces old `ParallaxBackground`/`ParallaxLayer` |
| `PointLight2D` / `CanvasModulate` | G — Environment | Optional 2D lighting for mood shots |
| `Tween` (`create_tween()`) | 5 — Tweening | Deterministic programmatic eases for punch-ins, squash/stretch, camera moves |
| `DampedSpringJoint2D` | B — Physics | Springs/bouncing props; secondary motion on loose objects |
| `AnimationTree` + `AnimationNodeBlendSpace1D/2D` | A — Blending | Only if locomotion blending is ever needed; current explicit `AnimationPlayer.play()` calls stay |
| `Line2D` / `Polygon2D` | D — Trails | Already used by `leon_projectile.gd`; extend for swing trails |
| Audio buses + `AudioEffectSFXRecorder`/`AudioStreamInteractive` (4.3+) | F — Audio | Music/voice mixing without replacing `AudioManager` |
| `CharacterBody2D` + `move_and_slide()` + physics interpolation (2D, 4.3+) | B/19 | Deterministic knockback/movement; smooth fixed-fps movie capture |
| Editor state-machine debugger / remote inspector / `--debug-collisions` | H — Debugging | No plugin needed for basic animation inspection |

**RECOMMENDATION for all:** built-in — **USE NOW** where the pipeline needs them. No third-party dependency exists for these categories that beats the engine.

---

### 4.10 Rejected candidates — DO NOT USE

| Tool | URL | Reason for rejection |
|---|---|---|
| **Spine runtime (esotericsoftware)** | http://esotericsoftware.com/spine-godot | **Proprietary runtime — requires a paid Spine license for commercial use.** Also forces a foreign rig format over our approved Skeleton2D pipeline. Only reconsider if we ever need mesh-deform-level 2D animation that Skeleton2D cannot deliver. |
| **DragonBones + Godot exporters** | github.com/search?q=dragonbones+godot | Abandoned (Godot 3 era, unmaintained). |
| **davcri/godot4-springs** | https://github.com/davcri/godot4-springs | **No license file**, last push 2022, 4★, minimal scope. Unusable legally. |
| **AnidemDex/Sequence (cutscene sequencer)** | github.com/AnidemDex/Sequence | Repo returned 404 on GitHub API at research time — moved or abandoned; **unverifiable**. |
| **Dialogue Manager 4 (Nathan Hoad)** | https://github.com/nathanhoad/godot_dialogue_manager | Good tool (MIT, Godot 4.6+, active) but redundant if Dialogic 2 is adopted — installing two dialogue systems adds complexity. Alternative only. |
| **Generic "best Godot assets" VFX packs** | (asset library) | One-off assets with unclear licenses; violates our reusability and licensing rules. |
| **Godot 3.x-only plugins generally** | (asset library) | Incompatible with 4.7 unless verified; none identified as compelling. |

---

## 5. Licensing Summary

| Tool | License | Commercial | Attribution | Redistribution | YouTube-safe |
|---|---|---|---|---|---|
| Phantom Camera | MIT | ✅ | ✅ keep LICENSE | ✅ | ✅ |
| gdUnit4 | MIT | ✅ | ✅ keep LICENSE | ✅ | ✅ |
| Kenney Particle Pack | CC0 1.0 | ✅ | ❌ not required | ✅ | ✅ |
| Dialogic 2 | MIT (+Apache 2.0 font) | ✅ | ✅ keep LICENSE | ✅ | ✅ |
| godot-statecharts | MIT | ✅ | ✅ keep LICENSE | ✅ | ✅ |
| gdtoolkit | MIT (dev tool, not shipped) | ✅ | n/a | n/a | ✅ |
| Godot engine built-ins | MIT (engine) | ✅ | Godot credits screen recommended | ✅ | ✅ |
| ffmpeg (external encode) | LGPL/GPL build | ✅ as external process | n/a | do not redistribute binary | ✅ |

> **⚠️ MAJOR IP FLAG (bigger than any plugin):** `docs/brawler_audio_and_assets_guide.md` documents the use of **authentic Supercell "Brawl Stars" SFX and voice lines** in `assets/audio/`. Supercell audio is **copyrighted**. For YouTube production this requires strict compliance with the **Supercell Fan Content Policy**: non-commercial use, mandatory disclaimer ("This material is unofficial and is not endorsed by Supercell…"), and no implication of endorsement. Recommended actions: (1) create `docs/ASSET_LICENSES.md` inventorying every audio file's origin; (2) add a standard fan-content disclaimer to video descriptions/templates; (3) plan original or CC0-licensed replacement audio for any monetized content. No plugin decision changes this.

---

## 6. Ranked Shortlist

| Rank | Tool | Recommendation | Effort to adopt | Impact |
|---|---|---|---|---|
| 1 | Phantom Camera v0.11.0.3 | ESSENTIAL | Low (addon + 2 node types) | Unlocks the entire cinematic layer (missing today) |
| 2 | gdUnit4 v6.2.1 | ESSENTIAL | Low (addon + `tests/`) | Makes every future change verifiable for the AI agent |
| 3 | Movie Maker + ffmpeg workflow | ESSENTIAL | Low (docs + script) | Deterministic, sync-locked video output for YouTube |
| 4 | Kenney Particle Pack (CC0) | ESSENTIAL | Low (copy textures) | Source art for a full reusable VFX library |
| 5 | Built-in 2D IK modifiers | USEFUL | Low (nodes only) | Head/eye look-at and hand aim polish |
| 6 | Custom `SceneDirector` (build) | USEFUL | Medium (new script) | Data-driven per-video sequencing |
| 7 | gdtoolkit (gdlint/gdformat) | USEFUL | Low (CLI) | Code consistency for agent edits |
| 8 | Dialogic 2 | USEFUL (later) | Medium (large addon) | Dialogue-driven video scripting |
| 9 | godot-statecharts | OPTIONAL | Medium | Only for complex future characters |
| 10 | Dialogue Manager 4 | OPTIONAL (alt) | — | Only if Dialogic 2 is rejected |
| — | Spine / DragonBones / godot4-springs / Sequence | DO NOT USE | — | Licensing, abandonment, or unverifiable |

---

## 7. Toolkit Plan

### CORE TOOLKIT (use now) — and the pipeline part each owns

| Tool | Pipeline responsibility |
|---|---|
| **Phantom Camera** | All camera behavior in videos: shot framing, follow with damping, limits, zoom, impact shake (hooked to `attack_impact`/`KNOCKBACK` signals), tweened shot transitions/cuts |
| **gdUnit4** | Regression safety net: locomotion state transitions, attack event ordering, audio event mapping, super-state guards — run headless before any render |
| **Godot Movie Maker + ffmpeg script** | Final video delivery: fixed-fps deterministic render (AVI/PNG+WAV) → H.264/AAC MP4 |
| **Kenney Particle Pack + built-in particles** | VFX library source: hit impacts, dust, flashes, smoke; emitter scenes triggered from existing signals |
| **Built-in `Parallax2D`, `Tween`, `Line2D`** | Background layering, programmatic punch-ins/squash-stretch, projectile/swing trails (trail already exists) |

### OPTIONAL TOOLKIT (later, trigger-based)

| Tool | Adopt when… |
|---|---|
| **Dialogic 2** | …a video script is dialogue-driven; timelines then drive character/audio/camera through a thin adapter |
| **Built-in 2D IK modifiers** | …a shot needs head look-at or hand aiming |
| **godot-statecharts** | …a future character's behavior outgrows an enum state machine |
| **gdtoolkit** | …any time — run before commits |
| **Dialogue Manager 4** | …only if Dialogic 2 proves too heavy |

### DO NOT USE
Spine (paid license), DragonBones (abandoned), godot4-springs (no license), AnidemDex/Sequence (unverifiable/abandoned), Dialogue Manager alongside Dialogic, random asset-library VFX packs, any Godot 3.x-only plugin.

---

## 8. Installation Plan (execute in this order; each step independently reversible)

**Step 0 — Pre-flight (no installs):**
1. Create a git branch: `git checkout -b toolkit/phase-1`.
2. Commit current state as the rollback point.

**Step 1 — gdUnit4 (test framework first, so everything after is verifiable):**
1. Download the v6.2.1 release (AssetLib: "GdUnit4", or GitHub release zip).
2. Copy `addons/gdUnit4/` into project root.
3. Confirm the 4.7 row in its compatibility table / run a smoke test.
4. Create `tests/` with one example suite (e.g., `tests/leon_state_machine_test.gd` verifying `IDLE → WALK → STOP` via `state_changed`).
5. Run headless: `addons/gdUnit4/runtest.sh -a`.
6. Do NOT enable the editor plugin UI if it slows startup — the CLI is enough.

**Step 2 — Phantom Camera:**
1. Download release v0.11.0.3 zip (AssetLib: "Phantom Camera").
2. Copy only `addons/phantom_camera/` into project root.
3. Enable in Project Settings → Plugins.
4. In one video scene only (e.g., `demo.tscn`): add `Camera2D` + `PhantomCameraHost`, add a `PhantomCamera2D` set to follow Leon (`Glued` or `Framed`).
5. Remove the `MIN_X/MAX_X` character clamping from that scene's director instance once the camera handles framing.
6. Keep Leon's scenes (`leon.tscn`, `leon_side.tscn`) untouched.

**Step 3 — Kenney Particle Pack (CC0):**
1. Download from kenney.nl/assets/particle-pack.
2. Copy selected PNGs to `assets/vfx/kenney_particles/` (keep the original `License.txt` alongside).
3. Build the first reusable emitter: `scenes/vfx/vfx_hit_impact.tscn` (`CPUParticles2D`, one-shot, additive blend), triggered from `attack_impact`.

**Step 4 — ffmpeg render script (external):**
1. Install ffmpeg (`brew install ffmpeg` on this macOS machine).
2. Add `tools/render_video.sh`: `godot --path . --write-movie output.avi --fixed-fps 60 scenes/<video>.tscn` then `ffmpeg -i output.avi -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p output.mp4`.

**Step 5 — Custom `SceneDirector` (build ourselves, no install):**
1. New `scripts/scene_director.gd`: steps as an `Array[Dictionary]` resource (`{wait, action, params}`) driving the same `character.wants_*` / `AudioManager` / camera APIs that `DemoDirector` uses.
2. Keep `DemoDirector` as-is; migrate demos gradually.

**Deferred installs:** Dialogic 2 (dialogue-driven videos), godot-statecharts (complex future characters), 2D IK modifier nodes (per-shot polish).

---

## 9. Rollback Steps

| Tool | Rollback |
|---|---|
| gdUnit4 | Disable plugin (if enabled) → delete `addons/gdUnit4/` + `tests/` → remove any `gdUnit4` settings keys from `project.godot` (verify with `git diff project.godot`). |
| Phantom Camera | Project Settings → Plugins → disable → delete `addons/phantom_camera/` → remove `PhantomCameraHost`/`PhantomCamera2D` nodes → re-add a plain `Camera2D` where needed. Before any PC2D nodes are added, rollback is a pure folder delete. |
| Kenney particles | Delete `assets/vfx/` + `scenes/vfx/`. No settings touched. |
| ffmpeg script | Delete `tools/render_video.sh`; uninstalling ffmpeg is optional. |
| SceneDirector | Delete `scripts/scene_director.gd`; `DemoDirector` remains the fallback at all times. |

**Universal rollback:** `git checkout main && git branch -D toolkit/phase-1` restores the exact pre-toolkit state.

---

## 10. Architecture Impact

| Layer | Impact |
|---|---|
| Leon scene / rig / animations | **None.** No edits to `character_controller.gd`, `face_controller.gd`, rig build scripts, or `AnimationPlayer` tracks. |
| Signals & event flow | **None replaced.** New systems *consume* existing signals (`attack_impact`, `state_changed`, `audio_event_triggered`) — the event-driven design stays the backbone. |
| Autoloads | `AudioManager` unchanged. Phantom Camera adds one plugin autoload (`PhantomCameraManager`) — scoped, documented, reversible. |
| Scenes | New additive scenes only: `tests/`, `scenes/vfx/`, camera nodes in video scenes. |
| Dependencies added | 2 MIT addons (pinned versions), 1 CC0 texture pack, 1 external CLI. Third-party surface deliberately minimized. |
| Determinism | Preserved and strengthened: fixed-fps Movie Maker, CPUParticles2D option, event-guard pattern unaffected. |

---

## 11. Second Pass — Missing Capabilities Audit

| Capability | Status | Action | Priority |
|---|---|---|---|
| Camera system | **Missing entirely** | Phantom Camera (ESSENTIAL) | **High** |
| Particles/VFX | **Missing entirely** | Kenney CC0 + built-in emitters | **High** |
| Automated regression tests | Ad-hoc only | gdUnit4 | **High** |
| Video encode pipeline | AVI only | Movie Maker + ffmpeg script | **High** |
| Data-driven sequencing | Hardcoded per-demo | Custom SceneDirector; Dialogic later | Medium |
| 2D IK | Missing | Built-in modifiers per-shot | Medium |
| Code lint/format | Missing | gdtoolkit | Medium |
| Dialogue system | Missing | Dialogic 2 — only when needed | Low (deferred) |
| Parallax/environment | Missing but trivial | Built-in `Parallax2D` | Low (no tool risk) |
| Secondary motion (springs) | Missing | Small custom script / `DampedSpringJoint2D` (no viable plugin exists) | Low |
| State-machine visualization | Editor-only | Deferred — current SM is simple | Low |
| Audio | **Complete** (`AudioManager`) | None — keep current | — |

No major capability beyond this table was identified; the project is unusually complete for animation production, with camera/VFX/testing/video being the true gaps.

---

## 12. Review Notes

- Re-verify pinned versions (Phantom Camera, gdUnit4) before each install; both projects release frequently.
- Re-run gdUnit4 suites before every Movie Maker render.
- Revisit this document after the first full video is produced (decision trigger: adopt Dialogic 2 or not).
- Create `docs/ASSET_LICENSES.md` as the license inventory, including the Supercell fan-content disclaimer template (see §5 IP flag).
