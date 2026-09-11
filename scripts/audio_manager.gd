extends Node
class_name AudioManagerClass

# Centralized Production Audio Manager for Godot 2D Brawler
# Handles event-driven playback of authentic Brawl Stars SFX and Voice Lines.

signal audio_event_triggered(event_name: String, file_path: String, category: String)

enum AudioCategory {
	SFX,
	VOICE,
	MUSIC
}

# Volume Controls (0.0 to 1.0)
var volume_master: float = 1.0:
	set(val):
		volume_master = clampf(val, 0.0, 1.0)
var volume_sfx: float = 1.0:
	set(val):
		volume_sfx = clampf(val, 0.0, 1.0)
var volume_voice: float = 1.0:
	set(val):
		volume_voice = clampf(val, 0.0, 1.0)
var volume_music: float = 1.0:
	set(val):
		volume_music = clampf(val, 0.0, 1.0)

var is_muted: bool = false

# Telemetry
var last_audio_event: String = "None"
var last_audio_file: String = "None"
var last_event_time: float = 0.0
var total_events_played: int = 0
var event_counts: Dictionary = {}

# Variant tracking for multi-file deterministic selection
var _variant_indices: Dictionary = {}

# Preloaded Audio Streams (Authentic user-provided & curated audio)
const AUDIO_PATHS := {
	# Combat & Projectiles (SFX plays ONLY on projectile release, not on hit)
	"ATTACK_RELEASE": "res://assets/audio/sfx/leon/leon_atk_01.ogg",
	"RELOAD": "res://assets/audio/sfx/leon/leon_reload_01.ogg",
	"ATTACK_END": "res://assets/audio/sfx/leon/leon_reload_01.ogg",

	# Super Ability (Invisibility)
	"SUPER_START": "res://assets/audio/sfx/leon/leon_invis_01.ogg",
	"SUPER_END": "res://assets/audio/sfx/leon/leon_invis_end_01.ogg",

	# Movement
	"JUMP": "res://assets/audio/sfx/common/springboard_jump_01.ogg",
	"LAND": "res://assets/audio/sfx/common/princess_land_01.ogg"
}

# Character-specific SFX mappings (Ensures Nita and Leon never share incorrect attack SFX)
const CHARACTER_AUDIO_PATHS := {
	"nita": {
		"ATTACK_RELEASE": "res://assets/audio/sfx/nita/nita_atk_01.ogg",
		"PROJECTILE_SPAWN": "res://assets/audio/sfx/nita/nita_atk_01.ogg",
		"SUPER_START": "res://assets/audio/sfx/nita/bear_spawn_01.ogg",
		"SUPER_END": "res://assets/audio/sfx/nita/bear_spawn_01.ogg",
		"JUMP": "res://assets/audio/sfx/common/springboard_jump_01.ogg",
		"LAND": "res://assets/audio/sfx/common/princess_land_01.ogg"
	},
	"bo": {
		"ATTACK_START": "res://assets/audio/sfx/bo/bo_reload_01.ogg",
		"ATTACK_RELEASE": "res://assets/audio/sfx/bo/bo_atk_01.ogg",
		"PROJECTILE_SPAWN": "res://assets/audio/sfx/bo/bo_atk_01.ogg",
		"JUMP": "res://assets/audio/sfx/common/springboard_jump_01.ogg",
		"LAND": "res://assets/audio/sfx/common/princess_land_01.ogg"
	},
	"leon": {
		"ATTACK_RELEASE": "res://assets/audio/sfx/leon/leon_atk_01.ogg",
		"PROJECTILE_SPAWN": "res://assets/audio/sfx/leon/leon_atk_01.ogg",
		"RELOAD": "res://assets/audio/sfx/leon/leon_reload_01.ogg",
		"ATTACK_END": "res://assets/audio/sfx/leon/leon_reload_01.ogg",
		"SUPER_START": "res://assets/audio/sfx/leon/leon_invis_01.ogg",
		"SUPER_END": "res://assets/audio/sfx/leon/leon_invis_end_01.ogg",
		"JUMP": "res://assets/audio/sfx/common/springboard_jump_01.ogg",
		"LAND": "res://assets/audio/sfx/common/princess_land_01.ogg"
	}
}

