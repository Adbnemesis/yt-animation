# Multiview Character System (LAB)

> **Status: LAB-ONLY.** Nothing in `assets/lab/` or `scenes/labs/characters/`
> is production. Production Leon/Nita/Bo rigs and artwork are untouched —
> they are *referenced read-only* by the lab scenes.

---

## 1. Purpose

Defines how one paper-cutout character provides multiple viewpoint artworks
(front / 3/4 / side / back) and how the lab selects the visible view from the
camera-relative angle — the "8-directional character" strategy for our 2.5D
cinematic staging experiments.

## 2. Supported views

| View name | Node | Leon | Nita | Bo | Source |
|---|---|---|---|---|---|
| `front` | `ViewFront` | ✅ | ✅ | ✅ new | Leon: production `leon_front.tscn`; Nita: production `nita_front.tscn`; Bo: **new lab composition** from approved front parts |
| `front_3q` | `ViewFront3Q` | ✅ new | ✅ new | ✅ new | Leon: approved `hood_34.svg` + front parts; Nita: **new lab `hood_34.svg`**; Bo: **new lab `bo_eagle_hood_3q.svg`** |
| `side` | `ViewSide` | ✅ | ✅ | ✅ | production animated rigs (`leon_side`, `nita_side`, `brawler_bo`) |
| `back_3q` | `ViewBack3Q` | ✅ new | ❌ (fallback → `back`) | ✅ new | derived: head turned at the neck pivot |
| `back` | `ViewBack` | ✅ | ✅ | ✅ new | Leon: production `leon_back.tscn`; Nita: production `nita_back.tscn`; Bo: **new lab art extracted from the approved `bo_view_back.svg` reference** (body + separable head) |

All 8 compass directions are covered with 5 unique artworks: the left-side
variants are horizontal mirrors of the right-side variants
(`scale.x = -1` on the view node).

## 3. Asset structure (Part 41)

```
assets/lab/characters/
    nita/front_3q/hood_34.svg            derived from nita hood_front.svg
    bo/front_3q/bo_eagle_hood_3q.svg     derived from bo_eagle_hood.svg
    bo/back/bo_back_body.svg             extracted from approved bo_view_back.svg
    bo/back/bo_back_head.svg             extracted (head separable for 3/4 turn)
scenes/labs/characters/
    leon_multiview_lab/  view_front_3q.tscn, view_back_3q.tscn,
                         leon_multiview.tscn (controller), leon_multiview_lab.tscn (actor)
    nita_multiview_lab/  view_front_3q.tscn, nita_multiview.tscn, nita_multiview_lab.tscn
    bo_multiview_lab/    view_front.tscn, view_front_3q.tscn, view_back.tscn,
                         view_back_3q.tscn, bo_multiview.tscn, bo_multiview_lab.tscn
```

## 4. View naming convention

`front`, `front_3q`, `side`, `back_3q`, `back` — author views turning toward
the **viewer's right**; the controller mirrors for the left side.

## 5. Root / pivot rules (Part 32)

- **Every view scene has the feet ground point at origin (0,0).**
- View scenes are authored at the character's native rig scale (production
  part pixel sizes; Bo's back art was extracted 1:1 in reference local units).
- No per-view position offsets are needed — verified: feet screen-y drift
  across all 5 views < 3 px (see lab verification).
- Bo's back head is a child of a `Head` node pivoted at the neck (0,-84) so
  the 3/4 turn rotates around the neck, not the feet.

## 6. View selection logic (Parts 6/7)

`scripts/labs/multiview_controller.gd`:

- **Relative angle** = angle between the character's facing vector and the
  direction toward the camera. 0 = facing camera, ±180 = facing away.
- Bucket boundaries: `±22.5°` front / `±67.5°` front_3q / `±112.5°` side /
  `±157.5°` back_3q / beyond → back (5 × 45° buckets over ±180°).
- Mirroring: `front`/`back` never mirror; `front_3q`/`side` mirror for
  negative angles; `back_3q` inverts (a > 0 mirrors) because the back view
  flips perceived turn direction.
- Selection is **stateless and deterministic** — same angle always yields
  the same view. No randomness.

## 7. Camera-relative selection

`CinematicCamera.relative_view_angle(world_pos, facing_deg)` computes the
relative angle; the actor calls `model.set_relative_angle()` every physics
frame. Works for camera orbit (position arc), character rotation, or both
moving — the visible view is always a pure function of the current relative
angle (verified by lab tests 1–3).

## 8. Missing views and fallback

`VIEW_FALLBACK` chains: `front_3q → front → side`, `back_3q → back → side`,
etc. Nita currently has no back_3q artwork; the system silently uses `back`.
The controller reports available views via `has_view()`.

## 9. Transition behavior (Parts 8/30)

- View changes crossfade over **0.12 s** (alpha), which reads as a soft cut.
- Deliberate rotation tests (lab tests 1–2) show the five-view rhythm
  front → 3/4 → side → back-3/4 → back reads naturally at walking-pace turns.
- **Known limits (not hidden):** a crossfade between two different drawings
  is a *dissolve*, not a rotation — at fast spins it reads as a pop-pair.
  Intermediate 15°/30° artwork would be needed for genuinely smooth spins;
  not worth the art cost for this production's camera grammar
  (cuts and orbit-and-hold shots).

## 10. Attack socket (Parts 43/44)

Each view scene carries an `AttackSocket` Marker2D (placed on the weapon
hand/bow). The controller exposes `attack_socket_local()` from the *active*
view, so the projectile spawn point follows the artwork across view changes.
Measured continuity across Leon's views: heights -60/-32/-34/-60 px — no
jumps outside natural artwork differences. Future characters must place an
`AttackSocket` in every view scene.

## 11. How future Brawlers should provide multi-view artwork

1. Produce front / side / back view part sets in the established style
   (same outline `#1e1e2c`, flat cel fills, native part scale).
2. Author feet-origin static pose scenes per view (copy the composition
   pattern of `view_front.tscn`).
3. For 3/4 views: derive the head part (shift features toward the turn,
   compress the far side) — do **not** mirror-flip the front view.
4. Instance all views under a controller scene; add `AttackSocket` markers.
5. Add the character to the view-consistency sheet render for QC.

## 12. Verification summary

All checks pass headless: view buckets at 0/40/90/135/180/-90°, pivot drift
< 3 px across views, socket determinism, orbit front→back flip, per-character
view inventory (Leon 5, Nita 4, Bo 5).

