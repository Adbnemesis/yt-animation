# Godot Production Toolkit — System Architecture & Reference

This document details the production toolkit installed and configured for the 2D Brawler animation pipeline in Godot 4.7.

---

## 1. Installed Tools & Specifications

### A. gdUnit4 (v6.2.1)
- **Engine / Release:** v6.2.1 (Author: Mike Schulze)
- **Location:** `addons/gdUnit4/`
- **Purpose:** Headless automated testing, scene-runner input simulation, state machine regression testing, and CI/CD validation.
- **Dependencies:** Godot 4.3+ (Engine v4.7 compatible), bash test runner (`./addons/gdUnit4/runtest.sh`).
- **Integration Points:**
  - `tests/` directory houses test suites.
  - `tests/test_leon_state_smoke.gd`: Real-character locomotion regression (`IDLE -> WALK -> STOP -> IDLE`).
  - `tests/test_phantom_camera.gd`: Multi-camera priority, follow, damping, and zoom verification.
  - `tests/test_vfx_events.gd`: Event-driven particle triggering verification.
  - Autoloads / reports: Outputs JUnit XML and HTML reports to `reports/`.

### B. Phantom Camera (v0.11.0.3)
- **Release:** v0.11.0.3 (Author: Marcus Skov)
- **Location:** `addons/phantom_camera/`
- **Purpose:** CineMachine-style dynamic 2D camera tweening, damping, zooming, and target framing for cinematic animation and combat sequences.
- **Dependencies:** Godot 4.x 2D/3D camera subsystems.
- **Integration Points:**
  - Plugin registration in `project.godot` (`editor_plugins/enabled=["res://addons/phantom_camera/plugin.cfg"]`).
  - Autoload manager: `PhantomCameraManager="*res://addons/phantom_camera/scripts/managers/phantom_camera_manager.gd"`.
  - Dedicated scene: `scenes/camera_test.tscn` with 3 operational cameras (`PCamFollow`, `PCamWide`, `PCamCloseUp`) and host `PhantomCameraHost` on `Camera2D`.
  - Zero modifications to core Leon scenes (`scenes/leon.tscn` remains independent).

### C. Kenney Particle Pack (CC0 1.0) & Starter VFX Library
- **Release:** Particle Pack v1.1 (Kenney.nl, CC0 1.0 Public Domain)
- **Location:** `assets/vfx/kenney_particles/`
- **Purpose:** Stylized starter visual effects (sparks, dust puffs, muzzle/spawn flashes, smoke bursts) optimized for 2D animation.
- **Starter VFX Scenes:**
  - `scenes/vfx/vfx_hit_impact.tscn`: Golden spark burst upon projectile collision or physical impact (`CPUParticles2D`).
  - `scenes/vfx/vfx_dust_puff.tscn`: Ground dust kick upon jump landing or sudden deceleration (`CPUParticles2D`).
  - `scenes/vfx/vfx_spawn_flash.tscn`: Shuriken projectile release flash (`CPUParticles2D`).
  - `scenes/vfx/vfx_smoke_bomb.tscn`: Chameleon smoke burst for Super cloak/uncloak (`CPUParticles2D`).
- **Determinism Note:** Implemented using `CPUParticles2D` for 100% deterministic sub-frame rendering during Godot Movie Maker video capture.

### D. VFX Event Integration (`VFXManager`)
- **Location:** `scripts/vfx_manager.gd`
- **Purpose:** Decoupled event-driven VFX spawning without cluttering character physics or state scripts.
- **Integration Points:**
  - Autoload: `VFXManager="*res://scripts/vfx_manager.gd"`.
  - Connected signals:
    - Character `jump_landed` (from `character_controller.gd`) $\rightarrow$ `vfx_dust_puff.tscn`
    - Character `projectile_spawned` (from `character_controller.gd`) $\rightarrow$ `vfx_spawn_flash.tscn`
    - Character `attack_impact` & Target `hit_received` (from `target_dummy.gd`) $\rightarrow$ `vfx_hit_impact.tscn`
    - Character `super_started` / `super_ended` $\rightarrow$ `vfx_smoke_bomb.tscn`

### E. Movie Maker & FFmpeg Rendering Pipeline
- **FFmpeg Version:** 8.1.2 (Apple clang, Homebrew: `/opt/homebrew/bin/ffmpeg`)
- **Render Script:** `tools/render_video.sh`
- **Output Directory:** `renders/` (configured in `.gitignore`)
- **Purpose:** Automated, deterministic high-framerate video rendering from Godot game scenes to YouTube-ready H.264/AAC MP4.
- **Pipeline Workflow:**
  1. Godot headless invocation with `--write-movie <intermediate_avi>` at fixed 60 FPS.
  2. FFmpeg two-stage remux/encode:
     - Video: H.264 (`libx264`), `yuv420p` pixel format, `-crf 18`, `-preset slow`.
     - Audio: AAC stereo, 48 kHz, 320 kbps.
     - Container: MP4 with `-movflags +faststart` for instant streaming playback.
  3. Automatic cleanup of heavy intermediate `.avi` capture files.

### F. gdtoolkit (v4.5.0)
- **Version:** 4.5.0 (`gdformat`, `gdlint`, `gdparse`)
- **Location:** `tools/.venv/` (isolated Python virtual environment)
- **Executable Wrappers:**
  - `tools/gdformat.sh`
  - `tools/gdlint.sh`
  - `tools/gdparse.sh`
- **Purpose:** Code consistency, AST validation, and linting for newly created production GDScript files without disrupting existing working scripts.

---

## 2. Built-in Godot 4.7 Capabilities

Godot 4.7 provides native engine systems that require no external plugins:
- **Skeleton & Inverse Kinematics:** `Skeleton2D`, `Bone2D`, `SkeletonModificationStack2D`, `SkeletonModification2DLookAt`, `SkeletonModification2DTwoBoneIK`, `SkeletonModification2DFABRIK`, `SkeletonModification2DCCDIK`, `SkeletonModification2DJiggle`.
- **Particles:** `GPUParticles2D` (GPU compute) and `CPUParticles2D` (CPU deterministic).
- **Parallax:** Native `Parallax2D` node with seamless repeat offsets and velocity mirroring.
- **Interpolation & Physics:** `physics/common/physics_interpolation` project setting and per-node `physics_interpolation_mode`.
- **Audio Routing:** Native `AudioServer` multi-bus routing system.
- **Geometry & Tweens:** Native `Line2D` and `SceneTree.create_tween()`.

---

## 3. Rollback & Disaster Recovery Notes

- **Rollback Git Checkpoint:**
  - Branch: `toolkit/phase-1`
  - Checkpoint Commit: `30e4473` (`checkpoint: before production toolkit installation`)
- **Preserved Core Files:**
  - `scenes/leon.tscn`
  - `scripts/character_controller.gd`
  - `scripts/face_controller.gd`
  - `scripts/leon_projectile.gd`
  - `scripts/hit_data.gd`
  - `scripts/target_dummy.gd`
  - `scripts/audio_manager.gd`
- **Reverting Toolkit:**
  To return cleanly to pre-toolkit state:
  ```bash
  git checkout 30e4473
  ```
