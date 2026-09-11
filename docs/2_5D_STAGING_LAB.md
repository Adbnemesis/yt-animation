# 2D/2.5D Staging Lab — Experiment Report

> **Status: EXPERIMENT — COMPLETE.** Isolated in `scenes/labs/` + `scripts/labs/`.
> **Nothing in production depends on it.** No production scene, character, or
> framework was modified.

---

## The Question

> *Can our existing 2D paper-cutout brawlers look like they occupy a real 3D
> space while remaining 2D cutout characters?*

## Verdict (short)

**Yes — with constraints.** A shared projection model (3D world coords → 2D
screen) makes our existing cutout rigs read as occupying depth: same artwork,
no re-rigging, real occlusion, coherent scale falloff. The two honest
limitations are (1) **view-dependent art**: only Nita currently has
front/back/side rigs, so full "any camera angle" staging is blocked at the
*art* layer, not the math layer, and (2) high-angle projections (OBLIQUE)
expose the cutout silhouette because our artwork has no top-down view.

---

## Files (all experimental)

| File | Role |
|---|---|
| `scripts/labs/projection_2_5d.gd` | Shared projection model (stateless static math) |
| `scripts/labs/depth_actor_2_5d.gd` | Thin wrapper: 3D world position → projected 2D transform; delegates all behavior to the untouched production rig inside it |
| `scenes/labs/actors/actor_leon_2_5d.tscn` | Wraps production `leon.tscn` (side view) — unmodified |
| `scenes/labs/actors/actor_nita_2_5d.tscn` | Wraps production Nita rigs (side/front/back switchable) — unmodified |
| `scenes/labs/actors/actor_bo_2_5d.tscn` | Wraps production `brawler_bo.tscn` (side view) — unmodified |
| `scenes/labs/lab_projectile.tscn` + `scripts/labs/lab_projectile.gd` | Depth-aware lab projectile (Bo arrow visual, world-space, z-projected) |
| `scenes/labs/2_5d_staging_lab.tscn` + `scripts/labs/staging_lab_2_5d.gd` | The lab stage + 11-test deterministic auto-demo |
| `renders/labs_2_5d_validation.mp4` | 30s visual validation render (tests 1–4 + part of 5) |

## Controls (interactive)

| Key | Action |
|---|---|
| `1` / `2` / `3` / `4` | View mode: FRONT / SIDE / 45-DEGREE / OBLIQUE |
| `F` | Cycle Nita rig: side → front → back |
| `V` | A/B toggle: FLAT (z=0, classic 1D staging) vs 2.5D depth |
| `Space` | Pause/resume auto-demo |
| `R` | Reset target dummies |

---

## Architecture

Modeled after the official Godot Foundation **2.5D demo** (3D spatial coords,
2D projection, depth-aware sorting) but adapted to our production reality:

```
World (x, y, z)                    z: 0 = near camera, 180 = far plane
    │
    │  Projection2_5D (static, shared by actors AND projectiles)
    │  ├─ screen_y  = GROUND_Y − z · rise_per_z(view) − elevation
    │  ├─ scale     = base · lerp(1.0, scale_far(view), depth01(z))
    │  ├─ sort      = CanvasItem y-sort (deeper ⇒ smaller screen_y ⇒ behind)
    │  └─ shadow    = alpha/size falloff with depth
    ▼
2D cutout rig (production scene, untouched) inside a DepthActor25D wrapper
```

- **The brawler stays a 2D cutout.** No mesh, no 3D lighting, no sprite
  rotation-as-fake-3D. The projection only touches *position, uniform scale,
  draw order, shadow*.
- **One projection source of truth.** Actors and projectiles share
  `Projection2_5D`, so an arrow fired from a far Bo is projected exactly like
  Bo is.
- **View modes are projection parameters**, not new art: FRONT (near-level
  camera: gentle rise 0.32/z, mild falloff), SIDE (classic, 0.5/z), DEG45
  (0.62/z), OBLIQUE (0.82/z, strongest falloff).
- **Bo's real production arrows are re-parented into his wrapper** each frame,
  so his actual `BO_BASIC` volley inherits his depth scale/position — no
  duplicate projectile system.

## What the demo demonstrates (auto-cycling, deterministic)

