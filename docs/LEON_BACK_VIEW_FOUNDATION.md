# LEON BACK VIEW — COMPLETE ANIMATION FOUNDATION

**Status:** COMPLETE & FULLY VALIDATED  
**Architecture:** 2.5D Spatial Perspective + Procedural State Controller  
**Canonical Production Rig:** `res://scenes/videos/leon_elevator/leon_back.tscn`  
**Controller Script:** `res://scripts/labs/leon_back_controller.gd`  
**Interactive Test Bed:** `res://scenes/labs/leon_back_view_animation_test.tscn`  
**Verification Suite:** `res://tests/test_leon_back_view.gd` & `res://tests/test_leon_back_view_stress.gd`  
**Video Showcase:** `renders/leon_back_view_complete_showcase.mp4` (48.0s @ 60 FPS)

---

## 1. Executive Summary & Objective

The **Leon Back View Complete Animation Foundation** completes the four canonical cardinal views of Leon (Side View, Front View, 3/4 View, and Back View).

In accordance with strict production requirements:
1. **Zero Re-rigging:** The canonical production back rig (`scenes/videos/leon_elevator/leon_back.tscn`) was directly preserved and attached to the procedural controller `LeonBackController`. No new back rigs or duplicated sprites were created.
2. **2.5D Spatial Depth Projection:** Horizontal movement preserves apparent scale; depth movement away from camera (positive depth) shrinks scale monotonically; depth movement toward camera enlarges scale.
3. **Facing-Yaw Trajectory Contract:** Back view faces $\text{yaw} = 180^\circ$ ($\pi$ rad). Attacks fire into depth away from the camera along vector $\vec{d} = (\sin(\text{yaw}), -\cos(\text{yaw})) = (0, 1)$ with perspective shrinking.
4. **View-Specific Animation Integrity:** Back view does NOT contain front-facing facial sprites (eyes, mouth, tongue). Emotional acting and attention are communicated through head tilt/turn, living tail dynamics, shoulder breathing, and body posture.

---

## 2. Canonical Rig Structure & Hierarchy

The production scene `res://scenes/videos/leon_elevator/leon_back.tscn` maintains the following verified node hierarchy:

```text
LeonBack (Node2D, class_name LeonBackController)
├── Tail (Sprite2D: tail.svg, pos (0, -22))
├── Feet (Node2D)
│   ├── FootL (Polygon2D, blue boot, pos (0, 0))
│   └── FootR (Polygon2D, blue boot, pos (0, 0))
├── Sole (Node2D)
│   ├── SoleL (Polygon2D, tan sole)
│   └── SoleR (Polygon2D, tan sole)
├── Legs (Node2D)
│   ├── LegL (Polygon2D, yellow skin)
│   └── LegR (Polygon2D, yellow skin)
├── Shorts (Node2D)
│   ├── ShortL (Polygon2D, dark navy)
│   └── ShortR (Polygon2D, dark navy)
├── Torso (Sprite2D: torso_back.svg, pos (0, -61))
├── Head (Sprite2D: hood_back.svg, pos (0, -110))
├── ArmL (Sprite2D: arm_back.svg, pos (-26, -68))
├── ArmR (Sprite2D: arm_back.svg, pos (26, -68))
└── AttackSocket (Marker2D, pos (26, -32))
```

All node baselines precisely align with the front and 3/4 rigs:
- **Feet Contact Baseline:** $Y = 0.0$
- **Torso Rest Origin:** $Y = -61.0$
- **Head Rest Origin:** $Y = -110.0$
- **Attack Socket:** Right hand throwing position at $(26, -32)$

---

## 3. State Machine Architecture (`LeonBackController`)

`LeonBackController` manages an 11-state machine with physics-process procedural interpolation:

| State | Purpose & Dynamics |
| :--- | :--- |
| **`IDLE`** | 2.8 rad/s respiratory heave ($Y \pm 0.45\text{px}$), subtle shoulder sway, organic sinusoidal tail motion ($0.08\text{rad}$). |
| **`ACCEL`** | Anticipation crouch ($Y +4\text{px}$), foot drive, forward torso pitch, leading into full walk. |
| **`WALK`** | Stride cycle ($7.0\text{rad/s}$), alternating foot stride/lift, counter-phase arm swing, tail counter-sway ($0.18\text{rad}$). |
| **`RUN`** | High-energy stride ($12.0\text{rad/s}$), pronounced torso lean ($+6\text{px}$), high tail swing ($0.32\text{rad}$), arm pumping. |
| **`STOP`** | Deceleration skid brake, forward foot brace, torso overshoot, elastic settle back to rest. |
| **`JUMP`** | Deep anticipation compression ($Y +8\text{px}$) $\to$ airborne liftoff with foot/tail tuck $\to$ apex hold. |
| **`LAND`** | Ground impact squish ($Y +9\text{px}$, $X \text{scale} 1.08$) $\to$ spring-damped return to idle/locomotion. |
| **`ATTACK`** | 3-phase causality: arm windup ($0.10\text{s}$) $\to$ release & blade spawn at $(26, -32)$ $\to$ arm follow-through recovery ($0.22\text{s}$). |
| **`SUPER`** | Cyan particle burst $\to$ alpha fade to $0.22$ stealth shimmer $\to$ sustained $1.6\text{s}$ stealth locomotion $\to$ smoke burst & opacity restore. |
| **`HIT`** | Rear flinch impact ($Y -6\text{px}$, rotation $-0.06\text{rad}$), head snap forward, tail shock flare. |
| **`KNOCKBACK`** | Translational displacement along knockback vector with decelerating velocity profile. |
| **`RECOVERY`** | Post-knockback stabilization back to neutral balance. |

