# NITA — Character Production Reference & Style QC Spec

**Stage:** In-Engine Production 2D Cutout Character Package.  
**Reference Video Benchmark:** `renders/leon_teaching_nita.mp4` / `scenes/videos/leon_teaching_nita/main.tscn`  
**Showcase Scene:** `scenes/nita_showcase.tscn`  
**Asset Root:** `assets/brawlers/nita/`

---

## 1. Visual Formula & Production Style Truth

All Nita visuals are directly generated from the actual production puppet rigs and modular SVGs used in our animations:

- **Front View Rig:** `scenes/nita_front.tscn`
- **Side Profile Rig (Locomotion & Combat):** `scenes/nita_side.tscn` / `scenes/brawler_nita.tscn`
- **Back View Rig:** `scenes/nita_back.tscn`
- **Proportion Parity:** 1:1 scale parity with Leon (`scenes/videos/leon_elevator/leon_front.tscn`), with oversized chibi head (~48% of total height), bold `#1e1e2c` outlines, flat cel fills, and zero synthetic gradients.

---

## 2. Palette & Character Specifications

| Element | Color Hex | Visual Description |
| :--- | :--- | :--- |
| **Outlines** | `#1e1e2c` | Bold uniform cartoon contours |
| **Bear Cowl** | `#d93848` | Crimson red cowl with round ears & 'X' stitch details |
| **Snout / Muzzle** | `#eb5e6d` | Salmon pink snout pad with dark nose pad & white fangs |
| **Skin** | `#b87349` | Warm caramel tan skin |
| **War Paint Mask** | `#4a2818` | Dark chocolate brown eye mask band |
| **Hair** | `#3a2015` | Dark chocolate brown bangs peeking under bear fangs |
| **Tunic** | `#06d6a0` | Emerald turquoise dress with brown leather belt (`#4a2e1b`) |
| **Paw Pendant** | `#48cae4` / `#00b4d8` | Cyan tribal bear-paw pendant |
| **Leggings / Shorts**| `#7a2828` | Maroon leggings under cyan skirt hem |
| **Boots / Feet** | `#b87349` / `#874724` | Warm tan boots with dark soles |

---

## 3. High-Resolution Reference Gallery

The following reference renders are captured directly from the in-engine Godot production scene in 4K UHD:

1. **`references/nita_model_sheet.png`**  
   4K multi-view master model sheet displaying:
   - Leon (1:1 Scale Reference)
   - Nita (Front View — `nita_front.tscn`)
   - Nita (Side Locomotion Rig — `nita_side.tscn`)
   - Nita (Back View — `nita_back.tscn`)

2. **`references/nita_view_front.png`**  
   High-resolution front view portrait of the authentic front puppet rig.

3. **`references/nita_view_side.png`**  
   High-resolution side view portrait of the authentic locomotion rig as seen walking and attacking in `leon_teaching_nita.mp4`.

4. **`references/nita_view_back.png`**  
   High-resolution back view portrait showing rear cowl seam stitching and skirt.

5. **`references/nita_expression_sheet.png`**  
   6-state facial expression matrix (GRIN, HAPPY, ANGRY, SHOCKED, HURT, NEUTRAL) mounted directly on the production front rig and driven by `FaceControllerNita`.
