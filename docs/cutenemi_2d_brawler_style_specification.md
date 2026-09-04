# Cutenemi 2D Brawler Style Specification
**Document Version:** 1.0.0  
**Status:** LOCKED MASTER STANDARD  
**Target Platform:** Godot Engine 4.x (2D Skeletal / Cutout Puppet Animation)  
**Resolution Standard:** 1080p (Full HD) Native / Scalable Vector Graphics (SVG)

---

## Executive Summary & Visual Philosophy

The **Cutenemi 2D Brawler Art Style** establishes a cohesive, charming, and punchy cartoon universe inspired by modern top-down hero action games (e.g. *Brawl Stars*), fused with stylized geometric and faceted design cues from the Cutenemi reference language.

Every character in the Cutenemi universe must balance four core pillars:
1. **Cute & Chunky:** Rounded silhouette volumes, oversized extremities, and playful proportions.
2. **Highly Expressive & Readable:** Bold facial components and strong gestural silhouettes readable even when characters occupy small screen footprints ($96\text{px}$ to $180\text{px}$ height).
3. **Clean Graphic Shading:** 2-tone cel shading (solid base + 1 primary shadow + subtle specular accent) with consistent, ink-like dark outlines.
4. **Animation-First Rigging Architecture:** Cutout modularity with overlapping ball-and-socket joint caps to allow radical rotations without silhouette breakage or gaps.

> [!IMPORTANT]
> **Strict Anti-Patterns:**
> - **NO** photorealistic textures or materials.
> - **NO** anime proportions, fine facial linework, or complex hair strands.
> - **NO** Pixar-style smooth 3D gradient surface shading.
> - **NO** generic flat corporate vector mascot styling.
> - **NO** noisy surface textures, high-frequency clutter, or micro-details.

---

## 1. Proportions

Cutenemi characters use an exaggerated **Large-Head / Compact-Body** proportion system:

| Body Section | Percentage of Total Height | Height in Standard Units (220px Puppet) |
| :--- | :--- | :--- |
| **Head (including hair volume)** | **40% – 50%** | **88px – 105px** |
| **Torso & Neck** | **20% – 25%** | **44px – 55px** |
| **Limbs (Upper + Lower Legs)** | **20% – 25%** | **44px – 55px** |
| **Feet & Boots** | **10% – 15%** | **22px – 33px** |

```
   +-----------------------+   <- Head Top (y = 0)
   |                       |
   |      LARGE HEAD       |   45% of total height
   |   (High Readability)  |
   |                       |
   +-----------------------+   <- Chin (y = 95)
   |     COMPACT TORSO     |   22% of total height
   +-----------------------+   <- Pelvis / Hip (y = 145)
   |      SHORT LEGS       |   18% of total height
   +-----------------------+   <- Ankles (y = 185)
   |    OVERSIZED BOOTS    |   15% of total height
   +-----------------------+   <- Ground (y = 220)
```

* **Hands:** Slightly oversized cartoon fists/mitts ($28\text{px} \times 28\text{px}$) communicating punchy impact during combat actions.
* **Feet:** Chunky, flat-soled boots ($36\text{px} \times 20\text{px}$) anchoring the character firmly to the ground plane to prevent "floatiness".
* **Torso:** Compact, rounded cylinder or trapezoid; acts as the visual bridge between head and legs without competing for visual dominance.

---

## 2. Shape Language

* **Primary Forms:** Dominant shapes are **sturdy rounded rectangles, soft capsules, and teardrops**.
* **Faceted Accents (Reference Language):** Derived from the Cutenemi reference mask, subtle planar facet breaks are integrated along the jawline, collar, and hair chunks. These planes are rendered with clean geometric angle cuts that terminate into rounded corners, imparting a confident, modern edge while remaining soft and cute.
* **Silhouette Clarity:** Every character must pass the "Black Silhouette Test": when filled with pure black against white, the pose, facing direction, head tilt, and held accessories must remain instantly identifiable within 0.1 seconds.

---

