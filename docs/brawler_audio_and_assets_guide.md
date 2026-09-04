# Brawler Audio (SFX & Voice Lines) Guide

This guide documents how to discover, download, and organize **genuine Brawl Stars** sound effects (SFX) and character voice lines (VO) into `cutenemi`'s asset system for Godot 4.

It is based on direct inspection of Supercell's internal game files (`characters.csv`, `skills.csv`, `sounds.csv`, `effects.csv`) and public asset mirrors, ensuring 100% authentic Supercell assets.

---

## 1. Asset Sources & Mirrors

### SFX & Voice Lines (VO)
Public mirror of official game data and audio packs:
```
tailsjs/brawl-stars-assets
```
Raw download URL template:
```
https://raw.githubusercontent.com/tailsjs/brawl-stars-assets/master/{VERSION}/sfx/{filename}.ogg
```
- `{VERSION}` — Game build number (e.g. `68.250`, `67.264`, `66.262`). Build `68.250` is verified and active.
- `{filename}` — Sound file name (e.g. `ninja_star_01.ogg`, `leon_ulti_vo_01.ogg`).

> **Rate Limit Note**: Always download directly from `raw.githubusercontent.com` or inspect raw CSV files. Do **not** rely on the GitHub REST API (`api.github.com`), which has strict unauthenticated rate limits (60 req/hr).

---

## 2. Project Folder Structure (`cutenemi`)

In `cutenemi`, all character audio follows this modular folder hierarchy:

```
cutenemi/
├── assets/
│   ├── audio/
│   │   ├── sfx/
│   │   │   ├── <brawler>/       # Character-specific gameplay sound effects
│   │   │   │   ├── leon/
│   │   │   │   │   ├── leon_atk_01.ogg            (Attack throw SFX)
│   │   │   │   │   ├── leon_invis_01.ogg          (Super vanish SFX)
│   │   │   │   │   ├── leon_invis_end_01.ogg      (Super reveal / decloak SFX)
│   │   │   │   │   └── leon_reload_01.ogg         (Ammo reload SFX)
│   │   │   └── common/          # Shared combat, UI, and environmental sound effects
│   │   │       ├── springboard_jump_01.ogg (or jump.ogg)
│   │   │       └── princess_land_01.ogg    (or land.ogg)
│   │   └── voices/
│   │       └── <brawler>/       # Character voice lines
│   │           └── leon/
│   │               ├── leon_start_vo_01.ogg
│   │               ├── leon_lead_vo_01.ogg
│   │               ├── leon_kill_vo_01.ogg
│   │               ├── leon_ulti_vo_01.ogg
│   │               ├── leon_hurt_vo_01.ogg
│   │               └── leon_die_vo_01.ogg
│   └── leon/                    # Vector rig parts (.svg)
```

---

## 3. Voice Line (VO) Categories

| Code | Meaning | Typical Usage |
|---|---|---|
| `start` | Match / round intro | Character spawn, game start, victory pose |
| `lead` | Lead / dominance taunt | Scoring, kill streaks, momentum shift |
| `kill` | Elimination line | Defeating a target or dummy |
| `ulti` / `super` | Super ability activation | Triggered on `SUPER_START` event |
| `hurt` | Damage grunt | Taking hit / interruption |
| `die` | Defeat / knock-out | HP reaching zero |
| `atk` | Attack grunt | Basic attack cast (only on select brawlers) |

---

## 4. Internal Character Names & Sound Mapping

Supercell frequently uses internal project codenames for brawlers and their abilities. To find the exact sounds for any brawler:

1. **Check Character Codename in `csv_logic/characters.csv`**:
   - URL: `https://raw.githubusercontent.com/tailsjs/brawl-stars-assets/master/68.250/csv_logic/characters.csv`
   - Example: **Leon** is internally named **`Ninja`**.
     - `WeaponSkill`: `NinjaWeapon`
     - `UltimateSkill`: `NinjaUlti`
     - `DefaultSkin`: `NinjaDefault`
     - `TakeDamageEffect`: `takedamage_gen`
     - `DeathEffect`: `death_ninja`
     - `FootstepClip`: `footstep`

2. **Check Weapon & Super Effects in `csv_logic/skills.csv`**:
   - `NinjaWeapon` -> `AttackEffect`: `ninja_attack`
   - `NinjaUlti` -> `UseEffect`: `ninja_go_invisible`

3. **Check Client Sound Events in `csv_client/sounds.csv`**:
   - `Leon_atk` -> `sfx/ninja_star_01.ogg`
   - `Leon_ulti` -> `sfx/ninja_invis_01.ogg`
   - `Leon_ulti_end` -> `sfx/ninja_invis_end_01.ogg`
   - `Dry_fire_leon` -> `sfx/ninja_star_dry_01.ogg`
   - `Leon_reload` -> `sfx/leon_reload_01.ogg`

