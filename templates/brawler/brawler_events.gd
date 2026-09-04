class_name BrawlerEvents
extends RefCounted

# Standardized Event Constants for Brawler Characters
# Used across Animation, Audio, VFX, Combat, and Sequencing systems.

# Locomotion & Physics Events
const EVENT_IDLE := "IDLE"
const EVENT_WALK := "WALK"
const EVENT_RUN := "RUN"
const EVENT_STOP := "STOP"
const EVENT_TURN := "TURN"
const EVENT_JUMP := "JUMP"
const EVENT_FALL := "FALL"
const EVENT_LAND := "LAND"

# Combat Events
const EVENT_ATTACK_START := "ATTACK_START"
const EVENT_ATTACK_RELEASE := "ATTACK_RELEASE"
const EVENT_PROJECTILE_SPAWN := "PROJECTILE_SPAWN"
const EVENT_ATTACK_FOLLOW_THROUGH := "ATTACK_FOLLOW_THROUGH"
const EVENT_ATTACK_END := "ATTACK_END"

# Ability Events (Super & Gadget)
const EVENT_SUPER_START := "SUPER_START"
const EVENT_SUPER_ACTIVE := "SUPER_ACTIVE"
const EVENT_SUPER_END := "SUPER_END"
const EVENT_GADGET_ACTIVATED := "GADGET_ACTIVATED"

# Damage & Health Events
const EVENT_CHARACTER_HIT := "CHARACTER_HIT"
const EVENT_KNOCKBACK_START := "KNOCKBACK_START"
const EVENT_DEATH := "DEATH"