## 3. Face Construction & Hierarchy

The face is the primary emotional communication center. It is strictly organized as an independent multi-layer hierarchy decoupled from the body skeletal nodes:

```
Head (Bone2D)
  └── HeadSprite (Z = 0)
  └── FaceRoot (Node2D, Z = 2)
        ├── Sclera_L & Sclera_R (Sprite2D)
        ├── Pupil_L & Pupil_R (Sprite2D, independent offset)
        ├── Eyebrow_L & Eyebrow_R (Sprite2D)
        └── Mouth (Sprite2D)
```

* **Decoupling Rule:** Body animations (attacks, walks, falls) must **never** bake facial expressions into their tracks. The `FaceController` retains independent authority over eyes, pupils, brows, and mouth.
* **Eye Center Distance:** Eyes are placed wide on the lower third of the head sphere ($y = +15\text{px}$ from head center) to maximize cuteness and baby-schema appeal.

---

## 4. Eye Construction

* **Sclera (Outer Eye):**
  * Large, bold rounded bean or pill shape ($22\text{px} \times 24\text{px}$).
  * Fill: Clean solid white (`#ffffff`).
  * Stroke: $3.5\text{px}$ `#1e1e2c` solid outline.
* **Pupils:**
  * Bold dark charcoal ellipses ($12\text{px} \times 14\text{px}$, `#2f3542`).
  * Specular Catchlight: Clean, crisp circle (`#ffffff`, $4\text{px}$ diameter) pinned to the upper-left of each pupil to establish universal light source direction.
  * Pupil Tracking: Pupils can move horizontally/vertically inside the sclera via script to support aiming and gaze stabilization.
* **Eyebrows:**
  * Thick expressive wedges ($4\text{px}$ stroke width or solid polygon shapes) that float $4\text{px}$ above the eye contours.
  * Expressive flexibility: Slanted down for aggression, raised arched for curiosity/confusion, wavy for fear.

---

## 5. Mouth System

The mouth utilizes a standardized swap library of **10 Discrete Vector Shapes**, each optimized for maximum graphic punch:

1. **`neutral`:** Small confident curved smile line with rounded stroke ends.
2. **`happy`:** Wide crescent upward arc with white tooth bar.
3. **`angry`:** Angular clenched teeth rectangle with dark outline grid.
4. **`sad`:** Downward drooping curved frown line.
5. **`shocked`:** Vertical tall "O" oval opening showing dark throat depth.
6. **`scared`:** Horizontal wavy chattering contour with visible trembling upper/lower teeth.
7. **`hurt`:** Tightly clenched zigzag grimace line.
8. **`confused`:** Asymmetrical diagonal slant line with raised corner.
9. **`smug`:** Sideways smirk curved up toward one cheek with closed teeth.
10. **`laughing`:** Wide open inverted wedge with visible rounded pink tongue (`#eb4d4b`).

---

## 6. Outline Rules

Consistency in line weight is mandatory to preserve stylistic cohesion across diverse brawlers:

* **Global Outline Color:** Solid deep midnight navy/charcoal (`#1e1e2c`). Pure pitch black (`#000000`) is prohibited to prevent harsh digital clipping against dark backgrounds.
* **Outline Stroke Width:**
  * **Standard Perimeter Outlines:** Exactly **$3.5\text{px}$** at $1080\text{p}$ reference scale.
  * **Internal Structural Seams (e.g. fingers, collar folds):** **$2.5\text{px}$** `#1e1e2c`.
* **Cap and Join Rules:** All SVG strokes must specify:
  * `stroke-linecap="round"`
  * `stroke-linejoin="round"`
* **Scaling Behavior:** Outlines must scale proportionally with character scale transforms without thinning out into hairline artifacts.

---

## 7. Color System

Each brawler design is bound to an **8-Slot Color Palette**:

