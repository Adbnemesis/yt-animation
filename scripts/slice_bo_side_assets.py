#!/usr/bin/env python3
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIDE_DIR = os.path.join(BASE_DIR, "assets", "brawlers", "bo", "side")
FACE_DIR = os.path.join(SIDE_DIR, "face")

os.makedirs(SIDE_DIR, exist_ok=True)
os.makedirs(FACE_DIR, exist_ok=True)

# HEAD UNIFIED VIEWBOX: viewBox="-58 -48 128 120"
# Origin (0, 0) is the Head Bone pivot. Every head part aligns pixel-perfectly with offset=(0,0)!

HEAD_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="120" viewBox="-58 -48 128 120">'

# 1. Hood: White Eagle Cowl Dome + Orange Crest + Golden Eagle Brow Eye
hood_svg = f"""{HEAD_HEADER}
  <!-- Bo Side Hood: Eagle Cowl Dome, Orange Crest, Cool Grey Shadow & Golden Eagle Brow Eye -->
  <g>
    <!-- Orange Feather Crest (Top-Rear, pointing back/up) -->
    <g transform="translate(-24, -28)">
      <path d="M-4,4 C-14,-6 -24,-4 -28,6 C-24,12 -16,12 -12,16 C-22,20 -24,30 -16,34 C-10,34 -4,24 2,18 Z"
            fill="#ff7b00" stroke="#1e1e2c" stroke-width="3.0" stroke-linejoin="round"/>
      <path d="M2,18 C-4,10 -8,4 -4,4 Z" fill="#e66e00"/>
    </g>

    <!-- White Eagle Cowl Dome -->
    <path d="M-22,-36 C-4,-42 26,-42 40,-26 C52,-10 50,16 42,38 C28,48 4,50 -14,46 C-34,40 -38,14 -38,-12 C-38,-28 -32,-34 -22,-36 Z"
          fill="#f8f9fa" stroke="#1e1e2c" stroke-width="3.8" stroke-linejoin="round"/>
    <!-- Soft Cool Grey Cel Shadow on Back/Under of Cowl -->
    <path d="M-22,-34 C-32,-20 -34,14 -12,44 C-28,38 -34,20 -34,-10 Z" fill="#dce1e6"/>

    <!-- Eagle Eye on Cowl Brow (Fierce Golden Eye) -->
    <g transform="translate(6, -20)">
      <!-- Heavy Black Eagle Brow Contour -->
      <path d="M-6,10 L16,4 L30,14" stroke="#1e1e2c" stroke-width="3.5" stroke-linecap="round" fill="none"/>
      <!-- Golden Iris -->
      <path d="M0,12 C8,8 20,8 26,14 C20,19 8,19 0,12 Z" fill="#ffd166" stroke="#1e1e2c" stroke-width="2.2"/>
      <!-- Sharp Black Pupil -->
      <circle cx="14" cy="13.5" r="3.4" fill="#1e1e2c"/>
      <circle cx="15.5" cy="12" r="1.1" fill="#ffffff"/>
    </g>
  </g>
</svg>
"""

# 2. Beak: Hooked Yellow Eagle Beak in unified head frame
beak_svg = f"""{HEAD_HEADER}
  <!-- Bo Side Beak: Proud Hooked Yellow Eagle Beak aligned to Cowl -->
  <g transform="translate(26, -16)">
    <path d="M-2,6 C16,4 32,12 40,26 C44,36 40,50 28,62 C26,50 20,40 8,36 C2,34 -4,30 -6,28 Z"
          fill="#ffd166" stroke="#1e1e2c" stroke-width="3.8" stroke-linejoin="round"/>
    <!-- Under-Beak Deep Amber Shadow -->
    <path d="M8,36 C22,40 26,50 28,62 C22,54 16,46 6,42 Z" fill="#ffb703"/>
    <!-- Nostril Slit -->
    <ellipse cx="16" cy="22" rx="3.5" ry="1.6" transform="rotate(-18 16 22)" fill="#1e1e2c"/>
  </g>
</svg>
"""

