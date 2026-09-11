# LEON — Character Production Reference & Style QC Spec

**Stage:** In-Engine Production 2D Cutout Character Package.  
**Reference Video Benchmark:** `renders/leon_teaching_nita.mp4` / `scenes/videos/leon_teaching_nita/main.tscn`  
**Showcase Scene:** `scenes/leon_showcase.tscn`  
**Asset Root:** `assets/brawlers/leon/`

---

## 1. Visual Formula & Production Style Truth

All Leon visuals are directly generated from the actual production puppet rigs and modular SVGs used in our animations:

- **Front View Rig:** `scenes/videos/leon_elevator/leon_front.tscn`
- **Side Profile Rig (Locomotion & Combat):** `scenes/leon.tscn` / `scenes/leon_side.tscn`
- **Back View Rig:** `scenes/videos/leon_elevator/leon_back.tscn`
- **Proportion Parity:** 1:1 scale parity with Nita (`scenes/nita_front.tscn`), oversized chibi chameleon head (~48% of total height), bold `#1e1e2c` outlines, flat cel fills, and zero synthetic gradients.

---

## 2. Palette & Character Specifications

| Element | Color Hex | Visual Description |
| :--- | :--- | :--- |
| **Outlines** | `#1e1e2c` | Bold uniform cartoon contours |
| **Chameleon Cowl** | `#38b000` / `#48c700` | Vibrant leaf green cowl with side eye bulbs |
| **Hood Crest** | `#ffd166` | Golden yellow spine crest stripe down the center/back |
| **Button Eyes** | `#1e90ff` / `#0077b6` | Blue circular buttons with bold black 'X' cross-stitching |
| **Face Base / Skin** | `#c47d48` / `#b87349` | Warm tan skin in dark hood cavity recess |
| **Lollipop** | `#e63946` / `#ffffff` | White lollipop stick with red candy ball protruding from cheek/mouth |
| **Hoodie / Torso** | `#38b000` & `#1e90ff` | Green hoodie jacket with front cyan/blue pocket patch |
| **Sleeves & Hands** | `#00d084` / `#1e90ff` | Bright cyan/green sleeves with blue mitt cuffs |
| **Shorts** | `#1f3160` | Dark navy shorts with split leg geometry |
| **Tail** | `#38b000` & `#ffd166` | Curled green chameleon tail with yellow tip behind torso |
| **Boots** | `#c47d48` / `#1e1e2c` | Tan boots with dark charcoal sole rims |

---

## 3. High-Resolution Reference Gallery

The following reference renders are captured directly from the in-engine Godot production scene in 4K UHD:

1. **`references/leon_model_sheet.png`**  
   4K multi-view master model sheet displaying:
   - Nita (1:1 Scale Reference)
   - Leon (Front View — `leon_front.tscn`)
   - Leon (Side Locomotion Rig — `leon.tscn`)
   - Leon (Back View — `leon_back.tscn`)

2. **`references/leon_view_front.png`**  
   High-resolution front view portrait of the authentic front puppet rig.

3. **`references/leon_view_side.png`**  
   High-resolution side view portrait of the authentic locomotion rig as seen walking, jumping, and fighting in `leon_teaching_nita.mp4`.

4. **`references/leon_view_back.png`**  
   High-resolution back view portrait showing rear crest stripe and curled tail.

5. **`references/leon_expression_sheet.png`**  
   10-state facial expression matrix (NEUTRAL, HAPPY, ANGRY, SAD, SHOCKED, SCARED, HURT, CONFUSED, SMUG, LAUGHING) mounted directly on the production front rig and driven by `FaceController`.
