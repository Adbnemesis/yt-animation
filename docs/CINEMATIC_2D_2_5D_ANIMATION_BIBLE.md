# Cinematic 2D / 2.5D Animation Bible

**Master production reference — cutenemi**
**Version:** 1.0 · **Status:** LIVE MASTER DOCUMENT
**Companions:** `CINEMATIC_ANIMATION_CONTRACT.md` (rules) ·
`CINEMATIC_ANIMATION_CHECKLIST.md` (gate) ·
`CINEMATIC_2D_2_5D_QUICK_REFERENCE.md` (agent digest) ·
`CINEMATIC_2_5D_LAB.md` + `MULTIVIEW_CHARACTER_SYSTEM.md` (empirical lab evidence).

This Bible explains **exactly how future animated videos should be designed
and animated** so they feel like *professionally staged 2D animation with
3D-like spatial depth, cinematic camera language, and strong character
acting* — using our existing 2D paper-cutout Brawlers.

> The goal is **not** to turn characters into 3D models. The goal is
> **2D character art + 2D cutout animation + 2.5D spatial staging +
> cinematic camera**, so the viewer feels: *"These are 2D animated
> characters, but the camera is filming them inside a real spatial world."*

---

## Table of Contents (Part 107)

1. [Project Animation Goal](#p1)
2. [2D vs 2.5D vs 3D](#p2)
3. [The "1D Animation" Failure](#p3)
4. [Spatial World Model](#p4)
5. [Ground Plane](#p5)
6. [Character Scale](#p6)
7. [Character-to-World Scale](#p7)
8. [Multi-View Character System](#p8)
9. [View-Dependent Artwork](#p9)
10. [View Transitions](#p10)
11. [Character Rotation vs Camera Rotation](#p11)
12. [Cinematic Camera: Parts 12–13](#p12)
13. [Shot Scale](#p14)
14. [Face Close-Ups](#p15)
15. [Depth Composition](#p16)
16. [Foreground Occlusion](#p17)
17. [Parallax](#p18)
18. [Movement Through Depth](#p19)
19. [Walk / Run / Jump (20–22)](#p20)
20. [Timing vs Spacing; Weight (23–25)](#p23)
21. [Arcs & Anticipation & Follow-Through (26–30)](#p26)
22. [Facial Acting & Eyelines & Posing (31–35)](#p31)
23. [2D Cutout Limitations (36–37)](#p36)
24. [Fight Staging & Movement & Depth (38–40)](#p38)
25. [Projectiles, Collision, Environment (41–44)](#p41)
26. [VFX Principles (45–47)](#p45)
27. [Audio Principles & BGM (48–49)](#p48)
28. [Energy, Pauses, Comedy & Drama (50–53)](#p50)
29. [Camera & Character Acting (54)](#p54)
30. [Lighting, Environment, Props (55–57)](#p55)
31. [Shot Continuity & Transitions (58–59)](#p58)
32. [Blocking-First Workflow & Reference (60–62)](#p60)
33. [AI-Specific Rules (63–69)](#p63)
34. [2.5D Lab Lessons (70)](#p70)
35. [Production Standards (71–74)](#p71)
36. [Group Shots & Hierarchy & Space (75–82)](#p75)
37. [Physics & Mass (83–85)](#p83)
38. [Camera Perspective & Motion (86–89)](#p86)
39. [VFX + Depth; Audio + Depth (90–91)](#p90)
40. [Review Modes & Quality Gate (92–97)](#p92)
41. [Anti-Patterns (98)](#p98)
42. [Future Brawler & Story Requirements (99–100)](#p99)
43. [Workflow, Priority, Philosophy (101–103)](#p101)
44. [Godot Implementation Guidance](#godot)
45. [Sources](#sources)

---

## PART 1 — Project Animation Goal

### What our animation should NOT look like
- Gameplay (HUD, arbitrary collision, player-camera feel).
- Sprites sliding along one line.
- Flat cutout puppets pasted over a background.
- Characters with a universal screen size regardless of distance.
- A static "documentary" camera.
- Disconnected VFX that float on top of the scene.
- Animation that is a row of isolated attacks.

### What it SHOULD look like
- **Designed 2D animation** — every pose, move, and beat is intentional.
- **Spatially staged scenes** — near/mid/far; things overlap and occlude.
- **Expressive character performances** — readable intent, emotion, attention.
- **Cinematic composition** — shot scale, framing, movement with purpose.
- **Believable movement** — weight, momentum, arcs, force.
- **Depth** — a real sense of space, not a flat backdrop.
- **Interaction** — characters act on the world and on each other.
- **Cause/effect** — nothing happens without a visible cause.
- **Deliberate camera language** — the camera serves the story.

The single test: **mute the video** and the story, spatial relationships,
---

## PART 2 — The Difference Between 2D, 2.5D and 3D

| Term | Definition | Applies to us? |
|---|---|---|
| **2D animation** | Characters and environments are 2D artwork (drawings/cutouts). | Our art is 2D. |
| **2.5D** | 2D artwork arranged and animated using **spatial depth + camera techniques** that create a 3D-like perception (scale by depth, occlusion, parallax, projection, multi-view switching). | **This is our target.** |
| **3D** | Actual 3D geometry and volumetric characters/worlds rendered with a 3D camera. | We do **not** do this. |

Our target in one sentence: **2D ART, implemented with 2.5D SPATIAL STAGING.**

We never claim to be a full 3D animation system. Sprite3D and true 3D camera
rendering were evaluated and rejected for our character pipeline (see
[Godot Implementation Guidance](#godot)): our bold `#1e1e2c` outlines and
flat cel fills are calibrated for the 2D canvas renderer, and billboard
sprites cannot show a back view during an orbit.

---

## PART 3 — The "1D Animation" Failure

### The failure mode we experienced
Character A, Character B, Character C all move **left/right on one invisible
horizontal line** at roughly the same screen size. Even our own "staged"
scenes initially read this way.

### Why it looks bad
- No depth — the eye has nothing spatial to hold onto.
- No spatial relationships — characters never meaningfully relate.
- No perspective; no scale variation.
- Weak staging; weak camera language.
- Little physical interaction possible on a flat strip.

### The cure (all required, not optional)
- **Depth** — characters occupy distinct world positions on the Z axis.
- **Multi-plane staging** — background / midground / characters / foreground.
- **Scale** — apparent size from depth via projection.
- **Perspective** — projected ground, horizon, convergence.
- **Camera** — framing and movement with story intent.
- **Occlusion** — props and other characters overlap by depth.
- **Ground plane** — feet planted on a real surface with shadows.
- **Parallax** — layers move at different speeds during camera moves.
- **Spatial movement** — approach, retreat, diagonal, crossing, emerge.

---

## PART 4 — Spatial World Model

### The mental model
Every character (and every important object) has a meaningful position in one
shared world:

- **X** — horizontal world position (left/right along the floor plane).
- **Y** — vertical relationship / elevation above the ground (feet contact at Y=0 of the object).
- **Z / DEPTH** — distance from the camera / which spatial layer the thing lives in.

### Depth zones
| Zone | Meaning | Use |
|---|---|---|
| **Near / Foreground** | closest to camera | emphasis, intimacy, impact, occlusion of the scene |
| **Mid / Midground** | main action lane | primary staging, interaction |
| **Far / Background** | deepest visible | geography, environment, approach/retreat, scale reference |

The camera-relative relationship is what matters: a "near" object is simply
an object with a small depth value relative to the camera.

### Rules
1. Decide depth *before* animation (Part 60 workflow).
2. Every staged object answers: *which depth plane, and why?*
3. The same world coordinate system applies to characters, enemies, props,
   projectiles, and cameras — one consistent spatial model (lab-verified).

---

## PART 5 — Ground Plane

The ground is one of the most important depth cues. Characters must look
like they *stand on a real surface*.

### Rules
- **Feet contact** — the character's root/feet sit exactly on the projected
  ground line for its depth. Never float.
- **Baseline** — deeper objects sit higher on screen (smaller ground rise);
  nearer objects sit lower (larger apparent size) — this is projection, not
  random Y offsets.
- **Character Y position** — derived from `feet baseline − depth rise`;
  hinder parts never "jump" their baseline without a reason (jump/step).
- **Depth movement** — when a character approaches the camera, the baseline
  moves down and scale grows continuously (never a manual step change).
- **Shadows** — a contact shadow polygon at the feet anchors the character;
  alpha/size falloff with depth; shadow lifts slightly when jumping.
- **Ground perspective** — the ground plane converges toward a horizon;
  the horizon responds to camera pitch (high/low angle).
- **Foreground ground / distant ground** — near ground can be visually
  larger/blanker; distant ground shrinks toward the horizon.

A character should *never* appear to float over the environment.
---

## PART 6 — Character Scale

### Two different scale conversations (never confuse them)
1. **Intrinsic size** — the character's authored proportions (approved part scale).
   This is **fixed**.
2. **Apparent size** — how large the character *appears* on screen. This is
   affected by depth and camera. This is what changes.

### The general rule
| Depth | Apparent size |
|---|---|
| NEAR | larger |
| MID | medium |
| FAR | smaller |

Scale is a continuous function of world depth via the camera projection.
**Do NOT manually rescale characters because a shot looks better.** If a
shot needs a different apparent size, move the character or the camera in the
world — don't fake it with a scale slider (contract law 3).

### Applies equally to
- Brawlers (Leon, Nita, Bo, future).
- Enemies, props, projectiles, environmental objects — the *same* depth rule.

---

## PART 7 — Character-to-World Scale

This is separate from depth scaling: it is the *character's physical size
relative to the environment* at the same depth.

A brawler must feel believable standing next to:
- doors (door ≈ 1.6–1.9× character height),
- walls and machines (tall enough to occlude),
- crates, tables, boxes (waist-to-chest height),
- platforms and stairs (step height ≈ shin height).

When a character looks gigantic relative to the world, **do not shrink the
character**. Fix one or more of:
- **World scale** — authored prop/environment dimensions.
- **Character baseline** — where the character stands in world units.
- **Camera distance** — pull the camera back / reposition.
- **Projection** — the shared model converts world units to screen correctly.

The 2.5D lab verified environment-relative staging (door/crate/table/pillar
beside each brawler reads coherently) using one shared projection for
characters *and* props.

---

## PART 8 — Multi-View Character System

Our Brawlers provide viewpoint artworks so the camera can move *around* them:
- `front` (ViewFront)
- `front 3/4` (ViewFront3Q)
- `side` (ViewSide — the main animated production rig)
- `back 3/4` (ViewBack3Q)
- `back` (ViewBack)

Left-side compass directions are horizontal mirrors of the right-authored
views (scale.x = -1). 5 unique artworks cover all 8 directions.

A character must **not** behave like a single front-facing cardboard image
when the camera moves around it. Camera moves that change the visible angle
must switch views.

Character prototype documentation: `docs/MULTIVIEW_CHARACTER_SYSTEM.md`
(view inventory per character: Leon 5, Nita 4, Bo 5 at lab time).<br>
*Production caveat:* the multi-view sets currently exist as **lab assets**
(`scenes/labs/characters/…`). Production scenes still reference the standard
side rigs. This Bible describes the intended production standard; adoption
into production scenes is a deliberate, reviewed step — not an automatic one.

---

## PART 9 — View-Dependent Artwork

### The relationship
| Camera position vs character | Visible artwork |
|---|---|
| camera front of character | front |
| camera 3/4 of character | front 3/4 |
| camera at side | side |
| camera rear of character | back |

Selection is driven by the **relative angle** between the character's facing
direction and the direction toward the camera (0° = facing camera,
±180° = facing away). Buckets: ±22.5° front / ±67.5° 3/4 / ±112.5° side /
±157.5° back-3/4 / else back.

### Handling missing views (honesty rule)
Do not pretend arbitrary angles can always be solved with existing artwork.
When a transition exposes a missing angle:
1. **Choose the nearest valid view** (fallback chain, e.g. back_3q → back → side).
2. **Adjust camera/staging** so the angle is covered by valid art.
3. **Flag new artwork as required** for future sessions.

Do NOT produce obvious visual distortions (stretching, warping, "elastic"
turns) to force an impossible shot.

---

## PART 10 — View Transitions

When switching front → 3/4 → side → back (and reverse), prevent:
- popping (sudden art swap with no transition),
- head drift, foot drift,
- weapon drift,
- scale jumps,
- sudden root movement,
- facial displacement.

### Rules
- **All views share a single character root** — the feet ground point at
  (0,0) in every view scene (lab-verified drift < 3 px across all views).
- Transitions use a controlled **crossfade** (~0.12 s) which reads as a soft
  cut; treat a crossfade as a dissolve, not a rotation.
- Keep transitions deterministic — the same camera-relative angle always
  selects the same view; no randomness.
- Fast spins (sub-0.3 s 180° turns) will read as a pop-pair with 5 views;
  either stage the turn to pass through readable angles, or cut away and
  cut back. Do not pretend a dissolve rotates the character.

---

## PART 11 — Character Rotation vs Camera Rotation

Three distinct cases — the system must respond correctly in all three:

| Case | What happens | Correct behavior |
|---|---|---|
| **A. Camera moves around character** | camera position changes; character facing held | character view switches as relative angle passes buckets (orbit test) |
| **B. Character rotates, camera fixed** | facing changes; camera held | character view switches as facing crosses buckets |
| **C. Both move** | both change | relative angle is the only thing that matters — view = f(relative angle) |

Never "rotate" a flat sprite through extreme angles (yawing a front face
into a false side view). The 2.5D lab verified all three cases with the
camera-relative model.
---

## PART 12 — Cinematic Camera

Supported camera operations (implemented in the 2.5D lab and the production
camera systems):

- **Pan** — rotate view horizontally (reveal geography).
- **Truck** — move camera left/right (follow lateral motion, change framing).
- **Dolly / push-in** — move camera toward subject (intimacy, scale change).
- **Pull-back** — move camera away (isolation, reveal, relief).
- **Tracking** — follow a moving subject while keeping framing stable.
- **Tilt** — vertical angle change (high/low angle, reveal height).
- **Controlled orbit** — camera path around a subject (multi-view showcase;
  must be a positional orbit, not an in-place yaw).
- **Static framing** — sometimes the most powerful choice.
- **Reveal** — camera movement that uncovers information.
- **Controlled shake** — only for significant impacts (Part 89).

Camera movement must have **purpose** (Part 13).

## PART 13 — Camera as Storyteller

The camera tells the audience:
- **what matters** (focus, framing, rack of attention),
- **who matters** (who is centered, who is near),
- **how far apart characters are** (spatial separation is emotional distance),
- **how dangerous something is** (shots from below = threat; from above = vulnerability),
- **how large/small something feels** (scale contrast, wide vs close),
- **when a reveal happens** (reveal shots, push-ins),
- **when a reaction matters** (cut to reaction, hold).

Do not move the camera merely because the shot feels empty. Fix the staging
or the acting first (Part 54).

## PART 14 — Shot Scale

Use shot variation intentionally; do not keep an entire video at one camera
distance.

| Shot | Purpose |
|---|---|
| **WIDE** | geography, spatial relationships, approach/retreat |
| **MEDIUM** | interaction, action, two-shot/group work |
| **CLOSE** | emotion, reaction, intent |
| **EXTREME CLOSE** | important expression, detail, decisive moment |

A sequence should move between these deliberately — e.g. open wide to
establish, push to medium for action, cut close on the decisive reaction,
pull back to wide for the consequence.

## PART 15 — Face Close-Ups

A cinematic expression shot must not be "scale the sprite up."
A camera push-in should preserve:
- face readability (art resolution sufficient for the close-up),
- eye movement and pupils,
- eyebrows,
- mouth,
- blink (the facial system runs at close range, not faked by zoom).

Use:
- real camera movement toward the character (scale from projection),
- the appropriate character view (front for straight-on, 3/4 for three-quarter
  close-ups — the lab's front-3/4 → side face tests),
- the facial expression system (eyes/eyebrows/mouth/blink) driving readable
  expression changes.

When a close-up needs an angle not covered by artwork: use an appropriate
view, restage, or flag additional art. The character must still feel like a
2D puppet, not a HUD element.

## PART 16 — Depth Composition

Practical arrangements put characters in meaningful depth, e.g.:
- foreground: Leon,
- midground: Nita,
- background: Bo.

The viewer should immediately perceive the spatial relationship through:
- **overlap** (nearer objects overlap farther ones at shared depths),
- **scale** (projected size differences),
- **spacing** (fewer world-units between near objects reads tighter),
- **occlusion** (foreground elements partially hide mid/far layers),
- **negative space** (open room around the focus), and
- **visual hierarchy** (Part 77).

Depth composition should be **readable at a glance** — this is the primary
spatial test.

## PART 17 — Foreground Occlusion

Foreground objects (pipes, pillars, crates, plants, walls, machinery) may
partially obscure characters. It is one of the strongest *cheap* depth cues:
- character moves behind object → character becomes obscured,
- character emerges → reveal.

Rules:
- Occlusion must follow **world depth** (draw order = f(depth)), never a
  hardcoded z-index flip that ignores position (contract law 2).
- A foreground object occludes a mid/background character; a side pillar
  occludes as they pass behind it — verified by the lab's occlusion tests.

## PART 18 — Parallax

During camera moves, layers move at different rates:
| Layer | Relative movement |
|---|---|
| background | slow (e.g. 0.08–0.12× camera offset) |
| midground | moderate |
| foreground | stronger |

Rules:
- Parallax applies **only when the camera moves**. Do not constantly animate
  backgrounds in static shots.
- Keep it subtle and consistent with the projection model (the lab used a
  far backdrop drift of ~0.12× and near drift ~0.4×).

## PART 19 — Character Movement Through Depth

Characters can and should:
- approach the camera,
- retreat from it,
- move diagonally,
- cross the scene,
- change depth mid-scene,
- cross another character (draw order updates naturally by depth),
- pass behind objects,
- emerge from objects.

Restrict characters to **LEFT ↔ RIGHT** only when the shot's geography
literally demands it (a side-locked corridor). Feet must stay attached to
the ground, and scale must track depth continuously as they move.
---

## PART 20 — Walking
A walk must communicate **direction, speed, weight, location, and depth**:
- Feet stride across the ground without slipping (root velocity = stride/step duration, contract law 5).
- When walking toward the camera: apparent scale grows.
- When walking away: apparent scale shrinks.
- Body lean, weight shift, and arm swing match the character's personality
  (Leon light/bouncy, Nita grounded/punchy, Bo measured/anchored).
- The same walk should **read differently at different depths** because
  scale and ground rise change with depth.

## PART 21 — Running
Running must communicate **momentum, acceleration, deceleration, weight, urgency**:
- Not simply a faster walk: use body lean, bigger arm drive, head stability,
  stronger knee lift, longer strides, secondary motion (hood/hair/tail/strap lag).
- Start with a push-off (lean + first-stride surge) and end with a settle or
  slide to stop — momentum must carry through.
- Leap spacing widens with speed; contact frames are clean.

## PART 22 — Jumping
Full arc: **anticipation → launch → airborne → fall → landing → settle**.
- Anticipation: crouch/compression.
- Launch: explosive extension.
- Airborne: arc, slight tuck/pike, eyes on the target.
- Fall: gravity accelerates the descent.
- Landing: **weight** — legs compress, body absorbs, recoil settles.
- Use squash/recoil, a dust puff, a contact shadow that lifts and lands with
  the character, and secondary movement (hair, tail, straps, bow).

## PART 23 — Timing vs Spacing
Two different quantities — never conflate them:
- **Timing** = *how long* an action takes (duration in frames/seconds).
- **Spacing** = *where the character is on each frame* (the distance between
  successive positions).

Use spacing to communicate acceleration, deceleration, force, mass, speed.
Uniform spacing reads robotic; slow-out into an impact reads powerful;
overshoot reads bouncy/comedic.

## PART 24 — Slow-In / Slow-Out
Use appropriate acceleration/deceleration — but **do NOT apply one generic
ease to every movement**:
- Light character → faster acceleration.
- Heavy object → slower acceleration, longer settle.
- Sudden impact → can stop abruptly (even with a hard contact frame).
- Stylized comedy → overshoot and recoil.

Choose the spacing per action; document the choice. Generic "smooth" tweening
everywhere is an anti-pattern (contract law 21).

## PART 25 — Weight
Weight is *perceived* — communicate mass with anticipation, acceleration,
deceleration, contact, recoil, follow-through, landing, and momentum.
The same universal controller can produce different perceived weights through
**performance** (see Part 85 for the character mass table).

## PART 26 — Arcs
Use believable curved paths for heads, arms, hands, legs, attacks, jumps,
dodges, thrown objects, and camera moves. Avoid robotic straight-line motion
where an arc is natural.

## PART 27 — Anticipation
Before meaningful actions: **prepare → action**.
- Attack: aim/load → fire.
- Jump: compress → launch.
- Turn: prepare → turn.
- Strong impact: brace → impact.

Do NOT add anticipation mechanically to every tiny movement — save it for
meaningful actions so it keeps its power.

## PART 28 — Follow-Through
After an action, the primary part finishes, secondary parts continue, then
everything settles. Apply to arms, hands, head, clothing, hood, hair,
accessories, weapons (2–5 frame lag on secondary parts).

## PART 29 — Overlapping Action
Parts should not all move simultaneously:
- torso turns → head follows,
- body stops → clothing/hair settles,
- arm swings → hand follows.
This is essential to avoid robotic cutout motion.

## PART 30 — Secondary Action
Secondary actions support the main action:
- Leon teaches → Nita watches (eyelines, reactions).
- Nita attacks → Leon follows her aim.
- Bo observes → eyes track the threat.
- Combat → characters reposition while monitoring the opponent.

No meaningless motion (contract law 20).
---

## PART 31 — Facial Acting
Characters must not remain neutral during important events. Use:
- eye direction and pupils,
- blink,
- head movement,
- eyebrows,
- mouth,
- expression transitions.

Expressions react to character actions, discoveries, attacks, impacts,
other characters, and the environment.

## PART 32 — Eyelines
Eyelines must correspond to **actual world positions**:
- Looking at a character → gaze points at their world position.
- Watching a projectile → gaze tracks the projectile.
- Shared threat → everyone's attention converges appropriately.
The face system drives pupils/head; verified against spatial geometry.

## PART 33 — Solid Posing
Even cutout rigs must communicate balance, weight, direction, intention, and
a line of action. Avoid symmetrical stiff poses unless intentionally comic or
menacing.

## PART 34 — Silhouette
Important poses must read as silhouettes. Prevent arms merging with the torso,
legs overlapping, bodies stacking, projectiles hidden behind the body, and
unclear attack direction. If a pose doesn't read in black, restage it.

## PART 35 — Appeal
Preserve the established appeal of Leon, Nita, Bo, and future Brawlers:
recognizable silhouette, personality, expressive pose, readable face, clean
design. Do not sacrifice character identity for perspective tricks
(contract law 25).

## PART 36 — 2D Cutout Limitations (honest)
Our characters are not volumetric 3D models:
- Extreme camera angles may require additional artwork views, alternative
  staging, controlled camera angles, view switching, or hybrid techniques.
- Do NOT force impossible views from insufficient artwork.
- Known lab limitations: fast-spin crossfades pop; Nita lacks a true back-3/4;
  Bo's front/back are static poses (no bones); strong pitch (≥25°) starts to
  look like a "slid" cutout; only the side rig has real walk cycles.

## PART 37 — 2.5D Camera / Character Rule
The camera can move through space; the character responds through **view
selection, spatial scale, layering, orientation, and projection** — never by
rotating a flat front-facing image through an extreme angle.

---

## PART 38 — Fight Staging
Fight scenes must have **geography**. At all times establish:
- **Attacker** — who is acting.
- **Target** — who is being acted upon.
- **Distance** — how far apart (combat encounter spacing, readable).
- **Direction** — the attack vector and where it leads.
- **Position** — where each fighter stands in the world.
- **Escape route** — where a dodge/reposition will go.

Never stage all characters on one horizontal line (contract law 1).

## PART 39 — Fight Movement
Use interaction vocabulary: **attack → dodge → reposition → counter →
reaction → environmental consequence**. Each action should change the
situation; pure attack→attack chains with no change read as static combat.

## PART 40 — Fight Depth
Use foreground/midground/background in combat:
- Bo far back fires an arrow,
- Nita midground dodges,
- Leon foreground attacks.
The spatial relationship must be instantly readable.

## PART 41 — Projectiles
Projectiles belong to the spatial world. They must respect depth, scale,
layering, obstacles, collision, and camera. The canonical chain:

**ATTACK → RELEASE → PROJECTILE → TRAVEL → COLLISION → IMPACT → VFX → SFX → REACTION**

- The projectile spawns at the attacker's **view-attached attack socket** in
  world space (Parts 43/44 in MULTIVIEW_CHARACTER_SYSTEM.md).
- It travels through world coordinates (projected each frame like everything
  else), so it shrinks/grows with depth and passes behind props correctly.

## PART 42 — Projectile Scale
A projectile farther from the camera may appear smaller if the spatial
representation requires it — the *same* depth rule as every other object.
Never randomly resize projectiles; their apparent size comes from world depth.

## PART 43 — Collision
Important physical interactions must be real:
- character → wall,
- projectile → wall,
- projectile → character,
- character → object.

Do not fake collision solely with VFX, screen shake, sound, or scripted
teleportation. Collision happens when world-space geometry actually contacts
the target's collision shape; the impact (VFX/SFX/reaction) follows.

## PART 44 — Environment Interaction
The environment should participate in the action:
- doors block characters,
- crates move/break,
- projectiles hit walls,
- foreground objects occlude characters,
- impacts create debris,
- characters react to terrain.

The environment must not feel like a static wallpaper.
---

## PART 45 — VFX Principles
VFX should **clarify** motion, and every major effect must have a cause:
- Good: arrow collision → impact → sparks → debris.
- Bad: Bo fires → explosion at target → arrow arrives later.

VFX must follow actual events, never precede them (contract law 14).

## PART 46 — VFX Scale and Depth
VFX must respect character scale, camera distance, environment scale, and
action intensity. Effects at the character's depth are sized to the character;
a distant effect is smaller. Effects must respect layering: an effect behind
a character stays behind; a foreground effect can partially obscure
(Part 90). Avoid effects that look pasted on top of the scene.

## PART 47 — VFX Hierarchy
Build effects in layers:
- **Primary effect** (impact flash, slash, burst) at the contact point,
- **Secondary particles** (sparks, debris, dust),
- **Environment response** (chips on a wall, cracks, knocked-over props).

Do not put maximum intensity on every action; reserve the big effects for the
important beats so hierarchy is readable.

## PART 48 — Audio Principles
Audio supports animation:
- SFX trigger from **actual events** (contact, release, land, break).
- Character-specific SFX remain correctly mapped (Leon→Leon, Nita→Nita, Bo→Bo).
- BGM supports scene energy.
- Audio must never be used to hide unclear animation (contract law 18).

## PART 49 — BGM
BGM provides mood, pacing support, and energy contrast. It must not dominate
dialogue, character vocalizations, SFX, or important impacts. Use dynamic
levels so the mix breathes with the scene (energy ducking on impacts).

## PART 50 — Scene Energy
A scene should follow an energy curve:
**CALM → BUILD → ACTION → REACTION → ESCALATION → RELEASE**.
Not constant maximum intensity; not constant stillness. The curve is a
storytelling tool: contrast makes the peaks hit.

## PART 51 — Pauses
| Type | Definition | Rule |
|---|---|---|
| **Meaningful pause** | supports emotion/reveal/comedy | keep |
| **Reaction pause** | lets the viewer process what happened | keep (0.3–0.6 s after events) |
| **Dead pause** | nothing meaningful occurs | **remove** (replace with micro-acting or cut) |

## PART 52 — Comedy Timing
For comedic animation: **SETUP → EXPECTATION → ACTION → REACTION → PAYOFF**.
The reaction often matters more than the action. Don't rush punchlines; don't
hold characters frozen without purpose.

## PART 53 — Dramatic Timing
For suspense/reveals: **establish → anticipation → reveal → reaction**.
Use controlled stillness where it helps — stillness is not a technical failure.
Hold before the reveal so the release lands.

## PART 54 — Camera and Character Acting
Do not solve an animation problem with camera movement. First fix pose,
acting, and staging; then use camera to emphasize. If the acting reads clean
with the camera locked static, the shot holds (contract law 23).

## PART 55 — Lighting / Depth Cues
Depth can also be supported by:
- simple atmospheric separation (background slightly reduced contrast/value),
- foreground contrast,
- background reduction,
- shadows,
- subtle lighting layers.

Do **not** use realistic lighting that conflicts with the flat paper-cutout
art style.

## PART 56 — Environment Design
Environment must support spatial perception. Prefer:
- layered construction (foreground, midground structures, distant background),
- a clear ground plane,
- clear scale references,
- geometry that gives characters places to hide behind, emerge from, and paths.

Avoid giant flat background images whenever the scene requires movement/depth.

## PART 57 — Prop Design
Props must relate believably to characters:
- a door should be tall enough,
- a crate coherently scaled to waist level,
- a table related to character height,
- a machine occupying believable space.

Prop dimensions are world units, projected like everything else (Part 7).

## PART 58 — Shot Continuity
Between cuts preserve: screen direction (180° rule), character relative
position, depth, scale, environment orientation, prop location, facing, and
attack direction. Do not randomly reset geography between shots.

## PART 59 — Shot Transitions
Prefer motivated transitions:
- cut on action,
- cut to reaction,
- reveal cut,
- wide after close,
- close after impact.

Do not add transitions purely for decoration.

## PART 60 — Blocking-First Workflow (REQUIRED)
The required production workflow — blocking before polish:
1. Understand the story beat.
2. Establish spatial composition.
3. Establish the camera.
4. Block major poses.
5. Block timing.
6. Block movement paths.
7. Validate depth/scale.
8. Add breakdowns.
9. Add spacing refinement.
10. Add anticipation/follow-through/overlap.
11. Add facial/eyeline acting.
12. Add physics/environment interaction.
13. Add camera polish.
14. Add VFX.
15. Add SFX/BGM.
16. Review.

**Do NOT polish VFX or camera before the staging and blocking work is done.**

## PART 61 — Thumbnail / Pose Planning
Before complex action, plan thumbnails conceptually: character placement,
camera, depth, direction, and important silhouettes. Do not start with
detailed animation. If the thumbnail doesn't read, don't animate it.

## PART 62 — Reference
Use real-world/video reference for walks, runs, jumps, fights, reactions,
weight, gestures, camera movement. Reference informs motion — but never copy
copyrighted footage directly into the project.
character intentions, and physical cause/effect must all be readable.