# 3. Hair: Dark Navy Hair in unified head frame
hair_svg = f"""{HEAD_HEADER}
  <!-- Bo Side Hair: Dark Navy Tucked Along Back of Neck -->
  <g transform="translate(-16, -12)">
    <path d="M-4,0 C-16,16 -14,36 -4,50 C0,48 2,38 0,26 C-2,14 0,4 2,0 Z"
          fill="#1f2438" stroke="#1e1e2c" stroke-width="3.2" stroke-linejoin="round"/>
    <path d="M-6,20 C-10,32 -8,44 -2,48 C-2,42 -4,32 -4,20 Z" fill="#151928"/>
  </g>
</svg>
"""

# 4. Face Base: Caramel Tan Warrior Profile (without eye/mouth for modular expression swaps)
face_base_svg = f"""{HEAD_HEADER}
  <!-- Bo Side Face Base: Caramel Tan Profile with Chiseled Jaw & Brow Shadow -->
  <g transform="translate(8, 8)">
    <path d="M0,6 C14,6 26,10 30,22 C34,36 30,48 18,54 C10,56 0,52 -2,44 C-4,30 -2,16 0,6 Z"
          fill="#b87349" stroke="#1e1e2c" stroke-width="3.0" stroke-linejoin="round"/>
    <!-- Deep Brow Shadow Arch -->
    <path d="M0,6 C12,12 26,14 28,24 C20,22 10,20 0,22 Z" fill="#8f4f2a"/>
    <!-- Chiseled Jawline -->
    <path d="M4,46 L18,54" stroke="#1e1e2c" stroke-width="2.4" stroke-linecap="round"/>
  </g>
</svg>
"""

# 4b. Complete Static Face (Face Base + Stoic Eye + Stoic Mouth)
face_complete_svg = f"""{HEAD_HEADER}
  <!-- Bo Side Complete Face: Chiseled Warrior Profile with Single Focused Eye & Stoic Mouth -->
  <g transform="translate(8, 8)">
    <path d="M0,6 C14,6 26,10 30,22 C34,36 30,48 18,54 C10,56 0,52 -2,44 C-4,30 -2,16 0,6 Z"
          fill="#b87349" stroke="#1e1e2c" stroke-width="3.0" stroke-linejoin="round"/>
    <path d="M0,6 C12,12 26,14 28,24 C20,22 10,20 0,22 Z" fill="#8f4f2a"/>
    <!-- Intense Focused Archer Eye (Single Eye) -->
    <polygon points="12,24 26,28 18,31" fill="#ffffff" stroke="#1e1e2c" stroke-width="2.0"/>
    <circle cx="19" cy="27.5" r="2.2" fill="#1e1e2c"/>
    <!-- Stoic Set Mouth -->
    <path d="M12,42 L24,40" stroke="#1e1e2c" stroke-width="2.8" stroke-linecap="round"/>
    <path d="M4,46 L18,54" stroke="#1e1e2c" stroke-width="2.4" stroke-linecap="round"/>
  </g>
</svg>
"""

# 5. Modular Eyes in unified head frame
eye_open_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Eye: Open Focused -->
  <g transform="translate(8, 8)">
    <polygon points="12,24 26,28 18,31" fill="#ffffff" stroke="#1e1e2c" stroke-width="2.0"/>
    <circle cx="19" cy="27.5" r="2.2" fill="#1e1e2c"/>
    <circle cx="20" cy="26.8" r="0.7" fill="#ffffff"/>
  </g>
</svg>
"""

eye_blink_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Eye: Blink / Closed -->
  <g transform="translate(8, 8)">
    <path d="M12,28 L25,29" stroke="#1e1e2c" stroke-width="2.6" stroke-linecap="round"/>
  </g>
</svg>
"""

eye_wide_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Eye: Wide Alert -->
  <g transform="translate(8, 8)">
    <polygon points="11,22 27,26 18,32" fill="#ffffff" stroke="#1e1e2c" stroke-width="2.0"/>
    <circle cx="19" cy="27" r="2.8" fill="#1e1e2c"/>
    <circle cx="20.2" cy="25.8" r="0.9" fill="#ffffff"/>
  </g>