# Voice Line Variants (Multi-file authentic variations)
const VOICE_VARIANTS := {
	"SUPER_START_VO": [
		"res://assets/audio/voices/leon/leon_ulti_vo_01.ogg",
		"res://assets/audio/voices/leon/leon_ulti_vo_02.ogg"
	],
	"CHARACTER_HIT": [
		"res://assets/audio/voices/leon/leon_hurt_vo_01.ogg",
		"res://assets/audio/voices/leon/leon_hurt_vo_02.ogg"
	],
	"KNOCKBACK_START": [
		"res://assets/audio/voices/leon/leon_hurt_vo_01.ogg",
		"res://assets/audio/voices/leon/leon_hurt_vo_02.ogg"
	],
	"DEATH": [
		"res://assets/audio/voices/leon/leon_die_vo_01.ogg",
		"res://assets/audio/voices/leon/leon_die_vo_02.ogg"
	],
	"KILL": [
		"res://assets/audio/voices/leon/leon_kill_vo_01.ogg",
		"res://assets/audio/voices/leon/leon_kill_vo_02.ogg"
	],
	"START": [
		"res://assets/audio/voices/leon/leon_start_vo_01.ogg",
		"res://assets/audio/voices/leon/leon_start_vo_03.ogg"
	]
}

# Character-specific Voice Line Variants
const CHARACTER_VOICE_VARIANTS := {
	"nita": {
		"CHARACTER_HIT": [
			"res://assets/audio/voices/nita/nita_hurt_vo_01.ogg",
			"res://assets/audio/voices/nita/nita_hurt_vo_02.ogg"
		],
		"KNOCKBACK_START": [
			"res://assets/audio/voices/nita/nita_hurt_vo_01.ogg",
			"res://assets/audio/voices/nita/nita_hurt_vo_02.ogg"
		],
		"DEATH": [
			"res://assets/audio/voices/nita/nita_die_vo_01.ogg",
			"res://assets/audio/voices/nita/nita_die_vo_02.ogg"
		],
		"KILL": [
			"res://assets/audio/voices/nita/nita_kill_vo_01.ogg",
			"res://assets/audio/voices/nita/nita_kill_vo_02.ogg"
		],
		"START": [
			"res://assets/audio/voices/nita/nita_start_vo_01.ogg",
			"res://assets/audio/voices/nita/nita_start_vo_02.ogg"
		],
		"SUPER_START_VO": [
			"res://assets/audio/voices/nita/nita_ulti_vo_01.ogg",
			"res://assets/audio/voices/nita/nita_ulti_vo_02.ogg"
		]
	},
	"leon": {
		"CHARACTER_HIT": [
			"res://assets/audio/voices/leon/leon_hurt_vo_01.ogg",
			"res://assets/audio/voices/leon/leon_hurt_vo_02.ogg"
		],
		"KNOCKBACK_START": [
			"res://assets/audio/voices/leon/leon_hurt_vo_01.ogg",
			"res://assets/audio/voices/leon/leon_hurt_vo_02.ogg"
		],
		"DEATH": [
			"res://assets/audio/voices/leon/leon_die_vo_01.ogg",
			"res://assets/audio/voices/leon/leon_die_vo_02.ogg"
		],
		"KILL": [
			"res://assets/audio/voices/leon/leon_kill_vo_01.ogg",
			"res://assets/audio/voices/leon/leon_kill_vo_02.ogg"
		],
		"START": [
			"res://assets/audio/voices/leon/leon_start_vo_01.ogg",
			"res://assets/audio/voices/leon/leon_start_vo_03.ogg"
		],
		"SUPER_START_VO": [
			"res://assets/audio/voices/leon/leon_ulti_vo_01.ogg",
			"res://assets/audio/voices/leon/leon_ulti_vo_02.ogg"
		]
	}
}

# Cache of loaded AudioStream objects
var _stream_cache: Dictionary = {}

# Audio Player Pool
const POOL_SIZE := 16
var _player_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

func _init() -> void:
	_preload_streams()

func _ready() -> void:
	_init_pool()

