#!/usr/bin/env python3
"""
Master Generator for Bo Production 2D Character Asset Package.
100% Style-locked to Leon and Nita.
Authentic Brawl Stars Bo character identity.
"""

import os
import sys
import xml.etree.ElementTree as ET

BO_DIR = os.path.dirname(os.path.abspath(__file__))
BODY_DIR = os.path.join(BO_DIR, "body")
FACE_DIR = os.path.join(BO_DIR, "face")
CLOTHING_DIR = os.path.join(BO_DIR, "clothing")
EQUIP_DIR = os.path.join(BO_DIR, "equipment")
REF_DIR = os.path.join(BO_DIR, "references")
POSES_DIR = os.path.join(BO_DIR, "poses")

for d in [BODY_DIR, FACE_DIR, CLOTHING_DIR, EQUIP_DIR, REF_DIR, POSES_DIR]:
    os.makedirs(d, exist_ok=True)

OUTLINE = "#1e1e2c"
SKIN = "#b87349"
SKIN_DARK = "#7a4222"
SKIN_LIGHT = "#c98255"

EAGLE_WHITE = "#f8f9fa"
EAGLE_SHADOW = "#dce1e6"
BEAK_YELLOW = "#ffd166"
BEAK_SHADOW = "#e09f24"

HAIR_NAVY = "#1f2438"
HAIR_TIE_RED = "#d93848"

TUNIC_GREEN = "#06d6a0"
TUNIC_SHADOW = "#059669"
SASH_MAROON = "#7a2828"
PANTS_MAROON = "#7a2828"
PANTS_SHADOW = "#541919"

BOW_WOOD = "#a0522d"
BOW_GRIP_BLUE = "#1e90ff"
BOW_STRING = "#ced4da"
TALON_WHITE = "#f8f9fa"
RING_GREEN = "#06d6a0"

ARROW_SHAFT = "#ced4da"
ARROW_FLETCH_CYAN = "#00b4d8"
ARROW_TIP_BLUE = "#1e90ff"

QUIVER_NAVY = "#1f3160"
QUIVER_COLLAR_WHITE = "#f8f9fa"
STRAP_LEATHER = "#4a2e1b"

MOUTH_RED = "#eb4d4b"
EYE_WHITE = "#ffffff"
PUPIL_DARK = "#1e1e2c"

created_files = []

def write_svg(filepath, content):
    content = content.strip()
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content + "\n")
    try:
        ET.fromstring(content)
        created_files.append(filepath)
    except ET.ParseError as e:
        print(f"Error parsing XML for {filepath}: {e}", file=sys.stderr)
        raise

# ==============================================================================
# 1. FACE COMPONENTS
# ==============================================================================