---

## 4. 2.5D Spatial Projection & Trajectory Rules

The perspective projection camera calculates 2D screen positions and scaling using:

$$\text{scale} = \frac{f}{f + (\text{world\_depth} - \text{cam\_z})}$$

### Spatial Laws:
1. **Horizontal Invariance:** Moving left/right ($\Delta X$) alters only screen X; character scale remains invariant ($\Delta \text{scale} = 0$).
2. **Monotonic Depth Scaling:** Moving away from camera ($\Delta Y > 0$) strictly decreases scale:
   $$\text{Scale}_{\text{NEAR}} (1.051) > \text{Scale}_{\text{MID}} (0.841) > \text{Scale}_{\text{FAR}} (0.743)$$
3. **Attack Vector Contract:** Facing yaw $\theta = 180^\circ$ ($\pi$ rad) yields:
   $$\vec{d} = (\sin\theta, -\cos\theta) = (\sin 180^\circ, -\cos 180^\circ) = (0.0, 1.0)$$
   Projectiles travel into the screen away from the camera, shrinking in scale monotonically until impacting targets or dissipating.
4. **Z-Sorting & Occlusion:** Depth maps to `z_index = -int(depth * 0.25)`. Leon dynamically passes behind foreground props (e.g. pillar at depth 80) and in front of background targets (dummy at depth 360).

---

## 5. Automated Verification & Stress Testing

The full automated suite verified all behavior with **100% pass rate (68/68 tests)**:

### Back-View Specific Suite (`tests/test_leon_back_view.gd`):
- `test_canonical_back_rig_hierarchy`: PASSED
- `test_state_transitions_full_chain`: PASSED
- `test_attack_direction_into_depth`: PASSED
- `test_attack_anticipation_precedes_release`: PASSED
- `test_tail_dynamics_idle_and_locomotion`: PASSED
- `test_root_and_feet_baseline_consistent`: PASSED
- `test_head_neck_attention_acting`: PASSED
- `test_super_stealth_events_and_recovery`: PASSED
- `test_hit_knockback_recovery_chain`: PASSED
- `test_horizontal_movement_preserves_scale`: PASSED
- `test_depth_movement_scales_monotonically`: PASSED
- `test_diagonal_movement_combines_x_and_depth`: PASSED
- `test_projectile_causality_travels_before_impact`: PASSED
- `test_ground_baseline_across_all_views`: PASSED

### 50-Cycle Stress Suite (`tests/test_leon_back_view_stress.gd`):
- 50 consecutive idle cycles: PASSED
- 50 consecutive walk cycles: PASSED
- 50 consecutive run cycles: PASSED
- 50 consecutive jumps & landings: PASSED
- 50 consecutive attacks: PASSED
- 50 consecutive Supers: PASSED
- 50 consecutive moving attacks: PASSED
- 50 diagonal movements: PASSED
- 50 depth approaches and retreats: PASSED
- 50 hit-knockback-recovery chains: PASSED

### Cross-View Regression Suite:
- `test_leon_three_quarter.gd` (19 tests): PASSED
- `test_leon_three_quarter_stress.gd` (10 tests): PASSED
- `test_leon_front_view.gd` (5 tests): PASSED
- `test_leon_2_5d_spatial.gd` (9 tests): PASSED
- `test_leon_state_smoke.gd` (1 test): PASSED

---

## 6. Demonstration Matrix & Video Showcase

The showcase video `renders/leon_back_view_complete_showcase.mp4` (48.0s @ 60 FPS) proves all 17 stages:
1. **Back Idle:** Respiratory chest/shoulder motion and living tail sway.
2. **Back Walk:** Alternating strides away into depth, tail counter-sway, monotonic shrinking.
3. **Walk Stop:** Readable brake settle.
4. **Back Run:** High-tempo stride and forward torso lean away into depth.
5. **Run Stop:** Heavy braking with overshoot recovery.
6. **Acceleration:** Push-off from standstill into depth walk.
7. **Jump:** Airborne tuck and landing squish.
8. **Hit & Knockback:** Rear flinch and elastic recovery.
9. **Basic Attack Straight:** Shuriken launch into depth away from camera toward dummy.
10. **Attack Angled Left:** Near-arm throw toward depth-left target.
11. **Attack Angled Right:** Throw toward depth-right target.
12. **Attack While Moving:** Seamless walk $\to$ attack $\to$ resume walk.
13. **Super (Stealth):** Cyan smoke explosion, $0.22$ alpha shimmer, reappearance.
14. **Head/Neck Acting:** Attention and curiosity communicated from behind.
15. **Depth Travel:** Run far (shrinks) and run near (enlarges).
16. **Foreground Occlusion:** Passage behind pillar at depth 80.
17. **Camera Close-up:** WIDE $\to$ MEDIUM $\to$ CLOSE dolly framing hood and tail geometry.