</svg>
"""

eye_angry_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Eye: Fierce / Combat -->
  <g transform="translate(8, 8)">
    <polygon points="12,26 27,27 18,31" fill="#ffffff" stroke="#1e1e2c" stroke-width="2.2"/>
    <circle cx="19" cy="28.2" r="2.0" fill="#1e1e2c"/>
  </g>
</svg>
"""

eye_happy_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Eye: Happy Arc -->
  <g transform="translate(8, 8)">
    <path d="M12,29 Q19,23 26,28" stroke="#1e1e2c" stroke-width="2.8" stroke-linecap="round" fill="none"/>
  </g>
</svg>
"""

brow_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Brow -->
  <g transform="translate(8, 8)">
    <path d="M11,21 L23,24 L27,27" stroke="#1e1e2c" stroke-width="2.8" stroke-linecap="round" fill="none"/>
  </g>
</svg>
"""

# Modular Mouths in unified head frame
mouth_stoic_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Mouth: Stoic Focused -->
  <g transform="translate(8, 8)">
    <path d="M12,42 L24,40" stroke="#1e1e2c" stroke-width="2.8" stroke-linecap="round"/>
  </g>
</svg>
"""

mouth_shout_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Mouth: Battle Shout -->
  <g transform="translate(8, 8)">
    <path d="M12,38 C18,36 24,37 25,43 C24,48 18,50 12,47 Z" fill="#7a1a1a" stroke="#1e1e2c" stroke-width="2.6" stroke-linejoin="round"/>
    <polygon points="14,38 22,39 18,42" fill="#ffffff"/>
  </g>
</svg>
"""

mouth_grimace_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Mouth: Clenched Grimace -->
  <g transform="translate(8, 8)">
    <path d="M12,40 L24,39 C25,44 22,46 19,46 L13,45 Z" fill="#ffffff" stroke="#1e1e2c" stroke-width="2.4" stroke-linejoin="round"/>
    <line x1="12" y1="42.5" x2="24" y2="42" stroke="#1e1e2c" stroke-width="1.6"/>
  </g>
</svg>
"""

mouth_smile_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Mouth: Subtle Smirk -->
  <g transform="translate(8, 8)">
    <path d="M12,43 Q18,46 24,40" stroke="#1e1e2c" stroke-width="2.8" stroke-linecap="round" fill="none"/>
  </g>
</svg>
"""

mouth_hurt_svg = f"""{HEAD_HEADER}
  <!-- Bo Profile Mouth: Hurt Grimace -->
  <g transform="translate(8, 8)">
    <path d="M12,41 Q18,38 24,44" stroke="#1e1e2c" stroke-width="2.6" stroke-linecap="round" fill="none"/>
  </g>
</svg>
"""

