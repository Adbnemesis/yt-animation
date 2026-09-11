# Leon — 2.5D Spatial Fundamentals Test Report

**Document:** `docs/LEON_2_5D_SPATIAL_TEST.md`  
**Status:** VALIDATED SYSTEM REPORT  
**Related Specifications:** `CINEMATIC_2D_2_5D_ANIMATION_BIBLE.md` · `CINEMATIC_ANIMATION_CONTRACT.md` · `MULTIVIEW_CHARACTER_SYSTEM.md`  
**Scene Location:** `scenes/labs/leon_2_5d_spatial_test.tscn`  
**Test Suite:** `tests/test_leon_2_5d_spatial.gd`

---

## 1. Executive Summary

This report validates the **2.5D Spatial Fundamentals** for Leon in Godot 4.7.2. Before staging cinematic shorts, we have proven that 2D paper-cutout characters can convincingly inhabit a 3D-like spatial world governed by mathematical projection rather than manual animation tricks.

### The Fundamental Axiom
> **Horizontal movement ($X$) and Depth movement ($\text{Depth}$) are decoupled.**  
> Moving left or right alters horizontal screen position while apparent scale remains constant. Moving toward or away from the camera alters apparent scale continuously via camera projection.

All 9 automated test cases in `tests/test_leon_2_5d_spatial.gd` pass with zero failures and zero regressions against the existing codebase.

---

## 2. World Coordinate System

Our 2.5D world employs three distinct spatial axes:

```
           +Y (Elevation / Jump)
            ▲
            │
            │      +Depth (Away into Scene / Horizon)
            │     ▲
            │    /
            │   /
            │  /
            │ /
────────────┼────────────────► +X (Horizontal Right)
           /│
          / │
         /  │
    Near    │
(Toward     ▼
Camera)
```

| Dimension | World Axis | Physical Meaning | Screen Effect | Scale Effect |
|---|---|---|---|---|
| **$X$** | Ground Lateral | Left / Right position along the stage floor | Changes `screen_x` | **Constant** ($\Delta \text{scale} = 0$) |
| **$Y$** | Elevation | Height above ground plane ($Y=0$ at feet) | Moves up/down (`screen_y`) | **Constant** (Jumping does not scale!) |
| **$\text{Depth}$ ($Z$)** | Distance to Camera | Near / Far position along line of sight | Changes `screen_y` baseline & horizon convergence | **Scales continuously** ($k = \frac{\text{focal}}{\text{focal} + \text{depth}}$) |

---

## 3. Mathematical Projection & Scale Relationship

Apparent size is derived strictly from the camera projection model. It is **never** keyframed manually or adjusted via per-shot scale hacks.

### 3.1 Perspective Mode (Primary Cinematic Mode)

Let $\mathbf{P}_{\text{world}} = (x, z)$ on the ground plane, elevation $y$, camera ground position $\mathbf{C} = (c_x, c_z)$, camera yaw $\theta$, camera height $H_{\text{cam}}$, and focal length $F$:

1. **Camera-Relative Coordinates**:
   $$\mathbf{R} = \mathbf{P}_{\text{world}} - \mathbf{C}$$
   $$\text{depth} = \mathbf{R} \cdot (\sin\theta, \cos\theta)$$
   $$\text{right} = \mathbf{R} \cdot (\cos\theta, -\sin\theta)$$

2. **Perspective Scaling Factor ($k$)**:
   $$k = \frac{F}{F + \max(\text{depth}, -0.6F)}$$

3. **Screen Mapping**:
   $$\text{screen}_x = \text{center}_x + (\text{right} \cdot k \cdot \text{PPU}) \cdot \text{zoom}$$
   $$\text{horizon} = \text{horizon}_y + \text{pitch} \cdot 2.2$$
   $$\text{ground}_y = \text{horizon} + (H_{\text{cam}} \cdot k \cdot \text{PPU}) \cdot \text{zoom}$$
   $$\text{screen}_y = \text{horizon} + ((\text{ground}_y - \text{horizon}) - y \cdot k \cdot \text{PPU}) \cdot \text{zoom}$$
   $$\text{apparent\_scale} = k \cdot \text{zoom}$$

### 3.2 Scale Continuity & Smoothness
- $k(\text{depth})$ is a strictly decreasing, continuous, infinitely differentiable function for all visible depths ($\text{depth} > -0.6F$).
- There are **zero discontinuities, zero sudden steps, and zero clipping jumps**.
- When Leon moves along $X$ ($\text{right}$ changes while $\text{depth}$ is constant):
  $$\frac{\partial k}{\partial x} = 0 \implies \text{Scale is strictly invariant to lateral position.}$$
- When Leon jumps along $Y$ ($y$ changes while $\text{depth}$ is constant):
  $$\frac{\partial k}{\partial y} = 0 \implies \text{Scale is strictly invariant to jump elevation.}$$

### 3.3 Orthographic vs Perspective Comparison

