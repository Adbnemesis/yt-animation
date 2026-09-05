# NITA — Character Art Style Notes & QC

**Stage:** Art Asset Package ONLY. No rig, no animation, no bear, no attack, no Super yet.
**Style benchmark:** Approved LEON production artwork (`assets/leon/`) — the master art-style reference.
**Identity reference:** Provided Nita reference image (bear-hood Brawler).

Nita must look like she belongs to the EXACT SAME animated universe as Leon.
If ever uncertain, the rule is: **match Leon. Never exceed Leon's detail or polish. Simplification is intentional.**

---

## 1. Source Files

- Individual parts: `assets/nita/{body,face,clothing,accessories}/*.svg` (41 swappable parts)
- Reference sheets: `assets/nita/references/*.svg` (7 sheets)
- Catalog entry: `assets/asset_catalog.json` → `brawler_assets.nita`

## 2. Locked Style Spec (extracted from Leon source SVGs)

| Property | Value |
|---|---|
| Outline color | `#1e1e2c` (same as Leon) |
| Outline weights | body 3.5 · face/hood 3.2 · secondary 2.8–3.0 · detail 2.2–2.6 · micro 1.8 |
| Stroke joins / caps | `round` |
| Fills | **flat only** — zero gradients, zero gloss, zero painterly shading |
| Shading | none on most parts; the hood interior dark + face-arch shadow is Nita's only "shade" (equivalent to Leon's cavity `#1a2512`) |
| Shape language | cut-paper discs + simple C/Q bezier silhouettes + rounded rects |
| Face system | white cut-paper eye + dark dot pupil + stroke brow + stroke/open red mouth **exactly like Leon** |
| Part convention | standalone small-canvas SVG per part, transparent, tight-padded to shape |
| Head-to-body | oversized readable head ≈ 55% of total height; compact body; short stylized limbs |

## 3. Nita Identity Checklist (from provided reference)

- [x] Bear hood (red) with two **round ears** + dark **X-stitch** button marks (same stitch language as Leon's button eyes)
- [x] Dark **navy muzzle/snout** across the face (Nita's signature)
- [x] Light **cyan skirt** with asymmetric angled hem
- [x] Emerald/green **tank top**
- [x] **Paw-print pendant** necklace
- [x] Skin-tone barefoot feet + skin mittens with **navy wrist cuffs**
- [x] Auburn side hair strands; back hair mass present for 3/4 & side views

## 4. Part Separation & Secondary Motion Candidates

Prepared for pivot-based cutout animation later:

- Skinny chain (no rig yet):
  - head: `hood_front` → `face_base` → face parts
  - torso: `torso` → `skirt` (skirt swings over hips)
  - arms L/R: `arm_*_upper` (pivot shoulder `17,4`) → `arm_*_lower` (elbow `15,4`) → `hand_*` (wrist `15,2`)
  - legs L/R: `leg_*_upper` (hip `15,4`) → `leg_*_lower` (knee `14,4`) → `foot_*` (ankle `6,4`)
- Secondary (uncapped "subtle bob" candidates): `hair_L`, `hair_R`, `hair_back`, `skirt`, `necklace`

## 5. Reference Views

| Sheet | Purpose |
|---|---|
| `nita_view_front.svg` | Front model sheet (head ≈ 55%) |
| `nita_view_three_quarter.svg` | 3/4 view, facing viewer-right, proportions locked |
| `nita_view_side.svg` | Side profile facing right |
| `nita_expression_sheet.svg` | 9 expressions + 4 eye states |
| `nita_pose_sheet.svg` | 10 key action poses (reference only) |
| `nita_silhouette_test.svg` | Leon vs Nita silhouettes, same construction philosophy check |
| `nita_leon_style_comparison.svg` | Side-by-side consistency vs approved Leon render |

## 6. QC Results (self-check during packaging)

| Check | Result |
|---|---|
| Same artist as Leon (outlines, fills, level of detail) | PASS |
| Same face construction philosophy | PASS |
| Nita recognizable (hood/ears/stitch/snout/skirt/pendant) | PASS |
| Proportions consistent across front / 3/4 / side | PASS |
| All required parts separated, transparent, pivot-able | PASS |
| No visible gaps from separation (overlap hides joints) | PASS |
| Silhouette distinct from Leon yet same universe | PASS |
| No rig / no animation / no bear / no attack / no Super created | PASS |

## 7. Known Open Items

- Reference sheets are SVG; a PNG render pass (Godot import or `qlmanage`) is recommended for quick eyeball QC.
- `nita_view_side.svg` uses flat stacking for profile; limb slice pivots still follow the same part files.
- No `.import` files exist yet for Nita SVGs — open the project in the Godot editor once to generate them (same as Leon workflow).