# 6. Torso: Broad Muscular Chest (52 units deep)
torso_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="84" height="74" viewBox="0 0 84 74">
  <!-- Bo Side Torso: Broad Caramel Chest, Open Emerald Vest, Quiver Harness & Maroon Sash -->
  <g transform="translate(18, 12)">
    <!-- Broad Caramel Tan Muscular Chest Profile (52 units deep) -->
    <path d="M-8,6 C-8,6 16,-2 34,-2 C46,-2 54,10 52,26 C50,40 42,48 30,50 L-8,50 Z"
          fill="#b87349" stroke="#1e1e2c" stroke-width="3.6" stroke-linejoin="round"/>

    <!-- Emerald Green Vest (Open front, covering back and shoulder) -->
    <path d="M-8,4 C-8,4 10,-2 22,-2 C20,12 16,24 8,34 C2,42 -4,46 -8,50 Z"
          fill="#06d6a0" stroke="#1e1e2c" stroke-width="3.2" stroke-linejoin="round"/>
    <!-- Vest Cel Shadow on Back Curve -->
    <path d="M-8,4 C-4,16 -6,36 -8,50 L-12,50 L-12,4 Z" fill="#05a87d"/>

    <!-- Pectoral Muscle Definition -->
    <path d="M12,12 C24,12 34,16 40,26 C36,34 28,36 18,34" stroke="#8f4f2a" stroke-width="2.6" fill="none" stroke-linecap="round"/>
    <path d="M18,34 C16,42 20,48 26,50" stroke="#8f4f2a" stroke-width="2.2" fill="none" stroke-linecap="round"/>

    <!-- Leather Quiver Harness Strap (Diagonal across chest) -->
    <line x1="2" y1="0" x2="38" y2="42" stroke="#4a2e1b" stroke-width="5.2" stroke-linecap="round"/>
    <line x1="2" y1="0" x2="38" y2="42" stroke="#1e1e2c" stroke-width="1.8" stroke-linecap="round" stroke-dasharray="3 3"/>

    <!-- Maroon Sash at Waist -->
    <rect x="-10" y="44" width="46" height="12" rx="2" fill="#7a2828" stroke="#1e1e2c" stroke-width="3.2"/>
    <line x1="-10" y1="50" x2="36" y2="50" stroke="#1e1e2c" stroke-width="2.0"/>
  </g>
</svg>
"""

# 7. Quiver: Diagonal Back Quiver with 4 Cyan Arrows
quiver_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="70" height="120" viewBox="0 0 70 120">
  <!-- Bo Side Quiver: Mounted on Back with 4 Cyan Arrows, Collar & Eagle Head -->
  <g transform="translate(30, 52) rotate(-22)">
    <g transform="translate(0, -18)">
      <path d="M-8,-16 L-3,-44 L1,-16 Z" fill="#00b4d8" stroke="#1e1e2c" stroke-width="2.0" stroke-linejoin="round"/>
      <line x1="-3" y1="-44" x2="-3" y2="-16" stroke="#1e1e2c" stroke-width="1.4"/>
      <path d="M-1,-18 L5,-50 L10,-18 Z" fill="#48cae4" stroke="#1e1e2c" stroke-width="2.0" stroke-linejoin="round"/>
      <line x1="5" y1="-50" x2="5" y2="-18" stroke="#1e1e2c" stroke-width="1.4"/>
      <path d="M7,-16 L13,-42 L17,-16 Z" fill="#00b4d8" stroke="#1e1e2c" stroke-width="2.0" stroke-linejoin="round"/>
      <line x1="13" y1="-42" x2="13" y2="-16" stroke="#1e1e2c" stroke-width="1.4"/>
      <path d="M14,-14 L20,-36 L23,-14 Z" fill="#48cae4" stroke="#1e1e2c" stroke-width="2.0" stroke-linejoin="round"/>
      <line x1="20" y1="-36" x2="20" y2="-14" stroke="#1e1e2c" stroke-width="1.4"/>
    </g>

    <rect x="-8" y="-18" width="34" height="15" rx="3" fill="#f8f9fa" stroke="#1e1e2c" stroke-width="3.2"/>
    <path d="M8,-15 C5,-15 4,-11 8,-7 C12,-11 11,-15 8,-15 Z" fill="#1f3160"/>

    <g transform="translate(-16, -6)">
      <path d="M10,0 C0,2 -4,12 2,18 C8,24 16,20 18,14 Z" fill="#ffd166" stroke="#1e1e2c" stroke-width="2.8" stroke-linejoin="round"/>
      <path d="M2,18 C-6,24 -12,20 -14,14 C-10,10 -2,8 2,18 Z" fill="#ffb703" stroke="#1e1e2c" stroke-width="2.4" stroke-linejoin="round"/>
      <circle cx="6" cy="8" r="1.8" fill="#1e1e2c"/>
    </g>

    <path d="M-6,-3 L22,-3 L18,52 L-2,52 Z" fill="#252b3e" stroke="#1e1e2c" stroke-width="3.5" stroke-linejoin="round"/>
    <line x1="4" y1="-3" x2="2" y2="52" stroke="#181d2a" stroke-width="3.0"/>
    <path d="M-2,52 L18,52 L16,60 L0,60 Z" fill="#151928" stroke="#1e1e2c" stroke-width="2.8" stroke-linejoin="round"/>
  </g>
</svg>
"""