func _preload_streams() -> void:
	for ev in AUDIO_PATHS:
		var path = AUDIO_PATHS[ev]
		if ResourceLoader.exists(path):
			_stream_cache[path] = load(path)

	for c in CHARACTER_AUDIO_PATHS:
		var paths = CHARACTER_AUDIO_PATHS[c]
		for ev in paths:
			var path = paths[ev]
			if ResourceLoader.exists(path) and not _stream_cache.has(path):
				_stream_cache[path] = load(path)

	for ev in VOICE_VARIANTS:
		var list = VOICE_VARIANTS[ev]
		for path in list:
			if ResourceLoader.exists(path) and not _stream_cache.has(path):
				_stream_cache[path] = load(path)

	for c in CHARACTER_VOICE_VARIANTS:
		var char_vo = CHARACTER_VOICE_VARIANTS[c]
		for ev in char_vo:
			var list = char_vo[ev]
			for path in list:
				if ResourceLoader.exists(path) and not _stream_cache.has(path):
					_stream_cache[path] = load(path)

func _init_pool() -> void:
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "AudioPlayerPool_%d" % i
		add_child(p)
		_player_pool.append(p)

func _get_available_player() -> AudioStreamPlayer:
	if _player_pool.is_empty():
		_init_pool()

	# Find idle player
	for p in _player_pool:
		if not p.playing:
			return p

	# Round-robin steal if all busy
	var p = _player_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _player_pool.size()
	p.stop()
	return p

# --- Public Audio Event API ---

func trigger_event(event_name: String, custom_data: Dictionary = {}) -> bool:
	if is_muted:
		_record_telemetry(event_name, "[MUTED]")
		return false

	var played = false
	var char_name = str(custom_data.get("character", "")).to_lower()

	# 1. Check SFX mapping (character-specific first, then global fallback)
	var sfx_path = ""
	if not char_name.is_empty() and CHARACTER_AUDIO_PATHS.has(char_name):
		var char_paths = CHARACTER_AUDIO_PATHS[char_name]
		if char_paths.has(event_name):
			sfx_path = char_paths[event_name]

	if sfx_path.is_empty() and AUDIO_PATHS.has(event_name):
		sfx_path = AUDIO_PATHS[event_name]

	if not sfx_path.is_empty():
		var should_play_audio = true

		# Debounce attack burst: if ATTACK_RELEASE already started the throw sound on blade 0,
		# avoid double-stacking the exact same sound in the same millisecond.
		if event_name == "PROJECTILE_SPAWN" and custom_data.get("blade_index", 0) == 0:
			if last_audio_event == "ATTACK_RELEASE" and ((Time.get_ticks_msec() / 1000.0) - last_event_time) < 0.05:
				should_play_audio = false

		if should_play_audio:
			if _play_stream_from_path(sfx_path, AudioCategory.SFX, 1.0):
				_record_telemetry(event_name, sfx_path)
				played = true
		else:
			# Still record telemetry so event counts and tracking remain accurate
			_record_telemetry(event_name, sfx_path)
			played = true

	# 2. Check Voice Variants mapping (character-specific first, then global fallback)
	var variants: Array = []
	if not char_name.is_empty() and CHARACTER_VOICE_VARIANTS.has(char_name):
		var char_vo = CHARACTER_VOICE_VARIANTS[char_name]
		if char_vo.has(event_name):
			variants = char_vo[event_name]

	if variants.is_empty() and VOICE_VARIANTS.has(event_name):
		variants = VOICE_VARIANTS[event_name]

	if not variants.is_empty():
		var vo_path = _select_variant(event_name, variants)
		if _play_stream_from_path(vo_path, AudioCategory.VOICE, 1.0):
			_record_telemetry(event_name, vo_path)
			played = true

	# 3. Special Composite Events (e.g. SUPER_START also plays SUPER_START_VO)
	if event_name == "SUPER_START" and not custom_data.get("suppress_voice", false):
		var vo_variants: Array = []
		if not char_name.is_empty() and CHARACTER_VOICE_VARIANTS.has(char_name):
			var char_vo = CHARACTER_VOICE_VARIANTS[char_name]
			if char_vo.has("SUPER_START_VO"):
				vo_variants = char_vo["SUPER_START_VO"]
		if vo_variants.is_empty() and VOICE_VARIANTS.has("SUPER_START_VO"):
			vo_variants = VOICE_VARIANTS["SUPER_START_VO"]

		if not vo_variants.is_empty():
			var vo_path = _select_variant("SUPER_START_VO", vo_variants)
			_play_stream_from_path(vo_path, AudioCategory.VOICE, 0.95)

	if not played:
		# Silent or unmapped event (e.g., ATTACK_START, ATTACK_END)
		_record_telemetry(event_name, "[SILENT/NO_SFX]")

	return played