| Property | Perspective Mode | Orthographic Mode | Production Decision |
|---|---|---|---|
| **Depth Perception** | Natural perspective convergence toward vanishing point | Cabinet affine projection; parallel lines stay parallel | **Perspective is chosen for cinematic scenes** |
| **Apparent Scale** | Continuous rational curve $k \propto \frac{1}{F+d}$ | Linear falloff: $k = \text{lerp}(1.0, 0.55, d/900)$ | Perspective matches camera optical behavior |
| **Ground Convergence** | Ground rises toward horizon; distant ground compresses | Constant ground rise rate (`ortho_rise = 0.62`) | Perspective creates authentic spatial depth |
| **2D Art Compatibility** | Preserves flat cel-shaded aesthetics without polygon distortion | Flattest possible reading | Multi-view artwork prevents cardboard distortion |

---

## 4. Multi-View Character System

Leon utilizes 5 feet-origin artwork scenes to cover all $360^\circ$ camera-relative orientations with horizontal symmetry mirroring:

```
                     FRONT (0°)
                 ┌───────────────┐
                 │   ViewFront   │
                 └───────┬───────┘
     FRONT-3Q (45°)      │      FRONT-3Q (-45° [Mirror])
     ┌──────────────┐    │    ┌──────────────┐
     │ ViewFront3Q  │◄───┼───►│ ViewFront3Q  │
     └──────────────┘    │    └──────────────┘
       SIDE (90°)        │        SIDE (-90° [Mirror])
     ┌──────────────┐    │    ┌──────────────┐
     │   ViewSide   │◄───┼───►│   ViewSide   │
     └──────────────┘    │    └──────────────┘
      BACK-3Q (135°)     │     BACK-3Q (-135° [Mirror])
     ┌──────────────┐    │    ┌──────────────┐
     │  ViewBack3Q  │◄───┼───►│  ViewBack3Q  │
     └──────────────┘    │    └──────────────┘
                 ┌───────┴───────┐
                 │   ViewBack    │
                 └───────────────┘
                     BACK (180°)
```

### Angular Selection Boundaries
- **FRONT**: $|\alpha| < 22.5^\circ$
- **FRONT-3/4**: $22.5^\circ \le |\alpha| < 67.5^\circ$ (mirrors when $\alpha < 0$)
- **SIDE**: $67.5^\circ \le |\alpha| < 112.5^\circ$ (mirrors when $\alpha < 0$)
- **BACK-3/4**: $112.5^\circ \le |\alpha| < 157.5^\circ$ (mirrors when $\alpha > 0$ due to reverse perspective)
- **BACK**: $|\alpha| \ge 157.5^\circ$

### Root Stability & Pivot Integrity
- Every view has its origin precisely at the ground feet contact $(0, 0)$.
- In automated test `test_multiview_root_stability()`, the vertical feet drift across all views is exactly **$0.0\text{px}$**, eliminating feet sliding or vertical popping during view transitions.
- Crossfades execute over $0.12\text{s}$, producing a smooth cinematic cut between drawings.

---

## 5. Ground Plane & Contact Shadows

### 5.1 Continuous Ground Plane
- The ground is rendered as a continuous plane starting at the projected horizon line and extending to the bottom of the frame.
- It is **never** a thin horizontal rectangle floating in space.
- Horizon height responds dynamically to camera pitch ($2.2\text{px}$ per degree of camera pitch).

### 5.2 Contact Shadow Dynamics
- Each character has a grounded shadow ellipse (`Polygon2D`) parented to the actor root.
- The shadow sits at feet contact:
  - Grounded ($Y \le 0.5$): shadow opacity $\alpha = 0.42$, full width.
  - Airborne / Jump ($Y > 0.5$): shadow opacity drops to $\alpha = 0.20$, softening to indicate vertical lift.
  - As depth changes, shadow scale scales automatically with the actor's projected scale factor $k$.

---

## 6. Projectile Depth & Strict Causality

Leon's spinner blade (`res://assets/brawlers/leon/projectile/spinner_blade.svg`) operates under the strict causality chain:

$$\text{ATTACK} \longrightarrow \text{RELEASE} \longrightarrow \text{SPAWN} \longrightarrow \text{TRAVEL} \longrightarrow \text{COLLISION} \longrightarrow \text{IMPACT VFX} \longrightarrow \text{TARGET REACTION}$$

### Key Properties
1. **Socket Anchoring**: Spawns from the active view's `AttackSocket` (weapon-attached in local space), not an arbitrary root offset.
2. **Depth Flight**: The projectile possesses independent 3D world coordinates $(x, z)$ and elevation $y$. As it travels from Near ($Z=60$) to Far ($Z=480$), its apparent screen scale decreases according to $k(\text{depth})$.
3. **Physical Collision**: Collision triggers when world distance to target $\le 24.0\text{px}$.
4. **Zero Pre-Triggering**: Target dummy reactions (recoil, hit flash, damage calculation) occur strictly upon projectile arrival, never on attack button release.

---

## 7. Depth Occlusion & Environment Scale

### 7.1 Occlusion Ordering
- Draw order is governed by world depth:
  $$\text{z\_index} = -\text{int}\Big(\text{clamp}(\text{depth}, -400.0, 4000.0) \times 0.25\Big)$$
