# Cinematic 2D / 2.5D Quick Reference

**Load before every animation task.** Full authority: `docs/CINEMATIC_2D_2_5D_ANIMATION_BIBLE.md`.
Contract: `docs/CINEMATIC_ANIMATION_CONTRACT.md`. Checklist: `docs/CINEMATIC_ANIMATION_CHECKLIST.md`.

---

## Mental Model

**SPACE:** X + Y + DEPTH (near/mid/far). Never stage on one line.

**CHARACTER:** ROOT(at feet) + MULTI-VIEW ART(front/3q/side/back) + RIG(Skeleton2D) + FACE(eyes/eyelines/expressions).

**CAMERA:** FRAMING(shot scale) + DEPTH(projection) + MOVEMENT(only with purpose).

**ANIMATION:** POSE → TIMING(how long) → SPACING(where on frames) → ACTING(intent).

**ACTION:** ANTICIPATION → ACTION → CONTACT → REACTION → FOLLOW-THROUGH.

**PROJECTILE:** SPAWN(at attack socket) → TRAVEL → COLLISION(real) → IMPACT → VFX/SFX → REACTION.

**SCENE:** BACKGROUND → MIDGROUND → CHARACTERS → FOREGROUND (all depth-sorted).

**ENERGY:** CALM → BUILD → ACTION → REACTION → ESCALATION → RELEASE.

---

## Space & Depth
- Depth = staging decision *before* animation.
- Scale derives ONLY from world depth + camera projection. NEAR larger, FAR smaller.
- y-sort / z-index = f(world depth). No arbitrary z-index.
- Ground is a real plane: feet planted, contact shadows, horizon responds to camera pitch.
- Characters may approach, retreat, cross, pass behind, and emerge — never only L↔R.
- Occlusion by props/pillars/crates is a cheap, strong depth cue.

## Character Views
- Match artwork to camera-relative angle: FRONT(±22.5°) → 3Q(±67.5°) → SIDE(±112.5°) → BACK3Q(±157.5°) → BACK.
- Left variants = horizontal mirrors of right-authored views (scale.x = -1).
- Missing view? Use nearest valid view, change staging, or flag new art. Never warp a flat sprite into a fake angle.
- All views share ONE feet-origin root: no pop, no drift on switch.
- Attack socket lives in each view scene; the projectile spawns from the ACTIVE view's socket.

## Camera
- Shot scale: WIDE=geography, MEDIUM=interaction/action, CLOSE=emotion, EC=extreme detail.
- Moves: pan, truck, dolly/push-in, pull-back, tracking, tilt, controlled orbit, reveal, controlled shake.
- Every move needs a story reason (reveal / emphasis / follow / geography / emotion / scale).
- Push-ins go WITH the face system (eyes/pupils/brows/mouth/blink readable) — never just scale a sprite.

## Action Building Blocks
- **Anticipation** before meaningful actions (load before fire, compress before jump).
- **Contact frame** must read clearly — do not bury it in VFX.
- **Reaction window** 0.3–0.6 s after strikes/reveals. No dead pauses (>0.8 s frozen).
- **Follow-through / overlap**: hood, hair, tail, straps, weapons lag 2–5 frames behind the body.
- **Spacing** communicates weight: clustered for anticipation/load, huge leaps for impact, settles for mass.
- No generic ease on everything. No random micro-motion. Stillness is allowed when purposeful.

## Physics & Causality
- Solid walls/doors/crates are solid: no clipping, no teleporting.
- Projectile chain is sacred: SPAWN → TRAVEL → COLLISION → IMPACT → VFX → SFX → REACTION.
- Impact VFX/SFX/shake fire ONLY after physical contact.
- Characters react to relevant events; eyelines track real world positions.

## VFX & Audio
- Primary effect + secondary particles + environment response; never max intensity on every beat.
- Effects respect depth/scale/layering (effect behind a character stays behind).
- SFX map strictly per character (Leon→Leon, Nita→Nita, Bo→Bo), synced to contact frames.

## Workflow (Blocking-First)
STORY → BEAT PURPOSE → ASSET NEEDS → SPATIAL BLOCKING → CAMERA BLOCKING → POSES → TIMING → SPACING → ACTING → PHYSICS → MULTI-VIEW → CAMERA POLISH → VFX → SFX/BGM → REVIEW → RENDER.
- Polish VFX/camera LAST, only after staging + acting read clean.

## Review Modes (all mandatory)
1. **Muted** — story/intent/cause-effect clear with no audio.
2. **Silhouette** — poses and hierarchy read as solid black.
3. **Grayscale** — hierarchy doesn't depend on color.
4. **Spatial debug** (dev only) — camera/ground/depth/bbox/collision checked, then removed.

## Decision Priority (when conflicted)
1. STORY CLARITY → 2. SPATIAL CLARITY → 3. CHARACTER ACTING → 4. TIMING/SPACING → 5. PHYSICS → 6. CAMERA → 7. VFX → 8. AUDIO → 9. VISUAL COMPLEXITY.
Never choose flash over clarity.

## Never Do
One-line staging · universal screen scale · random Y/scale/z · unmotivated camera · random jitter · generic easing everywhere · VFX before collision · projectile teleport · clipping through solids · scaling characters to fake depth · yawing flat sprites into impossible views · camera hiding weak acting.