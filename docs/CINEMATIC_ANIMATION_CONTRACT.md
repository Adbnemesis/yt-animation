# Cinematic 2D / 2.5D Animation Production Contract

**Status:** NON-NEGOTIABLE PRODUCTION CONTRACT — CINEMATIC TIER
**Authority:** Enforces `docs/CINEMATIC_2D_2_5D_ANIMATION_BIBLE.md`
**Supersedes/adds to:** `docs/ANIMATION_CONTRACT.md` (legacy 12 laws remain in force)
**Applicability:** All animated scenes, sequences, fights, VFX, camera work, and
renders produced for cutenemi. Developed from the empirical 2.5D staging lab
(`scenes/labs/` + `docs/CINEMATIC_2_5D_LAB.md`).

---

## The 25 Cinematic Non-Negotiable Laws

1. **Characters do not live on a single invisible horizontal line.**
   Every scene must place characters, enemies, and props in distinct depth
   planes (foreground / midground / background). A flat row of characters is
   a defect.

2. **Depth must be intentional.**
   Depth is a staging decision made before animation begins: it answers
   *who is near, who is far, and why*. Random Y offsets, random scale, and
   random z-index are prohibited.

3. **Scale must communicate distance.**
   All apparent scale derives from the spatial model and camera projection.
   NEAR = larger, MID = medium, FAR = smaller. Never rescale a character by
   hand because "a shot looks better."

4. **Character-to-world scale must be coherent.**
   A brawler standing beside a door, crate, table, or wall must read as a
   believable physical size relative to that object. Fix world scale and
   projection — do not shrink the character.

5. **Ground contact must be believable.**
   Feet planted on the ground; no floating, no ice-skating foot slip, no
   sliding across invisible strips. Shadows anchor characters to the ground.

6. **Multi-view artwork must be used for meaningful camera angles.**
   When the camera moves around a character, switch to the matching view
   (front / 3/4 / side / back). A Character must not behave like a
   front-facing cardboard image during camera moves.

7. **Flat sprites must not be rotated into obviously broken views.**
   Do not take a single 2D front face and yaw it into a 60° "side" view as if
   it were 3D. If the artwork isn't available, choose another staging.

8. **Camera movement must have purpose.**
   Every pan, dolly, push-in, pull-back, orbit, tilt, or shake must answer a
   story question (geography, emotion, reveal, emphasis, scale). "Dynamic" is
   not a reason.

9. **Important actions need readable anticipation.**
   Load before you fire: aim before the shot, compress before the jump,
   brace before the impact, look before the turn. Do not pop actions with
   zero setup.

10. **Reactions need enough time to read.**
    After a strike, reveal, or surprise, hold a 0.3–0.6 s reaction window so
    the viewer can register what happened. Fast action with zero comprehension
    time is a defect.

11. **Spacing must communicate force and weight.**
    Timing says *how long*; spacing says *where on each frame*. Use clustered
    frames for anticipation, wide leaps for impact, settle frames for weight.

12. **Physics must respect important solid geometry.**
    Characters, limbs, weapons, and projectiles never clip through solid
    walls, closed doors, crates, or the ground. Collisions are real.

13. **Projectiles must actually travel and collide.**
    The chain is exactly: ATTACK → RELEASE → PROJECTILE → TRAVEL →
    COLLISION → IMPACT → VFX → SFX → REACTION. No teleportation, no
    scripted hit at spawn.

14. **Impact VFX occur after collision.**
    Impact flashes, sparks, dust, and camera shake fire only when the
    projectile or weapon physically contacts the target's collision shape —
    never on attack start.

15. **Characters must react to relevant events.**
    A target getting hit reacts; bystanders flinch or watch; the attacker
    completes follow-through. Neutral expressions during major events are a
    defect.

16. **Eyelines follow important objects and characters.**
    If a character watches someone or a projectile, the pupils/head point at
    the real world-space position of that thing. Converging attention reads
    as shared threat.

17. **VFX must support rather than hide animation.**
    Effects clarify contact, direction, and intensity. They must not cover the
    primary acting silhouette or the impact contact point.

18. **Audio must correspond to actual events.**
    Character-specific SFX (Leon→Leon, Nita→Nita, Bo→Bo) stay mapped, sync on
    real collision frames, and never substitute for missing animation.

19. **Stillness is allowed when purposeful.**
    A held frame before a reveal, a beat of controlled stillness after an
    impact, a pause for comedy timing — these are strengths. Dead pauses
    (nothing happening while waiting) are defects.

20. **Random movement is prohibited.**
    No jitter, no idle flailing, no constant camera drift, no micro-motion
    added to "fill" time. Every motion must have intent.

21. **Generic easing is not a substitute for animation judgment.**
    One tween curve fitted to every movement is a defect. Choose spacing per
    action: fast accelerations for light action, slow ones for mass, hard
    stops for impact, overshoot for comedy.

22. **Do not globally speed up / slow down a scene to fix pacing.**
    Pacing is fixed beat-by-beat: shorten a dead pause here, lengthen a
    reaction there. Never multiply the whole timeline.

23. **Do not solve weak acting with camera movement.**
    Fix pose, acting, and staging first (blocking-first workflow). Camera
    only emphasizes what already works.

24. **Do not solve weak collisions with VFX.**
    If contact does not read, fix the contact frame and the spatial
    collision — not more sparks on top.

25. **Do not sacrifice character identity for perspective.**
    The brawler silhouette, proportions, and appeal are approved artwork.
    No extreme angle may distort them beyond recognition.

---

## Enforcement & Rejection

A scene fails review if any law is violated. All four review modes are
mandatory (see `docs/CINEMATIC_ANIMATION_CHECKLIST.md`):

- **Muted test** — story, intent, and cause/effect readable with no audio.
- **Silhouette test** — action, poses, and hierarchy readable in black shapes.
- **Grayscale test** — hierarchy and contrast do not rely on color alone.
- **Spatial/depth debug** — no debug overlays may remain in a final render.

Rejection also applies to: characters on one line, universal screen scale,
arbitrary z-index, VFX before collision, projectile teleportation, clipping
through solid objects, and all items in the Bible's Part 98 anti-pattern list.