1. **Same-brawler depth scale** — Leon ×3 at near/mid/far.
2. **Triangle** — Leon near / Nita mid / Bo far.
3. **Reverse triangle** — Bo near / Nita mid / Leon far.
4. **Movement through depth** — Leon walks background→foreground→back.
5. **Crossing characters** — draw order flips purely by depth.
6. **Foreground occlusion** — behind crate + pillar, then emerge.
7. **Projectile through depth** — arrows bg→fg and fg→bg, correctly scaled.
8. **Camera** — wide/medium/close + approach (apparent size changes).
9. **Combat geography** — 3-depth attack line with real production attacks.
10. **View modes + Nita rigs** — all 4 projections; side/front/back switching.
11. **A/B** — same action staged flat vs 2.5D (the "before/after" answer).

---

## Verification results (headless, deterministic)

Automated functional checks (all passing):

| Check | Result |
|---|---|
| Scene loads & runs headless, full 11-test loop (4200 frames) | PASS, 0 script errors |
| Movie Maker render (30s @ 60fps) | PASS, 0 script errors |
| All `@onready` stage references resolve | PASS |
| Apparent scale decreases with depth (same brawler ×3) | PASS — **0.976 → 0.785 → 0.594** (≈39% falloff near→far) |
| Deeper actors sort behind nearer actors (y-sort) | PASS |
| Moving through depth changes apparent scale live | PASS |
| Attack fires; projectile exists independently in world | PASS |
| Bo's 3-arrow volley re-parents into Bo wrapper (inherits depth) | PASS |
| A/B: flat mode collapses z→0, restore brings depth back | PASS |
| All 4 view modes apply without error | PASS |

## Ratings (1–10) — engineering assessment

*Technical dimensions are measured; aesthetic dimensions are preliminary and
should be confirmed by human review of `renders/labs_2_5d_validation.mp4`
before any production adoption decision.*

| Dimension | Rating | Notes |
|---|---|---|
| Depth scale readability | **8** | 39% size falloff across the stage; coherent, grounded, same artwork |
| Depth sorting / occlusion | **8** | Real y-sort occlusion incl. props and projectiles |
| Projectile-in-depth coherence | **8** | Arrows share the actor projection; spawn depth correct |
| Movement through depth | **7** | Walk+depth interpolation works; cutout walk cycle reads fine in SIDE/DEG45 |
| SIDE view staging | **8** | Natural fit for our side-view rigs |
| DEG45 view staging | **7** | Good depth read; best compromise candidate |
| FRONT view staging | **6** | Works, but side-view rigs face the wrong way in FRONT mode — art limitation |
| OBLIQUE view staging | **5** | Strongest depth read, but cutouts have no high-angle art; silhouettes can feel "slid up" |
| View-dependent rig switching (Nita only) | **6** | Functionally works (side/front/back); hard cuts between rigs can pop — needs blended transition if adopted |
| Camera depth response | **7** | Zoom/pan + parallax coherent |
| Isolation / zero production impact | **10** | Verified: only new files under `scenes/labs/`, `scripts/labs/`; no production file touched |
| Cost of adoption | **8** | One static model + one wrapper per actor; ~200 LOC total |

## Adopt / Do-not-adopt (recommendation)

**Adopt (if production wants 2.5D staging):**
- `Projection2_5D` as the single shared depth model (actors + projectiles).
- Depth-scaled staging + y-sorted stage root as direct children (the pattern
  the production rebuild can reuse).
- Contact shadows + subtle parallax (0.12× far / 0.4× near).
- **SIDE** and **DEG45** as the two production view modes.

**Adapt:**
- Nita-style multi-rig view switching — only worthwhile if more characters get
  front/back rigs; needs a transition treatment to avoid pops.

**Do not adopt:**
- **OBLIQUE** as a production view (art has no high-angle views; math alone
  can't fake it).
- Rotating sprites around Y as fake 3D turns (explicitly rejected).
- A bespoke per-scene depth model — the value is in the *shared* static model.

## Known rig gap (documented, not fixed here)

Per experiment scope: only **Nita** has front/back/side rigs; **Leon and Bo
are side-view only**, so FRONT/45/OBLIQUE staging of them shows side-view art.
Giving Leon and Bo front/back rigs is an *art task* and the main remaining
blocker for full multi-angle production staging.

## Constraints honored

- ✅ Existing production brawlers used as-is (wrapped, never modified)
- ✅ No new characters, no story, no new combat/projectile/audio/VFX framework
- ✅ No production scene or shared system modified
- ✅ Godot 2.5D demo studied as technical reference; approach adapted, not copied
- ✅ Front / side / 45° / oblique all switchable at runtime (keys 1–4)
- ✅ Same-brawler ×3 depth scale test + both triangle arrangements