---

## 5. Verified Leon Audio Assets Reference

### A. Sound Effects (`assets/audio/sfx/leon/`)
| File | Role | Event / State Hook |
|---|---|---|
| `leon_atk_01.ogg` | Shuriken Throw | `ATTACK_RELEASE` / projectile launch |
| `leon_invis_01.ogg` | Super Vanish | `SUPER_START` / smoke puff & ghost fade |
| `leon_invis_end_01.ogg` | Super Reveal | `SUPER_END` / uncloak & decloak chime |
| `leon_reload_01.ogg` | Ammo Reload | `ATTACK_END` / ammo recovery |

### B. Voice Lines (`assets/audio/voices/leon/`)
| File | Line Type |
|---|---|
| `leon_start_vo_01.ogg` | Match Start Taunt |
| `leon_start_vo_03.ogg` | Match Start Taunt Alt |
| `leon_lead_vo_01.ogg` | Dominance / Lead Taunt |
| `leon_lead_vo_02.ogg` | Dominance / Lead Taunt Alt |
| `leon_kill_vo_01.ogg` | Elimination Line ("Sneaky Time!") |
| `leon_kill_vo_02.ogg` | Elimination Line Alt |
| `leon_ulti_vo_01.ogg` | Super Cast ("Invisibility!") |
| `leon_ulti_vo_02.ogg` | Super Cast Alt |
| `leon_hurt_vo_01.ogg` | Hit Reaction Grunt |
| `leon_hurt_vo_02.ogg` | Hit Reaction Grunt Alt |
| `leon_die_vo_01.ogg` | Defeat Grunt |
| `leon_die_vo_02.ogg` | Defeat Grunt Alt |

---

## 6. How to Use in Godot 4 (`GDScript`)

Godot automatically imports `.ogg` files as `AudioStreamOggVorbis`.

### Preloading and Playing SFX & Voices in GDScript
```gdscript
extends CharacterBody2D

# Preload authentic audio streams
const SFX_ATTACK = preload("res://assets/audio/sfx/leon/ninja_star_01.ogg")
const SFX_SUPER_START = preload("res://assets/audio/sfx/leon/ninja_invis_01.ogg")
const SFX_SUPER_END = preload("res://assets/audio/sfx/leon/ninja_invis_end_01.ogg")
const VO_SUPER = preload("res://assets/audio/voices/leon/leon_ulti_vo_01.ogg")

@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer
@onready var voice_player: AudioStreamPlayer2D = $VoicePlayer

func _on_attack_release():
	sfx_player.stream = SFX_ATTACK
	sfx_player.pitch_scale = randf_range(0.95, 1.05) # Subtle variation
	sfx_player.play()

func _on_super_start():
	sfx_player.stream = SFX_SUPER_START
	sfx_player.play()
	
	# Play voice line alongside ability SFX
	voice_player.stream = VO_SUPER
	voice_player.play()

func _on_super_end():
	sfx_player.stream = SFX_SUPER_END
	sfx_player.play()
```

---

## 7. Automated Download Script for Any New Brawler

To add any future brawler's audio into the project, run this Python snippet from the project root:

```python
import os, urllib.request

def download_brawler_audio(brawler_name, sfx_dict, vo_list, version="68.250"):
    root = "."
    v_dir = f"{root}/assets/audio/voices/{brawler_name}"
    s_dir = f"{root}/assets/audio/sfx/{brawler_name}"
    for d in [v_dir, s_dir]:
        os.makedirs(d, exist_ok=True)
        
    base_sfx = f"https://raw.githubusercontent.com/tailsjs/brawl-stars-assets/master/{version}/sfx"
    
    # Download voice lines
    for vo in vo_list:
        dest = f"{v_dir}/{vo}"
        print(f"Downloading VO: {vo} -> {dest}")
        urllib.request.urlretrieve(f"{base_sfx}/{vo}", dest)
        
    # Download SFX
    for local_name, remote_file in sfx_dict.items():
        dest = f"{s_dir}/{local_name}"
        print(f"Downloading SFX: {remote_file} -> {dest}")
        urllib.request.urlretrieve(f"{base_sfx}/{remote_file}", dest)

# Example usage for Surge:
# download_brawler_audio(
#     brawler_name="surge",
#     sfx_dict={"surge_atk_01.ogg": "surge_atk_01.ogg", "surge_ulti_01.ogg": "surge_ulti_01.ogg"},
#     vo_list=["surge_start_vo_01.ogg", "surge_lead_vo_01.ogg", "surge_kill_vo_01.ogg", "surge_ulti_vo_01.ogg"]
# )
```