| Palette Slot | Purpose | Sample Neutral Brawler Hex |
| :--- | :--- | :--- |
| **Outline** | Perimeter ink & structural feature lines | `#1e1e2c` |
| **Primary** | Main clothing / signature body tone | `#34495e` (Slate Coat) |
| **Secondary** | Secondary clothing / trim accents | `#2c3e50` (Dark Charcoal Tunic) |
| **Skin / Face** | Face surface & neck tone | `#f5cd79` (Warm Pale Gold / Mask Ochre) |
| **Hair** | Hair volume & stylized locks | `#1e272e` (Deep Obsidian) |
| **Shadow** | Standard cel form & cast shadows | `#232f3e` (30% darker shade) |
| **Highlight** | Stylized specular sheen | `#70a1ff` / `#dfe4ea` |
| **Accent** | Eye pop, scarf, gems, combat emblems | `#ff4757` (Vibrant Crimson Scarf) |

* **Saturation Rule:** Base colors must sit in the medium-high saturation band ($50\% – 85\%$) to maintain vibrancy against game stage backgrounds. Muddy browns and desaturated grays are restricted to background props.

---

## 8. Shading Rules

Shading strictly follows a **Simplified 2-Tone Cel Architecture**:

$$\text{Final Surface} = \text{Base Tone} + \text{1 Primary Cel Shadow} + \text{[Optional Specular Highlight]}$$

* **No Gradients:** Radial and linear color gradients across body parts are prohibited. All shading transitions are sharp, clean vector cutoffs.
* **Shadow Placement:** Universal light source originates from the **Top-Left ($135^\circ$ angle)**.
  * Shadows sit under the chin, under sleeve cuffs, on the rear side of legs, and under hair bangs.
* **Shadow Density:** Shadows use a crisp, solid tone calculated at approximately $30\%$ lower brightness and $+10\%$ increased saturation compared to the base color.

---

## 9. Texture Rules

* **Zero Surface Noise:** No photographic overlays, grit textures, or perlin noise filters.
* **Graphic Decals:** Clothing patterns (stripes, badges, star insignias) must be drawn as clean geometric vector shapes bounded by the established color palette.

---

## 10. Hair Construction & Secondary Motion

* **Modular Separation:** Hair is divided into at least two discrete components:
  1. `HairBack`: Placed behind the head ($Z = -1$) to provide overall volume and head depth.
  2. `HairFront` / `Bangs`: Placed in front of the forehead ($Z = 1$) to frame the face and cast a clean cel shadow on the brow.
* **Chunky Clumping:** Hair strands are never drawn individually. Hair is grouped into 3 to 5 chunky, faceted locks with tapered teardrop tips.
* **Secondary Articulation:** Hair locks are parented to a dedicated secondary bone (or child of the Head bone) to support snappy lag and overshoot during leaps, sudden stops, and attack thrusts.

---

## 11. Body-Part Separation & Joint Hiding

To ensure cutout animation rotates without ugly seams or limb detachment, parts must use the **Concentric Ball-Socket Rule**:

```
[ Upper Arm ]
   (  R16  )  <-- Concentric overlapping circular cap
       ||
   [ Lower Arm ]
```

* **Joint Overlap:** The pivot point of the child bone (e.g. elbow) sits exactly at the center of a circular cap on the child sprite. The parent limb's socket is drawn slightly wider than the child cap, hiding the seam at rotation angles from $-130^\circ$ to $+130^\circ$.
* **Cuff Hiding:** Gloves, wristbands, collars, and boot cuffs are placed over joints to act as natural visual cover.

---

## 12. Rigging Rules (Godot Skeleton2D & Bone2D)

All brawler scenes must adhere to the standardized bone tree:

