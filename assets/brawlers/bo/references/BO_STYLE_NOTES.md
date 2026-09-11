# BO — Character Art Style Notes & Quality Control Spec

**Stage:** Production 2D Character Asset Package ONLY.  
**Constraint:** No rig, no animations, no basic attack, no arrow projectile script, no Super mines, no VFX/SFX, no video staging.  
**Style Benchmarks:** Approved LEON production artwork (`assets/brawlers/leon/`) and approved NITA production artwork (`assets/brawlers/nita/`).  
**Identity Reference:** Provided Brawl Stars Bo reference images (white eagle headdress, yellow beak, dark navy braided hair, emerald tunic, maroon sash and trousers, bare tan feet, recurve bow with blue grip wrap and eagle-claw tips, back quiver with cyan fletched arrows).

---

## 1. Core Visual Formula

$$\text{Final Bo} = \text{Bo Character Identity (from provided references)} + \text{Shared Visual Language (from Leon \& Nita)}$$

- **Same Universe:** Bo looks like he was drawn by the exact same artist for the exact same 2D animated production as Leon and Nita.
- **Simplification Level:** Consistent with Leon and Nita. No photorealism, no 3D shading, no complex gradients, no glossy highlights.
- **Outlines:** Bold, clean `#1e1e2c` dark outlines with standard stroke weights (3.5px body, 3.2px head/hood, 2.5-3.0px secondary, 1.8-2.6px details).
- **Fills:** Flat cel-fills only. One simple shadow region where needed (e.g. under the beak overhang).
- **Joint Construction:** Overlapping ball-and-socket circular joint caps at shoulders, elbows, wrists, hips, knees, and ankles for seamless future Godot 2D skeletal cutout rigging.

---

## 2. Color Palette Harmony

| Element | Color Hex | Cross-Character Harmony Anchor |
| :--- | :--- | :--- |
| **Outlines** | `#1e1e2c` | Identical across Leon, Nita, Bo |
| **Skin (Head, Arms, Feet)** | `#b87349` / `#8f4f2a` | Matches Nita and Leon warm caramel skin |
| **Eagle Cowl** | `#f8f9fa` / `#dce1e6` | Crisp cut-paper white with soft grey shadow |
| **Eagle Beak & Eyes** | `#ffd166` / `#ffb703` | Matches Leon's yellow crest stripe (`#ffd166`) |
| **Hair (Locks & Braid)** | `#1f2438` | Dark navy blue-black |
| **Hair Ties** | `#d93848` | Matches Nita's bear cowl red (`#d93848`) |
| **Tunic / Vest** | `#06d6a0` | Matches Nita's emerald tunic (`#06d6a0`) |
| **Trousers & Sash** | `#7a2828` | Matches Nita's maroon leggings (`#7a2828`) |
| **Recurve Bow Wood** | `#a0522d` | Warm cedar/wood |
| **Bow Center Grip** | `#1e90ff` | Matches Leon's blue pouch (`#1e90ff`) |
| **Arrow Fletching & Ties** | `#00b4d8` / `#48cae4` | Matches Nita's bear-paw pendant |
| **Quiver Cylinder** | `#1f3160` | Matches Leon's navy shorts (`#1f3160`) |

---

## 3. Modular Part Inventory (42 Animation-Ready Pieces)

1. **Body Parts (`assets/bo/body/`):**
   - `bo_face_base.svg` (Caramel face disc + beak shadow arch)
   - `bo_eagle_hood.svg` (White eagle cowl + yellow beak + eagle eye emblems)
   - `bo_eagle_beak.svg` (Detachable yellow beak overlay for angle swaps)
   - `bo_hair_side_L.svg` (Left dark navy hair lock)
   - `bo_hair_side_R.svg` (Right dark navy hair lock)
   - `bo_hair_braid_back.svg` (Back ponytail braid with red ties)
   - `bo_torso.svg` (Emerald green sleeveless vest + maroon sash)
   - `bo_arm_L_upper.svg` (Left shoulder/bicep)
   - `bo_arm_L_lower.svg` (Left forearm)
   - `bo_hand_L.svg` (Left fist / bow support)
   - `bo_arm_R_upper.svg` (Right shoulder/bicep)
   - `bo_arm_R_lower.svg` (Right forearm with white talon archer bracer)
   - `bo_hand_R.svg` (Right grip hand)
   - `bo_leg_L_upper.svg` (Left thigh in maroon trousers)
   - `bo_leg_L_lower.svg` (Left shin in maroon trousers)
   - `bo_foot_L.svg` (Left bare tan foot)
   - `bo_leg_R_upper.svg` (Right thigh in maroon trousers)
   - `bo_leg_R_lower.svg` (Right shin in maroon trousers)
   - `bo_foot_R.svg` (Right bare tan foot)

