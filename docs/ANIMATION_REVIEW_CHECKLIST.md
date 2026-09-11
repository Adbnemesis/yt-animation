# Animation Production Review Checklist
**Document Purpose:** Machine-readable & human-verifiable quality assurance checklist for Godot 2D cutout animated sequences.  
**Standard:** Locked against `docs/ANIMATION_PRINCIPLES.md` and `docs/ANIMATION_CONTRACT.md`.

---

## Instructions for Reviewers & AI Agents
Every scene or shot sequence produced in the pipeline must be audited against each gatekeeper check below.
- **PASS:** Meets or exceeds the production standard.
- **FAIL:** Violates the principle; sequence must be revised before final render export.

---

| Category | Check Item | Status (PASS/FAIL) | Evaluation Criteria & Remediation Notes |
| :--- | :--- | :--- | :--- |
| **Story & Narrative** | **Visual Story Clarity** | `[PASS / FAIL]` | The narrative beat, threat, and resolution are 100% understandable with audio muted. |
| **Story & Narrative** | **Character Intention** | `[PASS / FAIL]` | Every character action has a visible, motivated goal (no random wandering or unmotivated fidgeting). |
| **Story & Narrative** | **Cause and Effect** | `[PASS / FAIL]` | Every physical event is directly caused by a preceding action in the scene. |
| **Staging & Geography** | **Anti-1D Staging** | `[PASS / FAIL]` | Characters occupy distinct depth planes ($Y / Z$); they DO NOT all stand on a single horizontal line. |
| **Staging & Geography** | **Silhouette Readability** | `[PASS / FAIL]` | Key poses read with absolute clarity when filled with solid black (`#000000`) in under 0.1s. |
| **Staging & Geography** | **Composition & Negative Space** | `[PASS / FAIL]` | Primary action occurs in open negative space; actors form dynamic staging triangles. |
| **Staging & Geography** | **Screen Direction Continuity** | `[PASS / FAIL]` | 180-degree rule respected; heroes travel Screen-Right, enemies face Screen-Left unless turning. |
| **Depth & Scale** | **Distance-Based Scale** | `[PASS / FAIL]` | Characters in background lanes scale down ($\approx 0.80 - 0.85$); foreground characters scale up ($\approx 1.15 - 1.25$). |
| **Depth & Scale** | **Multiplane Layering** | `[PASS / FAIL]` | Foreground, midground, and background planes exist with appropriate visual occlusion. |
| **Depth & Scale** | **Ground Contact & Shadows** | `[PASS / FAIL]` | Feet lock to ground without slipping; contact shadows anchor characters to the floor plane. |
| **Timing & Spacing** | **Reaction Windows** | `[PASS / FAIL]` | $0.3\text{s} - 0.6\text{s}$ cognitive processing reaction windows exist after major strikes/reveals. |
| **Timing & Spacing** | **Zero Dead Pauses** | `[PASS / FAIL]` | No character stands frozen in an unmotivated idle pose for $> 0.8\text{s}$. |
| **Timing & Spacing** | **Snappy Easing & Spacing** | `[PASS / FAIL]` | Movements accelerate into strikes (Slow-Out) and ease into settles; no linear floating. |
| **Mechanics & Physics** | **Solid Geometry Obstruction** | `[PASS / FAIL]` | Characters, limbs, and projectiles NEVER visually clip through solid walls, doors, or crates. |
| **Mechanics & Physics** | **Authoritative Hit Causality** | `[PASS / FAIL]` | Attack -> Travel -> Collision -> Impact VFX -> Damage/Reaction. NO early hit effects. |
| **Mechanics & Physics** | **Perceived Mass & Recoil** | `[PASS / FAIL]` | Characters exhibit distinct weight profiles (Leon nimble recoil, Bo solid brace, Creature colossal lumber). |
| **Mechanics & Physics** | **Anticipation & Arcs** | `[PASS / FAIL]` | Major strikes have windup in the opposing direction; limbs and heads follow natural curved arcs. |
| **Mechanics & Physics** | **Follow-Through & Overlap** | `[PASS / FAIL]` | Secondary parts (hoods, hair, tails, straps) lag $2 - 5$ frames behind core bone movement. |
| **Acting & Performance** | **Facial & Eyeline Alignment** | `[PASS / FAIL]` | Head and pupils point directly toward the object or threat of interest; emotional shifts lead body action. |
| **Acting & Performance** | **Personality Integrity** | `[PASS / FAIL]` | Characters perform according to archetype (Leon clever/smug, Nita ferocious/eager, Bo stoic/tactical). |
| **Camera Choreography** | **Motivated Camera Movement** | `[PASS / FAIL]` | Camera pans, zooms, and punch-ins support storytelling; no aimless floating or constant jitter. |
| **Camera Choreography** | **Impact Camera Shake** | `[PASS / FAIL]` | Screen shake magnitude matches strike severity with exponential decay falloff. |
| **VFX & Audio** | **VFX Causality & Scale** | `[PASS / FAIL]` | Particles originate from real physical contact points; smoke/sparks never obscure key facial acting. |
| **VFX & Audio** | **Character Audio Sync** | `[PASS / FAIL]` | Character-specific SFX strictly mapped (Leon sound for Leon, Bo for Bo); audio hits sync on collision frames. |
| **Render Master** | **Technical Export Compliance** | `[PASS / FAIL]` | 60 FPS fixed framerate, 1152x648 or 4K master, H.264 High Profile, AAC Stereo 192k, FastStart enabled. |

---

## Gatekeeper Sign-Off Protocol
A sequence may only be committed to master release once all 25 checklist items are marked `PASS`. If any item fails, review the technical remedy in `docs/ANIMATION_PRINCIPLES.md` Section 32 before re-exporting.
