# Cinematic 2D/2.5D Staging Lab — Experiment Report v2

> **Status: EXPERIMENT — LAB-ONLY.** Everything lives in `scenes/labs/`,
> `scripts/labs/`, `assets/lab/`. Production Leon/Nita/Bo, the Brawler
> template, production scenes and completed videos are untouched.

---

## The Question (Part 35)

Can 2D paper-cutout Brawlers be *filmed* inside a 3D-like cinematic spatial
world — multi-angle views, camera-relative view switching, depth scale,
perspective, spatial ground, occlusion, projectile depth, cinematic close-ups
— while still looking like 2D artwork?

**Verdict: C → D.** With the v2 multi-view system the result clearly reads as
**convincing 2.5D** and approaches **"genuinely 3D-like despite 2D artwork"**
in orbit/close-up shots. It never reads as flat 1D sprites. It remains
visibly paper-cutout — which is the goal ("maximize D without sacrificing
the 2D art style").

---

## 1. Research (Parts 37/38)

Studied (as technical references, nothing installed):

- **Godot Foundation 2.5D demo (GDScript)** — confirmed the core pattern we
  adopted: keep sprites 2D, hold 3D-ish world coords, project to screen,
  depth-sort. v1 used a fixed-camera variant; v2 generalizes it.
- **Sprite3D / billboard documentation** — evaluated and **rejected** for
  production: Sprite3D puts characters in a real 3D renderer; our outlines
  are tuned for 2D canvas rendering, and billboards always face the camera
  (they cannot show a *back view* when the camera orbits — the exact thing
  this lab needs).
- **8-directional sprite systems** (top-down RPG heritage) — adopted the
  bucket + mirror strategy, modernized with crossfades instead of hard swaps.
- **Hybrid Skeleton2D + 3D spatial transforms** — adopted: the production
  side rigs stay fully intact inside wrapper nodes that only own world
  position/scale/view selection.

## 2. Chosen architecture

```
CinematicCamera (scripts/labs/cinematic_camera.gd)
    world: ground plane (x lateral, z depth), camera height, yaw (orbit),
    pitch (high/low angle), zoom, mode ORTHO | PERSPECTIVE
    project(world, elevation) -> {screen pos, scale, depth, bearing}
         ORTHO        affine x, linear depth rise, stylized scale falloff
         PERSPECTIVE  k = focal/(focal+depth) on x, ground drop AND scale
    relative_view_angle(world, facing) -> camera-relative angle

CinematicActor (scripts/labs/cinematic_actor.gd)
    owns (x, z, elevation, facing_deg); projects itself every physics frame;
    delegates artwork selection to:

MultiviewController (scripts/labs/multiview_controller.gd)   ← per character
    ViewFront / ViewFront3Q / ViewSide / ViewBack3Q / ViewBack
    5 unique artworks → 8 directions via mirroring; crossfade transitions;
    deterministic buckets; fallback chains; per-view AttackSocket

CinematicProp / CinematicProjectile (lab)
    same camera projection; depth z_index; world-distance collision
```

Key properties (Part 36 — no cheating):

- **One general spatial model.** Every visible thing (3 brawlers, 6 props,
  3 dummies, projectiles) is projected by the same `project()` call.
- No per-shot manual scaling, no perspective filters, no 3D meshes,
  no sprite stretching.
- The production rigs inside the wrappers run their own animations
  (idle/walk/attack) untouched.

## 3. Rejected architectures

| Approach | Why rejected |
|---|---|
| Sprite3D + real 3D camera | breaks 2D outline rendering; billboards can't show back views |
| Yaw-only "orbit" (rotate camera in place) | doesn't change which side of a character you see — the orbit must move the camera *position* (this was a real bug found by test 5) |
| Per-view full animation rigs (8 × animated) | enormous art cost; static pose views + one animated side rig covers the cinematic grammar |
| Mirroring front view as fake 3/4 or side | explicitly forbidden; reads wrong instantly |
| Manual z-index flips per shot | occlusion must follow world depth; z_index = f(depth) instead |

## 4. Multi-view implementation (Part 3)

New lab artwork created for this experiment (all derived from *approved*
production art — same outlines `#1e1e2c`, flat cel fills, same palettes):

- **Bo front** — composed from approved front parts (hood, face, beak, torso,
  sash, quiver strap, arms, bow, legs, feet).
- **Bo back** — extracted from the approved `bo_view_back.svg` reference into
  clean feet-origin lab SVGs, split body/head so the head can turn.
- **Bo front-3/4** — new `bo_eagle_hood_3q.svg`: beak/face recess shifted
  right, far-side eagle emblem compressed, dome identical.
- **Bo back-3/4** — head turned 9° at the neck pivot.
- **Leon front-3/4** — approved `hood_34.svg` + front parts, face features
  shifted/compressed toward the turn.
- **Leon back-3/4** — back rig with head turned, tail swung to the far side.
- **Nita front-3/4** — new `hood_34.svg` (muzzle/nose/eyes/cavity shifted
  right, ears asymmetric) + front parts.

View-consistency sheets (Part 4/31) were rendered and visually inspected:
head/torso/limb proportions, clothing and identity remain coherent across
front → 3/4 → side → back for all three characters (renders/sheet_*.mp4).

## 5. What the lab demonstrates (15 deterministic tests, Parts 8–34)

| # | Test | Parts |
|---|---|---|
| 1 | True camera orbit around Leon (position arc, 360°, both directions) — FRONT → 3/4 → SIDE → BACK-3/4 → BACK → reverse | 8 |
| 2 | Leon rotates, camera fixed (and reverse) | 9 |
| 3 | Camera and character both move — relative angle stays correct | 10 |
| 4 | Ground movement: left/right/forward/back/diagonal, feet planted | 13 |
| 5 | Depth scale: each brawler walked near/mid/far (continuous, not animated scale) | 14 |
| 6 | Environment scale beside door/crate/table/pillar (world scale coherent) | 15/16 |
| 7 | Occlusion: behind/in-front of pillar, crate, wall — order follows depth | 17 |
| 8 | Close-up wide → medium → close → extreme on Leon's face | 20 |
| 9 | 3/4 close-up: frontal → 3/4 → side near the face | 21 |
| 10 | High angle / low angle | 22 |
| 11 | 45-degree shot with all three brawlers at separate depths | 23 |
| 12 | ORTHOGRAPHIC vs PERSPECTIVE, same framing, A/B | 24/25 |
| 13 | Projectile depth + causality (attack → release → travel → collision → impact → reaction) | 26/27 |
| 14 | Characters crossing in depth (draw order updates naturally, then reverse) | 28 |
| 15 | Composed cinematic shot demo (Part 34's 14-beat sequence) | 34 |

## 6. Shadows and ground (Parts 12/18)

- Ground = clean plane below a projected horizon; horizon line + distant
  hill silhouette for depth; **horizon responds to pitch** (high/low angle).
- Contact shadows: soft dark ellipse per character at the projected ground
  point, alpha drops when airborne, scale follows depth automatically.
- The ground/horizon/hills are drawn at fixed negative z-index below all
  world objects (which range by depth) — no sorting conflicts.

## 7. Projectile depth and causality (Parts 26/27)

- RELEASE emits the **attack socket's world position** from the *active
  view's* marker (weapon-attached; Part 43).
- The lab projectile exists in (x, z, elevation), travels through depth,
  is projected by the same camera (so it shrinks correctly into the
  distance), and collides by **world distance** — never animation timing.
- Impact → dummy hit reaction + damage flash. Chain verified headless.

## 8. Verification (headless, deterministic — all passing)

| Check | Result |
|---|---|
| Scene loads; full 15-test loop, 5600 frames | 0 script errors |
| Movie render 92s @ 60fps | 0 script errors |
| View buckets at 0/40/90/135/180/-90° | PASS |
| Pivot stability: feet screen-y across all 5 views | PASS (drift < 3 px) |
| Socket deterministic (no jumps between frames) | PASS |
| Socket height continuity across views | PASS |
| Perspective: nearer = larger + lower | PASS |
| Ortho: stylized falloff, no lateral convergence | PASS |
| Orbit flips FRONT → BACK | PASS |
| Projectile causal hit by world distance | PASS |
| View inventory: Leon 5, Nita 4, Bo 5 | PASS |
| View consistency sheets (visual QC) | PASS (inspected) |

## 9. Final self-critique (Part 45)

| # | Question | Answer |
|---|---|---|
| 1 | Does the scene still feel 1D? | **No.** Depth scale + orbit + multi-view eliminate the "flat strip" feeling. |
| 2 | Does it feel like a flat side-scroller? | No — FRONT/BACK and 3/4 views are visible, and camera orbit changes which side you see. |
| 3 | Can characters approach/retreat from camera? | Yes, continuously (tests 4–5); feet planted, scale interpolates smoothly. |
| 4 | Does perspective communicate distance? | Yes in PERSPECTIVE mode (convergence + scale); ORTHO still reads but less dramatically. |
| 5 | Is character scale physically believable? | Yes — continuous function of depth, never manually animated. |
| 6 | Can the camera move around characters? | Yes — 360° positional orbit (test 1). |
| 7 | Do front/3-4/side/back switch correctly? | Yes — deterministic buckets + mirroring, verified at all 8 directions. |
| 8 | Do view transitions look natural? | **Mostly.** 0.12s crossfade is soft; fast spins pop (documented limit). |
| 9 | Do close-ups work? | Yes — face stays readable through extreme close; view follows the orbit. |
| 10 | Does the ground feel spatial? | Yes — projected horizon that responds to pitch, depth lines, hill silhouette. |
| 11 | Do shadows ground the characters? | Yes — contact shadows scale/alpha with depth; help a lot in PERSPECTIVE. |
| 12 | Does foreground occlusion work? | Yes — z_index = f(depth); characters pass behind props correctly. |
| 13 | Do projectiles occupy actual depth? | Yes — same projection, shrink into distance, collide by world distance. |
| 14 | Can characters cross each other in depth? | Yes — draw order updates naturally (test 14). |
| 15 | Do characters feel physically present? | Yes — this is the single biggest win of v2. |
| 16 | Does it still clearly look like 2D artwork? | **Yes** — outlines, flat fills, cutout rigs all preserved. |

## 10. Verdict on projection (Parts 24/25)

- **PERSPECTIVE** is the primary mode: it gives genuine convergence, distance
  scale, and makes close-ups feel like dollying in. Recommended for cinematic
  staging.
- **ORTHO** (cabinet-style with stylized falloff) still looks good and feels
  more "storybook"; it's the right choice if the art direction wants a
  flat, controlled depth. Both are available via keys 1/2.

## 11. Final recommendation (Part 46)

| Question | Recommendation |
|---|---|
| **BEST ARCHITECTURE** | CinematicActor wrapper + MultiviewController + shared CinematicCamera.project() — one general model, no per-shot hacks |
| **BEST CAMERA MODEL** | Ground-plane camera with cam_x/cam_z/cam_height + yaw/pitch/zoom + focal; positional orbit helper |
| **BEST PROJECTION** | **PERSPECTIVE** (k = focal/(focal+depth)); keep ORTHO as an A/B option |
| **BEST CHARACTER VIEW STRATEGY** | 5 unique artworks per character (front/front_3q/side/back_3q/back) + mirroring for the other 4 directions; static pose views + one animated side rig |
| **BEST SCALE STRATEGY** | Scale = pure function of projected depth. Never animate scale manually. |
| **BEST GROUND STRATEGY** | Projected horizon that responds to pitch + clean ground + contact shadows + one distant hill |
| **BEST OCCLUSION STRATEGY** | z_index = f(depth) on every world object (characters, props, projectiles, dummies) |
| **BEST PROJECTILE STRATEGY** | World-space projectile from the active view's AttackSocket; collide by world distance |
| **BEST WAY TO HANDLE FRONT/3Q/SIDE/BACK** | Buckets at ±22.5/±67.5/±112.5/±157.5°; crossfade 0.12s; fallback chains; keep views authored turning right + mirror |

## 12. What still looks bad / needs artwork

- **Fast-turn pops.** The 5-view crossfade reads as a dissolve on quick spins;
  needs intermediate 15°/30° artwork for genuinely smooth rotation (big art
  cost — probably not worth it for this production's cut-heavy grammar).
- **Nita back-3/4 missing.** Her back view is used as fallback; a dedicated
  back-3/4 would smooth her orbit.
- **Bo front/back are static poses** (no Skeleton2D). They animate as a lean
  pop during attack; a future lab could skin Bo's back/front to bones.
- **High/low angle limits:** with only 1 height of art per view, strong pitch
  (≥25°) begins to look like the cutout is "slid" rather than turned.
- **No per-view walk cycles** for front/back — characters side-walk in FRONT
  shots (the production side rig's walk anim plays regardless). Acceptable
  for lab; a front-walk would improve test 4.

## 13. What should be adopted into production

- The **CinematicCamera projection model** (perspective) + depth-scaled stage.
- **Multi-view controller pattern** (buckets + mirror + pivot-at-feet +
  per-view AttackSocket).
- **z_index = f(depth)** occlusion rule.
- **Contact shadows + projected horizon** ground treatment.
- World-space projectiles from the attack socket.

## 14. What should NOT be adopted

- **Sprite3D / real 3D render path** for the brawlers.
- **OBLIQUE-only or pure-orthographic** staging as the sole camera.
- **Manual per-shot scaling or z-indexing**.
- **Fast-spin crossfade** as a turn solution (document as a dissolve, not a rotation).
- Any of this un-appraised — production must be checked against the style spec
  before anything ships. The lab remains isolated.