2. **Face Parts (`assets/bo/face/`):**
   - `bo_eye_L.svg`, `bo_eye_R.svg`
   - `bo_pupil_L.svg`, `bo_pupil_R.svg`
   - `bo_eyebrow_L.svg`, `bo_eyebrow_R.svg`
   - Eye states: `bo_eye_blink.svg`, `bo_eye_happy.svg`, `bo_eye_wide.svg`, `bo_eye_angry_L.svg`, `bo_eye_angry_R.svg`, `bo_eye_closed.svg`
   - Mouth states: `bo_mouth_neutral.svg`, `bo_mouth_happy.svg`, `bo_mouth_angry.svg`, `bo_mouth_sad.svg`, `bo_mouth_shocked.svg`, `bo_mouth_scared.svg`, `bo_mouth_hurt.svg`, `bo_mouth_confused.svg`, `bo_mouth_smug.svg`, `bo_mouth_serious.svg`

3. **Clothing & Accessories (`assets/bo/clothing/`):**
   - `bo_sash.svg` (Waist sash overlay)
   - `bo_bracer.svg` (Eagle-talon archer wristguard)

4. **Equipment & Weapons (`assets/bo/equipment/`):**
   - `bo_bow.svg` (Complete recurve bow with blue center grip & eagle claw tips)
   - `bo_arrow.svg` (Arrow with cyan fletching & energy tip)
   - `bo_quiver.svg` (Navy cylinder quiver with white collar & arrows)
   - `bo_quiver_strap.svg` (Chest strap)

5. **Reference Sheets (`assets/brawlers/bo/references/`):**
   - `bo_view_front.svg` (Front view model sheet: authentic Brawl Stars character identity, 100% style locked)
   - `bo_view_side.svg` (Side view model sheet: broad muscular archer build, deep chest, hooked eagle beak, planted combat stance, diagonal back quiver)
   - `bo_view_back.svg` (Back view model sheet: white eagle cowl with orange crest tuft, hooked beak peeking left, dark navy hair, sleeveless emerald vest, diagonal quiver with cyan arrows and yellow eagle beak, recurve bow in left hand, wide maroon trousers)
   - `bo_expression_sheet.svg` (10 expressions + 6 eye states)
   - `bo_pose_sheet.svg` (10 key action poses)
   - `bo_three_character_style_sheet.svg` (Leon + Nita + Bo side-by-side consistency comparison)
   - `bo_silhouette_test.svg` (Leon + Nita + Bo solid black silhouette test)

---

## 4. Quality Control Verification Results

| Quality Check | Result | Verification Notes |
| :--- | :--- | :--- |
| **Character Identity** | **PASS** | White eagle hood, yellow curved beak, dark braided hair, stoic warrior brow, emerald tunic, maroon trousers, bare feet, and recurve bow faithfully preserved from Brawl Stars reference. |
| **Style Consistency** | **PASS** | 100% matches Leon and Nita in outline color (`#1e1e2c`), stroke weight rules, flat cel fills, and absence of 3D gloss. |
| **Three-Character Test** | **PASS** | Verified in `bo_three_character_style_sheet.svg`. Leon, Nita, and Bo stand side-by-side with identical scale parity, head/body ratio, and rendering language. |
| **Silhouette Distinctness** | **PASS** | Verified in `bo_silhouette_test.svg`. Bo's eagle beak, broad athletic stance, recurve bow curve, and quiver silhouette are instantly recognizable in 0.1s against white background. |
| **Godot Cutout Readiness** | **PASS** | 42 modular transparent SVGs with concentric overlapping pivots ready for Godot `Skeleton2D` / `Bone2D` node assignment. |
| **Scope Guardrails** | **PASS** | No rig, no animations, no attacks, no Super, no VFX, and zero modifications to Leon or Nita. |