# 8. Recurve Bow (Centered at grip: x=0, y=0)
bow_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="46" height="170" viewBox="-20 -85 46 170">
  <!-- Bo Side Recurve Bow: Grip at origin (0,0), limbs curve above and below -->
  <g>
    <!-- Bowstring -->
    <line x1="12" y1="-76" x2="12" y2="80" stroke="#ced4da" stroke-width="2.4"/>
    <!-- Curved Wooden Limbs -->
    <path d="M12,-76 C-8,-56 -12,-26 -4,2 C-12,30 -8,60 12,80 C0,62 -4,34 4,2 C-4,-30 0,-58 12,-76 Z"
          fill="#a0522d" stroke="#1e1e2c" stroke-width="3.8" stroke-linejoin="round"/>
    <!-- Blue Wrapped Center Grip -->
    <rect x="-8" y="-15" width="16" height="30" rx="2" fill="#1e90ff" stroke="#1e1e2c" stroke-width="2.8"/>
    <line x1="-8" y1="-7" x2="8" y2="-7" stroke="#1060c0" stroke-width="1.8"/>
    <line x1="-8" y1="1" x2="8" y2="1" stroke="#1060c0" stroke-width="1.8"/>
    <line x1="-8" y1="9" x2="8" y2="9" stroke="#1060c0" stroke-width="1.8"/>
    <!-- Upper Talon Tip -->
    <path d="M6,-76 L16,-88 L20,-78 L26,-84 L22,-72 Z" fill="#f8f9fa" stroke="#1e1e2c" stroke-width="2.4" stroke-linejoin="round"/>
    <!-- Lower Talon Tip -->
    <path d="M6,80 L16,92 L20,82 L26,88 L22,76 Z" fill="#f8f9fa" stroke="#1e1e2c" stroke-width="2.4" stroke-linejoin="round"/>
  </g>
</svg>
"""

# 9. Far Arm
arm_l_upper_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="36" height="30" viewBox="0 0 36 30">
  <g transform="translate(6, 6)">
    <path d="M0,0 C8,-2 18,2 24,8 C22,14 16,16 10,14 C4,12 0,8 0,0 Z"
          fill="#a15e37" stroke="#1e1e2c" stroke-width="3.0" stroke-linejoin="round"/>
  </g>
</svg>
"""

arm_l_lower_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="34" height="28" viewBox="0 0 34 28">
  <g transform="translate(6, 6)">
    <path d="M0,2 C8,4 16,10 20,16 C16,20 10,18 4,12 C0,8 0,4 0,2 Z"
          fill="#a15e37" stroke="#1e1e2c" stroke-width="3.0" stroke-linejoin="round"/>
  </g>
</svg>
"""

hand_l_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <g transform="translate(12, 12)">
    <circle cx="0" cy="0" r="8" fill="#a15e37" stroke="#1e1e2c" stroke-width="2.8"/>
  </g>
</svg>
"""

# 10. Near Arm
arm_r_upper_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="46" height="48" viewBox="0 0 46 48">
  <g transform="translate(12, 8)">
    <path d="M-4,0 C10,-4 24,0 28,12 C30,22 22,28 12,26 C4,24 -2,16 -4,0 Z"
          fill="#c48055" stroke="#1e1e2c" stroke-width="3.4" stroke-linejoin="round"/>
    <path d="M6,16 C16,14 26,20 26,32 C26,40 18,42 8,38 C0,36 -2,28 2,20 Z"
          fill="#b87349" stroke="#1e1e2c" stroke-width="3.2" stroke-linejoin="round"/>
  </g>