func _select_variant(event_name: String, variants: Array) -> String:
	if variants.is_empty():
		return ""
	if variants.size() == 1:
		return variants[0]

	var idx: int = _variant_indices.get(event_name, 0)
	var selected = variants[idx % variants.size()]
	_variant_indices[event_name] = (idx + 1) % variants.size()
	return selected

func _play_stream_from_path(path: String, category: AudioCategory, pitch_variation: float = 1.0) -> bool:
	if not _stream_cache.has(path):
		if ResourceLoader.exists(path):
			_stream_cache[path] = load(path)
		else:
			return false

	var stream: AudioStream = _stream_cache[path]
	if not stream:
		return false

	var player = _get_available_player()
	player.stream = stream

	# Calculate volume in dB
	var vol_scalar = volume_master
	match category:
		AudioCategory.SFX:
			vol_scalar *= volume_sfx
		AudioCategory.VOICE:
			vol_scalar *= volume_voice
		AudioCategory.MUSIC:
			vol_scalar *= volume_music

	if vol_scalar <= 0.001:
		return false

	player.volume_db = linear_to_db(vol_scalar)
	player.pitch_scale = pitch_variation
	if player.is_inside_tree():
		player.play()
	return true

func _record_telemetry(event_name: String, file_path: String) -> void:
	last_audio_event = event_name
	last_audio_file = file_path.get_file() if file_path.begins_with("res://") else file_path
	last_event_time = Time.get_ticks_msec() / 1000.0
	total_events_played += 1
	event_counts[event_name] = event_counts.get(event_name, 0) + 1
	audio_event_triggered.emit(event_name, last_audio_file, "SFX")

func toggle_mute() -> bool:
	is_muted = !is_muted
	if is_muted:
		stop_all()
	return is_muted

func stop_all() -> void:
	for p in _player_pool:
		p.stop()

var _bound_characters: Array[CharacterBody2D] = []

# Helper to automatically bind character controller signals
func bind_character(character: CharacterBody2D) -> void:
	if not character or _bound_characters.has(character):
		return
	_bound_characters.append(character)

	var char_id = "leon"
	if character.has_method("get_character_id"):
		char_id = character.get_character_id()
	elif "character_name" in character and not str(character.character_name).is_empty():
		char_id = str(character.character_name).to_lower()
	elif character.scene_file_path.to_lower().contains("nita") or (character.get_parent() and character.get_parent().name.to_lower().contains("nita")):
		char_id = "nita"

	if character.has_signal("attack_event"):
		character.attack_event.connect(func(ev_name: String, data: Dictionary):
			var merged_data = data.duplicate()
			if not merged_data.has("character"):
				merged_data["character"] = char_id
			trigger_event(ev_name, merged_data)
		)

	if character.has_signal("super_event"):
		character.super_event.connect(func(ev_name: String, data: Dictionary):
			var merged_data = data.duplicate()
			if not merged_data.has("character"):
				merged_data["character"] = char_id
			trigger_event(ev_name, merged_data)
		)

	if character.has_signal("state_changed"):
		character.state_changed.connect(func(_old_state: String, new_state: String):
			var data = {"character": char_id}
			match new_state:
				"JUMP_AIRBORNE":
					trigger_event("JUMP", data)
				"JUMP_LAND":
					trigger_event("LAND", data)
				"HIT":
					trigger_event("CHARACTER_HIT", data)
				"KNOCKBACK":
					trigger_event("KNOCKBACK_START", data)
		)
