# Godot Production Toolkit — Usage Guide

This guide provides command-line recipes and development instructions for working with the tools in this project.

---

## 1. Running Automated Tests (gdUnit4)

### Running All Tests Headlessly
To run the complete test suite headlessly via the gdUnit4 CLI runner:

```bash
./addons/gdUnit4/runtest.sh -a tests/
```

### Running a Specific Test File
```bash
# Leon Locomotion Smoke Test
./addons/gdUnit4/runtest.sh -a tests/test_leon_state_smoke.gd

# Phantom Camera Feature Test
./addons/gdUnit4/runtest.sh -a tests/test_phantom_camera.gd

# VFX Event Integration Test
./addons/gdUnit4/runtest.sh -a tests/test_vfx_events.gd
```

### Inspecting Test Failures & Reports
Reports are automatically written upon each test execution to the `reports/` directory:
- HTML Interactive Report: `reports/index.html`
- JUnit XML: `reports/results.xml`

Open in browser:
```bash
open reports/index.html
```

---

## 2. Launching & Testing Phantom Camera

### Running the Camera Test Scene
A dedicated test scene is available at `scenes/camera_test.tscn`. It integrates `Camera2D`, `PhantomCameraHost`, and 3 active `PhantomCamera2D` nodes:
- `PCamFollow`: Priority 10, smooth follow with position damping (0.5s), zoom 1.0x.
- `PCamWide`: Priority 5, wide overview shot, zoom 0.65x.
- `PCamCloseUp`: Priority 5, tight combat action shot, zoom 1.6x.

To launch interactively in Godot:
```bash
/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot scenes/camera_test.tscn
```

### Interactive Camera Hotkeys (in `camera_test.tscn`)
- `1`: Switch to Follow Camera (`PCamFollow`, 1.0x zoom, damped tracking).
- `2`: Switch to Wide Arena Camera (`PCamWide`, 0.65x zoom).
- `3`: Switch to Combat Close-Up (`PCamCloseUp`, 1.6x zoom).
- `A` / `D` or `Left` / `Right`: Move Leon left/right to observe camera damping and framing.
- `Space`: Jump.
- `J`: Attack / throw shuriken.
- `K`: Trigger Super (smoke burst and invisibility).

---

## 3. Using the Starter VFX Library

### Available Reusable VFX Scenes
All starter effects reside in `scenes/vfx/`:
1. `scenes/vfx/vfx_hit_impact.tscn` — Golden spark burst for projectile/melee impacts.
2. `scenes/vfx/vfx_dust_puff.tscn` — Ground dust puff for landing and hard braking.
3. `scenes/vfx/vfx_spawn_flash.tscn` — Energy flash for projectile spawns and muzzle blasts.
4. `scenes/vfx/vfx_smoke_bomb.tscn` — Radial chameleon smoke burst for stealth/Super abilities.

### Spawning VFX via Code
Using the autoloaded `VFXManager`:

```gdscript
# Spawn at a specific global position
VFXManager.spawn_hit_impact(target_node.global_position)
VFXManager.spawn_dust_puff(character.global_position)
VFXManager.spawn_spawn_flash(muzzle_position)
VFXManager.spawn_smoke_bomb(character.global_position)

# Or generic emitter:
VFXManager.spawn_effect("res://scenes/vfx/vfx_hit_impact.tscn", global_pos)
```

### Automatic Event Connections
In any scene containing Leon and/or Target Dummy:
```gdscript
# Connect Leon signals to VFXManager in your scene root _ready():
VFXManager.register_character(leon_instance)
VFXManager.register_target(dummy_instance)
```

---

## 4. Rendering Video (Movie Maker & FFmpeg)

The project includes an automated, deterministic capture script at `tools/render_video.sh`.

### Basic Usage
```bash
./tools/render_video.sh <scene_path> <duration_seconds> [output_name]
```

### Examples
Render 3 seconds of the camera test scene to `renders/camera_demo.mp4`:
```bash
./tools/render_video.sh res://scenes/camera_test.tscn 3 camera_demo
```

Render 4 seconds of the standard walk/combat test scene:
```bash
./tools/render_video.sh res://scenes/walk_test.tscn 4 walk_combat
```

### Configuration Options
The script exposes environment variables for render customization:
```bash
# Example: 120 FPS high-framerate capture
FPS=120 ./tools/render_video.sh res://scenes/camera_test.tscn 2 high_fps_demo

# Example: Custom resolution
WIDTH=1920 HEIGHT=1080 ./tools/render_video.sh res://scenes/camera_test.tscn 5 1080p_demo
```

Default Encoding Output:
- Video: H.264 High Profile, CRF 18, `yuv420p`, `-preset slow`.
- Audio: AAC Stereo, 48 kHz, 320 kbps.
- Container: MP4 with `+faststart` (YouTube / web playback optimized).

---

## 5. GDScript Linting and Formatting (gdtoolkit)

Standalone CLI wrappers are located in `tools/`:

### Formatting Code
Format a specific newly created script:
```bash
./tools/gdformat.sh scripts/vfx_manager.gd
```

Check format without modifying:
```bash
./tools/gdformat.sh --check scripts/vfx_manager.gd
```

### Linting Code
Lint a specific script or directory:
```bash
./tools/gdlint.sh scripts/vfx_manager.gd
./tools/gdlint.sh tests/test_vfx_events.gd
```

### Parsing AST Validation
Check syntax validity:
```bash
./tools/gdparse.sh scripts/vfx_manager.gd
```

---

## 6. Inspecting Failures and Troubleshooting

1. **Godot Headless Debugger Socket Warning:**
   When running `./addons/gdUnit4/runtest.sh`, Godot outputs `Remote Debugger: Unable to connect to host '127.0.0.1:0'`. This is intentional behavior from Godot when interactive debugging is disabled for headless execution. It is benign and does not interfere with test execution.
2. **Missing Render Artifacts:**
   Renders are saved to the `renders/` directory. If FFmpeg fails, the script will output the exact FFmpeg exit code and keep the intermediate file for diagnosis.
3. **Physics Space in Scene Tests:**
   When creating tests for `CharacterBody2D`, always run within a scene tree runner (`scene_runner("res://scenes/walk_test.tscn")`) rather than instantiating the node in isolation so that floor collisions and physics spaces function correctly.