</svg>
"""

arm_r_lower_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="38" height="38" viewBox="0 0 38 38">
  <g transform="translate(8, 6)">
    <path d="M0,4 L18,6 L14,24 L-2,20 Z" fill="#b87349" stroke="#1e1e2c" stroke-width="2.6"/>
    <path d="M2,6 L22,8 L18,24 L0,22 Z" fill="#f8f9fa" stroke="#1e1e2c" stroke-width="2.8" stroke-linejoin="round"/>
    <polygon points="16,12 24,13 18,18" fill="#1e1e2c"/>
    <circle cx="8" cy="14" r="3.2" fill="#00b4d8" stroke="#1e1e2c" stroke-width="1.6"/>
  </g>
</svg>
"""

hand_r_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">
  <g transform="translate(14, 14)">
    <circle cx="0" cy="0" r="9.5" fill="#b87349" stroke="#1e1e2c" stroke-width="2.8"/>
    <line x1="-3" y1="4" x2="-3" y2="-2" stroke="#7a4222" stroke-width="2.0"/>
    <line x1="1" y1="5" x2="1" y2="-2" stroke="#7a4222" stroke-width="2.0"/>
  </g>
</svg>
"""

# 11. Legs & Feet
leg_r_upper_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
  <g transform="translate(12, 6)">
    <path d="M-8,0 L26,0 C34,14 36,24 28,34 L2,34 C0,24 -2,12 -8,0 Z"
          fill="#7a2828" stroke="#1e1e2c" stroke-width="3.4" stroke-linejoin="round"/>
    <path d="M22,2 C28,14 26,24 22,34" stroke="#5e1d1d" stroke-width="2.4" fill="none"/>
  </g>
</svg>
"""

leg_r_lower_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="44" height="46" viewBox="0 0 44 46">
  <g transform="translate(10, 4)">
    <path d="M-2,0 L24,0 C22,14 18,28 12,38 L-4,38 C-2,26 0,14 -2,0 Z"
          fill="#7a2828" stroke="#1e1e2c" stroke-width="3.2" stroke-linejoin="round"/>
    <path d="M12,12 Q20,18 16,24" stroke="#1e1e2c" stroke-width="2.0" fill="none" stroke-linecap="round"/>
  </g>
</svg>
"""

foot_r_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="58" height="30" viewBox="0 0 58 30">
  <g transform="translate(6, 5)">
    <path d="M4,4 L38,4 C44,4 46,9 46,14 L46,17 L2,17 L0,12 C0,6 2,4 4,4 Z"
          fill="#b87349" stroke="#1e1e2c" stroke-width="3.2" stroke-linejoin="round"/>
    <line x1="32" y1="17" x2="32" y2="11" stroke="#7a4222" stroke-width="2.2" stroke-linecap="round"/>
    <line x1="40" y1="17" x2="40" y2="12" stroke="#7a4222" stroke-width="2.2" stroke-linecap="round"/>
  </g>
</svg>
"""

leg_l_upper_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="46" height="46" viewBox="0 0 46 46">
  <g transform="translate(12, 6)">
    <path d="M-8,0 L20,0 C24,14 22,26 14,34 L-6,34 C-8,24 -8,12 -8,0 Z"
          fill="#5e1d1d" stroke="#1e1e2c" stroke-width="3.2" stroke-linejoin="round"/>
  </g>
</svg>
"""

leg_l_lower_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="44" height="46" viewBox="0 0 44 46">
  <g transform="translate(10, 4)">
    <path d="M0,0 L20,0 C16,14 10,26 4,36 L-8,36 C-6,26 -2,12 0,0 Z"
          fill="#5e1d1d" stroke="#1e1e2c" stroke-width="3.2" stroke-linejoin="round"/>
  </g>
</svg>
"""

foot_l_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="54" height="30" viewBox="0 0 54 30">
  <g transform="translate(6, 5)">
    <path d="M2,4 L32,4 C38,4 40,9 40,14 L40,17 L0,17 L0,12 C0,6 1,4 2,4 Z"
          fill="#9e5d36" stroke="#1e1e2c" stroke-width="3.2" stroke-linejoin="round"/>
    <line x1="28" y1="17" x2="28" y2="11" stroke="#683418" stroke-width="2.0" stroke-linecap="round"/>
    <line x1="35" y1="17" x2="35" y2="12" stroke="#683418" stroke-width="2.0" stroke-linecap="round"/>
  </g>