- Objects closer to camera receive higher `z_index` and naturally occlude deeper objects.
- In automated test `test_depth_occlusion_sorting()`, swapping the depths of two overlapping characters automatically inverts their draw order without manual layer flipping.

### 7.2 Character-to-World Scale
Leon stands next to environmental markers authored at authentic physical proportions:
- **Doorway**: $180\text{px}$ tall ($\approx 1.8\times$ Leon height)
- **Crate**: $55\text{px}$ tall ($\approx$ waist height)
- **Tree**: $230\text{px}$ tall ($\approx 2.3\times$ Leon height)
- **Foreground Pillar**: $260\text{px}$ tall, placed at $Z=20$ to cleanly occlude Leon when passing behind.

---

## 8. Automated Test Suite Results

Test suite: `tests/test_leon_2_5d_spatial.gd`  
Executed via GdUnit4 command-line tool with Godot 4.7.2:

```
--------------------------------------------------------------------------------------------------
GdUnit4 Commandline Tool - Test Results
--------------------------------------------------------------------------------------------------
Run Test Suite: res://tests/test_leon_2_5d_spatial.gd
  [PASS] test_horizontal_movement_preserves_scale  (Scale delta: 0.00000)
  [PASS] test_depth_movement_scales_monotonically   (Near 1.383x > Mid 0.984x > Far 0.650x)
  [PASS] test_depth_reversal_decreases_scale       (Monotonic scale reduction confirmed)
  [PASS] test_vertical_jump_elevation_preserves_scale (Elev 80px: scale delta 0.00000, screen Y moves up)
  [PASS] test_multiview_selection_angles           (5 buckets + mirror logic verified)
  [PASS] test_multiview_root_stability             (All 5 view roots at (0, 0))
  [PASS] test_camera_dolly_scales_character        (Cam dolly in increases apparent scale)
  [PASS] test_projectile_travel_and_scale          (Proj scale shrinks from 1.38x to 0.65x)
  [PASS] test_depth_occlusion_sorting              (Nearer z_index > Farther z_index verified)

Statistics: 9 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | PASSED (6.37s)
```

Regression check: `tests/test_leon_state_smoke.gd` passes 1/1 test cases (0 errors).

---

## 9. 21-Step Demonstration Sequence

The interactive laboratory (`scenes/labs/leon_2_5d_spatial_test.tscn`) executes the full 21-beat demonstration sequence:

1. **Far Positioning**: Leon initialized at Far lane ($Z=480$), reading as a small silhouette.
2. **Horizontal X Sweep**: Leon walks from $X=-240$ to $X=+240$.
3. **Scale Invariance Verification**: Live HUD demonstrates scale stays fixed at $0.650\text{x}$.
4. **Depth Travel In**: Leon walks from $Z=480 \to 220 \to 60$.
5. **Progressive Enlargement**: Character smoothly expands to $1.383\text{x}$.
6. **Depth Travel Out**: Leon walks from $Z=60 \to 220 \to 480$.
7. **Progressive Reduction**: Character smoothly shrinks back to $0.650\text{x}$.
8. **Camera Dolly In**: Leon returns to Mid ($Z=220$), camera approaches from $Z=-260 \to -60$.
9. **Camera Orbit $45^\circ$**: Camera shifts to 3/4 bearing.
10. **View Transition (Front-3/4)**: Leon shifts to `view_front_3q.tscn`.
11. **Camera Orbit $90^\circ$**: Camera reaches lateral profile.
12. **View Transition (Side)**: Leon shifts to animated `leon_side.tscn` rig.
13. **Camera Orbit $180^\circ$**: Camera moves behind Leon.
14. **View Transition (Back)**: Leon shifts to `leon_back.tscn`.
15. **Return Orbit $0^\circ$**: Camera returns smoothly to frontal framing.
16. **Face Close-Up**: Camera pushes in to close distance ($Z=+100$), verifying readable eyes, pupils, eyebrows, smile expression, and blink cycle.
17. **Camera Pull-Back**: Camera pulls back to medium wide framing.
18. **Diagonal Trajectory**: Leon traverses from $(-260, 480)$ to $(0, 220)$ to $(+240, 60)$, combining X and Depth simultaneously.
19. **Projectile Travel**: Leon fires spinner blade; blade travels across depth planes to hit the Far dummy, triggering cyan impact burst and target recoil.
20. **Foreground Occlusion**: Leon walks along $Z=40$ behind the foreground pillar ($Z=20$), occluding completely and emerging cleanly.
21. **Final Wide Composition**: Camera establishes complete staged spatial environment.

---

## 10. Animator Guidelines & Known Boundaries

1. **Never Keyframe Scale for Distance**: Adjust character world depth ($Z$) or camera position.
2. **Never Confuse $Y$ with Depth**: To make a character jump, modify elevation ($Y$). To move them toward the camera, modify depth ($Z$).
3. **View Transition Timing**: View transitions crossfade over $0.12\text{s}$. Rapid $360^\circ$ camera spins should be avoided; cuts or controlled $45^\circ-90^\circ$ orbits look best with paper-cutout art.
4. **Attack Sockets**: Spawning projectiles must always query `model.attack_socket_local()` to ensure weapon alignment.
