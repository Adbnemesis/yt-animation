# Cinematic 2D / 2.5D Animation Production Checklist

**Purpose:** Mandatory pre-release quality gate for every cinematic scene.
**Standard:** `docs/CINEMATIC_2D_2_5D_ANIMATION_BIBLE.md` + `docs/CINEMATIC_ANIMATION_CONTRACT.md`.

---

## STORY
- [ ] Story beat is clear.
- [ ] Character intention is clear.
- [ ] Cause/effect is visible.
- [ ] Scene has an energy curve (calm → build → action → reaction → escalation → release).

## SPACE
- [ ] Ground is clear (feet planted, no floating).
- [ ] Depth is clear (foreground / midground / background distinguished).
- [ ] Near/far scale is coherent (from spatial model, never manual rescale).
- [ ] Foreground/midground/background are each useful (not just present).
- [ ] Occlusion is correct (behind-prop → hidden → emerge, by world depth).
- [ ] Environment scale is believable (door/crate/wall/table vs characters).
- [ ] No characters staged on a single horizontal line.
- [ ] z-index / draw order follows world depth; no arbitrary flips.

## CHARACTER
- [ ] Acting is intentional (every motion has a purpose).
- [ ] Poses are readable (line of action, weight, direction).
- [ ] Eyelines are correct (gaze tracks real world positions).
- [ ] Expressions react (they change at events, never neutral throughout).
- [ ] Character-specific proportions and silhouette are preserved.
- [ ] Multi-view artwork used for meaningful camera angles.
- [ ] No view switch pops (root/feet stay fixed; no drift).

## ANIMATION
- [ ] Anticipation exists where useful (aim/load/compress before action).
- [ ] Timing is readable (how long each beat takes).
- [ ] Spacing is intentional (acceleration, deceleration, impact leaps).
- [ ] Weight is believable (per character: Leon light, Nita mid, Bo heavy).
- [ ] Arcs are appropriate (curved paths, not straight-line robotics).
- [ ] Follow-through exists (hood/hair/tail/weapons settle after motion).
- [ ] Overlap exists where useful (parts don't all move simultaneously).
- [ ] Secondary action supports the primary action.
- [ ] No generic easing on everything; spacing chosen per action.

## COMBAT
- [ ] Attacker is clear.
- [ ] Target is clear.
- [ ] Direction is clear (attack vector + leading space).
- [ ] Attack → dodge → reposition → counter → reaction (not attack×4).
- [ ] Fight geography established (attacker/target/distance/escape route).
- [ ] Projectile travels (real world-space path, correct depth scale).
- [ ] Collision occurs (physical distance/geometry, not scripted).
- [ ] Impact occurs after collision.
- [ ] Reaction follows impact (target + bystanders).
- [ ] No teleportation; no hit-before-arrival.

## CAMERA
- [ ] Framing has purpose (shot scale matches intent: wide/medium/close/EC).
- [ ] Shot scale is appropriate for the beat (not one distance all video).
- [ ] Camera movement is motivated (reveal/emphasis/follow/geography/emotion).
- [ ] Close-ups are readable (face system: eyes/pupils/brows/mouth/blink).
- [ ] Depth is visible in the shot (layers, scale, occlusion, parallax).
- [ ] Camera does not hide weak animation (static read must hold).
- [ ] Camera easing is intentional; no arbitrary snapping; shake only on real impacts.

## VFX
- [ ] Effects have visible causes.
- [ ] Impact effects follow collisions (never before contact).
- [ ] Effects respect scale/depth/layering (not pasted on one plane).
- [ ] Effects do not obscure the primary action or silhouette.
- [ ] Effect hierarchy: primary effect + secondary particles + environment response.

## AUDIO
- [ ] Correct character SFX (Leon→Leon, Nita→Nita, Bo→Bo; no cross-mapping).
- [ ] Correct event timing (SFX on actual contact/impact frames).
- [ ] BGM supports mood without overpowering SFX/dialogue/impacts.
- [ ] Audio does not mask unclear animation.

## FINAL REVIEW MODES
- [ ] Muted test passes (story/intent/cause-effect clear with no audio).
- [ ] Silhouette test passes (poses+action read as solid black shapes).
- [ ] Grayscale test passes (hierarchy independent of color).
- [ ] Spatial test passes (depth debug overlays checked, then removed).
- [ ] No debug UI, markers, or overlays in the final render.
- [ ] Render works (full production pipeline: Movie Maker + FFmpeg, target fps/size).
- [ ] No anti-patterns from Bible Part 98 remain.

---

## Gatekeeper Sign-off
Every box must be `[x]` before a sequence is committed to master. Any FAIL
requires revision and a fresh review pass — there are no "rough draft"
exceptions for cinematic scenes.