</svg>
"""

arrow_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="14" viewBox="0 0 64 14">
  <g transform="translate(4, 7)">
    <line x1="0" y1="0" x2="48" y2="0" stroke="#a0522d" stroke-width="2.6" stroke-linecap="round"/>
    <path d="M0,0 L-6,-5 L2,-5 L8,0 L2,5 L-6,5 Z" fill="#00b4d8" stroke="#1e1e2c" stroke-width="1.6" stroke-linejoin="round"/>
    <polygon points="48,-4 58,0 48,4" fill="#ced4da" stroke="#1e1e2c" stroke-width="2.0" stroke-linejoin="round"/>
  </g>
</svg>
"""

files_to_write = {
    os.path.join(SIDE_DIR, "hood.svg"): hood_svg,
    os.path.join(SIDE_DIR, "beak.svg"): beak_svg,
    os.path.join(SIDE_DIR, "hair.svg"): hair_svg,
    os.path.join(SIDE_DIR, "face_base.svg"): face_base_svg,
    os.path.join(SIDE_DIR, "face.svg"): face_complete_svg,
    os.path.join(SIDE_DIR, "torso.svg"): torso_svg,
    os.path.join(SIDE_DIR, "quiver.svg"): quiver_svg,
    os.path.join(SIDE_DIR, "bow.svg"): bow_svg,
    os.path.join(SIDE_DIR, "arrow.svg"): arrow_svg,
    os.path.join(SIDE_DIR, "arm_L_upper.svg"): arm_l_upper_svg,
    os.path.join(SIDE_DIR, "arm_L_lower.svg"): arm_l_lower_svg,
    os.path.join(SIDE_DIR, "hand_L.svg"): hand_l_svg,
    os.path.join(SIDE_DIR, "arm_R_upper.svg"): arm_r_upper_svg,
    os.path.join(SIDE_DIR, "arm_R_lower.svg"): arm_r_lower_svg,
    os.path.join(SIDE_DIR, "hand_R.svg"): hand_r_svg,
    os.path.join(SIDE_DIR, "leg_R_upper.svg"): leg_r_upper_svg,
    os.path.join(SIDE_DIR, "leg_R_lower.svg"): leg_r_lower_svg,
    os.path.join(SIDE_DIR, "foot_R.svg"): foot_r_svg,
    os.path.join(SIDE_DIR, "leg_L_upper.svg"): leg_l_upper_svg,
    os.path.join(SIDE_DIR, "leg_L_lower.svg"): leg_l_lower_svg,
    os.path.join(SIDE_DIR, "foot_L.svg"): foot_l_svg,
    os.path.join(FACE_DIR, "eye_open.svg"): eye_open_svg,
    os.path.join(FACE_DIR, "eye_blink.svg"): eye_blink_svg,
    os.path.join(FACE_DIR, "eye_wide.svg"): eye_wide_svg,
    os.path.join(FACE_DIR, "eye_angry.svg"): eye_angry_svg,
    os.path.join(FACE_DIR, "eye_happy.svg"): eye_happy_svg,
    os.path.join(FACE_DIR, "brow.svg"): brow_svg,
    os.path.join(FACE_DIR, "mouth_stoic.svg"): mouth_stoic_svg,
    os.path.join(FACE_DIR, "mouth_shout.svg"): mouth_shout_svg,
    os.path.join(FACE_DIR, "mouth_grimace.svg"): mouth_grimace_svg,
    os.path.join(FACE_DIR, "mouth_smile.svg"): mouth_smile_svg,
    os.path.join(FACE_DIR, "mouth_hurt.svg"): mouth_hurt_svg,
}

for path, content in files_to_write.items():
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")
    print(f"[OK] Wrote {path}")

print("\n[COMPLETE] Unified coordinate frame assets generated!")
