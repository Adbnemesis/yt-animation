# Cutenemi 2D Animation Production Contract
**Status:** NON-NEGOTIABLE CORE CONTRACT  
**Applicability:** Antigravity AI Agents, Riggers, Animators, Scene Directors  
**Authority:** Enforces standards defined in `docs/ANIMATION_PRINCIPLES.md`

---

## The 12 Non-Negotiable Animation Laws

Every animated sequence produced within this repository must strictly adhere to these twelve non-negotiable rules. Any scene violating any of these rules is considered defective and must be rejected during review.

### 1. Thou Shalt Not Stage on a Single Line (The Anti-1D Law)
Characters, enemies, and props must **never** be placed on a single horizontal line ($X$-axis lock). Scenes must utilize foreground, midground, and background depth lanes with dynamic $Y$-sorting and multiplane staging.

### 2. Thou Shalt Not Use a Universal Screen Size for All Distances
A character standing in a deeper background lane must appear smaller ($\approx 0.80 - 0.85$ scale) than a character standing near the camera ($\approx 1.15 - 1.25$ scale). Apparent screen size must derive from scene depth and world scale.

### 3. Thou Shalt Not Allow Solid Geometry Clipping
Characters, limbs, weapons, and projectiles must **never** visually cut or pass through solid architecture, closed blast doors, or solid environmental props. Use proper collision, spatial pathing, or occlusion layering.

### 4. Thou Shalt Never Trigger Impact VFX Before Physical Collision
Attack causality is sacred. The lifecycle is strictly: `Attack -> Travel -> Contact -> Impact VFX -> Reaction`. Impact flashes, camera shakes, and target damage reactions must **never** fire before the projectile or weapon physically collides with the target's collision shape.

### 5. Thou Shalt Not Fill Empty Time with Aimless Motion
Do not add random jitter, continuous drifting, or unmotivated limb flailing to make a scene "busy." Motion must be driven by narrative intent, character personality, or deliberate secondary action.

### 6. Thou Shalt Not Eliminate Intentional Reaction Windows
Fast action does not mean zero comprehension time. Every major strike, reveal, or sudden turn must include a $0.30\text{s} - 0.60\text{s}$ cognitive processing window (the "thinking beat") so the viewer can register what happened before the next beat strikes.

### 7. Thou Shalt Not Allow Dead Pauses
Characters must never freeze in an unmotivated idle pose for $> 0.8\text{s}$ waiting for a script timer. If an action holds, maintain organic life through micro-acting: breathing, eye darts, blinking, or posture shifts.

### 8. Thou Shalt Not Use Camera Shakes or Pans to Disguise Weak Animation
Camera motion must support and elevate staging, not conceal weak silhouettes, missing contact frames, or bad timing. The animation must read cleanly with the camera locked static.

### 9. Thou Shalt Never Sacrifice Readability for Decorative Clutter
A bold, readable silhouette always trumps complex micro-details. Particle effects, smoke, and debris must never obscure the primary acting silhouette or facial expression of the performing character.

### 10. Thou Shalt Always Preserve Anatomical Proportions
Squash and stretch must preserve volume ($\text{Scale}_X \times \text{Scale}_Y \approx 1.0$). Cutout limbs must never detach from their joint sockets, and brawlers must maintain their approved style specification proportions ($45\%$ head, $22\%$ torso, $18\%$ legs, $15\%$ boots).

### 11. Thou Shalt Maintain Physical Ground Contact Without Foot Slipping
When a character is walking or running on the floor, their planted foot must lock solidly to the ground surface line without sliding like an ice skater. Horizontal root velocity must mathematically match the footstride distance divided by step duration.

### 12. Thou Shalt Strictly Map Character-Specific Audio Signatures
Leon attacks use Leon SFX; Nita attacks use Nita SFX; Bo arrows use Bo SFX. Attack audio, impact clangs, and voice vocalizations must never be cross-mapped, and impact sound effects must sync frame-accurately with physical collision contact.

---

## Enforcement & Rejection Criteria
Any pull request, automated render, or story scene that fails to observe this contract will fail the automated review suite (`docs/ANIMATION_REVIEW_CHECKLIST.md`). There are no exceptions for "rough drafts" or "test videos."