write_svg(os.path.join(FACE_DIR, "bo_eye_L.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">
  <path d="M4,16 C8,6 18,5 24,10 C22,21 12,22 4,16 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eye_R.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">
  <path d="M24,16 C20,6 10,5 4,10 C6,21 16,22 24,16 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_pupil_L.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
  <ellipse cx="7" cy="7" rx="4.5" ry="5.5" fill="{PUPIL_DARK}"/>
  <circle cx="5.5" cy="5.2" r="1.5" fill="{EYE_WHITE}"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_pupil_R.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
  <ellipse cx="7" cy="7" rx="4.5" ry="5.5" fill="{PUPIL_DARK}"/>
  <circle cx="5.5" cy="5.2" r="1.5" fill="{EYE_WHITE}"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eyebrow_L.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="12" viewBox="0 0 28 12">
  <path d="M2,10 C8,4 18,3 26,6" stroke="{OUTLINE}" stroke-width="3.5" stroke-linecap="round" fill="none"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eyebrow_R.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="12" viewBox="0 0 28 12">
  <path d="M26,10 C20,4 10,3 2,6" stroke="{OUTLINE}" stroke-width="3.5" stroke-linecap="round" fill="none"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eye_blink.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="26" height="12" viewBox="0 0 26 12">
  <path d="M2,6 Q13,10 24,6" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round" fill="none"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eye_happy.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="26" height="14" viewBox="0 0 26 14">
  <path d="M2,10 Q13,2 24,10" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round" fill="none"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eye_wide.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">
  <ellipse cx="14" cy="14" rx="11" ry="12" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="3.0"/>
  <circle cx="14" cy="14" r="4.5" fill="{PUPIL_DARK}"/>
  <circle cx="12.5" cy="12" r="1.5" fill="{EYE_WHITE}"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eye_angry_L.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="26" viewBox="0 0 28 26">
  <path d="M2,6 L26,12 L22,22 L4,18 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
  <ellipse cx="15" cy="15" rx="4.5" ry="5" fill="{PUPIL_DARK}"/>
  <circle cx="13.5" cy="13.5" r="1.2" fill="{EYE_WHITE}"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eye_angry_R.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="26" viewBox="0 0 28 26">
  <path d="M26,6 L2,12 L6,22 L24,18 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
  <ellipse cx="13" cy="15" rx="4.5" ry="5" fill="{PUPIL_DARK}"/>
  <circle cx="11.5" cy="13.5" r="1.2" fill="{EYE_WHITE}"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_eye_closed.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="26" height="10" viewBox="0 0 26 10">
  <line x1="3" y1="5" x2="23" y2="5" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round"/>
</svg>''')

# Mouths
write_svg(os.path.join(FACE_DIR, "bo_mouth_neutral.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="12" viewBox="0 0 28 12">
  <path d="M4,6 L24,6" stroke="{OUTLINE}" stroke-width="3.0" stroke-linecap="round"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_happy.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="30" height="18" viewBox="0 0 30 18">
  <path d="M4,5 Q15,16 26,5 Z" fill="{MOUTH_RED}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
  <path d="M7,5 Q15,10 23,5 Z" fill="{EYE_WHITE}"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_angry.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="30" height="16" viewBox="0 0 30 16">
  <rect x="4" y="4" width="22" height="8" rx="2" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.8"/>
  <line x1="15" y1="4" x2="15" y2="12" stroke="{OUTLINE}" stroke-width="2.0"/>
  <line x1="9" y1="4" x2="9" y2="12" stroke="{OUTLINE}" stroke-width="1.8"/>
  <line x1="21" y1="4" x2="21" y2="12" stroke="{OUTLINE}" stroke-width="1.8"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_sad.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="26" height="14" viewBox="0 0 26 14">
  <path d="M3,10 Q13,2 23,10" stroke="{OUTLINE}" stroke-width="3.0" stroke-linecap="round" fill="none"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_shocked.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="26" viewBox="0 0 24 26">
  <ellipse cx="12" cy="13" rx="7.5" ry="9" fill="{OUTLINE}"/>
  <ellipse cx="12" cy="15" rx="5" ry="5.5" fill="{MOUTH_RED}"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_scared.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="16" viewBox="0 0 24 16">
  <ellipse cx="12" cy="8" rx="6" ry="5" fill="{OUTLINE}"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_hurt.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="14" viewBox="0 0 28 14">
  <path d="M4,8 L9,5 L14,9 L19,5 L24,8" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_confused.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="14" viewBox="0 0 28 14">
  <path d="M4,10 Q10,4 16,8 Q21,11 24,6" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" fill="none"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_smug.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="26" height="14" viewBox="0 0 26 14">
  <path d="M4,6 Q14,8 22,2" stroke="{OUTLINE}" stroke-width="3.0" stroke-linecap="round" fill="none"/>
</svg>''')

write_svg(os.path.join(FACE_DIR, "bo_mouth_serious.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="12" viewBox="0 0 28 12">
  <path d="M4,5 L14,7 L24,5" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>''')

# ==============================================================================
# 2. BODY COMPONENTS
# ==============================================================================

write_svg(os.path.join(BODY_DIR, "bo_face_base.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="80" height="74" viewBox="0 0 80 74">
  <path d="M12,18 C12,6 24,4 40,4 C56,4 68,6 68,18 C68,36 64,56 54,66 C48,72 44,72 40,72 C36,72 32,72 26,66 C16,56 12,36 12,18 Z"
        fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
  <path d="M14,18 C22,26 32,30 40,30 C48,30 58,26 66,18 C58,10 48,8 40,8 C32,8 22,10 14,18 Z" fill="{SKIN_DARK}"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_eagle_hood.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="136" height="124" viewBox="0 0 136 124">
  <!-- White Eagle Dome -->
  <path d="M68,6 C38,6 20,28 20,62 C20,92 38,108 68,108 C98,108 116,92 116,62 C116,28 98,6 68,6 Z"
        fill="{EAGLE_WHITE}" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
  <!-- Eagle Eyes on Forehead Dome -->
  <g transform="translate(36, 26)">
    <path d="M2,14 L18,8 L16,18 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
    <circle cx="10" cy="13" r="2.2" fill="{OUTLINE}"/>
    <line x1="0" y1="10" x2="20" y2="4" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
  </g>
  <g transform="translate(80, 26)">
    <path d="M18,14 L2,8 L4,18 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
    <circle cx="10" cy="13" r="2.2" fill="{OUTLINE}"/>
    <line x1="20" y1="10" x2="0" y2="4" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
  </g>
  <!-- Hooked Yellow Beak -->
  <path d="M52,22 C52,16 58,14 68,14 C78,14 84,16 84,22 C84,38 78,54 68,60 C58,54 52,38 52,22 Z"
        fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
  <line x1="68" y1="14" x2="68" y2="60" stroke="{BEAK_SHADOW}" stroke-width="2.0"/>
  <!-- Face Opening Recess -->
  <ellipse cx="68" cy="78" rx="36" ry="28" fill="{SKIN_DARK}" stroke="{OUTLINE}" stroke-width="3.2"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_eagle_beak.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="46" height="56" viewBox="0 0 46 56">
  <path d="M4,12 C4,4 12,2 23,2 C34,2 42,4 42,12 C42,30 34,46 23,50 C12,46 4,30 4,12 Z"
        fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
  <line x1="23" y1="2" x2="23" y2="50" stroke="{BEAK_SHADOW}" stroke-width="2.0"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_hair_side_L.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="56" viewBox="0 0 32 56">
  <path d="M22,2 C14,2 6,10 6,26 C6,42 10,52 16,54 C22,54 26,44 26,34 C26,24 26,12 24,2 Z"
        fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_hair_side_R.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="56" viewBox="0 0 32 56">
  <path d="M10,2 C18,2 26,10 26,26 C26,42 22,52 16,54 C10,54 6,44 6,34 C6,24 6,12 8,2 Z"
        fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_hair_braid_back.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="40" height="76" viewBox="0 0 40 76">
  <path d="M14,4 C10,14 8,26 12,38 C14,46 12,56 16,68 C20,72 26,72 28,66 C32,54 28,42 30,30 C32,18 28,8 24,4 Z"
        fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
  <rect x="12" y="24" width="18" height="7" rx="2" fill="{HAIR_TIE_RED}" stroke="{OUTLINE}" stroke-width="2.2"/>
  <rect x="14" y="48" width="14" height="6" rx="2" fill="{HAIR_TIE_RED}" stroke="{OUTLINE}" stroke-width="2.0"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_torso.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="84" height="70" viewBox="0 0 84 70">
  <path d="M16,6 C10,6 6,18 6,34 C6,52 14,64 24,64 L60,64 C70,64 78,52 78,34 C78,18 74,6 68,6 Z"
        fill="{TUNIC_GREEN}" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
  <path d="M30,6 Q42,20 54,6 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="2.5" stroke-linejoin="round"/>
  <rect x="8" y="50" width="68" height="14" rx="2" fill="{SASH_MAROON}" stroke="{OUTLINE}" stroke-width="3.2"/>
  <line x1="8" y1="56" x2="76" y2="56" stroke="{OUTLINE}" stroke-width="1.8"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_arm_L_upper.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="36" height="42" viewBox="0 0 36 42">
  <path d="M18,4 C10,4 5,11 5,20 L6,34 C6,38 11,40 18,40 C25,40 30,38 30,34 L31,20 C31,11 26,4 18,4 Z"
        fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_arm_L_lower.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="34" height="40" viewBox="0 0 34 40">
  <path d="M17,4 C10,4 6,10 6,18 L7,32 C7,36 11,38 17,38 C23,38 27,36 27,32 L28,18 C28,10 24,4 17,4 Z"
        fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_hand_L.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="34" viewBox="0 0 32 34">
  <path d="M16,4 C8,4 4,9 4,17 C4,25 9,29 16,29 C23,29 28,25 28,17 C28,13 25,9 21,6 C21,9 18,11 16,11 C14,11 14,7 16,4 Z"
        fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
  <line x1="10" y1="18" x2="22" y2="18" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_arm_R_upper.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="36" height="42" viewBox="0 0 36 42">
  <path d="M18,4 C10,4 5,11 5,20 L6,34 C6,38 11,40 18,40 C25,40 30,38 30,34 L31,20 C31,11 26,4 18,4 Z"
        fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_arm_R_lower.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="36" height="44" viewBox="0 0 36 44">
  <path d="M18,4 C11,4 7,10 7,18 L8,34 C8,38 12,40 18,40 C24,40 28,38 28,34 L29,18 C29,10 25,4 18,4 Z"
        fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
  <path d="M6,16 L30,16 L31,34 C31,37 25,39 18,39 C11,39 5,37 5,34 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.8" stroke-linejoin="round"/>
  <path d="M10,24 L14,32 L18,24 L22,32 L26,24" stroke="{OUTLINE}" stroke-width="2.0" stroke-linecap="round" fill="none"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_hand_R.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="34" viewBox="0 0 32 34">
  <path d="M16,4 C24,4 28,9 28,17 C28,25 23,29 16,29 C9,29 4,25 4,17 C4,13 7,9 11,6 C11,9 14,11 16,11 C18,11 18,7 16,4 Z"
        fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
  <line x1="10" y1="18" x2="22" y2="18" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_leg_L_upper.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="34" height="36" viewBox="0 0 34 36">
  <path d="M5,4 L29,4 C29,14 27,24 25,32 L9,32 C7,24 5,14 5,4 Z" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_leg_L_lower.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="34" viewBox="0 0 32 34">
  <path d="M6,4 L26,4 C26,12 24,22 23,30 L9,30 C8,22 6,12 6,4 Z" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_foot_L.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="40" height="26" viewBox="0 0 40 26">
  <path d="M6,5 L28,5 C32,5 35,11 35,16 L35,21 L3,21 C3,11 3,5 6,5 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
  <line x1="12" y1="21" x2="12" y2="16" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="20" y1="21" x2="20" y2="16" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_leg_R_upper.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="34" height="36" viewBox="0 0 34 36">
  <path d="M5,4 L29,4 C29,14 27,24 25,32 L9,32 C7,24 5,14 5,4 Z" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_leg_R_lower.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="34" viewBox="0 0 32 34">
  <path d="M6,4 L26,4 C26,12 24,22 23,30 L9,30 C8,22 6,12 6,4 Z" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(BODY_DIR, "bo_foot_R.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="40" height="26" viewBox="0 0 40 26">
  <path d="M34,5 L12,5 C8,5 5,11 5,16 L5,21 L37,21 C37,11 37,5 34,5 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
  <line x1="28" y1="21" x2="28" y2="16" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="20" y1="21" x2="20" y2="16" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
</svg>''')

# ==============================================================================
# 3. CLOTHING & EQUIPMENT
# ==============================================================================

write_svg(os.path.join(CLOTHING_DIR, "bo_sash.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="86" height="24" viewBox="0 0 86 24">
  <path d="M4,4 L82,4 L84,20 L2,20 Z" fill="{SASH_MAROON}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
  <rect x="38" y="2" width="10" height="20" rx="2" fill="{PANTS_SHADOW}" stroke="{OUTLINE}" stroke-width="2.2"/>
</svg>''')

write_svg(os.path.join(CLOTHING_DIR, "bo_bracer.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="34" height="28" viewBox="0 0 34 28">
  <path d="M4,4 L30,4 L28,24 L6,24 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.8" stroke-linejoin="round"/>
  <circle cx="17" cy="14" r="6" fill="{RING_GREEN}" stroke="{OUTLINE}" stroke-width="2.0"/>
  <circle cx="17" cy="14" r="3" fill="{TALON_WHITE}"/>
</svg>''')

write_svg(os.path.join(EQUIP_DIR, "bo_bow.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="100" height="140" viewBox="0 0 100 140">
  <line x1="32" y1="14" x2="32" y2="126" stroke="{BOW_STRING}" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M32,14 C12,30 8,50 14,70 C8,90 12,110 32,126 C22,112 18,92 24,70 C18,48 22,28 32,14 Z"
        fill="{BOW_WOOD}" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
  <rect x="14" y="58" width="14" height="24" rx="3" fill="{BOW_GRIP_BLUE}" stroke="{OUTLINE}" stroke-width="2.8"/>
  <line x1="14" y1="64" x2="28" y2="64" stroke="{OUTLINE}" stroke-width="1.8"/>
  <line x1="14" y1="70" x2="28" y2="70" stroke="{OUTLINE}" stroke-width="1.8"/>
  <line x1="14" y1="76" x2="28" y2="76" stroke="{OUTLINE}" stroke-width="1.8"/>
  <g transform="translate(24, 4)">
    <path d="M4,16 L14,4 L18,12 L24,6 L20,18 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.5" stroke-linejoin="round"/>
    <circle cx="8" cy="18" r="4" fill="{RING_GREEN}" stroke="{OUTLINE}" stroke-width="2.0"/>
  </g>
  <g transform="translate(24, 114)">
    <path d="M4,4 L14,16 L18,8 L24,14 L20,2 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.5" stroke-linejoin="round"/>
    <circle cx="8" cy="2" r="4" fill="{RING_GREEN}" stroke="{OUTLINE}" stroke-width="2.0"/>
  </g>
</svg>''')

write_svg(os.path.join(EQUIP_DIR, "bo_arrow.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="90" height="24" viewBox="0 0 90 24">
  <rect x="14" y="10" width="62" height="4" rx="1" fill="{ARROW_SHAFT}" stroke="{OUTLINE}" stroke-width="1.8"/>
  <path d="M4,6 L16,12 L4,18 L8,12 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
  <path d="M8,4 L20,12 L8,20 L12,12 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
  <path d="M72,6 L88,12 L72,18 L76,12 Z" fill="{ARROW_TIP_BLUE}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
</svg>''')

write_svg(os.path.join(EQUIP_DIR, "bo_quiver.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="48" height="110" viewBox="0 0 48 110">
  <g transform="translate(10, 4)">
    <path d="M4,16 L10,4 L16,16 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <path d="M14,14 L20,2 L26,14 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <path d="M22,18 L28,6 L34,18 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.0"/>
  </g>
  <path d="M8,26 L40,26 L36,104 C36,106 32,108 24,108 C16,108 12,106 12,104 Z"
        fill="{QUIVER_NAVY}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
  <rect x="6" y="24" width="36" height="12" rx="2" fill="{QUIVER_COLLAR_WHITE}" stroke="{OUTLINE}" stroke-width="2.8"/>
  <path d="M24,26 C22,28 20,31 20,33 C20,35 22,36 24,36 C26,36 28,35 28,33 C28,31 26,28 24,26 Z" fill="{OUTLINE}"/>
</svg>''')

write_svg(os.path.join(EQUIP_DIR, "bo_quiver_strap.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="80" height="70" viewBox="0 0 80 70">
  <line x1="14" y1="12" x2="66" y2="60" stroke="{STRAP_LEATHER}" stroke-width="5.0" stroke-linecap="round"/>
  <line x1="14" y1="12" x2="66" y2="60" stroke="{OUTLINE}" stroke-width="2.0" stroke-linecap="round" stroke-dasharray="6 4"/>
</svg>''')

# ==============================================================================
# 4. MASTER ASSEMBLED CHARACTER GRAPHIC FUNCTION
# ==============================================================================

def render_bo_front_group(scale=2.5, x=400, y=410):
    return f'''
    <g transform="translate({x}, {y}) scale({scale})">
      <!-- 1. Bare Tan Feet -->
      <g transform="translate(-28, 70)">
        <path d="M4,4 L24,4 C27,4 29,9 29,14 L29,18 L2,18 C2,10 2,4 4,4 Z"
              fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
        <line x1="10" y1="18" x2="10" y2="13" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
        <line x1="18" y1="18" x2="18" y2="13" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
      </g>
      <g transform="translate(6, 70)">
        <path d="M26,4 L6,4 C3,4 1,9 1,14 L1,18 L28,18 C28,10 28,4 26,4 Z"
              fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
        <line x1="20" y1="18" x2="20" y2="13" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
        <line x1="12" y1="18" x2="12" y2="13" stroke="{SKIN_DARK}" stroke-width="1.8" stroke-linecap="round"/>
      </g>

      <!-- 2. Maroon Trousers Pelvis & Legs (Grounded, organic brawler build) -->
      <path d="M-26,42 L26,42 L24,70 L4,70 L2,54 L-2,54 L-4,70 L-24,70 Z"
            fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
      <line x1="0" y1="42" x2="0" y2="54" stroke="{OUTLINE}" stroke-width="2.2"/>

      <!-- 3. Torso: Emerald Green Tunic + Maroon Sash -->
      <g transform="translate(-36, -26)">
        <path d="M12,4 C8,4 6,14 6,28 C6,48 12,56 20,56 L52,56 C60,56 66,48 66,28 C66,14 64,4 60,4 Z"
              fill="{TUNIC_GREEN}" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
        <path d="M26,4 Q36,16 46,4 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="2.5"/>
        <line x1="12" y1="8" x2="56" y2="48" stroke="{STRAP_LEATHER}" stroke-width="4.0" stroke-linecap="round"/>
        <line x1="12" y1="8" x2="56" y2="48" stroke="{OUTLINE}" stroke-width="1.6" stroke-linecap="round" stroke-dasharray="3 3"/>
        <rect x="8" y="44" width="56" height="12" rx="2" fill="{SASH_MAROON}" stroke="{OUTLINE}" stroke-width="3.0"/>
        <line x1="8" y1="50" x2="64" y2="50" stroke="{OUTLINE}" stroke-width="1.8"/>
      </g>

      <!-- 4. Left Arm & Hand Holding Recurve Bow -->
      <g transform="translate(-40, -24)">
        <path d="M16,4 C10,4 6,10 6,18 L7,34 C7,38 11,40 16,40 C21,40 25,38 25,34 L26,18 C26,10 22,4 16,4 Z"
              fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
        <g transform="translate(3, 34)">
          <path d="M12,3 C6,3 3,7 3,13 C3,19 7,22 12,22 C17,22 21,19 21,13 C21,10 19,7 16,5 C16,7 14,9 12,9 C10.5,9 10.5,6 12,3 Z"
                fill="{SKIN}" stroke="{OUTLINE}" stroke-width="2.8" stroke-linejoin="round"/>
        </g>
        <!-- Bow -->
        <g transform="translate(-24, -20) scale(0.65)">
          <line x1="28" y1="14" x2="28" y2="126" stroke="{BOW_STRING}" stroke-width="2.2"/>
          <path d="M28,14 C12,30 8,50 14,70 C8,90 12,110 28,126 C18,112 14,92 20,70 C14,48 18,28 28,14 Z"
                fill="{BOW_WOOD}" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
          <rect x="12" y="58" width="14" height="24" rx="2" fill="{BOW_GRIP_BLUE}" stroke="{OUTLINE}" stroke-width="2.8"/>
          <path d="M22,14 L30,4 L34,12 L38,6 L36,16 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.2"/>
          <path d="M22,126 L30,136 L34,128 L38,134 L36,124 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.2"/>
        </g>
      </g>

      <!-- 5. Right Arm with Talon Bracer -->
      <g transform="translate(18, -24)">
        <path d="M16,4 C10,4 6,10 6,18 L7,34 C7,38 11,40 16,40 C21,40 25,38 25,34 L26,18 C26,10 22,4 16,4 Z"
              fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
        <path d="M5,18 L27,18 L28,34 C28,37 22,39 16,39 C10,39 4,37 4,34 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.6" stroke-linejoin="round"/>
        <circle cx="16" cy="27" r="4.5" fill="{RING_GREEN}" stroke="{OUTLINE}" stroke-width="1.8"/>
        <g transform="translate(3, 34)">
          <path d="M12,3 C18,3 21,7 21,13 C21,19 17,22 12,22 C7,22 3,19 3,13 C3,10 5,7 8,5 C8,7 10,9 12,9 C13.5,9 13.5,6 12,3 Z"
                fill="{SKIN}" stroke="{OUTLINE}" stroke-width="2.8" stroke-linejoin="round"/>
        </g>
      </g>

      <!-- 6. Dark Navy Hair Framing Cheeks (Chunky & Bold like reference) -->
      <g transform="translate(-44, -58)">
        <path d="M16,4 C10,4 4,14 4,30 C4,46 10,58 14,60 C18,60 22,50 22,38 Z"
              fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
      </g>
      <g transform="translate(16, -58)">
        <path d="M10,4 C16,4 22,14 22,30 C22,46 16,58 12,60 C8,60 4,50 4,38 Z"
              fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
      </g>

      <!-- 7. Head & Eagle Hood -->
      <g transform="translate(-60, -112)">
        <!-- White Eagle Dome -->
        <path d="M60,6 C32,6 16,28 16,62 C16,92 34,106 60,106 C86,106 104,92 104,62 C104,28 88,6 60,6 Z"
              fill="{EAGLE_WHITE}" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
        
        <!-- Eagle Eyes on Brow Dome -->
        <g transform="translate(30, 26)">
          <path d="M2,14 L18,8 L16,18 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
          <circle cx="10" cy="13" r="2.2" fill="{OUTLINE}"/>
          <line x1="0" y1="10" x2="20" y2="4" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
        </g>
        <g transform="translate(74, 26)">
          <path d="M18,14 L2,8 L4,18 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
          <circle cx="10" cy="13" r="2.2" fill="{OUTLINE}"/>
          <line x1="20" y1="10" x2="0" y2="4" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
        </g>

        <!-- Dark Cavity Opening -->
        <ellipse cx="60" cy="74" rx="34" ry="28" fill="{SKIN_DARK}" stroke="{OUTLINE}" stroke-width="3.2"/>

        <!-- Tan Face Disc -->
        <g transform="translate(26, 44)">
          <path d="M6,14 C6,4 16,2 34,2 C52,2 62,4 62,14 C62,30 58,48 48,56 C42,60 38,60 34,60 C30,60 26,60 20,56 C10,48 6,30 6,14 Z"
                fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>

          <!-- Eyes (Authentic white cut-paper warrior eye shapes) -->
          <g transform="translate(12, 18)">
            <path d="M2,12 C6,4 14,3 18,6 C16,15 8,17 2,12 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.4" stroke-linejoin="round"/>
          </g>
          <path d="M12,16 C16,12 22,11 28,14" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" fill="none"/>

          <g transform="translate(38, 18)">
            <path d="M18,12 C14,4 6,3 2,6 C4,15 12,17 18,12 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.4" stroke-linejoin="round"/>
          </g>
          <path d="M38,14 C44,11 50,12 54,16" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" fill="none"/>

          <!-- Stoic Set Mouth -->
          <path d="M27,44 L41,44" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round"/>
        </g>

        <!-- Hooked Yellow Beak -->
        <g transform="translate(46, 20)">
          <path d="M2,8 C2,2 6,0 14,0 C22,0 26,2 26,8 C26,22 22,40 14,46 C6,40 2,22 2,8 Z"
                fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
          <line x1="14" y1="0" x2="14" y2="46" stroke="{BEAK_SHADOW}" stroke-width="1.8"/>
        </g>
      </g>
    </g>'''

# 5.1 BO VIEW FRONT
write_svg(os.path.join(REF_DIR, "bo_view_front.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
  <rect width="800" height="800" fill="#181a20"/>
  <text x="400" y="55" fill="#ffd166" font-family="system-ui, -apple-system, sans-serif" font-size="26" font-weight="bold" text-anchor="middle">BO — FRONT VIEW (PRODUCTION ASSET)</text>
  <text x="400" y="85" fill="#a0aab8" font-family="system-ui, -apple-system, sans-serif" font-size="14" text-anchor="middle">Authentic Brawl Stars Character Identity • 100% Locked to Leon &amp; Nita Paper-Cutout Art Style</text>
  <ellipse cx="400" cy="710" rx="110" ry="18" fill="#101216"/>
  {render_bo_front_group(scale=2.6, x=400, y=410)}
</svg>''')

# 5.2 BO VIEW 3/4
write_svg(os.path.join(REF_DIR, "bo_view_three_quarter.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
  <rect width="800" height="800" fill="#181a20"/>
  <text x="400" y="55" fill="#ffd166" font-family="system-ui, -apple-system, sans-serif" font-size="26" font-weight="bold" text-anchor="middle">BO — 3/4 VIEW MODEL SHEET</text>
  <text x="400" y="85" fill="#a0aab8" font-family="system-ui, -apple-system, sans-serif" font-size="14" text-anchor="middle">Perspective Proportions Locked • Recurve Bow &amp; Quiver Silhouettes Verified</text>
  <ellipse cx="400" cy="710" rx="110" ry="18" fill="#101216"/>
  <g transform="translate(400, 410) scale(2.6)">
    <!-- Quiver Silhouette Behind Left Shoulder -->
    <g transform="translate(-48, -44) rotate(-14) scale(0.65)">
      <path d="M8,26 L40,26 L36,104 C36,106 32,108 24,108 C16,108 12,106 12,104 Z" fill="{QUIVER_NAVY}" stroke="{OUTLINE}" stroke-width="3.2"/>
      <rect x="6" y="24" width="36" height="12" rx="2" fill="{QUIVER_COLLAR_WHITE}" stroke="{OUTLINE}" stroke-width="2.8"/>
      <path d="M4,16 L10,4 L16,16 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.0"/>
      <path d="M14,14 L20,2 L26,14 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.0"/>
      <path d="M22,18 L28,6 L34,18 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.0"/>
    </g>
    <!-- Feet -->
    <g transform="translate(-24, 70)"><path d="M4,4 L24,4 C27,4 29,9 29,14 L29,18 L2,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/></g>
    <g transform="translate(10, 70)"><path d="M24,4 L6,4 C3,4 1,9 1,14 L1,18 L26,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/></g>
    <!-- Legs in 3/4 -->
    <path d="M-22,42 L22,42 L20,70 L2,70 L0,54 L-4,54 L-6,70 L-20,70 Z" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
    <!-- Torso 3/4 -->
    <g transform="translate(-30, -26)">
      <path d="M10,4 C6,4 4,14 4,28 C4,48 10,56 18,56 L48,56 C56,56 62,48 62,28 C62,14 58,4 54,4 Z" fill="{TUNIC_GREEN}" stroke="{OUTLINE}" stroke-width="3.5"/>
      <line x1="8" y1="12" x2="52" y2="48" stroke="{STRAP_LEATHER}" stroke-width="4.5" stroke-linecap="round"/>
      <line x1="8" y1="12" x2="52" y2="48" stroke="{OUTLINE}" stroke-width="1.8" stroke-linecap="round" stroke-dasharray="4 3"/>
      <rect x="6" y="44" width="52" height="12" rx="2" fill="{SASH_MAROON}" stroke="{OUTLINE}" stroke-width="3.0"/>
    </g>
    <!-- Left Arm & Bow -->
    <g transform="translate(-36, -22)">
      <path d="M14,4 C9,4 5,10 5,18 L6,34 C6,38 10,40 15,40 C20,40 24,38 24,34 L25,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
      <g transform="translate(-20, -14) scale(0.6)">
        <line x1="28" y1="14" x2="28" y2="126" stroke="{BOW_STRING}" stroke-width="2.2"/>
        <path d="M28,14 C12,30 8,50 14,70 C8,90 12,110 28,126 C18,112 14,92 20,70 C14,48 18,28 28,14 Z" fill="{BOW_WOOD}" stroke="{OUTLINE}" stroke-width="3.5"/>
        <rect x="12" y="58" width="14" height="24" rx="2" fill="{BOW_GRIP_BLUE}" stroke="{OUTLINE}" stroke-width="2.8"/>
        <path d="M22,14 L30,4 L34,12 L38,6 L36,16 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.2"/>
        <path d="M22,126 L30,136 L34,128 L38,134 L36,124 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.2"/>
      </g>
    </g>
    <!-- Right Arm -->
    <g transform="translate(16, -22)">
      <path d="M14,4 C9,4 5,10 5,18 L6,34 C6,38 10,40 15,40 C20,40 24,38 24,34 L25,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
      <path d="M4,18 L24,18 L25,34 C25,37 20,39 15,39 C10,39 4,37 4,34 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.6"/>
      <circle cx="15" cy="27" r="4" fill="{RING_GREEN}" stroke="{OUTLINE}" stroke-width="1.6"/>
    </g>
    <!-- Back Hair Braid -->
    <g transform="translate(22, -64)">
      <path d="M10,4 C8,14 6,24 8,36 C10,44 8,52 12,62 C14,66 18,66 20,60 C22,50 20,40 20,30 Z" fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.0"/>
      <rect x="8" y="24" width="14" height="6" rx="2" fill="{HAIR_TIE_RED}" stroke="{OUTLINE}" stroke-width="2.0"/>
    </g>
    <!-- Head 3/4 -->
    <g transform="translate(-54, -112)">
      <path d="M54,6 C28,6 14,28 14,62 C14,92 30,106 56,106 C80,106 98,92 98,62 C98,28 82,6 54,6 Z" fill="{EAGLE_WHITE}" stroke="{OUTLINE}" stroke-width="3.5"/>
      <g transform="translate(62, 28)">
        <path d="M2,12 L16,7 L14,15 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.0"/>
        <circle cx="9" cy="11" r="2.0" fill="{OUTLINE}"/>
      </g>
      <g transform="translate(24, 44)">
        <path d="M6,14 C6,4 16,2 32,2 C46,2 54,4 56,14 C56,30 52,48 42,56 C38,60 34,60 30,60 C26,60 22,60 18,56 C10,48 6,30 6,14 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.0"/>
        <g transform="translate(12, 18)"><path d="M2,12 C6,4 14,3 18,6 C16,15 8,17 2,12 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.4"/></g>
        <path d="M24,44 L36,44" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
      </g>
      <g transform="translate(36, 22)">
        <path d="M2,6 C2,2 6,0 12,0 C18,0 22,2 22,6 C22,18 18,34 12,40 C6,34 2,18 2,6 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.8"/>
      </g>
    </g>
  </g>
</svg>''')

# 5.3 BO VIEW SIDE
write_svg(os.path.join(REF_DIR, "bo_view_side.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
  <rect width="800" height="800" fill="#181a20"/>
  <text x="400" y="55" fill="#ffd166" font-family="system-ui, -apple-system, sans-serif" font-size="26" font-weight="bold" text-anchor="middle">BO — SIDE PROFILE VIEW</text>
  <text x="400" y="85" fill="#a0aab8" font-family="system-ui, -apple-system, sans-serif" font-size="14" text-anchor="middle">Full Side Profile • Quiver, Braided Hair &amp; Recurve Bow Alignment</text>
  <ellipse cx="400" cy="710" rx="100" ry="16" fill="#101216"/>
  <g transform="translate(390, 410) scale(2.6)">
    <!-- Quiver -->
    <g transform="translate(-36, -34) rotate(-8) scale(0.65)">
      <path d="M8,26 L40,26 L36,104 C36,106 32,108 24,108 C16,108 12,106 12,104 Z" fill="{QUIVER_NAVY}" stroke="{OUTLINE}" stroke-width="3.2"/>
      <rect x="6" y="24" width="36" height="12" rx="2" fill="{QUIVER_COLLAR_WHITE}" stroke="{OUTLINE}" stroke-width="2.8"/>
      <path d="M4,16 L10,4 L16,16 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.0"/>
      <path d="M14,14 L20,2 L26,14 Z" fill="{ARROW_FLETCH_CYAN}" stroke="{OUTLINE}" stroke-width="2.0"/>
    </g>
    <!-- Braid -->
    <g transform="translate(-28, -60)">
      <path d="M10,4 C8,14 6,24 8,36 C10,46 8,56 12,68 C14,72 18,72 20,66 C22,54 20,42 20,30 Z" fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.0"/>
      <rect x="8" y="24" width="14" height="6" rx="2" fill="{HAIR_TIE_RED}" stroke="{OUTLINE}" stroke-width="2.0"/>
      <rect x="10" y="48" width="10" height="5" rx="2" fill="{HAIR_TIE_RED}" stroke="{OUTLINE}" stroke-width="1.8"/>
    </g>
    <!-- Feet -->
    <g transform="translate(-6, 70)"><path d="M2,4 L26,4 C30,4 32,10 32,14 L32,18 L0,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/></g>
    <!-- Leg Profile -->
    <path d="M-2,42 L20,42 L18,70 L0,70 Z" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
    <!-- Torso Profile -->
    <g transform="translate(-16, -26)">
      <path d="M8,4 L36,4 C42,4 46,14 46,28 C46,48 42,56 36,56 L6,56 Z" fill="{TUNIC_GREEN}" stroke="{OUTLINE}" stroke-width="3.5"/>
      <rect x="4" y="44" width="40" height="12" rx="2" fill="{SASH_MAROON}" stroke="{OUTLINE}" stroke-width="3.0"/>
    </g>
    <!-- Arm -->
    <g transform="translate(0, -22)">
      <path d="M14,4 C9,4 5,10 5,18 L6,34 C6,38 10,40 15,40 C20,40 24,38 24,34 L25,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
      <path d="M4,18 L24,18 L25,34 C25,37 20,39 15,39 C10,39 4,37 4,34 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.6"/>
    </g>
    <!-- Head -->
    <g transform="translate(-32, -112)">
      <path d="M38,6 C16,6 6,28 6,62 C6,92 20,106 44,106 C62,106 74,92 74,62 C74,28 60,6 38,6 Z" fill="{EAGLE_WHITE}" stroke="{OUTLINE}" stroke-width="3.5"/>
      <g transform="translate(18, 44)">
        <path d="M4,10 C4,4 14,2 26,2 C38,2 44,6 46,18 C46,34 40,50 32,58 C26,60 20,60 16,56 C10,50 4,30 4,10 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.0"/>
        <path d="M14,18 L28,24" stroke="{EYE_WHITE}" stroke-width="3.5" stroke-linecap="round"/>
        <path d="M22,44 L32,44" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
      </g>
      <g transform="translate(42, 24)">
        <path d="M2,10 C2,2 8,0 14,0 C20,0 26,4 28,14 C30,22 26,34 18,38 C14,38 8,28 6,22 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="3.0"/>
      </g>
    </g>
  </g>
</svg>''')

# 5.4 BO EXPRESSION & EYE STATE SHEET (800x800 Canvas, 100% Uncropped)
write_svg(os.path.join(REF_DIR, "bo_expression_sheet.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
  <rect width="800" height="800" fill="#181a20"/>
  <text x="400" y="38" fill="#ffd166" font-family="system-ui, -apple-system, sans-serif" font-size="20" font-weight="bold" text-anchor="middle">BO — EXPRESSION &amp; EYE STATE MATRIX</text>
  <text x="400" y="58" fill="#a0a8b4" font-family="system-ui, -apple-system, sans-serif" font-size="11" text-anchor="middle">Authentic Brawl Stars Character Identity • 10 Core Expressions • 6 Modular Animation-Ready Eye States</text>

  <defs>
    <!-- Reusable Mini Bo Head Base (Centered at 0, 0) -->
    <g id="mini-bo-head">
      <!-- White Eagle Dome -->
      <path d="M0,-48 C-28,-48 -44,-26 -44,8 C-44,38 -26,52 0,52 C26,52 44,38 44,8 C44,-26 28,-48 0,-48 Z" fill="{EAGLE_WHITE}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
      <!-- Eagle Eyes on Brow -->
      <g transform="translate(-30, -28)">
        <path d="M2,14 L18,8 L16,18 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.0" stroke-linejoin="round"/>
        <circle cx="10" cy="13" r="2.0" fill="{OUTLINE}"/>
        <line x1="0" y1="10" x2="20" y2="4" stroke="{OUTLINE}" stroke-width="2.2" stroke-linecap="round"/>
      </g>
      <g transform="translate(12, -28)">
        <path d="M18,14 L2,8 L4,18 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.0" stroke-linejoin="round"/>
        <circle cx="10" cy="13" r="2.0" fill="{OUTLINE}"/>
        <line x1="20" y1="10" x2="0" y2="4" stroke="{OUTLINE}" stroke-width="2.2" stroke-linecap="round"/>
      </g>
      <!-- Dark Face Cavity -->
      <ellipse cx="0" cy="20" rx="30" ry="24" fill="{SKIN_DARK}" stroke="{OUTLINE}" stroke-width="2.8"/>
      <!-- Tan Face Disc -->
      <path d="M-24,-4 C-24,-14 -14,-16 0,-16 C14,-16 24,-14 24,-4 C24,12 20,28 12,34 C6,38 0,38 -6,38 C-14,34 -24,20 -24,-4 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="2.6" stroke-linejoin="round"/>
      <!-- Hooked Yellow Beak -->
      <path d="M-10,-32 C-10,-38 -6,-40 0,-40 C6,-40 10,-38 10,-32 C10,-18 7, -2 0,4 C-7,-2 -10,-18 -10,-32 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.8" stroke-linejoin="round"/>
      <line x1="0" y1="-40" x2="0" y2="4" stroke="{BEAK_SHADOW}" stroke-width="1.6"/>
    </g>
  </defs>

  <!-- ROW 1 (y = 140): NEUTRAL, HAPPY, ANGRY, SAD, SHOCKED -->
  <!-- 1. NEUTRAL -->
  <g transform="translate(75, 140) scale(1.08)">
    <use href="#mini-bo-head"/>
    <g transform="translate(-16, 0)"><path d="M2,10 C5,3 12,2 15,5 C13,13 7,14 2,10 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/></g>
    <g transform="translate(2, 0)"><path d="M15,10 C12,3 5,2 2,5 C4,13 10,14 15,10 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/></g>
    <line x1="-8" y1="24" x2="8" y2="24" stroke="{OUTLINE}" stroke-width="2.4" stroke-linecap="round"/>
  </g>
  <text x="75" y="218" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">NEUTRAL</text>

  <!-- 2. HAPPY -->
  <g transform="translate(235, 140) scale(1.08)">
    <use href="#mini-bo-head"/>
    <path d="M-16,8 Q-10,0 -4,8" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round" fill="none"/>
    <path d="M4,8 Q10,0 16,8" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round" fill="none"/>
    <path d="M-8,22 Q0,30 8,22 Z" fill="#eb5e6d" stroke="{OUTLINE}" stroke-width="2.2"/>
  </g>
  <text x="235" y="218" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">HAPPY</text>

  <!-- 3. ANGRY -->
  <g transform="translate(400, 140) scale(1.08)">
    <use href="#mini-bo-head"/>
    <path d="M-16,4 L-4,8 L-6,14 L-16,11 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="-9" cy="9" r="2.0" fill="{OUTLINE}"/>
    <path d="M16,4 L4,8 L6,14 L16,11 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="9" cy="9" r="2.0" fill="{OUTLINE}"/>
    <rect x="-8" y="22" width="16" height="5" rx="1.5" fill="#ffffff" stroke="{OUTLINE}" stroke-width="2.0"/>
  </g>
  <text x="400" y="218" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">ANGRY</text>

  <!-- 4. SAD -->
  <g transform="translate(565, 140) scale(1.08)">
    <use href="#mini-bo-head"/>
    <ellipse cx="-10" cy="6" rx="4" ry="5" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <ellipse cx="10" cy="6" rx="4" ry="5" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="-10" cy="7" r="2.2" fill="{OUTLINE}"/>
    <circle cx="10" cy="7" r="2.2" fill="{OUTLINE}"/>
    <path d="M-8,25 Q0,19 8,25" stroke="{OUTLINE}" stroke-width="2.4" stroke-linecap="round" fill="none"/>
  </g>
  <text x="565" y="218" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">SAD</text>

  <!-- 5. SHOCKED -->
  <g transform="translate(725, 140) scale(1.08)">
    <use href="#mini-bo-head"/>
    <circle cx="-10" cy="6" r="6" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.2"/>
    <circle cx="10" cy="6" r="6" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.2"/>
    <circle cx="-10" cy="6" r="2.2" fill="{OUTLINE}"/>
    <circle cx="10" cy="6" r="2.2" fill="{OUTLINE}"/>
    <ellipse cx="0" cy="24" rx="4.5" ry="6" fill="{OUTLINE}"/>
  </g>
  <text x="725" y="218" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">SHOCKED</text>

  <!-- ROW 2 (y = 295): SCARED, HURT, CONFUSED, SMUG, SERIOUS -->
  <!-- 6. SCARED -->
  <g transform="translate(75, 295) scale(1.08)">
    <use href="#mini-bo-head"/>
    <circle cx="-10" cy="6" r="5" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="10" cy="6" r="5" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="-10" cy="6" r="1.5" fill="{OUTLINE}"/>
    <circle cx="10" cy="6" r="1.5" fill="{OUTLINE}"/>
    <ellipse cx="0" cy="24" rx="4" ry="3.5" fill="{OUTLINE}"/>
  </g>
  <text x="75" y="373" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">SCARED</text>

  <!-- 7. HURT -->
  <g transform="translate(235, 295) scale(1.08)">
    <use href="#mini-bo-head"/>
    <path d="M-15,3 L-8,7 L-15,11" stroke="{OUTLINE}" stroke-width="2.4" stroke-linecap="round" fill="none"/>
    <path d="M15,3 L8,7 L15,11" stroke="{OUTLINE}" stroke-width="2.4" stroke-linecap="round" fill="none"/>
    <path d="M-9,24 L-5,21 L0,25 L5,21 L9,24" stroke="{OUTLINE}" stroke-width="2.4" stroke-linecap="round" fill="none"/>
  </g>
  <text x="235" y="373" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">HURT</text>

  <!-- 8. CONFUSED -->
  <g transform="translate(400, 295) scale(1.08)">
    <use href="#mini-bo-head"/>
    <circle cx="-10" cy="5" r="5.5" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="-10" cy="5" r="2.0" fill="{OUTLINE}"/>
    <ellipse cx="10" cy="7" rx="3.5" ry="4" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="10" cy="7" r="1.8" fill="{OUTLINE}"/>
    <path d="M-16,-2 Q-10,-8 -4,-2" stroke="{OUTLINE}" stroke-width="2.2" stroke-linecap="round" fill="none"/>
    <path d="M4,-4 Q10,-2 16,-4" stroke="{OUTLINE}" stroke-width="2.2" stroke-linecap="round" fill="none"/>
    <path d="M-7,25 Q0,20 7,23" stroke="{OUTLINE}" stroke-width="2.4" stroke-linecap="round" fill="none"/>
  </g>
  <text x="400" y="373" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">CONFUSED</text>

  <!-- 9. SMUG -->
  <g transform="translate(565, 295) scale(1.08)">
    <use href="#mini-bo-head"/>
    <path d="M-15,8 Q-9,2 -3,8" stroke="{OUTLINE}" stroke-width="2.4" stroke-linecap="round" fill="none"/>
    <ellipse cx="10" cy="6" rx="4" ry="4.5" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="10" cy="6" r="2.0" fill="{OUTLINE}"/>
    <path d="M-6,25 Q2,26 8,20" stroke="{OUTLINE}" stroke-width="2.4" stroke-linecap="round" fill="none"/>
  </g>
  <text x="565" y="373" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">SMUG</text>

  <!-- 10. SERIOUS -->
  <g transform="translate(725, 295) scale(1.08)">
    <use href="#mini-bo-head"/>
    <line x1="-16" y1="2" x2="-4" y2="4" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
    <line x1="4" y1="4" x2="16" y2="2" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
    <g transform="translate(-16, 2)"><path d="M2,10 C5,3 12,2 15,5 C13,13 7,14 2,10 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/></g>
    <g transform="translate(2, 2)"><path d="M15,10 C12,3 5,2 2,5 C4,13 10,14 15,10 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/></g>
    <line x1="-10" y1="24" x2="10" y2="24" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round"/>
  </g>
  <text x="725" y="373" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">SERIOUS</text>

  <!-- BOTTOM CARD: 6 MODULAR EYE STATE PRESETS -->
  <rect x="30" y="430" width="740" height="330" rx="14" fill="#121418" stroke="#2a2f3a" stroke-width="1.5"/>
  <text x="400" y="468" fill="#ffd166" font-family="sans-serif" font-size="14" font-weight="bold" text-anchor="middle">6 MODULAR EYE STATE PRESETS (GODOT ANIMATION-READY)</text>
  <text x="400" y="490" fill="#a0a8b4" font-family="sans-serif" font-size="11" text-anchor="middle">Sprite2D / Texture Swapping Presets • Shared Standard Matrix with Leon &amp; Nita</text>

  <!-- 1. Neutral Eye Preset -->
  <g transform="translate(85, 600) scale(1.9)">
    <ellipse cx="0" cy="0" rx="8" ry="11" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="0" cy="0" r="4.5" fill="{OUTLINE}"/>
  </g>
  <text x="85" y="670" fill="#a0aab8" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">NEUTRAL</text>

  <!-- 2. Blink Eye Preset -->
  <g transform="translate(210, 600) scale(1.9)">
    <path d="M-10,0 Q0,7 10,0" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" fill="none"/>
  </g>
  <text x="210" y="670" fill="#a0aab8" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">BLINK</text>

  <!-- 3. Wide Eye Preset -->
  <g transform="translate(335, 600) scale(1.9)">
    <circle cx="0" cy="0" r="12" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="0" cy="0" r="4.5" fill="{OUTLINE}"/>
  </g>
  <text x="335" y="670" fill="#a0aab8" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">WIDE</text>

  <!-- 4. Angry Eye Preset -->
  <g transform="translate(465, 600) scale(1.9)">
    <path d="M-10,-6 L10,0 L8,9 L-10,5 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
    <circle cx="2" cy="1" r="3.5" fill="{OUTLINE}"/>
  </g>
  <text x="465" y="670" fill="#a0aab8" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">ANGRY</text>

  <!-- 5. Happy Eye Preset -->
  <g transform="translate(590, 600) scale(1.9)">
    <path d="M-10,3 Q0,-6 10,3" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" fill="none"/>
  </g>
  <text x="590" y="670" fill="#a0aab8" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">HAPPY</text>
    <g transform="translate(715, 600) scale(1.9)">
    <line x1="-10" y1="0" x2="10" y2="0" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round"/>
  </g>
  <text x="715" y="670" fill="#a0aab8" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">CLOSED</text>
</svg>''')

# 5.5 BO KEY ACTION POSES (800x800 Canvas, 10 Production Poses)
def render_full_bo_character(x, y, scale=0.92, rot=0, leg_l_rot=0, leg_r_rot=0,
                             arm_l_rot=0, arm_r_rot=0, bow_rot=0, bow_drawn=False,
                             arrow_flying=False, hurt=False, jump_air=False,
                             crouch=False, knockback=False):
    shadow_rx = 44 if not jump_air and not crouch else (24 if jump_air else 52)
    shadow_ry = 8 if not crouch else 10
    shadow_y = y + 95
    y_off = -22 if jump_air else (15 if crouch else 0)
    
    # Eye shape choice
    if hurt or knockback:
        face_features_svg = f'''
          <path d="M14,20 L22,24 L14,28" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round" fill="none"/>
          <path d="M54,20 L46,24 L54,28" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round" fill="none"/>
          <path d="M26,44 L30,41 L34,45 L38,41 L42,44" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round" fill="none"/>'''
    else:
        face_features_svg = f'''
          <g transform="translate(12, 18)">
            <path d="M2,12 C6,4 14,3 18,6 C16,15 8,17 2,12 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.4" stroke-linejoin="round"/>
          </g>
          <path d="M12,16 C16,12 22,11 28,14" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" fill="none"/>
          <g transform="translate(38, 18)">
            <path d="M18,12 C14,4 6,3 2,6 C4,15 12,17 18,12 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.4" stroke-linejoin="round"/>
          </g>
          <path d="M38,14 C44,11 50,12 54,16" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" fill="none"/>
          <path d="M27,44 L41,44" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round"/>'''

    # Bow string state
    if bow_drawn:
        bow_string_svg = f'<path d="M28,14 L80,70 L28,126" stroke="{BOW_STRING}" stroke-width="2.6" fill="none"/>'
        arrow_svg = f'''
          <g transform="translate(24, 70)">
            <line x1="-36" y1="0" x2="60" y2="0" stroke="{BOW_WOOD}" stroke-width="3.6"/>
            <polygon points="-46,0 -34,-6 -34,6" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
            <polygon points="60,0 50,-7 52,0" fill="{ARROW_FLETCH_CYAN}"/>
            <polygon points="60,0 50,7 52,0" fill="{ARROW_FLETCH_CYAN}"/>
          </g>'''
    else:
        bow_string_svg = f'<line x1="28" y1="14" x2="28" y2="126" stroke="{BOW_STRING}" stroke-width="2.2"/>'
        arrow_svg = ''

    # Projectile flying
    projectile_svg = ''
    if arrow_flying:
        projectile_svg = f'''
          <g transform="translate(32, -8)">
            <line x1="0" y1="0" x2="48" y2="0" stroke="{BOW_WOOD}" stroke-width="3.6"/>
            <polygon points="56,0 44,-6 44,6" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.0"/>
            <polygon points="2,0 -8,-7 -4,0" fill="{ARROW_FLETCH_CYAN}"/>
            <polygon points="2,0 -8,7 -4,0" fill="{ARROW_FLETCH_CYAN}"/>
            <line x1="-24" y1="0" x2="-8" y2="0" stroke="{ARROW_FLETCH_CYAN}" stroke-width="2.0" stroke-dasharray="4 4"/>
          </g>'''

    # Crouch scaling
    torso_scale_y = 0.85 if crouch else 1.0

    return f'''
    <!-- Ground Shadow -->
    <ellipse cx="{x}" cy="{shadow_y}" rx="{shadow_rx}" ry="{shadow_ry}" fill="#101216"/>

    <!-- Bo Main Group -->
    <g transform="translate({x}, {y + y_off}) scale({scale}) rotate({rot})">
      {projectile_svg}
      <!-- 1. Left Leg & Foot -->
      <g transform="rotate({leg_l_rot}, -10, 42)">
        <rect x="-24" y="42" width="18" height="28" rx="2" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2"/>
        <g transform="translate(-28, 68)">
          <path d="M4,4 L24,4 C27,4 29,9 29,14 L29,18 L2,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
        </g>
      </g>

      <!-- 2. Right Leg & Foot -->
      <g transform="rotate({leg_r_rot}, 10, 42)">
        <rect x="6" y="42" width="18" height="28" rx="2" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.2"/>
        <g transform="translate(6, 68)">
          <path d="M26,4 L6,4 C3,4 1,9 1,14 L1,18 L28,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
        </g>
      </g>

      <!-- 3. Pelvis Trousers Base -->
      <path d="M-24,40 L24,40 L22,54 L-22,54 Z" fill="{PANTS_MAROON}" stroke="{OUTLINE}" stroke-width="3.0"/>

      <!-- 4. Torso with Green Tunic & Maroon Sash -->
      <g transform="scale(1, {torso_scale_y})">
        <g transform="translate(-36, -26)">
          <path d="M12,4 C8,4 6,14 6,28 C6,48 12,56 20,56 L52,56 C60,56 66,48 66,28 C66,14 64,4 60,4 Z" fill="{TUNIC_GREEN}" stroke="{OUTLINE}" stroke-width="3.5"/>
          <line x1="12" y1="8" x2="56" y2="48" stroke="{STRAP_LEATHER}" stroke-width="4.0" stroke-linecap="round"/>
          <line x1="12" y1="8" x2="56" y2="48" stroke="{OUTLINE}" stroke-width="1.6" stroke-linecap="round" stroke-dasharray="3 3"/>
          <rect x="8" y="44" width="56" height="12" rx="2" fill="{SASH_MAROON}" stroke="{OUTLINE}" stroke-width="3.0"/>
        </g>
      </g>

      <!-- 5. Left Arm with Recurve Bow -->
      <g transform="translate(-38, -20) rotate({arm_l_rot}, 0, 0)">
        <path d="M16,4 C10,4 6,10 6,18 L7,34 C7,38 11,40 16,40 C21,40 25,38 25,34 L26,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
        <g transform="translate(-24, -10) rotate({bow_rot}) scale(0.65)">
          {bow_string_svg}
          <path d="M28,14 C12,30 8,50 14,70 C8,90 12,110 28,126 C18,112 14,92 20,70 C14,48 18,28 28,14 Z" fill="{BOW_WOOD}" stroke="{OUTLINE}" stroke-width="3.5"/>
          <rect x="12" y="58" width="14" height="24" rx="2" fill="{BOW_GRIP_BLUE}" stroke="{OUTLINE}" stroke-width="2.8"/>
          <path d="M22,14 L30,4 L34,12 L38,6 L36,16 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.2"/>
          <path d="M22,126 L30,136 L34,128 L38,134 L36,124 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.2"/>
          {arrow_svg}
        </g>
      </g>

      <!-- 6. Right Arm with Talon Bracer -->
      <g transform="translate(16, -20) rotate({arm_r_rot}, 0, 0)">
        <path d="M16,4 C10,4 6,10 6,18 L7,34 C7,38 11,40 16,40 C21,40 25,38 25,34 L26,18 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
        <path d="M5,18 L27,18 L28,34 C28,37 22,39 16,39 C10,39 4,37 4,34 Z" fill="{TALON_WHITE}" stroke="{OUTLINE}" stroke-width="2.6"/>
        <circle cx="16" cy="27" r="4.5" fill="{RING_GREEN}" stroke="{OUTLINE}" stroke-width="1.8"/>
      </g>

      <!-- 7. Hair Locks Framing Face -->
      <g transform="translate(-44, -58)">
        <path d="M16,4 C10,4 4,14 4,30 C4,46 10,58 14,60 C18,60 22,50 22,38 Z" fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.2"/>
      </g>
      <g transform="translate(16, -58)">
        <path d="M10,4 C16,4 22,14 22,30 C22,46 16,58 12,60 C8,60 4,50 4,38 Z" fill="{HAIR_NAVY}" stroke="{OUTLINE}" stroke-width="3.2"/>
      </g>

      <!-- 8. Head, Eagle Hood & Face -->
      <g transform="translate(-60, -112)">
        <!-- White Eagle Dome -->
        <path d="M60,6 C32,6 16,28 16,62 C16,92 34,106 60,106 C86,106 104,92 104,62 C104,28 88,6 60,6 Z" fill="{EAGLE_WHITE}" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
        <!-- Eagle Eyes on Hood Brow -->
        <g transform="translate(30, 26)">
          <path d="M2,14 L18,8 L16,18 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
          <circle cx="10" cy="13" r="2.2" fill="{OUTLINE}"/>
          <line x1="0" y1="10" x2="20" y2="4" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
        </g>
        <g transform="translate(74, 26)">
          <path d="M18,14 L2,8 L4,18 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="2.2" stroke-linejoin="round"/>
          <circle cx="10" cy="13" r="2.2" fill="{OUTLINE}"/>
          <line x1="20" y1="10" x2="0" y2="4" stroke="{OUTLINE}" stroke-width="2.6" stroke-linecap="round"/>
        </g>
        <!-- Dark Cavity -->
        <ellipse cx="60" cy="74" rx="34" ry="28" fill="{SKIN_DARK}" stroke="{OUTLINE}" stroke-width="3.2"/>
        <!-- Face Disc -->
        <g transform="translate(26, 44)">
          <path d="M6,14 C6,4 16,2 34,2 C52,2 62,4 62,14 C62,30 58,48 48,56 C42,60 38,60 34,60 C30,60 26,60 20,56 C10,48 6,30 6,14 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.0" stroke-linejoin="round"/>
          {face_features_svg}
        </g>
        <!-- Hooked Yellow Beak -->
        <g transform="translate(46, 20)">
          <path d="M2,8 C2,2 6,0 14,0 C22,0 26,2 26,8 C26,22 22,40 14,46 C6,40 2,22 2,8 Z" fill="{BEAK_YELLOW}" stroke="{OUTLINE}" stroke-width="3.0"/>
          <line x1="14" y1="0" x2="14" y2="46" stroke="{BEAK_SHADOW}" stroke-width="1.8"/>
        </g>
      </g>
    </g>'''

write_svg(os.path.join(REF_DIR, "bo_pose_sheet.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
  <rect width="800" height="800" fill="#181a20"/>
  <text x="400" y="36" fill="#ffd166" font-family="system-ui, -apple-system, sans-serif" font-size="20" font-weight="bold" text-anchor="middle">BO — KEY ACTION POSES (ASSET &amp; ANIMATION REFERENCE)</text>
  <text x="400" y="56" fill="#a0a8b4" font-family="system-ui, -apple-system, sans-serif" font-size="11" text-anchor="middle">Neutral • Walk • Run • Jump • Atk Anticipation • Attack (Release) • Follow-Through • Hit • Knockback • Landing</text>

  <!-- ROW 1 (y = 200): NEUTRAL, WALK, RUN, JUMP, ATK ANTICIPATION -->
  <!-- 1. NEUTRAL -->
  {render_full_bo_character(75, 200, scale=0.92)}
  <text x="75" y="325" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">NEUTRAL</text>

  <!-- 2. WALK -->
  {render_full_bo_character(235, 200, scale=0.92, leg_l_rot=-20, leg_r_rot=22, arm_l_rot=15, arm_r_rot=-15, bow_rot=10)}
  <text x="235" y="325" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">WALK</text>

  <!-- 3. RUN -->
  {render_full_bo_character(400, 200, scale=0.92, rot=12, leg_l_rot=-36, leg_r_rot=38, arm_l_rot=-22, arm_r_rot=25, bow_rot=-15)}
  <text x="400" y="325" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">RUN</text>

  <!-- 4. JUMP -->
  {render_full_bo_character(565, 200, scale=0.92, jump_air=True, leg_l_rot=-22, leg_r_rot=22, arm_l_rot=-25, arm_r_rot=-25, bow_rot=-20)}
  <text x="565" y="325" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">JUMP</text>

  <!-- 5. ATK ANTICIPATION -->
  {render_full_bo_character(725, 200, scale=0.92, rot=4, arm_l_rot=45, arm_r_rot=-35, bow_rot=30, bow_drawn=True)}
  <text x="725" y="325" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">ATK ANTICIPATION</text>

  <!-- ROW 2 (y = 530): ATTACK, FOLLOW-THROUGH, HIT REACTION, KNOCKBACK, LANDING -->
  <!-- 6. ATTACK (RELEASE) -->
  {render_full_bo_character(75, 530, scale=0.92, arm_l_rot=50, arm_r_rot=-10, bow_rot=35, arrow_flying=True)}
  <text x="75" y="655" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">ATTACK (RELEASE)</text>

  <!-- 7. FOLLOW-THROUGH -->
  {render_full_bo_character(235, 530, scale=0.92, rot=3, arm_l_rot=20, arm_r_rot=-15, bow_rot=15)}
  <text x="235" y="655" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">FOLLOW-THROUGH</text>

  <!-- 8. HIT REACTION -->
  {render_full_bo_character(400, 530, scale=0.92, rot=-14, hurt=True, arm_l_rot=-20, arm_r_rot=25, bow_rot=-25)}
  <text x="400" y="655" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">HIT REACTION</text>

  <!-- 9. KNOCKBACK -->
  {render_full_bo_character(565, 530, scale=0.92, rot=-26, jump_air=True, knockback=True, leg_l_rot=30, leg_r_rot=15, arm_l_rot=-35, arm_r_rot=40, bow_rot=-30)}
  <text x="565" y="655" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">KNOCKBACK</text>

  <!-- 10. LANDING (CROUCH) -->
  {render_full_bo_character(725, 530, scale=0.92, crouch=True, leg_l_rot=24, leg_r_rot=-24, arm_l_rot=30, arm_r_rot=-20, bow_rot=45)}
  <text x="725" y="655" fill="#ffd166" font-family="sans-serif" font-size="11" font-weight="bold" text-anchor="middle">LANDING (CROUCH)</text>
</svg>''')

# 5.6 THREE-CHARACTER STYLE SHEET (800x800 Canvas for 100% Uncropped Square Thumbnailing)
write_svg(os.path.join(REF_DIR, "bo_three_character_style_sheet.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
  <rect width="800" height="800" fill="#181a20"/>
  <text x="400" y="48" fill="#ffd166" font-family="system-ui, -apple-system, sans-serif" font-size="20" font-weight="bold" text-anchor="middle">TRIO PRODUCTION STYLE VALIDATION: LEON ↔ NITA ↔ BO</text>
  <text x="400" y="74" fill="#a0aab8" font-family="system-ui, -apple-system, sans-serif" font-size="12" text-anchor="middle">Identical #1e1e2c Outlines • Shared Proportion Philosophy • Harmonized Cel-Palette • 100% Shared 2D Universe</text>

  <!-- Ground Shadows -->
  <ellipse cx="150" cy="610" rx="76" ry="14" fill="#101216"/>
  <ellipse cx="400" cy="610" rx="76" ry="14" fill="#101216"/>
  <ellipse cx="650" cy="610" rx="80" ry="14" fill="#101216"/>

  <!-- Dividers -->
  <line x1="275" y1="100" x2="275" y2="660" stroke="#2a2f3a" stroke-width="1.5" stroke-dasharray="4 4"/>
  <line x1="525" y1="100" x2="525" y2="660" stroke="#2a2f3a" stroke-width="1.5" stroke-dasharray="4 4"/>

  <!-- 1. LEON (x = 150) -->
  <g transform="translate(150, 420) scale(1.7)">
    <g transform="translate(-24, 70)">
      <polygon points="-5,-4 15,-4 17,10 -7,10" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
      <line x1="-7" y1="10" x2="17" y2="10" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round"/>
    </g>
    <g transform="translate(24, 70)">
      <polygon points="-15,-4 5,-4 7,10 -17,10" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
      <line x1="-17" y1="10" x2="7" y2="10" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round"/>
    </g>
    <rect x="-21" y="55" width="16" height="15" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
    <rect x="5" y="55" width="16" height="15" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/>
    <path d="M-24,30 L-2,30 L-1,56 L-26,56 Z" fill="#1f3160" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
    <path d="M2,30 L24,30 L26,56 L1,56 Z" fill="#1f3160" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
    <g transform="translate(-38, -25)">
      <path d="M12,4 C8,4 6,14 6,28 C6,46 12,54 20,54 L56,54 C64,54 70,46 70,28 C70,14 68,4 64,4 Z" fill="#38b000" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
      <line x1="38" y1="4" x2="38" y2="54" stroke="{OUTLINE}" stroke-width="2.5"/>
      <path d="M22,32 L54,32 L58,54 L18,54 Z" fill="#1e90ff" stroke="{OUTLINE}" stroke-width="3.2" stroke-linejoin="round"/>
      <rect x="35" y="16" width="6" height="12" rx="2" fill="#ced4da" stroke="{OUTLINE}" stroke-width="2.0"/>
    </g>
    <g transform="translate(-36, -24)">
      <path d="M15,4 C8,4 4,9 4,16 L5,30 C5,34 9,36 15,36 C21,36 25,34 25,30 L26,16 Z" fill="#38b000" stroke="{OUTLINE}" stroke-width="3.2"/>
      <circle cx="14" cy="40" r="8" fill="#1e90ff" stroke="{OUTLINE}" stroke-width="2.8"/>
    </g>
    <g transform="translate(14, -24)">
      <path d="M15,4 C8,4 4,9 4,16 L5,30 C5,34 9,36 15,36 C21,36 25,34 25,30 L26,16 Z" fill="#38b000" stroke="{OUTLINE}" stroke-width="3.2"/>
      <circle cx="14" cy="40" r="8" fill="#1e90ff" stroke="{OUTLINE}" stroke-width="2.8"/>
    </g>
    <g transform="translate(-64, -108)">
      <circle cx="24" cy="38" r="16" fill="#38b000" stroke="{OUTLINE}" stroke-width="3.5"/>
      <circle cx="104" cy="38" r="16" fill="#38b000" stroke="{OUTLINE}" stroke-width="3.5"/>
      <path d="M64,6 C30,6 12,28 12,64 C12,94 32,114 64,114 C96,114 116,94 116,64 C116,28 98,6 64,6 Z" fill="#38b000" stroke="{OUTLINE}" stroke-width="3.5" stroke-linejoin="round"/>
      <path d="M54,6 C58,6 59,32 58,52 L70,52 C69,32 70,6 74,6 Z" fill="#ffd166" stroke="{OUTLINE}" stroke-width="2.5"/>
      <circle cx="28" cy="40" r="14" fill="#1e90ff" stroke="{OUTLINE}" stroke-width="3.5"/>
      <circle cx="28" cy="40" r="10" fill="#0077b6"/>
      <line x1="22" y1="34" x2="34" y2="46" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round"/>
      <line x1="34" y1="34" x2="22" y2="46" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round"/>
      <circle cx="100" cy="40" r="14" fill="#1e90ff" stroke="{OUTLINE}" stroke-width="3.5"/>
      <circle cx="100" cy="40" r="10" fill="#0077b6"/>
      <line x1="94" y1="34" x2="106" y2="46" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round"/>
      <line x1="106" y1="34" x2="94" y2="46" stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round"/>
      <ellipse cx="64" cy="74" rx="36" ry="32" fill="#1a2512" stroke="{OUTLINE}" stroke-width="3.5"/>
      <g transform="translate(28, 48)">
        <ellipse cx="36" cy="26" rx="32" ry="24" fill="{SKIN}"/>
        <path d="M26,30 Q36,36 46,30" stroke="{OUTLINE}" stroke-width="3.0" stroke-linecap="round" fill="none"/>
        <line x1="42" y1="31" x2="54" y2="40" stroke="#ffffff" stroke-width="3.0" stroke-linecap="round"/>
        <circle cx="43" cy="32" r="5" fill="#e63946" stroke="{OUTLINE}" stroke-width="2.0"/>
      </g>
    </g>
  </g>
  <text x="150" y="675" fill="#ffd166" font-family="system-ui, sans-serif" font-size="15" font-weight="bold" text-anchor="middle">LEON (REFERENCE A)</text>

  <!-- 2. NITA (x = 400) -->
  <g transform="translate(400, 410) scale(1.7)">
    <g transform="translate(-32, 70)"><path d="M4,4 L22,4 C25,4 27,9 27,13 L27,17 L2,17 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/></g>
    <g transform="translate(8, 70)"><path d="M26,4 L8,4 C5,4 3,9 3,13 L3,17 L28,17 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/></g>
    <rect x="-26" y="44" width="20" height="28" rx="2" fill="#7a2828" stroke="{OUTLINE}" stroke-width="3.2"/>
    <rect x="6" y="44" width="20" height="28" rx="2" fill="#7a2828" stroke="{OUTLINE}" stroke-width="3.2"/>
    <g transform="translate(-38, 20)">
      <path d="M10,2 L66,2 L71,28 L5,28 Z" fill="#48cae4" stroke="{OUTLINE}" stroke-width="3.2"/>
      <path d="M12,2 L64,2 L60,18 L38,27 L16,18 Z" fill="#06d6a0" stroke="{OUTLINE}" stroke-width="3.2"/>
    </g>
    <g transform="translate(-38, -32)">
      <path d="M14,4 C10,4 8,14 8,28 C8,46 14,54 20,54 L56,54 C62,54 68,46 68,28 C68,14 66,4 62,4 Z" fill="#06d6a0" stroke="{OUTLINE}" stroke-width="3.5"/>
      <circle cx="38" cy="27" r="8" fill="#48cae4" stroke="{OUTLINE}" stroke-width="2.5"/>
      <rect x="14" y="44" width="48" height="10" rx="2" fill="#4a2e1b" stroke="{OUTLINE}" stroke-width="3.0"/>
    </g>
    <g transform="translate(-40, -30)"><path d="M15,4 C9,4 5,9 5,16 L6,30 C6,34 10,36 15,36 C20,36 24,34 24,30 L25,16 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/></g>
    <g transform="translate(15, -30)"><path d="M15,4 C9,4 5,9 5,16 L6,30 C6,34 10,36 15,36 C20,36 24,34 24,30 L25,16 Z" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="3.2"/></g>
    <g transform="translate(-64, -114)">
      <circle cx="26" cy="34" r="16" fill="#d93848" stroke="{OUTLINE}" stroke-width="3.5"/>
      <circle cx="102" cy="34" r="16" fill="#d93848" stroke="{OUTLINE}" stroke-width="3.5"/>
      <path d="M64,6 C30,6 12,28 12,64 C12,94 32,114 64,114 C96,114 116,94 116,64 C116,28 98,6 64,6 Z" fill="#d93848" stroke="{OUTLINE}" stroke-width="3.5"/>
      <line x1="26" y1="24" x2="42" y2="40" stroke="{OUTLINE}" stroke-width="4.2" stroke-linecap="round"/>
      <line x1="42" y1="24" x2="26" y2="40" stroke="{OUTLINE}" stroke-width="4.2" stroke-linecap="round"/>
      <line x1="86" y1="24" x2="102" y2="40" stroke="{OUTLINE}" stroke-width="4.2" stroke-linecap="round"/>
      <line x1="102" y1="24" x2="86" y2="40" stroke="{OUTLINE}" stroke-width="4.2" stroke-linecap="round"/>
      <ellipse cx="64" cy="48" rx="25" ry="15" fill="#eb5e6d" stroke="{OUTLINE}" stroke-width="3.2"/>
      <path d="M55,43 C55,38 60,36 64,36 C68,36 73,38 73,43 C73,49 68,52 64,52 Z" fill="{OUTLINE}"/>
      <ellipse cx="64" cy="78" rx="36" ry="30" fill="#6e1f28" stroke="{OUTLINE}" stroke-width="3.5"/>
      <g transform="translate(26, 48)">
        <ellipse cx="38" cy="34" rx="34" ry="30" fill="{SKIN}"/>
        <path d="M10,24 C14,12 24,6 38,6 C52,6 62,12 66,24 Z" fill="#3a2015"/>
        <path d="M6,32 C6,23 18,21 38,21 C58,21 70,23 70,32 Z" fill="#4a2818"/>
        <g transform="translate(10, 22)">
          <path d="M4,15 C8,4 18,3 24,6 C22,17 12,21 4,15 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.6"/>
          <ellipse cx="14" cy="11" rx="4.5" ry="5.5" fill="{OUTLINE}"/>
        </g>
        <g transform="translate(42, 22)">
          <path d="M24,15 C20,4 10,3 4,6 C6,17 16,21 24,15 Z" fill="{EYE_WHITE}" stroke="{OUTLINE}" stroke-width="2.6"/>
          <ellipse cx="12" cy="11" rx="4.5" ry="5.5" fill="{OUTLINE}"/>
        </g>
        <path d="M28,48 Q38,54 48,48" stroke="{OUTLINE}" stroke-width="2.8" stroke-linecap="round" fill="none"/>
      </g>
    </g>
  </g>
  <text x="400" y="675" fill="#ffd166" font-family="system-ui, sans-serif" font-size="15" font-weight="bold" text-anchor="middle">NITA (REFERENCE B)</text>

  <!-- 3. BO (x = 650) -->
  {render_bo_front_group(scale=1.7, x=650, y=410)}
  <text x="650" y="675" fill="#ffd166" font-family="system-ui, sans-serif" font-size="15" font-weight="bold" text-anchor="middle">BO (PRODUCTION ASSET)</text>
</svg>''')

# 5.7 BO SILHOUETTE TEST (800x800 Canvas, Centered Without Overlap)
write_svg(os.path.join(REF_DIR, "bo_silhouette_test.svg"), f'''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
  <rect width="800" height="800" fill="#ffffff"/>
  <text x="400" y="48" fill="#14171d" font-family="system-ui, -apple-system, sans-serif" font-size="20" font-weight="900" text-anchor="middle">BLACK SILHOUETTE READABILITY TEST: LEON ↔ NITA ↔ BO</text>
  <text x="400" y="74" fill="#555a66" font-family="system-ui, -apple-system, sans-serif" font-size="12" text-anchor="middle">Instant 0.1s Readability • Unique Shape Language • Same Oversized-Head / Compact-Body Philosophy</text>

  <line x1="60" y1="630" x2="740" y2="630" stroke="#d0d5dd" stroke-width="2"/>

  <!-- LEON SILHOUETTE (x = 150) -->
  <g transform="translate(150, 420) scale(1.7)" fill="#14171d" stroke="#14171d" stroke-width="2">
    <g transform="translate(-64, 0)">
      <circle cx="24" cy="-70" r="18"/>
      <circle cx="104" cy="-70" r="18"/>
      <ellipse cx="64" cy="-44" rx="52" ry="54"/>
      <rect x="26" y="6" width="76" height="52" rx="12"/>
      <path d="M22,30 C6,30 2,46 14,56 C24,62 30,56 26,46 Z"/>
      <rect x="36" y="58" width="18" height="26"/>
      <rect x="74" y="58" width="18" height="26"/>
      <rect x="28" y="78" width="28" height="14" rx="3"/>
      <rect x="72" y="78" width="28" height="14" rx="3"/>
    </g>
  </g>
  <text x="150" y="680" fill="#14171d" font-family="system-ui, sans-serif" font-size="15" font-weight="900" text-anchor="middle">LEON SILHOUETTE</text>

  <!-- NITA SILHOUETTE (x = 400) -->
  <g transform="translate(400, 410) scale(1.7)" fill="#14171d" stroke="#14171d" stroke-width="2">
    <g transform="translate(-64, 0)">
      <circle cx="26" cy="-80" r="18"/>
      <circle cx="102" cy="-80" r="18"/>
      <ellipse cx="64" cy="-50" rx="52" ry="54"/>
      <ellipse cx="64" cy="-66" rx="26" ry="16"/>
      <rect x="30" y="2" width="68" height="48" rx="8"/>
      <polygon points="18,50 110,50 116,74 12,74"/>
      <rect x="34" y="74" width="20" height="24"/>
      <rect x="74" y="74" width="20" height="24"/>
      <rect x="28" y="92" width="28" height="14" rx="3"/>
      <rect x="72" y="92" width="28" height="14" rx="3"/>
    </g>
  </g>
  <text x="400" y="680" fill="#14171d" font-family="system-ui, sans-serif" font-size="15" font-weight="900" text-anchor="middle">NITA SILHOUETTE</text>

  <!-- BO SILHOUETTE (x = 650) -->
  <g transform="translate(650, 410) scale(1.7)" fill="#14171d" stroke="#14171d" stroke-width="2">
    <ellipse cx="0" cy="-52" rx="46" ry="50"/>
    <path d="M-14,-28 C-14,-12 -8,4 0,10 C8,4 14,-12 14,-28 Z"/>
    <path d="M24,-24 C30,-12 32,8 28,24 L18,24 Z"/>
    <path d="M-24,-24 C-30,-12 -32,8 -28,24 L-18,24 Z"/>
    <rect x="-24" y="-2" width="48" height="42" rx="6"/>
    <rect x="-25" y="40" width="50" height="8" rx="2"/>
    <rect x="-34" y="-2" width="12" height="36" rx="6"/>
    <rect x="22" y="-2" width="12" height="36" rx="6"/>
    <path d="M-38,-26 C-46,0 -46,30 -38,54" stroke-width="6" fill="none"/>
    <rect x="-22" y="48" width="18" height="28"/>
    <rect x="4" y="48" width="18" height="28"/>
    <rect x="-26" y="76" width="22" height="12" rx="2"/>
    <rect x="4" y="76" width="22" height="12" rx="2"/>
  </g>
  <text x="650" y="680" fill="#14171d" font-family="system-ui, sans-serif" font-size="15" font-weight="900" text-anchor="middle">BO SILHOUETTE</text>
</svg>''')

print(f"Successfully generated {len(created_files)} Bo SVG assets.")