```
Character (CharacterBody2D)
  └── CollisionShape2D (CapsuleShape2D)
  └── Visuals (Node2D, handles facing scale.x)
        └── Skeleton (Skeleton2D)
              └── Hip (Pelvis Root, y = -56)
                    ├── Torso (y = -10)
                    │     ├── Head (y = -38)
                    │     │     ├── Face (Node2D, FaceController)
                    │     │     ├── HairFront (Bone2D)
                    │     │     └── Scarf / Accessory (Bone2D, leaf)
                    │     ├── LeftUpperArm (Z = -1)
                    │     │     └── LeftLowerArm
                    │     │           └── LeftHand (leaf)
                    │     └── RightUpperArm (Z = 1)
                    │           └── RightLowerArm
                    │                 └── RightHand (leaf)
                    ├── LeftUpperLeg (Z = -1)
                    │     └── LeftLowerLeg
                    │           └── LeftFoot (leaf)
                    └── RightUpperLeg (Z = 1)
                          └── RightLowerLeg
                                └── RightFoot (leaf)
```

* **Leaf Bone Warning Prevention:** Every leaf bone (`Hand`, `Foot`, `Scarf`) must explicitly set:
  ```gdscript
  bone.auto_calculate_length_and_angle = false
  bone.length = 16.0
  ```

---

## 13. Animation Compatibility Rules

* **Z-Layering Standard:**
  * $Z = -2$: `HairBack`, `CoatTails`
  * $Z = -1$: Back Limbs (`LeftLeg`, `LeftArm`)
  * $Z = 0$: `Torso`, `Head`
  * $Z = 1$: Front Limbs (`RightLeg`, `RightArm`), `HairFront`
  * $Z = 2$: `Face` (`Eyes`, `Pupils`, `Mouth`, `Brows`)
* **Facing Scale Flipping:** Direction changes are driven by `Visuals.scale.x = 1` or `-1`. Transitions must execute through a dedicated profile compression state (`State.TURN`) over $0.18\text{s}$ to prevent jarring instant flips.

---

## 14. Standard Expression Matrix

The 10 standard expressions map to the following component states:

| Expression | Eyebrow State | Eye Sclera State | Pupil Offset | Mouth State |
| :--- | :--- | :--- | :--- | :--- |
| **`neutral`** | Relaxed horizontal | Standard oval | $(0, 0)$ | `mouth_neutral` |
| **`happy`** | High gentle arch | Wide crescent | $(0, -1)$ | `mouth_happy` |
| **`angry`** | Slanted sharply downward | Angled top lid | $(0, +1)$ | `mouth_angry` |
| **`sad`** | Slanted outward/upward | Soft lowered lid | $(0, +2)$ | `mouth_sad` |
| **`shocked`** | Raised high off eyes | Wide round circle | $(0, 0)$ centered | `mouth_shocked` |
| **`scared`** | Quivering wavy line | Wide with pin-prick | Trembling $( \pm 1, 0 )$ | `mouth_scared` |
| **`hurt`** | Pinched down tightly | Squeezed shut `><` | Hidden | `mouth_hurt` |
| **`confused`** | One high arch, one flat | Asymmetrical $(?\_?)$ | Left centered, Right lowered | `mouth_confused` |
| **`smug`** | One cocked eyebrow | Narrowed hooded lids | $(+2, 0)$ side glance | `mouth_smug` |
| **`laughing`** | Curved high crest | Closed happy arcs `^^` | Hidden | `mouth_laughing` |

---

## 15. Universality & Distinct Character Identity Rules

To ensure a cohesive universe where every character looks like they belong to the same game, yet each maintains an unmistakable identity:

1. **Shared Visual DNA:**
   * All characters share the **40–50% head proportion**, **3.5px dark ink outline**, and **2-tone cel shading**.
   * All characters share the same **10-expression face logic** and **joint rotation architecture**.
2. **Unique Identity Levers:**
   * **Silhouette Signature:** Character silhouettes must be distinguishable by exterior silhouette alone (e.g. distinct hats, bulky coats, flowing scarves, oversized gear, distinct hair volumes).
   * **Color Palette Signature:** Each character is assigned a unique primary and accent color pair (e.g. Slate/Crimson, Gold/Violet, Emerald/Ochre).
   * **Stance Posture:** While rigs share the bone hierarchy, rest poses can vary in stance width, arm bend, and spinal posture.

---
*Signed and Locked for Cutenemi 2D Brawler Production.*
